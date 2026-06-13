import * as net from 'node:net';

/**
 * TCP client for Godot's MCP bridge on port 6008.
 *
 * Wire format:
 *   Request:  JSON string (no length prefix)
 *   Response: 4-byte little-endian length prefix + JSON string
 *
 * The MCP bridge understands these commands:
 *   ping(), get_scene_tree(), get_node(path), get_properties(path),
 *   call_method(path, method, args), list_nodes_by_type(type),
 *   find_node(name, contains?), take_snapshot(), get_diff(),
 *   get_node_snapshot(path), get_node_diff(path)
 */
export class MCPBridge {
  private host: string;
  private port: number;

  constructor(port = 6008, host = '127.0.0.1') {
    this.host = host;
    this.port = port;
  }

  /**
   * Send a raw JSON-RPC-like command to the Godot MCP bridge.
   * Returns the parsed response dictionary.
   */
  async request(command: string, payload: Record<string, unknown> = {}): Promise<any> {
    const body = JSON.stringify({ command, payload });

    return new Promise((resolve, reject) => {
      const client = new net.Socket();
      const timeout = 10_000;

      client.setTimeout(timeout);

      // Buffer to accumulate data from TCP chunks
      let buffer = Buffer.alloc(0);

      client.on('connect', () => {
        client.write(body);
      });

      client.on('data', (chunk: Buffer) => {
        // Append incoming data to buffer
        buffer = Buffer.concat([buffer, chunk]);

        // Need at least the 4-byte length prefix
        if (buffer.length < 4) return;

        // Godot's put_utf8_string prepends a 4-byte little-endian length prefix
        const msgLength = buffer.readUInt32LE(0);
        const totalLength = 4 + msgLength;

        // Wait until we have the full message
        if (buffer.length < totalLength) return;

        client.destroy();

        const payloadBytes = buffer.subarray(4, totalLength);

        try {
          const result = JSON.parse(payloadBytes.toString('utf-8'));
          resolve(result);
        } catch (e) {
          reject(new Error(`Invalid JSON response: ${payloadBytes.toString('utf-8')}`));
        }
      });

      client.on('error', (err) => {
        client.destroy();
        reject(err);
      });

      client.on('timeout', () => {
        client.destroy();
        reject(new Error('MCP bridge request timed out'));
      });

      client.connect(this.port, this.host);
    });
  }

  /** Check whether the Godot MCP bridge is reachable. */
  async ping(): Promise<boolean> {
    try {
      const result = await this.request('ping');
      return result?.ok === true;
    } catch {
      return false;
    }
  }

  /** Wait until the bridge responds or the timeout expires. */
  async waitForReady(timeoutMs = 30_000): Promise<void> {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      if (await this.ping()) return;
      await new Promise((r) => setTimeout(r, 500));
    }
    throw new Error(`MCP bridge did not become ready within ${timeoutMs}ms`);
  }

  /** Return the full scene tree as a serialized node hierarchy. */
  async getSceneTree(): Promise<any> {
    return this.request('get_scene_tree');
  }

  /** Get basic info (name, path, type) for a node by its scene path. */
  async getNode(path: string): Promise<any> {
    return this.request('get_node', { path });
  }

  /** Get all properties of a node by its scene path. */
  async getProperties(path: string): Promise<Record<string, any>> {
    return this.request('get_properties', { path });
  }

  /** Call a method on a node and return the result. */
  async callMethod(path: string, method: string, args: unknown[] = []): Promise<any> {
    return this.request('call_method', { path, method, args });
  }

  /** Find all nodes in the scene tree matching a Godot class name. */
  async listNodesByType(typeName: string): Promise<string[]> {
    const result = await this.request('list_nodes_by_type', { type: typeName });
    return result?.results ?? [];
  }

  /**
   * Find a node by name in the scene tree.
   * Searches recursively and returns the path of the first match.
   * Set contains=true to search for partial name matches.
   * Pass nodeType (e.g. "Node3D") to filter by Godot class.
   */
  async findNode(name: string, contains = false, nodeType?: string): Promise<string | null> {
    const payload: Record<string, unknown> = { name, contains };
    if (nodeType) payload.type = nodeType;
    const result = await this.request('find_node', payload);
    return result?.path ?? null;
  }

  /** Capture a snapshot of all current node paths for later diffing. */
  async takeSnapshot(): Promise<void> {
    await this.request('take_snapshot');
  }

  /**
   * Compare the current scene tree against the last snapshot.
   * Returns { added: string[], removed: string[], changed: string[] }
   */
  async getDiff(): Promise<{ added: string[]; removed: string[]; changed: string[] }> {
    return this.request('get_diff');
  }

  /** Capture a detailed snapshot of a single node. */
  async getNodeSnapshot(path: string): Promise<any> {
    return this.request('get_node_snapshot', { path });
  }

  /** Compare a node's current state against its last snapshot. */
  async getNodeDiff(path: string): Promise<any> {
    return this.request('get_node_diff', { path });
  }

  /**
   * Capture the Godot viewport as a PNG screenshot saved to disk.
   * @param savePath Absolute path where the PNG should be written.
   * @returns { status, path, size }
   */
  async takeScreenshot(savePath: string): Promise<{ status: string; path: string; size?: number[] }> {
    return this.request('take_screenshot', { path: savePath });
  }
}
