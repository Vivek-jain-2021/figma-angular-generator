# Skill: Wireframes to Figma

Reference guide for pushing locally-generated wireframes (HTML screens and FigJam diagrams) directly into Figma using the Figma MCP connection.

---

## Prerequisites

Two one-time setup steps are required before the first push. Claude checks these automatically when `/push-to-figma` is run.

### 1 — Figma Plugin for Claude

Install the official Figma plugin so Claude Code can authenticate with Figma:

```bash
claude plugin install figma@claude-plugins-official
```

### 2 — Figma Remote MCP Connection

Register the official Figma MCP server:

```bash
claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp
```

Verify the connection is active:

```bash
claude mcp list
# Should show: figma-remote-mcp  https://mcp.figma.com/mcp  connected
```

---

## Figma URL Parsing

Extract `fileKey` and `pageId` from any Figma URL:

| URL pattern | fileKey | pageId |
|-------------|---------|--------|
| `figma.com/design/:fileKey/:name` | `:fileKey` | none → targets current page |
| `figma.com/design/:fileKey/:name?node-id=:nodeId` | `:fileKey` | `:nodeId` (convert `-` to `:`) |
| `figma.com/board/:fileKey/:name` | `:fileKey` | FigJam board |

---

## HTML Wireframes → Figma Frames

### What each wireframe becomes in Figma

Each `.html` file in `.claude/wireframes/html/` is imported as a **top-level frame** on the target Figma page:

| HTML file | Figma frame name |
|-----------|-----------------|
| `01-landing.html` | `Wireframe / Landing` |
| `02-login.html` | `Wireframe / Login` |
| `03-dashboard.html` | `Wireframe / Dashboard` |

### Frame naming convention

All imported frames are prefixed `Wireframe /` so they are easy to identify and group:

```
Page: "Wireframes"
  └── Wireframe / Landing        (1440 × auto)
  └── Wireframe / Login          (1440 × auto)
  └── Wireframe / Dashboard      (1440 × auto)
  └── Wireframe / Orders         (1440 × auto)
```

Mobile frames use `375` width:

```
  └── Wireframe / Mobile / Login    (375 × auto)
  └── Wireframe / Mobile / Home     (375 × auto)
```

### Import method: Figma MCP write

Use the Figma remote MCP to create frames on the target page.

For each HTML file:
1. Read the file content
2. Extract viewport width from `<meta name="viewport" content="width=...">` — default `1440`
3. Extract the screen name from the `<title>` tag or filename
4. Call the Figma MCP write tool to create a frame with the HTML content rendered at the viewport width
5. Position frames vertically with `80px` gap between them

### Frame positioning grid

Lay frames out left-to-right, top-to-bottom in a 3-column grid:

```
col gap: 80px   row gap: 80px   start x: 0   start y: 0

[Frame 1] [Frame 2] [Frame 3]
[Frame 4] [Frame 5] [Frame 6]
```

---

## FigJam Diagrams → Figma

### Source

FigJam diagrams are generated from `.claude/wireframe-spec.json` using the `userFlows` and `componentHierarchy` sections.

If a FigJam URL is already saved in `.claude/wireframe-spec.json` under `figjamUrl`, use that board. Otherwise generate a new one.

### Tool

Use `mcp__claude_ai_Figma__generate_diagram` to create or update the FigJam board.

Pass the Mermaid flowchart built from `wireframe-spec.json`:

```
flowchart TD
  A[Landing Page] --> B{Has account?}
  B -->|Yes| C[Login]
  B -->|No| D[Sign Up]
  ...
```

### FigJam output

After generation, print the board URL and save it to `.claude/wireframe-spec.json`:

```json
{
  "figjamUrl": "https://www.figma.com/board/abc123/...",
  "figjamUpdated": "2025-01-15T10:30:00Z"
}
```

---

## Duplicate Detection

Before pushing, check if frames with the same `Wireframe / <name>` already exist on the target page.

| Scenario | Behaviour |
|----------|-----------|
| Frame does not exist | Create new |
| Frame exists, `--update` flag passed | Replace existing frame |
| Frame exists, no flag | Ask: "Frame 'Wireframe / Dashboard' already exists. Replace? (y/n/all/skip)" |
| Frame exists, `--skip-existing` flag | Leave existing, skip silently |

---

## Fallback: html.to.design

If the Figma remote MCP write is unavailable or returns an error, fall back to `html.to.design` instructions:

```
Could not push directly via Figma MCP.

Manual import via html.to.design:
  1. Install: figma.com/community/plugin/1159123024924461424
  2. Plugins → html.to.design → Import → HTML file
  3. Upload each file from .claude/wireframes/html/
  4. Set width to 1440, click Import
  See .claude/wireframes/html/IMPORT.md for full steps.
```

---

## Design Tokens After Push

After frames are created in Figma, print a reminder to apply design tokens:

```
Wireframes pushed.

Next: apply design tokens in Figma
  Open .claude/wireframes/design-tokens.md — copy the CSS variables into
  Figma Local Variables so designers can apply the colour/spacing system
  on top of the wireframe frames.
```

---

## Connection Status Checks

| Check | Command | Expected output |
|-------|---------|-----------------|
| Plugin installed | `claude plugin list` | `figma@claude-plugins-official` |
| MCP connected | `claude mcp list` | `figma-remote-mcp … connected` |
| MCP whoami | `mcp__claude_ai_Figma__whoami` | Returns user info |

If any check fails, print the exact setup command needed and stop — do not proceed with a broken connection.

---

## Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `MCP not found: figma-remote-mcp` | MCP not registered | Run `claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp` |
| `Unauthorized` | Not logged in to Figma plugin | Run `claude plugin install figma@claude-plugins-official` and log in |
| `File not found` | Wrong fileKey in URL | Re-copy URL from Figma address bar |
| `Cannot write to page` | Insufficient Figma permissions | Ask file owner for Editor access |
| `No wireframes found` | HTML files not generated yet | Run `/requirements-to-figma` first |
| `Invalid fileKey` | URL contains branch key | Use the main file URL, not a branch URL |
