const { spawnSync } = require('child_process');
const path = require('path');

const script = path.join(__dirname, 'fix_docx.ps1');
const result = spawnSync('powershell.exe', [
  '-NoProfile',
  '-ExecutionPolicy',
  'Bypass',
  '-File',
  script,
], {
  cwd: __dirname,
  stdio: 'inherit',
});

if (result.status !== 0) {
  process.exit(result.status || 1);
}
