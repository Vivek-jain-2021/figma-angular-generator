#!/usr/bin/env node
// trigger-asset-download.js
// PostToolUse hook — fires after every Write tool call.
// When the written file is assets-manifest.json, auto-runs download-assets.sh
// then process-assets.sh so assets are ready before Angular code generation.

const { execSync } = require('child_process');

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  let toolInput;
  try {
    const payload = JSON.parse(input);
    toolInput = payload.tool_input || payload.input || {};
  } catch {
    process.exit(0);
  }

  const filePath = toolInput.file_path || toolInput.path || '';

  // Only trigger when Claude writes the assets manifest
  if (!filePath.includes('assets-manifest.json')) {
    process.exit(0);
  }

  // Derive project root: walk up from the manifest file path until we find
  // a directory that contains src/ or angular.json
  const path = require('path');
  const fs   = require('fs');

  let dir = path.dirname(filePath);
  let projectRoot = dir;

  // Walk up max 5 levels looking for angular.json or src/
  for (let i = 0; i < 5; i++) {
    if (fs.existsSync(path.join(dir, 'angular.json')) ||
        fs.existsSync(path.join(dir, 'src'))) {
      projectRoot = dir;
      break;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break; // filesystem root
    dir = parent;
  }

  const downloadScript  = path.join(projectRoot, '.claude', 'scripts', 'download-assets.sh');
  const processScript   = path.join(projectRoot, '.claude', 'scripts', 'process-assets.sh');

  // Only run if scripts are installed in the target project
  if (!fs.existsSync(downloadScript)) {
    process.exit(0);
  }

  console.log('\n[figma-angular] Assets manifest written — downloading assets...');

  try {
    execSync(`bash "${downloadScript}" "${projectRoot}"`, { stdio: 'inherit' });
  } catch {
    console.error('[figma-angular] download-assets.sh failed — check output above.');
    process.exit(0); // non-blocking: don't abort the conversation
  }

  if (fs.existsSync(processScript)) {
    console.log('[figma-angular] Optimizing assets...');
    try {
      execSync(`bash "${processScript}" "${projectRoot}"`, { stdio: 'inherit' });
    } catch {
      // Optimization failures are non-fatal
    }
  }

  console.log('[figma-angular] Assets ready. Continuing with code generation.\n');
  process.exit(0);
});
