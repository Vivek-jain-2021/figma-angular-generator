#!/usr/bin/env bash
# =============================================================================
# install.sh — Install figma-angular-generator plugin.
#
# Usage:
#   bash scripts/install.sh                        # interactive mode (recommended)
#   bash scripts/install.sh ./my-app               # install into existing Angular project
#   bash scripts/install.sh ./workspace            # install into empty folder
#   bash scripts/install.sh --new my-app           # create Angular project + install
#   bash scripts/install.sh ./my-app --force       # reinstall / overwrite
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}[figma-angular]${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $*"; }
error()   { echo -e "${RED}  ✗ ERROR:${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── OS Detection ──────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s 2>/dev/null || echo "Windows")" in
    Linux*)  echo "linux"   ;;
    Darwin*) echo "mac"     ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) [[ "${OS:-}" == "Windows_NT" ]] && echo "windows" || echo "unknown" ;;
  esac
}

OS_TYPE=$(detect_os)

resolve_cmd() {
  local base="$1"
  if [[ "$OS_TYPE" == "windows" ]] && command -v "${base}.cmd" &>/dev/null; then
    echo "${base}.cmd"
  else
    echo "$base"
  fi
}

NODE_CMD=$(resolve_cmd node)
NPM_CMD=$(resolve_cmd npm)
NG_CMD=$(resolve_cmd ng)

# ── Parse args ────────────────────────────────────────────────────────────────
TARGET_DIR=""
NEW_PROJECT=""
FORCE=false
STYLESHEET="scss"
INSTALL_MODE=""   # "existing" | "empty" | "new"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --new)    NEW_PROJECT="${2:-}"; shift 2 ;;
    --force)  FORCE=true; shift ;;
    --style)  STYLESHEET="${2:-scss}"; shift 2 ;;
    -*)       error "Unknown flag: $1"; exit 1 ;;
    *)        TARGET_DIR="$1"; shift ;;
  esac
done

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   figma-angular-generator  —  Installer      ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo -e "  OS: ${OS_TYPE}  |  Plugin: ${PLUGIN_DIR}"
echo ""

# ── Step 1: Check dependencies ────────────────────────────────────────────────
header "[ 1 / 4 ]  Checking dependencies"

check_dep() {
  local cmd="$1" label="$2" install_hint="$3"
  if command -v "$cmd" &>/dev/null; then
    local ver; ver=$("$cmd" --version 2>&1 | head -1 | tr -d '\n') || ver=$("$cmd" version 2>&1 | head -1 | tr -d '\n') || ver="(unknown)"
    success "${label}  (${ver})"
    return 0
  else
    warn "${label} not found.   Hint: ${install_hint}"
    return 1
  fi
}

NODE_OK=true; NPM_OK=true; NG_OK=true

check_dep "$NODE_CMD" "Node.js"     "https://nodejs.org"     || NODE_OK=false
check_dep "$NPM_CMD"  "npm"         "bundled with Node.js"   || NPM_OK=false

if ! command -v "$NG_CMD" &>/dev/null; then
  NG_OK=false
  warn "Angular CLI not found."
  if [[ "$NODE_OK" == "true" && "$NPM_OK" == "true" ]]; then
    echo ""
    read -rp "  Install Angular CLI globally now? (Y/n): " install_ng
    install_ng="${install_ng:-Y}"
    if [[ "$install_ng" =~ ^[Yy] ]]; then
      info "Running: npm install -g @angular/cli ..."
      if [[ "$OS_TYPE" == "windows" ]]; then
        "$NPM_CMD" install -g @angular/cli 2>&1 | sed 's/^/  /' || {
          warn "Trying elevated PowerShell..."
          powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
            "Start-Process powershell -ArgumentList '-NoProfile -Command \"npm install -g @angular/cli\"' -Verb RunAs -Wait" || true
        }
      elif [[ "$(id -u)" -ne 0 ]] && npm config get prefix 2>/dev/null | grep -q "^/usr"; then
        sudo "$NPM_CMD" install -g @angular/cli
      else
        "$NPM_CMD" install -g @angular/cli
      fi
      NG_CMD=$(resolve_cmd ng)
      command -v "$NG_CMD" &>/dev/null && { NG_OK=true; success "Angular CLI installed."; } || {
        error "Angular CLI installation failed. Please install manually: npm install -g @angular/cli"
        exit 1
      }
    else
      info "Skipping. You can install later:  npm install -g @angular/cli"
      info "Note: Angular CLI is only needed when creating a new project."
    fi
  else
    error "Node.js and npm are required. Install from https://nodejs.org"
    exit 1
  fi
else
  check_dep "$NG_CMD" "Angular CLI" "npm install -g @angular/cli"
fi

# ── Step 2: Resolve target directory ──────────────────────────────────────────
header "[ 2 / 4 ]  Resolving target"

# ── Mode A: --new flag ────────────────────────────────────────────────────────
if [[ -n "$NEW_PROJECT" ]]; then
  INSTALL_MODE="new"
  PARENT_DIR="${TARGET_DIR:-.}"
  TARGET_DIR="${PARENT_DIR}/${NEW_PROJECT}"

  if [[ -d "$TARGET_DIR" ]] && [[ "$FORCE" == "false" ]]; then
    error "Directory '$TARGET_DIR' already exists. Use --force to overwrite."
    exit 1
  fi

  info "Creating Angular project: ${NEW_PROJECT}"
  "$NG_CMD" new "$NEW_PROJECT" \
    --style="$STYLESHEET" --standalone --routing --no-interactive \
    --directory="$TARGET_DIR" 2>&1 | sed 's/^/  /'
  echo ""
  success "Angular project created at: ${TARGET_DIR}"

# ── Mode B: No target → interactive menu ──────────────────────────────────────
elif [[ -z "$TARGET_DIR" ]]; then
  echo ""
  echo "  How would you like to use the plugin?"
  echo ""
  echo -e "    ${BOLD}1)${RESET} Install into an ${BOLD}existing${RESET} Angular project"
  echo -e "    ${BOLD}2)${RESET} Create a ${BOLD}new${RESET} Angular project and install"
  echo -e "    ${BOLD}3)${RESET} Install into an ${BOLD}empty folder${RESET} — I'll create the Angular project"
  echo -e "          later using ${CYAN}/setup-wizard${RESET} inside Claude Code"
  echo ""
  read -rp "  Choose [1/2/3]: " choice

  case "$choice" in
    2)
      INSTALL_MODE="new"
      read -rp "  Project name (kebab-case, e.g. my-app): " NEW_PROJECT
      read -rp "  Parent directory [$(pwd)]: " PARENT_DIR
      PARENT_DIR="${PARENT_DIR:-$(pwd)}"
      PARENT_DIR="${PARENT_DIR/#\~/$HOME}"
      read -rp "  Stylesheet format (scss/css/less) [scss]: " STYLESHEET
      STYLESHEET="${STYLESHEET:-scss}"
      TARGET_DIR="${PARENT_DIR}/${NEW_PROJECT}"

      info "Running: ng new ${NEW_PROJECT} --style=${STYLESHEET} ..."
      echo ""
      "$NG_CMD" new "$NEW_PROJECT" \
        --style="$STYLESHEET" --standalone --routing --no-interactive \
        --directory="$TARGET_DIR" 2>&1 | sed 's/^/  /'
      echo ""
      success "Angular project created at: ${TARGET_DIR}"
      ;;

    3)
      INSTALL_MODE="empty"
      read -rp "  Empty folder path [$(pwd)]: " TARGET_DIR
      TARGET_DIR="${TARGET_DIR:-$(pwd)}"
      TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

      # Create the folder if it doesn't exist yet
      if [[ ! -d "$TARGET_DIR" ]]; then
        mkdir -p "$TARGET_DIR"
        success "Created folder: ${TARGET_DIR}"
      fi
      ;;

    *)
      INSTALL_MODE="existing"
      read -rp "  Angular project path: " TARGET_DIR
      TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
      ;;
  esac

# ── Mode C: Path provided as argument — auto-detect type ──────────────────────
else
  TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
  if [[ -f "$TARGET_DIR/angular.json" ]]; then
    INSTALL_MODE="existing"
  else
    # Folder exists but no angular.json → treat as empty folder
    INSTALL_MODE="empty"
    if [[ ! -d "$TARGET_DIR" ]]; then
      mkdir -p "$TARGET_DIR"
      success "Created folder: ${TARGET_DIR}"
    fi
  fi
fi

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
info "Target: ${TARGET_DIR}  [mode: ${INSTALL_MODE}]"

# ── Reinstall check ───────────────────────────────────────────────────────────
if [[ -d "$TARGET_DIR/.claude/commands" ]] && [[ "$FORCE" == "false" ]]; then
  echo ""
  warn "Plugin is already installed in this folder."
  read -rp "  Reinstall / update? (Y/n): " reinstall
  reinstall="${reinstall:-Y}"
  [[ "$reinstall" =~ ^[Yy] ]] || { info "Installation cancelled."; exit 0; }
fi

# ── Step 3: Copy plugin files ─────────────────────────────────────────────────
header "[ 3 / 4 ]  Installing plugin files"

install_glob() {
  local src="$1" dst="$2" label="$3" pattern="${4:-*.md}"
  mkdir -p "$dst"
  cp "$src"/$pattern "$dst/" 2>/dev/null \
    && success "${label}  →  ${dst#"$TARGET_DIR"/}" \
    || warn "No files matched in ${src} — skipping"
}

install_glob "$PLUGIN_DIR/commands" "$TARGET_DIR/.claude/commands" "Commands (7)"
install_glob "$PLUGIN_DIR/agents"   "$TARGET_DIR/.claude/agents"   "Agents  (4)"
install_glob "$PLUGIN_DIR/skills"   "$TARGET_DIR/.claude/skills"   "Skills  (6)"

mkdir -p "$TARGET_DIR/.claude/hooks/scripts"
cp "$PLUGIN_DIR/hooks/hooks.json"       "$TARGET_DIR/.claude/hooks/"
cp "$PLUGIN_DIR/hooks/scripts/"*.js     "$TARGET_DIR/.claude/hooks/scripts/"
success "Hooks    →  .claude/hooks/"

mkdir -p "$TARGET_DIR/.claude/scripts"
cp "$PLUGIN_DIR/scripts/download-assets.sh" "$TARGET_DIR/.claude/scripts/"
cp "$PLUGIN_DIR/scripts/process-assets.sh"  "$TARGET_DIR/.claude/scripts/"
chmod +x "$TARGET_DIR/.claude/scripts/"*.sh
success "Scripts  →  .claude/scripts/"

# Only create src/assets/ if src/ already exists (existing or new Angular project)
if [[ -d "$TARGET_DIR/src" ]]; then
  mkdir -p "$TARGET_DIR/src/assets/images"
  mkdir -p "$TARGET_DIR/src/assets/icons"
  success "Assets   →  src/assets/images/  +  src/assets/icons/"
else
  info "src/ not found — asset folders will be created by /setup-wizard when you create your Angular project."
fi

# Plugin version stamp
cat > "$TARGET_DIR/.claude/.plugin-version" <<EOF
name=figma-angular-generator
version=1.0.0
installed=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mode=${INSTALL_MODE}
source=${PLUGIN_DIR}
EOF
success "Version stamp  →  .claude/.plugin-version"

# ── Step 4: Validate installation ─────────────────────────────────────────────
header "[ 4 / 4 ]  Validating installation"

ERRORS=0
check_installed() {
  if [[ -f "$TARGET_DIR/$1" ]]; then
    success "$1"
  else
    error "Missing: $1"; ((ERRORS++)) || true
  fi
}

check_installed ".claude/commands/generate-component.md"
check_installed ".claude/commands/generate-page.md"
check_installed ".claude/commands/generate-all.md"
check_installed ".claude/commands/setup-wizard.md"
check_installed ".claude/commands/requirements-to-figma.md"
check_installed ".claude/commands/api-to-components.md"
check_installed ".claude/commands/push-to-figma.md"
check_installed ".claude/agents/figma-analyzer.md"
check_installed ".claude/agents/angular-generator.md"
check_installed ".claude/agents/requirements-analyzer.md"
check_installed ".claude/agents/api-analyzer.md"
check_installed ".claude/skills/angular-component.md"
check_installed ".claude/skills/figma-to-css.md"
check_installed ".claude/skills/requirements-to-wireframe.md"
check_installed ".claude/skills/api-to-angular.md"
check_installed ".claude/skills/html-wireframe.md"
check_installed ".claude/skills/wireframes-to-figma.md"
check_installed ".claude/hooks/hooks.json"
check_installed ".claude/hooks/scripts/validate-figma-url.js"
check_installed ".claude/hooks/scripts/log-generated-file.js"
check_installed ".claude/hooks/scripts/trigger-asset-download.js"
check_installed ".claude/scripts/download-assets.sh"
check_installed ".claude/scripts/process-assets.sh"

echo ""
if [[ $ERRORS -gt 0 ]]; then
  error "${ERRORS} file(s) missing — installation incomplete."
  exit 1
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   Installation complete  (24 / 24 files)     ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  Folder: ${BOLD}${TARGET_DIR}${RESET}"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Open the folder in VS Code:"
echo -e "       ${CYAN}code \"${TARGET_DIR}\"${RESET}"
echo ""
echo "  2. Open Claude Code inside that window"
echo ""

# Tailored next-step message per install mode
if [[ "$INSTALL_MODE" == "empty" ]]; then
  echo -e "  3. ${BOLD}Run /setup-wizard${RESET} to create your Angular project:"
  echo ""
  echo "       /setup-wizard"
  echo ""
  echo "     The wizard will ask for your project name and preferences,"
  echo "     run  ng new  for you, and configure everything automatically."
  echo ""
  echo "  4. Then use the plugin commands:"
  echo ""
  echo "       /requirements-to-figma --text \"...\"   requirements → HTML wireframes + FigJam"
  echo "       /push-to-figma --figma <url>           push wireframes → Figma"
  echo "       /api-to-components --spec ./api.yaml  backend API  → Angular services"
  echo "       /generate-component <figma-url>        Figma node  → Angular component"
  echo "       /generate-page <figma-url> --route X   Figma frame → Angular page"
else
  echo "  3. Type / in Claude Code to see available commands:"
  echo ""
  echo "       /requirements-to-figma --text \"...\"   requirements → HTML wireframes + FigJam"
  echo "       /push-to-figma --figma <url>           push wireframes → Figma"
  echo "       /api-to-components --spec ./api.yaml  backend API  → Angular services"
  echo "       /setup-wizard                          configure Figma generation"
  echo "       /generate-component <figma-url>        Figma node  → Angular component"
  echo "       /generate-page <figma-url> --route X   Figma frame → Angular page"
fi

echo ""
echo "  Optional: set FIGMA_TOKEN for SVG vector export"
echo "       export FIGMA_TOKEN=your_token_here"
echo ""
