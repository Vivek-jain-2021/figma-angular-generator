#!/usr/bin/env bash
# download-assets.sh — Download Figma assets listed in .claude/assets-manifest.json
#
# Usage (called automatically by the asset-download hook, or manually):
#   bash .claude/scripts/download-assets.sh [project-root]
#
# Reads:   .claude/assets-manifest.json
# Writes:  src/assets/images/<name>.<ext>
#          src/assets/icons/<name>.svg
#
# Requires: curl
# Optional: FIGMA_TOKEN env var — enables SVG export via Figma REST API
#           (without it, falls back to the screenshot URL in the manifest)

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
MANIFEST="$PROJECT_ROOT/.claude/assets-manifest.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "No assets manifest found at $MANIFEST — skipping asset download."
  exit 0
fi

# Require node to parse JSON
if ! command -v node &>/dev/null; then
  echo "Error: node is required to parse the assets manifest."
  exit 1
fi

echo "Downloading assets from manifest: $MANIFEST"
echo ""

# Parse manifest and download each asset
node - "$PROJECT_ROOT" "$MANIFEST" << 'NODE_SCRIPT'
const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectRoot = process.argv[2];
const manifest    = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const fileKey     = manifest.fileKey || '';
const assets      = manifest.assets  || [];
const figmaToken  = process.env.FIGMA_TOKEN || '';

if (assets.length === 0) {
  console.log('No assets in manifest.');
  process.exit(0);
}

let downloaded = 0;
let skipped    = 0;
let failed     = 0;

for (const asset of assets) {
  const targetPath = path.join(projectRoot, asset.targetPath);
  const targetDir  = path.dirname(targetPath);

  // Create target directory if needed
  fs.mkdirSync(targetDir, { recursive: true });

  // Skip if already downloaded (unless --force is passed)
  if (fs.existsSync(targetPath) && !process.argv.includes('--force')) {
    console.log(`  SKIP  ${asset.targetPath}  (already exists)`);
    skipped++;
    continue;
  }

  // Determine download URL
  let downloadUrl = asset.url || '';

  // If SVG format + FIGMA_TOKEN available → use Figma export API for proper vector
  if (asset.format === 'svg' && figmaToken && fileKey && asset.nodeId) {
    try {
      const apiUrl = `https://api.figma.com/v1/images/${fileKey}?ids=${encodeURIComponent(asset.nodeId)}&format=svg&svg_include_id=true`;
      const result = JSON.parse(
        execSync(`curl -sf -H "X-Figma-Token: ${figmaToken}" "${apiUrl}"`, { encoding: 'utf8' })
      );
      const nodeUrl = result.images && result.images[asset.nodeId.replace('-', ':')];
      if (nodeUrl) downloadUrl = nodeUrl;
    } catch {
      // Fall back to manifest URL
    }
  }

  if (!downloadUrl) {
    console.log(`  FAIL  ${asset.targetPath}  (no download URL)`);
    failed++;
    continue;
  }

  // Download
  try {
    execSync(`curl -sf -L -o "${targetPath}" "${downloadUrl}"`, { stdio: 'pipe' });
    console.log(`  OK    ${asset.targetPath}`);
    downloaded++;
  } catch (err) {
    console.log(`  FAIL  ${asset.targetPath}  (curl error)`);
    failed++;
  }
}

console.log('');
console.log(`Done: ${downloaded} downloaded, ${skipped} skipped, ${failed} failed.`);
if (failed > 0) process.exit(1);
NODE_SCRIPT
