# /generate-all

Generate Angular pages for **every top-level frame** in a Figma file in one run.
Pass the Figma file URL (no `?node-id` required) and this command fetches all frames,
shows you a plan, then generates each page sequentially.

## Usage

```
/generate-all <figma-file-url> [--page <figma-page-name>] [--skip <frame1,frame2>] [--only <frame1,frame2>] [--route-prefix <prefix>]
```

### Examples

```
# Generate all frames on every Figma page
/generate-all https://www.figma.com/design/abc123/MyDesign

# Generate all frames on a specific Figma page named "Web"
/generate-all https://www.figma.com/design/abc123/MyDesign --page Web

# Skip frames you don't want
/generate-all https://www.figma.com/design/abc123/MyDesign --skip "Loading Screen,404"

# Only generate specific frames
/generate-all https://www.figma.com/design/abc123/MyDesign --only "Dashboard,Profile,Settings"

# Prefix all route paths with "app/"
/generate-all https://www.figma.com/design/abc123/MyDesign --route-prefix app
```

---

## Step 0 — Setup Wizard

Load `.claude/figma-generator.config.json` from the workspace root.

- **If config exists** — load silently, print one-line summary:
  ```
  Using config: Angular 17 | SCSS | ./src/app/components/ | specs: on
  ```
- **If config is missing** or `--reconfigure` was passed — run `/setup-wizard` first.

---

## Step 1 — Fetch File Metadata

Call `mcp__claude_ai_Figma__get_metadata` with the `fileKey` extracted from the URL.

Extract all **top-level frames** from each Figma page:

```
Figma file: "MyDesign"

  Page: Web (6 frames)
    1. Landing Page
    2. Login
    3. Dashboard
    4. Profile
    5. Settings
    6. 404

  Page: Mobile (skipped — use --page to target a specific page)
```

Apply filters:
- `--page <name>` → only frames on that Figma page
- `--skip <list>` → remove named frames from the plan
- `--only <list>` → keep only named frames

---

## Step 2 — Show Generation Plan

Present the full plan before writing any files. **Wait for user confirmation.**

```
Generation plan:

  Frame                 Route path          Angular page
  ─────────────────────────────────────────────────────────────────
  Landing Page      →   /                   landing-page
  Login             →   /login              login
  Dashboard         →   /dashboard          dashboard
  Profile           →   /profile            profile
  Settings          →   /settings           settings
  404               →   /not-found          not-found

  6 pages  ·  Angular 17  ·  SCSS  ·  ./src/app/

  Routes will be appended to app.routes.ts (you can review before saving).

Proceed? Y/N [Y]:
```

If the user types **N** they can adjust filters (`--skip`, `--only`, `--page`) and re-run.
If they type **Y**, begin generation.

---

## Step 3 — Generate Pages (Sequential)

For each frame in the plan, in order:

1. Call `mcp__claude_ai_Figma__get_design_context` with the frame's `nodeId`
2. Call `mcp__claude_ai_Figma__get_screenshot` in parallel for visual reference
3. Decompose the frame into child components (same logic as `/generate-page` Step 2)
4. Generate all child component files under `outputDir/<component-name>/`
5. Generate the page component under `src/app/pages/<page-name>/`
6. Print progress after each page:

```
[1/6] ✓ landing-page      (3 child components, 16 files)
[2/6] ✓ login             (2 child components, 10 files)
[3/6] ✓ dashboard         (5 child components, 24 files)
[4/6] ✗ profile           (error — see details below, continuing…)
[5/6] ✓ settings          (3 child components, 14 files)
[6/6] ✓ not-found         (1 child component, 5 files)
```

If a frame fails (Figma error, malformed node, etc.) — log the error, continue with the next frame. Do not stop the entire run.

---

## Step 4 — Generate Route File

Collect all generated route definitions and write or append to `src/app/app.routes.ts`.

If the file already exists, show a diff of the additions and ask before writing:

```
The following routes will be added to app.routes.ts:

  { path: '', loadComponent: () => import('./pages/landing-page/landing-page.component').then(m => m.LandingPageComponent) },
  { path: 'login', loadComponent: () => import('./pages/login/login.component').then(m => m.LoginComponent) },
  { path: 'dashboard', loadComponent: () => import('./pages/dashboard/dashboard.component').then(m => m.DashboardComponent) },
  { path: 'profile', loadComponent: () => import('./pages/profile/profile.component').then(m => m.ProfileComponent) },
  { path: 'settings', loadComponent: () => import('./pages/settings/settings.component').then(m => m.SettingsComponent) },
  { path: '**', loadComponent: () => import('./pages/not-found/not-found.component').then(m => m.NotFoundComponent) },

Apply? Y/N [Y]:
```

Apply `--route-prefix <prefix>` to all paths when provided (e.g. `app/dashboard`).

---

## Step 5 — Summary Report

```
╔══════════════════════════════════════════════════════╗
║   /generate-all complete                             ║
╚══════════════════════════════════════════════════════╝

  File:    MyDesign
  Page:    Web
  Frames:  6 total  ·  5 succeeded  ·  1 failed

  Pages generated:
    src/app/pages/landing-page/     ✓ (3 child components)
    src/app/pages/login/            ✓ (2 child components)
    src/app/pages/dashboard/        ✓ (5 child components)
    src/app/pages/profile/          ✗ failed
    src/app/pages/settings/         ✓ (3 child components)
    src/app/pages/not-found/        ✓ (1 child component)

  Routes: added to src/app/app.routes.ts

  Assets detected: 12 images, 8 icons
    → Run: bash .claude/scripts/download-assets.sh

  Errors:
    profile — mcp__claude_ai_Figma__get_design_context returned empty tree.
              Try: /generate-page <profile-frame-url> to retry manually.

  Next steps:
    1. Review generated components
    2. Run: ng serve
    3. Retry failed frames individually with /generate-page
```

---

## Options

| Flag | Effect |
|------|--------|
| `--page <name>` | Only process frames on the named Figma page (case-insensitive) |
| `--skip <frame1,frame2>` | Comma-separated list of frame names to exclude |
| `--only <frame1,frame2>` | Comma-separated list of frame names to include (all others skipped) |
| `--route-prefix <prefix>` | Prepend prefix to all generated route paths |
| `--no-confirm` | Skip the Step 2 confirmation prompt and generate immediately |
| `--no-routes` | Do not write or modify `app.routes.ts` |
| `--reconfigure` | Re-run setup wizard before generating |
| `--spec` | Override config: always generate `.spec.ts` files |
| `--no-spec` | Override config: never generate `.spec.ts` files |

---

## How to get the URL

In Figma, click anywhere **outside** all frames on the canvas (deselect everything).
The URL bar will show just `https://www.figma.com/design/<fileKey>/<fileName>` — no `node-id`.
Copy that URL and pass it to `/generate-all`.

Alternatively, right-click the **page tab** at the bottom of Figma → **Copy link to page** to get a URL scoped to that page.

---

## Notes

- Frames are processed in the order they appear in the Figma layers panel (top to bottom).
- Frames inside other frames (nested) are treated as child components, not separate pages.
- Only **Frame** nodes at the top level of a Figma page become Angular pages. Groups and Components are skipped.
- For very large files (10+ frames) the run may take several minutes. Progress is printed after each frame.
- Use `--only` to test with 1–2 frames first before generating the full file.
