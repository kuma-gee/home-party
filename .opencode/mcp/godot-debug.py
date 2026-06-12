import json
import socket
import struct
import subprocess
import time
import os
import signal

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Godot Inspector")

HOST = "127.0.0.1"
PORT = 6008

GODOT_BINARY = "/usr/bin/godot"

# Resolve the project root by walking up from this script's location.
# Script lives at:  <project>/.opencode/mcp/godot-debug.py
# So project root = <script_dir>/../..
PROJECT_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..")
)

game_process = None


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _is_port_open(host=HOST, port=PORT, timeout=1.0) -> bool:
    """Check whether the Godot MCP bridge port is already accepting connections."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception:
        return False


def _godot_request(command: str, payload: dict | None = None) -> dict:
    """Send a JSON request to the Godot MCP bridge and return the parsed response.

    Returns a dict. On success it contains whatever the bridge returned.
    On failure it contains an ``"error"`` key with a human-readable message.
    """
    payload = payload or {}
    request = {"command": command, "payload": payload}

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect((HOST, PORT))
        sock.send(json.dumps(request).encode())

        # Godot's put_utf8_string prepends a 4-byte little-endian length prefix.
        length_bytes = sock.recv(4)
        if len(length_bytes) < 4:
            sock.close()
            return {"error": "incomplete response from bridge"}
        msg_length = struct.unpack('<I', length_bytes)[0]

        raw = b""
        while len(raw) < msg_length:
            chunk = sock.recv(msg_length - len(raw))
            if not chunk:
                break
            raw += chunk
        sock.close()

        return json.loads(raw.decode())
    except socket.timeout:
        return {"error": "request timed out — Godot MCP bridge is not responding"}
    except ConnectionRefusedError:
        return {"error": "connection refused — Godot MCP bridge is not running"}
    except json.JSONDecodeError:
        return {"error": "invalid JSON response from bridge"}
    except Exception as e:
        return {"error": str(e)}


# ---------------------------------------------------------------------------
# Lifecycle tools
# ---------------------------------------------------------------------------

@mcp.tool()
def ping() -> dict:
    """Check whether the Godot MCP bridge is reachable.`.
    """
    return _godot_request("ping")


@mcp.tool()
def launch_game(headless: bool = False) -> dict:
    """Start the game with the MCP enabled.
    """
    global game_process

    # Don't launch a second instance if the bridge is already up
    if _is_port_open():
        return {"status": "already_running"}

    # Kill any orphaned godot processes that are still holding the port
    try:
        result = subprocess.run(
            ["pgrep", "-f", "godot.*--mcp-bridge"],
            capture_output=True, text=True, timeout=3,
        )
        for pid_str in result.stdout.strip().splitlines():
            if pid_str:
                try:
                    os.kill(int(pid_str), signal.SIGTERM)
                    time.sleep(0.3)
                except (ProcessLookupError, PermissionError, ValueError):
                    pass
    except Exception:
        pass

    args = [
        GODOT_BINARY,
        "--path",
        PROJECT_PATH,
        "--mcp-bridge",
    ]

    if headless:
        args += ["--headless"]

    try:
        game_process = subprocess.Popen(
            args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        return {"status": "error", "message": f"Godot binary not found at {GODOT_BINARY}"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

    # Brief wait to catch immediate startup failures (e.g. missing project file)
    time.sleep(0.5)
    if game_process.poll() is not None:
        return {
            "status": "crashed",
            "pid": game_process.pid,
            "returncode": game_process.returncode,
        }

    return {
        "status": "started",
        "pid": game_process.pid,
    }


@mcp.tool()
def wait_for_godot(timeout: int = 15) -> dict:
    """Wait until the Godot MCP bridge is reachable on port 6008.
    """
    start = time.time()
    while time.time() - start < timeout:
        if _is_port_open(timeout=1.0):
            return {
                "status": "connected",
                "elapsed": round(time.time() - start, 1),
            }
        time.sleep(0.5)
    return {"status": "timeout", "elapsed": timeout}


@mcp.tool()
def stop_game() -> dict:
    """Kill the running Godot process"""
    global game_process
    pid = None

    if game_process is not None:
        pid = game_process.pid
        game_process.terminate()
        try:
            game_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            game_process.kill()
            game_process.wait(timeout=3)
        game_process = None

    # Safety net: kill any stray godot --mcp-bridge processes
    try:
        result = subprocess.run(
            ["pgrep", "-f", "godot.*--mcp-bridge"],
            capture_output=True, text=True, timeout=3,
        )
        for pid_str in result.stdout.strip().splitlines():
            if pid_str:
                try:
                    os.kill(int(pid_str), signal.SIGTERM)
                except (ProcessLookupError, PermissionError, ValueError):
                    pass
    except Exception:
        pass

    return {"status": "stopped", "pid": pid}


# ---------------------------------------------------------------------------
# Inspection tools
# ---------------------------------------------------------------------------

@mcp.tool()
def get_scene_tree() -> dict:
    """Return the running scene tree."""
    return _godot_request("get_scene_tree")


@mcp.tool()
def get_node(path: str) -> dict:
    """Get information about a node."""
    return _godot_request("get_node", {"path": path})


@mcp.tool()
def get_properties(path: str) -> dict:
    """Get node properties."""
    return _godot_request("get_properties", {"path": path})


@mcp.tool()
def call_method(path: str, method: str, args: list = []) -> dict:
    """Invoke a node method."""
    return _godot_request("call_method", {"path": path, "method": method, "args": args})


@mcp.tool()
def list_nodes_by_type(type_name: str) -> dict:
    """Find nodes by Godot class."""
    return _godot_request("list_nodes_by_type", {"type": type_name})


@mcp.tool()
def take_snapshot() -> dict:
    """Capture the current scene tree as a snapshot for later diffing.
    Use ``get_diff()`` to compare the current tree against this snapshot.
    """
    return _godot_request("take_snapshot")


@mcp.tool()
def get_diff() -> dict:
    """Compare the current scene tree against the last snapshot.
    Returns a dict with three lists: added, removed, changed
    """
    return _godot_request("get_diff")


@mcp.tool()
def get_node_snapshot(path: str) -> dict:
    """Capture a detailed snapshot of a single node
    Use ``get_node_diff()`` to compare the current state against this snapshot.
    """
    return _godot_request("get_node_snapshot", {"path": path})


@mcp.tool()
def get_node_diff(path: str) -> dict:
    """Compare a node's current state against its last snapshot.
    Returns a dict with three lists: added, removed, changed
    """
    return _godot_request("get_node_diff", {"path": path})


if __name__ == "__main__":
    mcp.run()
