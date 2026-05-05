const { spawnSync } = require('child_process');
const path = require('path');

const generator = path.join(__dirname, 'scripts', 'generate_study_area_map.js');
const generated = spawnSync('node', [generator], {
  cwd: __dirname,
  stdio: 'inherit',
});

if (generated.status !== 0) {
  process.exit(generated.status || 1);
}

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
