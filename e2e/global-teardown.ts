export default async function globalTeardown(): Promise<void> {
  console.log('\n--- E2E Global Teardown ---');

  const pid = process.env.GODOT_PID;
  if (!pid) {
    console.log('  No Godot PID stored — skipping teardown.');
    return;
  }

  const pidNum = parseInt(pid, 10);
  if (isNaN(pidNum)) {
    console.log(`  Invalid GODOT_PID: ${pid} — skipping.`);
    return;
  }

  try {
    console.log(`  Terminating Godot process (PID: ${pidNum})...`);
    process.kill(pidNum, 'SIGTERM');
    // Give it 5 seconds to shut down gracefully
    await new Promise((resolve) => setTimeout(resolve, 5000));
    // If still alive, force kill
    try {
      process.kill(pidNum, 0); // check if alive
      console.log('  Process still alive — sending SIGKILL...');
      process.kill(pidNum, 'SIGKILL');
    } catch {
      console.log('  Process terminated gracefully.');
    }
  } catch (err: any) {
    if (err.code === 'ESRCH') {
      console.log('  Process already exited.');
    } else {
      console.error(`  Failed to kill process: ${err.message}`);
    }
  }

  console.log('--- Teardown complete ---\n');
}
