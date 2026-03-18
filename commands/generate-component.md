# /generate-component

Generate a single Angular standalone component from a Figma node URL.

## Usage

```
/generate-component <figma-url> [--reconfigure]
```

### Example

```
/generate-component https://www.figma.com/design/abc123/MyDesign?node-id=12:34
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

## Step 1 — Analyze

Call `mcp__claude_ai_Figma__get_design_context` with the `fileKey` and `nodeId` extracted from the URL:

- `figma.com/design/:fileKey/...?node-id=:nodeId` → convert `-` to `:` in nodeId

Also call `mcp__claude_ai_Figma__get_screenshot` in parallel to capture the visual reference.

Extract from the result:
- Component name (from Figma layer name → kebab-case)
- Layout: auto-layout direction, gap, padding → CSS flexbox/grid
- Colors, typography, border-radius → map to theme tokens if a reference project was configured
- All child nodes that are themselves reusable components
- Image/icon assets that need to be exported

---

## Step 2 — Generate

Using the config from Step 0 and the design spec from Step 1, generate:

### TypeScript (`<name>.component.ts`)

- `standalone: true`
- **Angular 17**: use `input<T>()` / `output<T>()` signals, `@if` / `@for` in template
- **Angular 16/15**: use `@Input()` / `@Output()` decorators, `*ngIf` / `*ngFor`
- **Angular 14**: NgModule-based with `@Input()` / `@Output()` decorators
- Import from reference project's shared modules/UI library when configured

### HTML (`<name>.component.html`)

- Semantic HTML5 elements
- BEM class names matching the SCSS
- Conditionals and loops using the correct syntax for the target Angular version
- Bind all `input()` / `@Input()` values in the template

### Stylesheet (`<name>.component.<ext>`)

- File extension: `.scss` / `.css` / `.less` per config
- BEM structure
- Use theme tokens from reference project when configured; otherwise inline values
- No hard-coded pixel values for colors or typography if tokens are available

### Spec file (`<name>.component.spec.ts`) — only if `generateSpecs: true`

```typescript
describe('<ComponentName>', () => {
  beforeEach(() => TestBed.configureTestingModule({ imports: [ComponentName] }).compileComponents());
  it('should create', () => {
    const fixture = TestBed.createComponent(ComponentName);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
```

### Output path

Place all files in `<outputDir>/<component-name>/` where `outputDir` comes from config.

---

## Step 3 — Report

After writing all files, summarize:

```
✓ Generated: <component-name>
  Files:
    <outputDir>/<component-name>/<component-name>.component.ts
    <outputDir>/<component-name>/<component-name>.component.html
    <outputDir>/<component-name>/<component-name>.component.<ext>
    <outputDir>/<component-name>/<component-name>.component.spec.ts  (if specs on)

  Selector:  app-<component-name>
  Inputs:    <list>
  Outputs:   <list>

  Assets to export from Figma:
    - <asset-name> → src/assets/images/<asset-name>.png

  Usage:
    Import ComponentName and add <app-<component-name> /> to your template.
```

---

## Options

| Flag | Effect |
|------|--------|
| `--reconfigure` | Re-run the setup wizard even if config exists |
| `--stories` | Also generate a Storybook `.stories.ts` file |
| `--output <path>` | Override `outputDir` from config for this run only |

---

## Notes

- The component name is inferred from the Figma layer name. Rename the layer in Figma for a better selector.
- If the node contains nested components, each is generated as a separate standalone component.
- Run `/setup-wizard` at any time to update the saved configuration.
