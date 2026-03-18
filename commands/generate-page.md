# /generate-page

Generate a full Angular page (route component + all child components) from a Figma frame URL.

## Usage

```
/generate-page <figma-url> [--route <route-path>] [--reconfigure]
```

### Example

```
/generate-page https://www.figma.com/design/abc123/MyDesign?node-id=5:10 --route dashboard
```

---

## Step 0 — Setup Wizard (runs first)

Before generating, load `.claude/figma-generator.config.json` from the workspace root.

- **If the config file exists** — load it silently and use its values. Print a one-line summary:
  ```
  Using config: Angular 17 | SCSS | ./src/app/components/ | specs: on
  ```
  Skip to Step 1.

- **If the config file does not exist**, or the user passed `--reconfigure` — run the full `/setup-wizard` interactively before continuing.

---

## Step 1 — Analyze the Page Frame

Call `mcp__claude_ai_Figma__get_design_context` with the `fileKey` and `nodeId` from the URL.
Call `mcp__claude_ai_Figma__get_screenshot` in parallel for a visual reference.

Extract:
- Page/frame name → infer route path and component name
- Full component tree: identify each distinct section or repeated pattern
- Layout structure: grid, flex, spacing, breakpoints
- All assets (images, icons) that need to be exported

---

## Step 2 — Decompose into Components

Analyze the component tree and propose a breakdown. **Present the plan to the user before generating:**

```
Component plan for "<FrameName>":

  Page component:     src/app/pages/<page-name>/<page-name>.component.*
  Child components:
    1. <section-name>     → src/app/components/<section-name>/
    2. <section-name>     → src/app/components/<section-name>/
    ...

  Route: /<route-path>

Proceed? Y/N [Y]:
```

Wait for confirmation before continuing.

---

## Step 3 — Generate Child Components

For each identified child component, generate all files using the config from Step 0:

### TypeScript (`<name>.component.ts`)

- `standalone: true`
- **Angular 17**: use `input<T>()` / `output<T>()` signals, `@if` / `@for` in template
- **Angular 16/15**: use `@Input()` / `@Output()` decorators, `*ngIf` / `*ngFor`
- **Angular 14**: NgModule-based with `@Input()` / `@Output()` decorators
- Import from reference project's shared modules/UI library when configured

### HTML (`<name>.component.html`)

- Semantic HTML5 elements, BEM class names
- Conditionals and loops using the correct syntax for the target Angular version

### Stylesheet (`<name>.component.<ext>`)

- Extension: `.scss` / `.css` / `.less` per config
- BEM structure; theme tokens from reference project when available

### Spec file — only if `generateSpecs: true`

```typescript
describe('<ComponentName>', () => {
  beforeEach(() => TestBed.configureTestingModule({ imports: [ComponentName] }).compileComponents());
  it('should create', () => {
    const fixture = TestBed.createComponent(ComponentName);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
```

Output path: `<outputDir>/<component-name>/` from config.

---

## Step 4 — Generate the Page Component

Create the route-level component in `src/app/pages/<page-name>/`:

- `<page-name>.component.ts` — imports all child components
- `<page-name>.component.html` — composes child components with page layout
- `<page-name>.component.<ext>` — page-level layout only (no component internals)
- `<page-name>.component.spec.ts` — if `generateSpecs: true`

---

## Step 5 — Generate Route Snippet

Output the lazy-loaded route definition to add to `app.routes.ts`:

```typescript
{
  path: '<route-path>',
  loadComponent: () => import('./pages/<page-name>/<page-name>.component')
    .then(m => m.<PageName>Component)
}
```

---

## Step 6 — Report

```
✓ Generated page: <page-name>

  Page component:
    src/app/pages/<page-name>/<page-name>.component.ts
    src/app/pages/<page-name>/<page-name>.component.html
    src/app/pages/<page-name>/<page-name>.component.<ext>

  Child components:
    src/app/components/<name-1>/   (3 files)
    src/app/components/<name-2>/   (3 files)
    ...

  Route snippet: (see above — add to app.routes.ts)

  Assets to export from Figma:
    - <asset> → src/assets/images/<asset>.png

  Next steps:
    1. Add the route snippet to app.routes.ts
    2. Export Figma assets to src/assets/
    3. Run: ng serve
```

---

## Options

| Flag | Effect |
|------|--------|
| `--route <path>` | Set the Angular route path (default: inferred from Figma frame name) |
| `--reconfigure` | Re-run the setup wizard even if config exists |
| `--spec` | Override config: always generate `.spec.ts` files |
| `--no-spec` | Override config: never generate `.spec.ts` files |
| `--stories` | Generate Storybook stories for all components |
| `--flat` | Put all child components directly in `outputDir` instead of per-component sub-folders |
| `--output <path>` | Override `outputDir` from config for this run only |

---

## Notes

- Always run on a top-level **Frame** node in Figma, not a Group or Component.
- For large pages the agent will chunk generation and show progress after each component.
- Run `/setup-wizard` at any time to update the saved configuration.
