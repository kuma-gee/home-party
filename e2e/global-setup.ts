import { spawn, type ChildProcess } from 'node:child_process';
import * as net from 'node:net';
import * as path from 'node:path';

const GODOT_BINARY = process.env.GODOT_BINARY_PATH || '/usr/bin/godot';
const BRIDGE_PORT = 6008;
const HTTP_PORT = 8484;

let godotProcess: ChildProcess | null = null;

/**
 * Wait until a TCP port is accepting connections.
 */
function waitForPort(port: number, host: string, timeoutMs: number): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve, reject) => {
    const poll = () => {
      if (Date.now() > deadline) {
        reject(new Error(`Timed out waiting for ${host}:${port}`));
        return;
      }
      const sock = new net.Socket();
      sock.setTimeout(2000);
      sock.on('connect', () => {
        sock.destroy();
        resolve();
      });
      sock.on('error', () => {
        sock.destroy();
        setTimeout(poll, 500);
      });
      sock.on('timeout', () => {
        sock.destroy();
        setTimeout(poll, 500);
      });
      sock.connect(port, host);
    };
    poll();
  });
}

/**
 * Kill any orphaned godot --mcp-bridge processes from previous runs.
 */
function killOrphans(): void {
  try {
    const { execSync } = require('node:child_process');
    const stdout = execSync('pgrep -f "godot.*--mcp-bridge"', {
      encoding: 'utf-8',
      timeout: 3000,
    }).trim();
    if (stdout) {
      for (const pid of stdout.split('\n').filter(Boolean)) {
        try {
          process.kill(parseInt(pid, 10), 'SIGTERM');
          console.log(`  Killed orphan godot process: ${pid}`);
        } catch {
          // process already gone
        }
      }
    }
  } catch {
    // pgrep returned non-zero (no matches) or command not found
  }
}

export default async function globalSetup(): Promise<void> {
  console.log('\n--- E2E Global Setup ---');

  // Kill any leftover godot processes from previous failed runs
  killOrphans();

  // Check if the bridge is already running (e.g. user started Godot manually)
  const bridgeAlive = await new Promise<boolean>((resolve) => {
    const sock = new net.Socket();
    sock.setTimeout(1000);
    sock.on('connect', () => {
      sock.destroy();
      resolve(true);
    });
    sock.on('error', () => resolve(false));
    sock.on('timeout', () => {
      sock.destroy();
      resolve(false);
    });
    sock.connect(BRIDGE_PORT, '127.0.0.1');
  });

  if (bridgeAlive) {
    console.log('  Godot MCP bridge is already running — reusing.');
    return;
  }

  // Launch Godot
  const projectRoot = path.resolve(__dirname, '..');
  const args = ['--path', projectRoot, '--mcp-bridge', '--headless'];

  console.log(`  Launching: ${GODOT_BINARY} ${args.join(' ')}`);

  godotProcess = spawn(GODOT_BINARY, args, {
    cwd: projectRoot,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  godotProcess.stdout?.on('data', (data: Buffer) => {
    for (const line of data.toString().trim().split('\n')) {
      console.log(`  [godot] ${line}`);
    }
  });

  godotProcess.stderr?.on('data', (data: Buffer) => {
    for (const line of data.toString().trim().split('\n')) {
      console.log(`  [godot:err] ${line}`);
    }
  });

  godotProcess.on('exit', (code, signal) => {
    console.log(`  Godot exited (code=${code}, signal=${signal})`);
    godotProcess = null;
  });

  godotProcess.on('error', (err) => {
    console.error(`  Failed to start Godot: ${err.message}`);
    godotProcess = null;
    throw err;
  });

  // Wait for the MCP bridge to be ready
  console.log('  Waiting for MCP bridge on port 6008...');
  await waitForPort(BRIDGE_PORT, '127.0.0.1', 30_000);
  console.log('  MCP bridge is ready.');

  // Wait for the HTTP server to be ready
  console.log('  Waiting for HTTP server on port 8484...');
  await waitForPort(HTTP_PORT, '127.0.0.1', 15_000);
  console.log('  HTTP server is ready.');

  // Store the PID so global-teardown can kill it
  process.env.GODOT_PID = godotProcess.pid?.toString() ?? '';

  console.log('--- Setup complete ---\n');
}
