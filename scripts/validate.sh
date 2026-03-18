#!/usr/bin/env bash
# validate.sh — Validate that the plugin structure is complete and well-formed.
#
# Usage:
#   bash scripts/validate.sh
#
# Exits 0 if valid, 1 if any required files are missing or malformed.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

check_file() {
  local file="$PLUGIN_DIR/$1"
  if [[ ! -f "$file" ]]; then
    echo "  MISSING: $1"
    ((ERRORS++)) || true
  else
    echo "  OK:      $1"
  fi
}

check_json() {
  local rel="$1"
  local file="$PLUGIN_DIR/$rel"
  if [[ ! -f "$file" ]]; then
    echo "  MISSING: $rel"
    ((ERRORS++)) || true
  else
    # Pass file path via env var to avoid shell-quoting issues with spaces in path
    if ! VALIDATE_FILE="$file" node -e "JSON.parse(require('fs').readFileSync(process.env.VALIDATE_FILE,'utf8'))" 2>/dev/null; then
      echo "  INVALID JSON: $rel"
      ((ERRORS++)) || true
    else
      echo "  OK:      $rel"
    fi
  fi
}

echo "Validating figma-angular-generator plugin..."
echo ""

echo "[ Manifest ]"
check_json ".claude-plugin/plugin.json"

echo ""
echo "[ Commands ]"
check_file "commands/generate-component.md"
check_file "commands/generate-page.md"
check_file "commands/generate-all.md"
check_file "commands/setup-wizard.md"
check_file "commands/requirements-to-figma.md"
check_file "commands/api-to-components.md"
check_file "commands/push-to-figma.md"

echo ""
echo "[ Agents ]"
check_file "agents/figma-analyzer.md"
check_file "agents/angular-generator.md"
check_file "agents/requirements-analyzer.md"
check_file "agents/api-analyzer.md"

echo ""
echo "[ Skills ]"
check_file "skills/angular-component.md"
check_file "skills/figma-to-css.md"
check_file "skills/requirements-to-wireframe.md"
check_file "skills/api-to-angular.md"
check_file "skills/html-wireframe.md"
check_file "skills/wireframes-to-figma.md"

echo ""
echo "[ Hooks ]"
check_json "hooks/hooks.json"
check_file "hooks/scripts/validate-figma-url.js"
check_file "hooks/scripts/log-generated-file.js"
check_file "hooks/scripts/trigger-asset-download.js"

echo ""
echo "[ Scripts ]"
check_file "scripts/install.sh"
check_file "scripts/validate.sh"
check_file "scripts/download-assets.sh"
check_file "scripts/process-assets.sh"

echo ""
echo "[ Docs ]"
check_file "README.md"
check_json "package.json"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "$ERRORS check(s) failed."
  exit 1
fi
