"""
RUNTIME — run per task.
Starts a Svelte agent session and streams the response.

Usage:
    python svelte_agent_run.py "Add a dark mode toggle to the navbar"
    python svelte_agent_run.py "Create a reusable Modal component"

Requires env vars (from svelte_agent_setup.py output):
    ANTHROPIC_API_KEY
    SVELTE_AGENT_ID
    SVELTE_ENVIRONMENT_ID

Optional:
    SVELTE_AGENT_VERSION  (pins to a specific version; defaults to latest)
    SVELTE_REPO_PATH      (local path to mount; not used without a file upload)
"""

import os
import sys
import json
import anthropic


def run_svelte_task(task: str) -> None:
    client = anthropic.Anthropic()

    agent_id = os.environ["SVELTE_AGENT_ID"]
    env_id = os.environ["SVELTE_ENVIRONMENT_ID"]
    agent_version = os.environ.get("SVELTE_AGENT_VERSION")

    # Build agent reference — pin version if provided
    if agent_version:
        agent_ref = {"type": "agent", "id": agent_id, "version": int(agent_version)}
    else:
        agent_ref = agent_id  # uses latest version

    print(f"Starting Svelte agent session...")
    session = client.beta.sessions.create(
        agent=agent_ref,
        environment_id=env_id,
        title=task[:80],
    )
    print(f"Session: {session.id}\n")
    print("=" * 60)

    # Stream first, then send message (stream-first ordering)
    tool_calls: list[dict] = []
    idle = False

    while not idle:
        with client.beta.sessions.stream(session_id=session.id) as stream:
            # Send the task (first loop) or tool results (subsequent loops)
            if not tool_calls:
                client.beta.sessions.events.send(
                    session_id=session.id,
                    events=[
                        {
                            "type": "user.message",
                            "content": [{"type": "text", "text": task}],
                        }
                    ],
                )
            else:
                results = [
                    {
                        "type": "user.custom_tool_result",
                        "custom_tool_use_id": call["id"],
                        "content": [{"type": "text", "text": call["result"]}],
                    }
                    for call in tool_calls
                ]
                client.beta.sessions.events.send(
                    session_id=session.id,
                    events=results,
                )
                tool_calls = []

            for event in stream:
                if event.type == "agent.message":
                    for block in event.content:
                        if block.type == "text":
                            print(block.text, end="", flush=True)

                elif event.type == "agent.thinking":
                    # Uncomment to show thinking:
                    # print(f"\n[thinking...]\n", flush=True)
                    pass

                elif event.type == "agent.custom_tool_use":
                    # Handle custom tools if any were defined
                    print(f"\n[tool: {event.tool_name}] {json.dumps(event.input)}")
                    tool_calls.append(
                        {"id": event.id, "name": event.tool_name, "result": "OK"}
                    )

                elif event.type == "session.status_idle":
                    stop_type = getattr(event, "stop_reason", {})
                    if hasattr(stop_type, "type") and stop_type.type == "requires_action":
                        # Waiting on tool results — loop back
                        break
                    else:
                        # Done
                        idle = True
                        break

                elif event.type == "session.status_terminated":
                    idle = True
                    break

    print("\n" + "=" * 60)
    print(f"\nSession complete: {session.id}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python svelte_agent_run.py <task description>")
        sys.exit(1)

    task = " ".join(sys.argv[1:])
    run_svelte_task(task)
