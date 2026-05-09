#!/usr/bin/env python3
"""
Convert a VS Code Copilot Chat debug log session to ATIF v1.7 JSON.

ATIF spec: https://github.com/harbor-framework/harbor/blob/main/rfcs/0001-trajectory-format.md

Data is read from the session's debug-log directory, which contains:
  - main.jsonl          : all session events (tool calls, LLM requests, agent responses)
  - system_prompt_0.json: system prompt content
  - tools_0.json        : tool definitions available to the agent

Usage:
  python3 export_copilot_to_atif.py --session SESSION_UUID [--out output.json]
  python3 export_copilot_to_atif.py --debug-log-dir /path/to/dir [--out output.json]
"""

import json
import re
import datetime
import sys
import argparse
from pathlib import Path


# ---------------------------------------------------------------------------
# Discovery helpers
# ---------------------------------------------------------------------------

def find_debug_log_dir(session_id: str) -> Path:
    """Search all VS Code workspace storage locations for the session debug log."""
    base = Path.home() / '.config' / 'Code' / 'User' / 'workspaceStorage'
    if not base.exists():
        raise SystemExit(f'VS Code workspaceStorage not found at {base}')
    for ws_dir in base.iterdir():
        candidate = ws_dir / 'GitHub.copilot-chat' / 'debug-logs' / session_id
        if candidate.is_dir():
            return candidate
    raise SystemExit(f'Debug log directory not found for session: {session_id}')



# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def read_jsonl(path: Path) -> list:
    """Read a JSONL file, skipping malformed lines."""
    items = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                items.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return items


def ms_to_iso(ms) -> str:
    """Convert a millisecond UNIX timestamp to an ISO 8601 string."""
    if ms is None:
        return None
    try:
        dt = datetime.datetime.fromtimestamp(ms / 1000.0, tz=datetime.timezone.utc)
        return dt.strftime('%Y-%m-%dT%H:%M:%S.') + f'{dt.microsecond // 1000:03d}Z'
    except Exception:
        return None


def parse_json_field(value):
    """Return the value as a Python object.  Handles already-parsed objects and
    JSON-encoded strings transparently."""
    if isinstance(value, (list, dict)):
        return value
    if isinstance(value, str) and value.strip():
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return None
    return None


# ---------------------------------------------------------------------------
# VS Code internal tool-result format -> plain text
# ---------------------------------------------------------------------------

def _collect_vscode_text_nodes(obj: object, out: list) -> None:
    """Recursively collect (priority, text) pairs from a VS Code node tree."""
    if isinstance(obj, dict):
        if obj.get('type') == 2 and 'text' in obj:
            out.append((obj.get('priority', 0), obj['text']))
        for child in obj.get('children', []):
            _collect_vscode_text_nodes(child, out)
    elif isinstance(obj, list):
        for item in obj:
            _collect_vscode_text_nodes(item, out)


def extract_vscode_node_text(node: object) -> str:
    """Convert a VS Code internal node tree to plain text.

    The tree stores content in leaf nodes (type=2) with a ``priority`` field.
    Higher priority values correspond to content that appears earlier in the
    original output, so we sort descending before joining.
    """
    nodes = []
    _collect_vscode_text_nodes(node, nodes)
    if not nodes:
        return ''
    nodes.sort(key=lambda x: x[0], reverse=True)
    return ''.join(text for _, text in nodes)


_VSCODE_NODE_PAT = re.compile(
    r'"priority":(\d+),"text":"((?:[^"\\]|\\.)*?)"'
)


def _extract_vscode_text_via_regex(raw: str) -> str:
    """Fallback: extract (priority, text) pairs from a potentially-truncated
    VS Code node JSON string using a regex and reconstruct the content."""
    nodes = []
    for m in _VSCODE_NODE_PAT.finditer(raw):
        priority = int(m.group(1))
        try:
            text = json.loads(f'"{ m.group(2) }"')
        except json.JSONDecodeError:
            text = m.group(2)
        nodes.append((priority, text))
    if not nodes:
        return ''
    nodes.sort(key=lambda x: x[0], reverse=True)
    return ''.join(t for _, t in nodes)


def extract_tool_result_text(result_raw: object) -> str:
    """Extract a human-readable string from a tool_call event's attrs.result.

    The result field is a VS Code internal node tree serialised as JSON.
    That JSON string is often truncated (capped at ~5 KB in the debug log),
    so we try a full parse first and fall back to a regex scan.
    """
    if not result_raw:
        return ''

    # If it's already a plain (non-JSON) string, return as-is
    if isinstance(result_raw, str) and not result_raw.lstrip().startswith('{'):
        return result_raw

    obj = parse_json_field(result_raw)
    if obj is not None:
        # Wrapped node: {"node": {...}}
        if isinstance(obj, dict) and 'node' in obj:
            text = extract_vscode_node_text(obj['node'])
            return text if text else json.dumps(obj)[:2000]
        # Direct node
        if isinstance(obj, dict) and obj.get('type') in (1, 2):
            text = extract_vscode_node_text(obj)
            return text if text else json.dumps(obj)[:2000]
        return json.dumps(obj)[:2000]

    # JSON parse failed (truncated) — use regex fallback on the raw string
    if isinstance(result_raw, str):
        text = _extract_vscode_text_via_regex(result_raw)
        if text:
            return text
        return result_raw[:2000]

    return str(result_raw)[:2000]


# ---------------------------------------------------------------------------
# Message-part helpers
# ---------------------------------------------------------------------------

def parts_text(parts: list, part_type: str) -> str:
    """Join the content of all parts of the given type."""
    return '\n'.join(
        str(p.get('content') or p.get('text') or '')
        for p in parts
        if p.get('type') == part_type and (p.get('content') or p.get('text'))
    )


def parse_tool_calls(parts: list) -> list:
    """Return ATIF tool_call objects from the tool_call parts of a message."""
    result = []
    for p in parts:
        if p.get('type') != 'tool_call':
            continue
        args = p.get('arguments', {})
        if isinstance(args, str):
            args = parse_json_field(args) or {}
        result.append({
            'tool_call_id': p.get('id', ''),
            'function_name': p.get('name', ''),
            'arguments': args if isinstance(args, dict) else {},
        })
    return result


# ---------------------------------------------------------------------------
# Turn grouping
# ---------------------------------------------------------------------------

def build_turns(events: list) -> list:
    """Group events into agent turns bounded by turn_start / turn_end.

    Each turn dict contains:
      pre_llm_tools  - tool_call events that ran *before* the LLM call (these
                       are the results of the *previous* turn's LLM tool_calls)
      post_llm_tools - tool_call events that ran *after* the LLM call (rare)
      llm_request    - the llm_request event
      agent_response - the agent_response event
    """
    turns = []
    current = None
    llm_seen = False

    for event in events:
        etype = event.get('type', '')

        if etype == 'turn_start':
            current = {
                'pre_llm_tools': [],
                'post_llm_tools': [],
                'llm_request': None,
                'agent_response': None,
            }
            llm_seen = False

        elif etype == 'tool_call' and current is not None:
            tc = {
                'name': event.get('name', ''),
                'ts': event.get('ts'),
                'dur': event.get('dur'),
                'args': parse_json_field(event.get('attrs', {}).get('args', '')),
                'result_raw': event.get('attrs', {}).get('result', ''),
            }
            if llm_seen:
                current['post_llm_tools'].append(tc)
            else:
                current['pre_llm_tools'].append(tc)

        elif etype == 'llm_request' and current is not None:
            current['llm_request'] = event
            llm_seen = True

        elif etype == 'agent_response' and current is not None:
            current['agent_response'] = event

        elif etype == 'turn_end' and current is not None:
            turns.append(current)
            current = None
            llm_seen = False

    return turns


# ---------------------------------------------------------------------------
# Observation builder
# ---------------------------------------------------------------------------

def build_observations(tool_calls: list, executed: list) -> list:
    """Pair LLM-requested tool_calls with the events that executed them.

    Matching is done by function name in the order the LLM requested them.
    For multiple calls to the same function the nth request matches the nth
    execution of that function in the executed list.
    """
    by_name: dict = {}
    for tc in executed:
        by_name.setdefault(tc['name'], []).append(tc)

    name_pos: dict = {}
    results = []
    for tc in tool_calls:
        fname = tc['function_name']
        pos = name_pos.get(fname, 0)
        candidates = by_name.get(fname, [])
        exec_tc = candidates[pos] if pos < len(candidates) else None
        name_pos[fname] = pos + 1

        content = extract_tool_result_text(exec_tc['result_raw']) if exec_tc else ''
        results.append({
            'source_call_id': tc['tool_call_id'],
            'content': content,
        })
    return results


# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------

def strip_none(obj):
    """Remove all None values recursively."""
    if isinstance(obj, dict):
        return {k: strip_none(v) for k, v in obj.items() if v is not None}
    if isinstance(obj, list):
        return [strip_none(item) for item in obj]
    return obj


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Convert a VS Code Copilot Chat debug log session to ATIF v1.7 JSON.',
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--session', '-s',
        help='Session UUID -- auto-discovers the debug log directory under VS Code workspaceStorage',
    )
    group.add_argument(
        '--debug-log-dir', '-d',
        help='Path to the session debug log directory',
    )
    parser.add_argument('--out', '-o', default=None,
                        help='Output file path (default: <session_id>.atif.json)')
    args = parser.parse_args()

    # Locate debug log directory
    if args.debug_log_dir:
        log_dir = Path(args.debug_log_dir).expanduser()
        if not log_dir.is_dir():
            raise SystemExit(f'Directory not found: {log_dir}')
        session_id = log_dir.name
    else:
        session_id = args.session
        log_dir = find_debug_log_dir(session_id)

    print(f'Reading: {log_dir}', file=sys.stderr)

    main_log = log_dir / 'main.jsonl'
    if not main_log.exists():
        raise SystemExit(f'main.jsonl not found in {log_dir}')

    events = read_jsonl(main_log)

    # -- Top-level event extraction -------------------------------------------
    session_start = next((e for e in events if e.get('type') == 'session_start'), {})
    user_messages = [e for e in events if e.get('type') == 'user_message']
    turns = build_turns(events)

    if not turns:
        raise SystemExit('No agent turns found in debug log.')

    # -- System prompt --------------------------------------------------------
    system_prompt_text = ''
    sp_file = log_dir / 'system_prompt_0.json'
    if sp_file.exists():
        try:
            sp_data = json.loads(sp_file.read_text(encoding='utf-8'))
            parts = parse_json_field(sp_data.get('content', ''))
            if isinstance(parts, list):
                system_prompt_text = '\n'.join(
                    str(p.get('content') or p.get('text') or '')
                    for p in parts
                    if isinstance(p, dict) and p.get('type') == 'text'
                )
            elif isinstance(sp_data.get('content'), str):
                system_prompt_text = sp_data['content']
        except Exception as exc:
            print(f'Warning: could not read system_prompt_0.json: {exc}', file=sys.stderr)

    # -- Tool definitions -----------------------------------------------------
    tool_definitions = None
    tools_file = log_dir / 'tools_0.json'
    if tools_file.exists():
        try:
            td_data = json.loads(tools_file.read_text(encoding='utf-8'))
            td_list = parse_json_field(td_data.get('content', ''))
            if isinstance(td_list, list):
                tool_definitions = []
                for t in td_list:
                    if not isinstance(t, dict):
                        continue
                    fn: dict = {
                        'name': t.get('name', ''),
                        'description': t.get('description', ''),
                    }
                    params = t.get('parameters') or t.get('inputSchema')
                    if params:
                        fn['parameters'] = params
                    tool_definitions.append({'type': 'function', 'function': fn})
        except Exception as exc:
            print(f'Warning: could not read tools_0.json: {exc}', file=sys.stderr)

    # -- Determine default model name -----------------------------------------
    model_name = None
    for turn in turns:
        lr = turn.get('llm_request') or {}
        m = lr.get('attrs', {}).get('model')
        if m:
            model_name = m
            break
        name = lr.get('name', '')
        if ':' in name:
            model_name = name.split(':', 1)[1]
            break

    copilot_version = session_start.get('attrs', {}).get('copilotVersion', 'unknown')

    # -- Build steps ----------------------------------------------------------
    # The event timeline looks like:
    #   user_message              <- user sends a request
    #   turn_start:0
    #     tool_call (autonomous)  <- pre-LLM actions (e.g. manage_todo_list)
    #     llm_request             <- first LLM call
    #     agent_response          <- LLM output (may contain tool_calls)
    #   turn_end:0
    #   turn_start:1
    #     tool_call (read_file)   <- executing turn-0's LLM tool_calls
    #     tool_call (fetch_...)
    #     llm_request             <- second LLM call with those results
    #     agent_response
    #   turn_end:1
    #   ...
    #
    # Therefore: turn[N].pre_llm_tools are the observations for turn[N-1]'s
    # agent step.  Turn[0].pre_llm_tools are autonomous (skipped for observations).

    steps: list = []
    step_id = 1

    # System step
    if system_prompt_text:
        steps.append({
            'step_id': step_id,
            'source': 'system',
            'message': system_prompt_text,
            'timestamp': ms_to_iso(session_start.get('ts')),
        })
        step_id += 1

    # Assign user_message events to turn indices: each user_message goes before
    # the first turn whose start timestamp is >= the message timestamp.
    turn_start_ts = []
    for event in events:
        if event.get('type') == 'turn_start':
            turn_start_ts.append(event.get('ts', 0))

    um_by_turn: dict = {}  # turn_idx -> [user_message_event, ...]
    for um in user_messages:
        um_ts = um.get('ts', 0)
        assigned = len(turns)  # default: after all turns
        for i, ts in enumerate(turn_start_ts):
            if ts >= um_ts:
                assigned = i
                break
        um_by_turn.setdefault(assigned, []).append(um)

    total_prompt = 0
    total_completion = 0
    total_cached = 0

    for turn_idx, turn in enumerate(turns):
        # Emit user messages that precede this turn
        for um in um_by_turn.get(turn_idx, []):
            content = um.get('attrs', {}).get('content', '')
            steps.append({
                'step_id': step_id,
                'source': 'user',
                'message': content,
                'timestamp': ms_to_iso(um.get('ts')),
            })
            step_id += 1

        ar = turn.get('agent_response')
        lr = turn.get('llm_request')
        if not ar:
            continue

        # Parse the assistant's output for this turn
        response_msgs = parse_json_field(ar.get('attrs', {}).get('response', '[]')) or []
        assistant_msg = next((m for m in response_msgs if m.get('role') == 'assistant'), None)
        if not assistant_msg:
            continue

        msg_parts = assistant_msg.get('parts', [])
        message_text = parts_text(msg_parts, 'text')
        # Reasoning may live in attrs.reasoning or in a 'reasoning' part
        reasoning_text = (
            ar.get('attrs', {}).get('reasoning', '')
            or parts_text(msg_parts, 'reasoning')
        )
        tool_calls = parse_tool_calls(msg_parts)

        # Observations come from the *next* turn's pre_llm_tools
        observation = None
        if tool_calls and turn_idx + 1 < len(turns):
            executed = turns[turn_idx + 1].get('pre_llm_tools', [])
            if executed:
                obs_results = build_observations(tool_calls, executed)
                if obs_results:
                    observation = {'results': obs_results}

        # Metrics from the llm_request event
        metrics = None
        if lr:
            lr_attrs = lr.get('attrs', {})
            m: dict = {}
            if lr_attrs.get('inputTokens') is not None:
                m['prompt_tokens'] = lr_attrs['inputTokens']
                total_prompt += lr_attrs['inputTokens']
            if lr_attrs.get('outputTokens') is not None:
                m['completion_tokens'] = lr_attrs['outputTokens']
                total_completion += lr_attrs['outputTokens']
            if m:
                metrics = m

        # Per-step model override (only if different from the session default)
        step_model = None
        if lr:
            m = (lr.get('attrs', {}).get('model')
                 or (lr.get('name', '').split(':', 1)[1] if ':' in lr.get('name', '') else None))
            if m and m != model_name:
                step_model = m

        # Timestamp: end of LLM call (start + duration)
        ts = None
        if lr and lr.get('ts') is not None and lr.get('dur') is not None:
            ts = ms_to_iso(lr['ts'] + lr['dur'])

        step: dict = {
            'step_id': step_id,
            'source': 'agent',
            'message': message_text,
            'timestamp': ts,
        }
        if step_model:
            step['model_name'] = step_model
        if reasoning_text:
            step['reasoning_content'] = reasoning_text
        if tool_calls:
            step['tool_calls'] = tool_calls
        if observation:
            step['observation'] = observation
        if metrics:
            step['metrics'] = metrics

        steps.append(step)
        step_id += 1

    # Emit any user messages that appear after all turns (edge case)
    for um in um_by_turn.get(len(turns), []):
        content = um.get('attrs', {}).get('content', '')
        steps.append({
            'step_id': step_id,
            'source': 'user',
            'message': content,
            'timestamp': ms_to_iso(um.get('ts')),
        })
        step_id += 1

    # -- Assemble ATIF document -----------------------------------------------
    final_metrics: dict = {'total_steps': len(steps)}
    if total_prompt:
        final_metrics['total_prompt_tokens'] = total_prompt
    if total_completion:
        final_metrics['total_completion_tokens'] = total_completion
    if total_cached:
        final_metrics['total_cached_tokens'] = total_cached

    agent_obj: dict = {
        'name': 'github.copilot-chat',
        'version': copilot_version,
    }
    if model_name:
        agent_obj['model_name'] = model_name
    if tool_definitions:
        agent_obj['tool_definitions'] = tool_definitions

    atif = {
        'schema_version': 'ATIF-v1.7',
        'session_id': session_id,
        'agent': agent_obj,
        'notes': 'Converted from VS Code Copilot Chat debug log (main.jsonl).',
        'final_metrics': final_metrics,
        'steps': steps,
    }

    atif = strip_none(atif)

    out_path = args.out or f'{session_id}.atif.json'
    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(atif, ensure_ascii=False, indent=2), encoding='utf-8')

    print(f'Wrote {len(steps)} steps -> {out}', file=sys.stderr)
    print(str(out))


if __name__ == '__main__':
    main()
