# /push-to-figma

Push locally-generated wireframes (HTML screens and FigJam diagrams) directly into a Figma file using the Claude CLI and Figma remote MCP.

---

## Before First Use — One-Time Setup

Two CLI commands are required before `/push-to-figma` will work. Run them once in a terminal, not inside Claude Code.

**A. Install Figma plugin and log in:**

```bash
claude plugin install figma@claude-plugins-official
```

This opens a browser window — log in with your Figma account and authorise the plugin.

**B. Connect the Figma remote MCP:**

```bash
claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp
```

Done. Both steps only need to be run once per machine.

> Tip: run `/push-to-figma --setup` for a guided walkthrough of steps A and B.

---

## Usage

```
/push-to-figma --figma <figma-url> [--html <file-or-folder>] [options]
```

### Examples

Push a **single HTML file** to a specific Figma node:

```
/push-to-figma \
  --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo?node-id=134-2&t=P8L3JPZeTcdBzmlx-1" \
  --html "D:\Intelliswift\Projects\diamond\.claude\wireframes\html\10-account.html"
```

Push **all HTML wireframes** in a folder to a Figma file:

```
/push-to-figma \
  --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo" \
  --html "D:\Intelliswift\Projects\diamond\.claude\wireframes\html\"
```

Push **everything** (HTML wireframes + FigJam) using the default wireframes folder:

```
/push-to-figma --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo"
```

Push **FigJam only**:

```
/push-to-figma \
  --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo" \
  --figjam-only
```

Run the **setup wizard**:

```
/push-to-figma --setup
```

---

## Options

| Flag | Effect |
|------|--------|
| `--figma <url>` | Target Figma URL — file, page, or node URL (required unless `--setup`) |
| `--html <path>` | Single `.html` file **or** folder of `.html` files (default: `.claude/wireframes/html/`) |
| `--html-only` | Push HTML wireframes only; skip FigJam |
| `--figjam-only` | Push FigJam diagram only; skip HTML |
| `--update` | Replace frames that already exist on the Figma page |
| `--skip-existing` | Skip existing frames silently; never prompt |
| `--page <name>` | Target Figma page name (default: `Wireframes`) |
| `--setup` | Run the one-time connection setup wizard |

### --html accepts a file or a folder

| Value | Behaviour |
|-------|-----------|
| `--html ./screens/login.html` | Push that one file only |
| `--html ./screens/` | Push all `.html` files in the folder, sorted by filename |
| *(omitted)* | Push all `.html` files from `.claude/wireframes/html/` |

---

## Step 0 — Connection Check

Before anything else, verify both required connections are active.

### Check A — Figma plugin

Run:

```bash
claude plugin list
```

If `figma@claude-plugins-official` is **not** listed, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Figma plugin not installed.

  Run this in your terminal:

    A.  claude plugin install figma@claude-plugins-official

  Then re-run /push-to-figma.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Stop here.

### Check B — Figma remote MCP

Run:

```bash
claude mcp list
```

If `figma-remote-mcp` is **not** listed, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Figma remote MCP not connected.

  Run this in your terminal:

    B.  claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp

  Then re-run /push-to-figma.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Stop here.

### Check — MCP is live

Call `mcp__claude_ai_Figma__whoami`. If it fails, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Figma MCP is registered but not responding.
  Check your internet connection or re-add the MCP:

    claude mcp remove figma-remote-mcp
    claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Stop here.

When all checks pass, print:

```
✓ Figma plugin installed
✓ Figma MCP connected  (logged in as: <user name>)
```

---

## Step 1 — Parse Target URL

Extract `fileKey` and optional `nodeId` from `--figma <url>`:

| URL pattern | fileKey | nodeId |
|-------------|---------|--------|
| `figma.com/design/:fileKey/:name` | `:fileKey` | none |
| `figma.com/design/:fileKey/:name?node-id=134-2&...` | `:fileKey` | `134-2` → `134:2` |
| `figma.com/board/:fileKey/:name` | `:fileKey` | FigJam board |

Convert `node-id` dash format to colon format: `134-2` → `134:2`.

Call `mcp__claude_ai_Figma__get_metadata` with the `fileKey` to confirm the file is accessible and list its pages.

Print:

```
Target Figma file:  Demo
File key:           TFKVdeFYl6pJLffnmduUqF
Node:               134:2  (frame targeted)
Target page:        Wireframes  (will be created if it does not exist)
```

If `nodeId` is provided, the imported frames will be placed inside that node.

---

## Step 2 — Locate HTML Files

Unless `--figjam-only` was passed:

Resolve the `--html` value:

- **Single file** — confirm the file exists and is a `.html` file; add it to the push list
- **Folder** — list all `.html` files in the folder sorted by filename
- **Omitted** — default to `.claude/wireframes/html/`

If no `.html` files are found, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  No HTML wireframes found.

  Generate them first:
    /requirements-to-figma --text "describe your screens here"

  Or point to an existing file or folder:
    /push-to-figma --figma <url> --html ./path/to/screen.html
    /push-to-figma --figma <url> --html ./path/to/html/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Stop here.

When files are resolved, list them:

```
HTML files to push:
  10-account.html    (1440px)   →  Wireframe / Account

  1 file queued.
```

Or for a folder:

```
HTML files to push:
  01-landing.html       (1440px)   →  Wireframe / Landing
  02-login.html         (1440px)   →  Wireframe / Login
  03-dashboard.html     (1440px)   →  Wireframe / Dashboard
  10-account.html       (1440px)   →  Wireframe / Account

  4 files queued.
```

---

## Step 3 — Duplicate Check

Derive each target frame name: strip the leading number + hyphen from the filename, capitalise words, prefix with `Wireframe / `.

Examples:
- `10-account.html` → `Wireframe / Account`
- `03-dashboard.html` → `Wireframe / Dashboard`
- `my-order-detail.html` → `Wireframe / My Order Detail`

Call `mcp__claude_ai_Figma__get_metadata` to list existing frames on the target page.

If duplicates exist and neither `--update` nor `--skip-existing` was passed, ask **once**:

```
The following frames already exist on page "Wireframes":
  Wireframe / Account

How should duplicates be handled?
  1) Replace existing frames   (--update)
  2) Skip duplicates, push new frames only   (--skip-existing)
  3) Cancel

Enter 1–3 [2]:
```

Apply the chosen strategy to all duplicates — do not ask per frame.

---

## Step 4 — Push HTML Files

For each file in the push list (in order):

1. Read the file content
2. Extract viewport width from `<meta name="viewport" content="width=...">` — default `1440`
3. Derive screen name from `<title>` tag; fall back to filename
4. Call the Figma remote MCP write tool to create (or replace) the frame on the target page
5. If `nodeId` was provided, place the new frame inside that node
6. Position frames in a 3-column grid with `80px` gaps

Print progress after each frame:

```
Pushing to Figma page "Wireframes":
  ✓  Wireframe / Account    (frame created)
```

For multiple files:

```
Pushing to Figma page "Wireframes":
  ✓  Wireframe / Landing       (frame created)
  ✓  Wireframe / Login         (frame created)
  ✓  Wireframe / Dashboard     (frame created)
  ✓  Wireframe / Account       (frame created)
```

If a frame fails, print inline and retry once:

```
  ✗  Wireframe / Dashboard  (write timeout — retrying...)
  ✓  Wireframe / Dashboard  (frame created on retry)
```

If it still fails after retry, mark as failed and continue. List failures in the summary.

---

## Step 5 — Push FigJam Diagram

Unless `--html-only` was passed:

Check `.claude/wireframe-spec.json` for `userFlows`. If missing, print:

```
No user flow data in .claude/wireframe-spec.json — skipping FigJam push.
Run /requirements-to-figma first to generate flows, then re-run /push-to-figma.
```

Otherwise build a Mermaid flowchart from the `userFlows` array and call `mcp__claude_ai_Figma__generate_diagram`.

After generation:

```
✓ FigJam diagram created:  https://www.figma.com/board/<key>/...
```

Save the FigJam URL to `.claude/wireframe-spec.json` under `figjamUrl`.

---

## Step 6 — Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Push complete.

  HTML frames  →  4 / 4 pushed to page "Wireframes"
  FigJam       →  https://www.figma.com/board/<key>/...

  View in Figma:
    https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo

Next:
  — Share the Figma link with your designers
  — Designers apply the visual layer on top of the wireframe frames
  — Reference .claude/wireframes/design-tokens.md for tokens
  — Once designs are finalised:
      /generate-component <figma-url>    →  Angular component
      /generate-page <figma-url>         →  Angular page + route
      /generate-all <figma-file-url>     →  All pages at once
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If any frames failed, add:

```
  Failures (retry individually):
    ✗  Wireframe / Dashboard
       /push-to-figma --figma <url> --html ./03-dashboard.html --update
```

---

## --setup Mode

When `/push-to-figma --setup` is run, print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  figma-angular-generator — Figma Connection Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  A.  Install Figma plugin and log in
      Run this in your terminal:

        claude plugin install figma@claude-plugins-official

      A browser window will open — log in with your Figma account.

  Press Enter once you have completed step A:
```

Wait for Enter, then:

```
  B.  Connect the Figma remote MCP
      Run this in your terminal:

        claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp

  Press Enter once done:
```

Wait for Enter, then call `mcp__claude_ai_Figma__whoami` to verify. If it succeeds:

```
  ✓ Connected as: <user name>

  Setup complete. Example usage:

    /push-to-figma \
      --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo?node-id=134-2" \
      --html "D:\Intelliswift\Projects\diamond\.claude\wireframes\html\10-account.html"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If `whoami` fails, print the error and suggest re-running step B.

---

## Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `figma@claude-plugins-official` not in plugin list | Plugin not installed | `claude plugin install figma@claude-plugins-official` |
| `figma-remote-mcp` not in MCP list | MCP not registered | `claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp` |
| MCP registered but not responding | Network or auth issue | Remove and re-add the MCP |
| `Unauthorized` | Not logged in | Re-run plugin install and log in via browser |
| `Cannot write to page` | No Editor access | Ask Figma file owner for Editor access |
| `File not found` | Wrong fileKey | Re-copy URL from Figma browser address bar |
| `No HTML files found` | Wrong path or files not generated | Run `/requirements-to-figma` or fix the `--html` path |
| `Invalid node-id format` | URL has malformed node-id | Remove `?node-id=...` from the URL and try again |
