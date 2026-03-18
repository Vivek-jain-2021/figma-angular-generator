# figma-angular-generator

A Claude Code plugin that covers the full frontend development workflow — from raw requirements through to production Angular components styled from Figma designs.

Uses Claude's **built-in Figma connector** — no token setup, no `.mcp.json`, no extra packages required.

---

## Commands

| Command | Description |
|---------|-------------|
| `/setup-wizard` | Configure Angular version, output path, stylesheet format, and spec preferences |
| `/requirements-to-figma` | Convert requirements into HTML wireframes + FigJam user-flow diagram |
| `/push-to-figma <figma-url>` | Push generated HTML wireframes and FigJam diagrams directly into a Figma file |
| `/api-to-components` | Analyze backend API contracts and generate Angular services, interceptors, models, and feature components |
| `/generate-component <figma-url>` | Generate a single Angular standalone component from a Figma node |
| `/generate-page <figma-url> [--route <name>]` | Generate a full page with all child components and a route snippet |
| `/generate-all <figma-file-url>` | Generate **all frames** in a Figma file as Angular pages in one run |

---

## Installation

### Option A — Interactive (recommended)

```bash
bash scripts/install.sh
```

The installer presents a menu:

```
  How would you like to use the plugin?

    1) Install into an existing Angular project
    2) Create a new Angular project and install
    3) Install into an empty folder — I'll create the Angular project
          later using /setup-wizard inside Claude Code
```

- **Option 1** — paste your existing project path → plugin files are copied in
- **Option 2** — enter a project name → installer runs `ng new` then installs
- **Option 3** — paste any empty folder → plugin installs, Angular project created later via `/setup-wizard`

### Option B — Direct path

```bash
# Into an existing Angular project
bash scripts/install.sh ./my-app

# Into an empty folder (create project later via /setup-wizard)
bash scripts/install.sh ./my-workspace

# Create new Angular project + install in one step
bash scripts/install.sh --new my-app

# Force reinstall / update
bash scripts/install.sh ./my-app --force
```

### Option C — npm shortcuts

```bash
npm run install-to ./my-app        # install into existing project
npm run install-new my-app         # create new project + install
npm run validate                   # check plugin structure
```

### What gets installed

```
.claude/
  commands/       ← 7 slash commands Claude Code recognizes
  agents/         ← 4 agents (figma-analyzer, angular-generator, requirements-analyzer, api-analyzer)
  skills/         ← 6 skills (angular-component, figma-to-css, requirements-to-wireframe, api-to-angular, html-wireframe, wireframes-to-figma)
  hooks/          ← hooks.json + 3 hook scripts
  scripts/        ← download-assets.sh, process-assets.sh
  .plugin-version ← version stamp with install date and mode
src/
  assets/
    images/       ← created automatically (if src/ exists)
    icons/        ← created automatically (if src/ exists)
```

The installer checks for Node.js, npm, and Angular CLI. If Angular CLI is missing it offers to install it automatically.

After installation the installer validates all 24 files and prints a pass/fail result.

### Reinstall / Update

```bash
bash scripts/install.sh ./my-app --force
```

---

## Workflow

```
  /requirements-to-figma         ← Phase 1: requirements → HTML wireframes + FigJam diagram
        ↓
  /push-to-figma --figma <url>   ← Phase 2: push wireframes + FigJam directly into Figma
        ↓
       Designer's turn           ← Phase 3: visual design applied on top of wireframes in Figma
        ↓
  bash scripts/install.sh        ← Phase 4: install plugin into Angular project (options 1/2/3)
  /setup-wizard                  ←          configure Angular version, output, stylesheet
        ↓
  /api-to-components             ← Phase 5: backend API → Angular services + interceptors + models
        ↓
  /generate-all <file-url>       ← Phase 6: entire Figma file → all Angular pages at once
                                             OR
  /generate-component <node-url> ←          single Figma node  → Angular component
  /generate-page <node-url>      ←          single Figma frame → Angular page + route snippet
        ↓
       Asset pipeline            ← Phase 7: images + icons auto-downloaded and optimized
```

Each command is independent — skip any step that does not apply.

---

## Requirements to Wireframes

**Command:** `/requirements-to-figma`

Converts GUI requirements from any source into HTML wireframes (for Figma import) and a FigJam user-flow diagram.

### Usage

```
/requirements-to-figma --text "A task management app where users create projects, add tasks, assign team members, and track progress."
/requirements-to-figma --jira https://yourorg.atlassian.net/browse/PROJ-123
/requirements-to-figma --file ./docs/UI-Brief.pdf
/requirements-to-figma --file ./specs/requirements.docx
/requirements-to-figma --jira https://... --file ./docs/extra-specs.pdf
```

### What it produces

| Output | Location | Purpose |
|--------|----------|---------|
| HTML wireframes | `.claude/wireframes/html/*.html` | Import into Figma via html.to.design |
| Import instructions | `.claude/wireframes/html/IMPORT.md` | Step-by-step Figma import guide |
| UX spec (JSON) | `.claude/wireframe-spec.json` | Structured spec for reference |
| Summary | `.claude/wireframe-summary.md` | Human-readable overview |
| Per-screen descriptions | `.claude/wireframes/screens/` | Markdown per screen |
| Design tokens | `.claude/wireframes/design-tokens.md` | CSS custom properties |
| Component inventory | `.claude/wireframes/component-inventory.md` | All components + props |
| FigJam user-flow diagram | Link printed after generation | Navigation flow between screens |
| FigJam component hierarchy | Same FigJam board | Which components belong to which screens |

### HTML Wireframes → Figma via html.to.design

The HTML wireframes are greyscale, self-contained `.html` files that open directly in a browser. They use:
- Only grey tones — no brand colour at this stage
- Real labels and plausible data (not lorem ipsum)
- Pure HTML/CSS — no JavaScript, no external fonts, no CDN dependencies
- Fixed viewport width (`1440px` desktop, `375px` mobile)
- Proper structural layout per screen type (sidebar+content, centered card, full-width sections, etc.)

**To import into Figma:**
1. Install the [html.to.design](https://www.figma.com/community/plugin/1159123024924461424) plugin in Figma
2. Plugins → html.to.design → Import → **HTML file** tab
3. Upload each `.html` file from `.claude/wireframes/html/`
4. Set width to `1440` and click Import
5. Each screen becomes a Figma frame — designers apply the visual layer on top

See `.claude/wireframes/html/IMPORT.md` for the full step-by-step guide including the live URL option.

### Design decisions Claude makes autonomously

| Decision | Rule |
|----------|------|
| Navigation pattern | ≤4 screens → top nav; 5–9 → sidebar; ≥10 → sidebar with sections |
| Color palette | By domain (SaaS → indigo/slate; healthcare → blue/green; finance → navy/teal) |
| Font family | By domain (Inter, Roboto, IBM Plex Sans, Plus Jakarta Sans) |
| Border radius | By domain (enterprise → 2–4px; SaaS → 6–8px; consumer → 12px) |
| Density | By app type (data-heavy → compact; consumer/forms → comfortable) |

### Options

| Flag | Effect |
|------|--------|
| `--jira <url>` | Fetch and parse a Jira ticket |
| `--file <path>` | Read a PDF, Word doc, Markdown, or text file |
| `--text "<text>"` | Inline requirements |
| `--figjam <url>` | Push user-flow diagram into an existing FigJam board |
| `--no-figjam` | Skip FigJam diagram |
| `--no-html` | Skip HTML wireframes; output markdown descriptions only |
| `--mobile` | Generate HTML wireframes at 375px viewport |
| `--tablet` | Generate HTML wireframes at 768px viewport |

---

## Push Wireframes to Figma

**Command:** `/push-to-figma`

Pushes locally-generated HTML wireframes and FigJam diagrams directly into a Figma file using the Claude CLI — no manual html.to.design import required.

### One-time Setup

Run these two commands once in your terminal (not inside Claude Code):

**A. Install Figma plugin and log in:**

```bash
claude plugin install figma@claude-plugins-official
```

**B. Connect the Figma remote MCP:**

```bash
claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp
```

Or walk through both steps with the guided wizard:

```
/push-to-figma --setup
```

### Usage

Push a **single HTML file** to a specific Figma node:

```
/push-to-figma \
  --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo?node-id=134-2&t=P8L3JPZeTcdBzmlx-1" \
  --html "D:\Intelliswift\Projects\diamond\.claude\wireframes\html\10-account.html"
```

Push **all HTML files** in a folder:

```
/push-to-figma \
  --figma "https://www.figma.com/design/TFKVdeFYl6pJLffnmduUqF/Demo" \
  --html "D:\Intelliswift\Projects\diamond\.claude\wireframes\html\"
```

Push **everything** using the default wireframes folder:

```
/push-to-figma --figma "https://www.figma.com/design/<fileKey>/MyDesign"
```

Push **FigJam only**:

```
/push-to-figma --figma "https://www.figma.com/design/<fileKey>/MyDesign" --figjam-only
```

### What it does

1. Checks that both CLI setup steps (A and B) are complete — prints the exact command if not
2. Resolves the `--html` value as a single file or a folder of `.html` files
3. Creates a `Wireframe / <Screen>` frame on the target Figma page for each file, arranged in a 3-column grid
4. If a `node-id` is in the URL, places frames inside that specific node
5. Generates (or updates) the FigJam user-flow diagram from `.claude/wireframe-spec.json`
6. Saves the FigJam board URL back to `.claude/wireframe-spec.json`

### Options

| Flag | Effect |
|------|--------|
| `--figma <url>` | Target Figma URL — file, page, or node URL with `?node-id=` (required) |
| `--html <path>` | Single `.html` file **or** folder of `.html` files (default: `.claude/wireframes/html/`) |
| `--html-only` | Push HTML wireframes only; skip FigJam |
| `--figjam-only` | Push FigJam diagram only; skip HTML |
| `--update` | Replace frames that already exist on the page |
| `--skip-existing` | Skip existing frames silently |
| `--page <name>` | Target page name in Figma (default: `Wireframes`) |
| `--setup` | Run the one-time A/B connection setup wizard |

### Frame naming

Each HTML file becomes a named frame on the Figma page:

| File | Frame name |
|------|-----------|
| `10-account.html` | `Wireframe / Account` |
| `03-dashboard.html` | `Wireframe / Dashboard` |
| `my-order-detail.html` | `Wireframe / My Order Detail` |

### Troubleshooting

| Problem | Solution |
|---------|----------|
| Plugin not installed | `claude plugin install figma@claude-plugins-official` |
| MCP not connected | `claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp` |
| `Unauthorized` | Re-run step A and log in via browser |
| `Cannot write to page` | Ask the Figma file owner for Editor access |
| No HTML files found | Run `/requirements-to-figma` first, or check the `--html` path |
| FigJam skipped | Run `/requirements-to-figma` first so `wireframe-spec.json` has user flows |

---

## API to Angular Components

**Command:** `/api-to-components`

Reads backend API contracts and generates a complete Angular HTTP layer.

### Usage

```
/api-to-components --spec ./openapi.yaml
/api-to-components --spec https://api.yourapp.com/v3/api-docs
/api-to-components --backend ./backend/src
```

### Supported backend sources

| Source | Flag |
|--------|------|
| OpenAPI / Swagger YAML or JSON | `--spec <file>` |
| Swagger UI URL | `--spec <url>` |
| NestJS source | `--backend <dir>` |
| Spring Boot source | `--backend <dir>` |
| FastAPI source | `--backend <dir>` |
| Express source | `--backend <dir>` |
| Plain text | `--text "..."` |

### What it generates

```
src/
  environments/
    environment.ts              ← apiUrl: '/api' (proxied in dev)
    environment.prod.ts         ← apiUrl: 'https://...' (HTTPS required)
  app/
    core/
      interceptors/
        auth.interceptor.ts     ← Authorization: Bearer <token> on every request
        error.interceptor.ts    ← 401 → logout, 403 → forbidden, 0 → network error
      services/
        auth.service.ts         ← token storage + isLoggedIn signal
        <entity>.service.ts     ← one per API resource
      models/
        <entity>.model.ts       ← TypeScript interfaces per domain
    app.config.ts               ← interceptors registered
proxy.conf.json                 ← /api proxied to localhost:8080 in dev
.claude/cors-handoff.md         ← CORS config for backend team (NestJS / Spring / FastAPI)
```

### JWT auth and CORS

| Concern | Behaviour |
|---------|-----------|
| JWT header | `Authorization: Bearer <token>` on every request |
| withCredentials | `false` — matches `allowCredentials(false)` on the backend |
| Token storage | `localStorage` (default); use `--cookie-auth` for httpOnly cookie |
| API URL | Always from `environment.apiUrl` — never hardcoded |
| Production | `apiUrl` must start with `https://` |
| Local dev | `proxy.conf.json` avoids CORS entirely |

### Options

| Flag | Effect |
|------|--------|
| `--spec <path\|url>` | OpenAPI/Swagger file or URL |
| `--backend <path>` | Backend source directory |
| `--domain <name>` | Generate only one domain |
| `--no-components` | Services and models only |
| `--no-interceptors` | Skip interceptor generation |
| `--cookie-auth` | httpOnly cookie instead of localStorage JWT |

---

## Figma to Angular Components

**Commands:** `/generate-component`, `/generate-page`, and `/generate-all`

### Usage

```
/generate-component https://www.figma.com/design/<fileKey>/...?node-id=<nodeId>
/generate-page https://www.figma.com/design/<fileKey>/...?node-id=<nodeId> --route dashboard
/generate-all https://www.figma.com/design/<fileKey>/MyDesign
```

Right-click any frame or component in Figma → **Copy link** to get the URL for a single frame.
To get the whole-file URL, click outside all frames (deselect) and copy the address bar — there will be no `?node-id` parameter.

### Generate All Screens at Once

`/generate-all` is the fastest way to turn a complete Figma file into a full Angular app. It:

1. Reads the Figma file metadata to discover every top-level frame (one frame = one screen)
2. Shows you a plan table with frame names, inferred route paths, and component names
3. Waits for your confirmation, then generates each page sequentially
4. Writes all route definitions to `app.routes.ts` in one pass

```
/generate-all https://www.figma.com/design/abc123/MyDesign

# Only frames on the "Web" Figma page
/generate-all https://www.figma.com/design/abc123/MyDesign --page Web

# Skip frames you don't want
/generate-all https://www.figma.com/design/abc123/MyDesign --skip "Loading Screen,404"

# Generate specific frames only
/generate-all https://www.figma.com/design/abc123/MyDesign --only "Dashboard,Profile,Settings"

# Test with one frame first, then re-run for the rest
/generate-all https://www.figma.com/design/abc123/MyDesign --only Dashboard
```

If a frame fails (network error, empty tree) the run continues and failed frames are listed in the summary so you can retry them individually with `/generate-page`.

**`/generate-all` options:**

| Flag | Effect |
|------|--------|
| `--page <name>` | Only process frames on the named Figma page |
| `--skip <frame1,frame2>` | Exclude these frames |
| `--only <frame1,frame2>` | Include only these frames |
| `--route-prefix <prefix>` | Prepend prefix to all route paths (e.g. `app/`) |
| `--no-confirm` | Skip the confirmation prompt |
| `--no-routes` | Do not write or modify `app.routes.ts` |

### Setup Wizard

Run `/setup-wizard` once to configure preferences. If no `angular.json` is detected (empty-folder mode), the wizard creates the Angular project first via `ng new`.

The wizard **always** asks for the Angular version — including when creating a new project. All five settings are prompted every run:

| Setting | Options | Default |
|---------|---------|---------|
| Angular version | 17, 16, 15, 14 | 17 |
| Output directory | any path | `./src/app/components/` |
| Reference project | path or N | None |
| Stylesheet format | SCSS, CSS, LESS | SCSS |
| Generate spec files | Yes / No | Yes |

Config saved to `.claude/figma-generator.config.json`. Pass `--reconfigure` to re-run.

### Generated output

**Single component:**
```
src/app/components/<name>/
  <name>.component.ts      standalone, input()/output() signals
  <name>.component.html    @if / @for control flow
  <name>.component.scss    scoped SCSS with CSS custom properties
  <name>.component.spec.ts basic TestBed spec (if enabled)
```

**Full page:**
```
src/app/
  components/<section-N>/   child components
  pages/<page-name>/
    <page-name>.component.ts
    <page-name>.component.html
    <page-name>.component.scss
    <page-name>.component.spec.ts
```

### Angular version support

| Feature | v17 | v16 / v15 | v14 |
|---------|-----|-----------|-----|
| Standalone | ✓ | ✓ | Optional |
| Inputs | `input<T>()` signal | `@Input()` | `@Input()` |
| Outputs | `output<T>()` signal | `@Output() EventEmitter` | `@Output() EventEmitter` |
| Conditionals | `@if` / `@else` | `*ngIf` | `*ngIf` |
| Loops | `@for … track` | `*ngFor` | `*ngFor` |
| NgModule required | No | No | Yes |

---

## Asset Pipeline

When a Figma design is analyzed the plugin automatically:

1. **Detects** image and icon nodes in the Figma tree
2. **Fetches** download URLs via Figma MCP
3. **Writes** `.claude/assets-manifest.json` → PostToolUse hook fires
4. **Downloads** all assets:
   - Images → `src/assets/images/<name>.png`
   - Icons  → `src/assets/icons/<name>.svg`
5. **Optimizes** — SVGs strip hard-coded dimensions (`svgo`); PNGs compressed (`optipng`)
6. **Generates** Angular code with `/assets/` paths — never Figma CDN URLs

```bash
export FIGMA_TOKEN=your_token_here   # enables proper SVG vector export
npm install -g svgo                  # SVG optimization
brew install optipng                 # PNG compression (macOS)
```

---

## Plugin Structure

```
figma-angular-generator/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── setup-wizard.md              /setup-wizard
│   ├── requirements-to-figma.md     /requirements-to-figma
│   ├── push-to-figma.md             /push-to-figma
│   ├── api-to-components.md         /api-to-components
│   ├── generate-component.md        /generate-component
│   ├── generate-page.md             /generate-page
│   └── generate-all.md              /generate-all
├── agents/
│   ├── requirements-analyzer.md     Requirements → structured UX spec
│   ├── api-analyzer.md              Backend/OpenAPI → API contract + CORS analysis
│   ├── figma-analyzer.md            Figma → design spec + asset manifest
│   └── angular-generator.md         Design spec → Angular files
├── skills/
│   ├── html-wireframe.md            HTML wireframe component library + layout templates
│   ├── requirements-to-wireframe.md UX layout patterns, FigJam diagram conventions
│   ├── wireframes-to-figma.md       Push wireframes to Figma via CLI + remote MCP
│   ├── api-to-angular.md            JWT interceptor, CORS, HTTP service patterns
│   ├── angular-component.md         Angular 17 component patterns reference
│   └── figma-to-css.md              Figma → CSS/SCSS conversion reference
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── validate-figma-url.js     PreToolUse: validates fileKey + nodeId
│       ├── log-generated-file.js     PostToolUse: logs generated component files
│       └── trigger-asset-download.js PostToolUse: auto-runs download + optimize
├── scripts/
│   ├── install.sh                    Interactive installer (OS-aware, dep-checking)
│   ├── validate.sh                   Validate plugin structure (24 checks)
│   ├── download-assets.sh            Download images/icons from assets manifest
│   └── process-assets.sh             Optimize SVGs and PNGs after download
├── package.json                      npm install shortcuts
└── README.md
```

---

## Hooks

| Type | Matcher | Script | Behaviour |
|------|---------|--------|-----------|
| `PreToolUse` | `mcp__claude_ai_Figma__get_design_context` | `validate-figma-url.js` | Blocks if `fileKey` or `nodeId` format is invalid |
| `PostToolUse` | `Write` | `log-generated-file.js` | Logs each generated `.component.ts/html/scss` file |
| `PostToolUse` | `Write` | `trigger-asset-download.js` | Detects `assets-manifest.json` write → auto-downloads + optimizes assets |

---

## Validate Plugin

```bash
bash scripts/validate.sh
# or
npm run validate
```

Runs 28 checks — manifest, all commands, agents, skills, hooks, scripts, and docs.

---

## Tips

- **Empty folder flow** — run the installer with option 3, open the folder in VS Code, run `/setup-wizard` to create the Angular project entirely within Claude Code
- **Chain the commands** — requirements → `/push-to-figma` → designer polishes in Figma → `/generate-all` → Angular app
- **Push wireframes directly** — use `/push-to-figma` instead of the manual html.to.design import step
- **Name Figma layers clearly** — layer names become component selectors (`"Nav Bar"` → `app-nav-bar`)
- **Use Auto Layout in Figma** — maps directly to CSS Flexbox/Grid
- **Share `.claude/cors-handoff.md`** with your backend team after running `/api-to-components`
- **Set `FIGMA_TOKEN`** for proper SVG vector export instead of PNG screenshots

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Slash commands not appearing | Open the Angular project folder (not the plugin folder) in VS Code; reload the window |
| `Invalid nodeId` hook error | Right-click the Figma layer and **Copy link** — ensure URL has `?node-id=X-Y` |
| Assets not downloading | Check `node` is installed; inspect `.claude/assets-manifest.json` for empty URLs |
| SVGs downloading as PNGs | Set `FIGMA_TOKEN` env var to enable the Figma export API |
| Generated styles look off | Enable Auto Layout in Figma; see `skills/figma-to-css.md` |
| Component name is garbled | Rename the Figma layer to a clear English name before generating |
| Wrong Angular syntax | Run `/setup-wizard --reconfigure` and select the correct Angular version |
| Jira fetch fails | Ticket may require login — paste the description with `--text` |
| Word doc unreadable | Install `python-docx` (`pip install python-docx`) or paste content with `--text` |
| html.to.design import looks wrong | Ensure the `.html` file renders correctly in a browser first; check the viewport width matches |
| CORS blocked in browser | See `.claude/cors-handoff.md` — backend must whitelist the exact HTTPS origin |
| 401 on every request | Confirm the JWT token is being stored after login; check `AuthService.getToken()` |
| Angular CLI not found during install | Installer offers to install it automatically; or run `npm install -g @angular/cli` manually |
