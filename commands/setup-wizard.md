# Setup Wizard

Interactive configuration wizard for the figma-angular-generator plugin. Runs automatically before `/generate-component` and `/generate-page`, or manually to update preferences.

## Usage

```
/setup-wizard
```

---

## Wizard Steps

Run through each step interactively. Show the current/default value in brackets. Accept the user's input or use the default if they press Enter.

---

### Step 0 — Project Detection

**Before asking anything**, check whether the current workspace already has an Angular project:

```
Does angular.json exist in the workspace root?
  YES → skip creation questions, go straight to Step 1
  NO  → project creation mode (see below)
```

If `angular.json` is missing, print:

```
No Angular project detected in this workspace.
The plugin is installed — let's create your Angular project now.
```

Then ask:

> **Are you working in an existing Angular project or creating a new one?**
>
> 1. Create a new Angular project here *(recommended)*
> 2. Point to an existing Angular project at another path
>
> Enter 1–2 [1]:

---

#### If "Create a new Angular project here" (or no angular.json detected):

Ask in sequence:

> **Project name?**
>
> Enter name (kebab-case, e.g. my-app):

Validate: lowercase letters, numbers, hyphens only. No spaces. Re-ask if invalid.

> **Where should the project be created?**
>
> 1. Inside this workspace folder as a subfolder  *(e.g. ./my-app/)*  *(default)*
> 2. At a custom path
>
> Enter 1–2 [1]:

If option 2, ask:
> Enter parent directory:

> **Which Angular version are you targeting?**
>
> 1. Angular 17 — Standalone Components, `input()`/`output()` signals, `@if`/`@for` control flow *(default)*
> 2. Angular 16 — Standalone Components, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
> 3. Angular 15 — Standalone Components, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
> 4. Angular 14 — NgModule-based, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
>
> Enter 1–4 [1]:

Save choice as `angularVersion` (17 | 16 | 15 | 14).

> **Stylesheet format?**
> (Used for the new project and all generated components)
>
> 1. SCSS *(default)*
> 2. CSS
> 3. LESS
>
> Enter 1–3 [1]:

Then run:

```bash
ng new "<project-name>" \
  --style=<stylesheet> \
  --standalone \
  --skip-git \
  --routing \
  --no-interactive \
  --directory="<resolved-path>"
```

Show live output so the user can see `ng new` running.

After `ng new` completes:

```
✓ Angular project created at <resolved-path>

Creating asset directories...
✓ src/assets/images/
✓ src/assets/icons/
```

Create `src/assets/images/` and `src/assets/icons/` immediately after `ng new`.

Save `projectPath` as the resolved absolute path.

Skip Steps 2–5 defaults — pre-fill: outputDir = ./src/app/components/, referenceProject = None, stylesheet = chosen above, specs = Yes. Angular version was already collected above.
Go directly to the Confirmation Summary and save config.

---

#### If "Point to an existing project at another path":

Ask:
> Enter the full path to your Angular project:

Validate that `angular.json` exists at that path. Re-ask if not found.

Set `projectPath` to that path and continue to Step 1 below.

---

#### If angular.json already exists in workspace:

Continue directly to Step 1 below.

---

### Step 1 — Angular Version

Ask:

> **Which Angular version are you targeting?**
>
> 1. Angular 17 — Standalone Components, `input()`/`output()` signals, `@if`/`@for` control flow *(default)*
> 2. Angular 16 — Standalone Components, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
> 3. Angular 15 — Standalone Components, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
> 4. Angular 14 — NgModule-based, `@Input()`/`@Output()` decorators, `*ngIf`/`*ngFor`
>
> Enter 1–4 [1]:

Save choice as `angularVersion` (17 | 16 | 15 | 14).

**Generation rules per version:**

| Feature | v17 | v16/v15 | v14 |
|---------|-----|---------|-----|
| `standalone: true` | ✓ | ✓ | Optional |
| Inputs | `input<T>()` signal | `@Input()` decorator | `@Input()` decorator |
| Outputs | `output<T>()` signal | `@Output() EventEmitter` | `@Output() EventEmitter` |
| Conditional | `@if` / `@else` | `*ngIf` | `*ngIf` |
| Loops | `@for ... track` | `*ngFor` | `*ngFor` |
| NgModule | Not needed | Not needed | Required |

---

### Step 2 — Output Directory

Ask:

> **Where should generated components be placed?**
>
> Enter path [./src/app/components/]:

- Accept relative or absolute paths.
- If the path doesn't exist, note that it will be created.
- Remember the last used path and show it as the default on subsequent runs.
- For `/generate-page`, child components go in this path; the page component always goes in `./src/app/pages/`.

Save as `outputDir`.

---

### Step 3 — Reference Existing Angular Project

Ask:

> **Reference an existing Angular project for style conventions?**
>
> Y/N [N]:

If **Yes**, ask:

> **Enter the path to the existing Angular project:**
>
> Path:

Then silently analyze the project:

1. **Naming conventions** — scan component filenames and class names to detect kebab-case vs camelCase patterns.
2. **Coding style** — check whether existing components use signals (`input()`) or decorators (`@Input()`), standalone or NgModule, inline templates or separate files.
3. **Existing modules/imports** — list shared modules, UI libraries (Angular Material, PrimeNG, NGX Bootstrap, etc.), and utility services that generated code should import instead of creating duplicates.
4. **Theme / design system** — look for `_variables.scss`, `_tokens.scss`, `theme.scss`, CSS custom properties, or a design token file; extract the token names/values to use in generated styles.

After analysis, print a summary:

```
✓ Project analyzed:
  Angular version detected: 17
  Style: Standalone + signals
  UI library: Angular Material (detected)
  Theme tokens: src/styles/_variables.scss (found)
  Naming: kebab-case selectors, PascalCase classes
```

Save as `referenceProjectPath` and `referenceProjectSummary`.

---

### Step 4 — Stylesheet Format

Ask:

> **Stylesheet format?**
>
> 1. SCSS *(default)*
> 2. CSS
> 3. LESS
>
> Enter 1–3 [1]:

Save as `stylesheetFormat` (scss | css | less).

Apply to all generated style files (`.component.scss` / `.component.css` / `.component.less`).

---

### Step 5 — Generate Unit Test Files

Ask:

> **Generate unit test (`.spec.ts`) files?**
>
> Y/N [Y]:

Save as `generateSpecs` (true | false).

When `true`, generate a `.spec.ts` alongside every `.component.ts` with:
- `TestBed.configureTestingModule` setup
- A basic `should create` test
- Stubs for any `@Input()` / `input()` properties

---

## Confirmation Summary

After all steps, print:

```
┌─────────────────────────────────────────────────┐
│           figma-angular-generator config         │
├──────────────────────┬──────────────────────────┤
│ Project              │ ./  (existing)            │
│ Angular version      │ 17                        │
│ Output directory     │ ./src/app/components/     │
│ Reference project    │ None                      │
│ Stylesheet format    │ SCSS                      │
│ Generate spec files  │ Yes                       │
└──────────────────────┴──────────────────────────┘

Proceed with these settings? Y/N [Y]:
```

For a newly created project, show:

```
┌─────────────────────────────────────────────────┐
│           figma-angular-generator config         │
├──────────────────────┬──────────────────────────┤
│ Project              │ C:/Projects/my-app (new)  │
│ Angular version      │ 17                        │
│ Output directory     │ ./src/app/components/     │
│ Reference project    │ None                      │
│ Stylesheet format    │ SCSS                      │
│ Generate spec files  │ Yes                       │
└──────────────────────┴──────────────────────────┘

Proceed with these settings? Y/N [Y]:
```

If **No**, restart from Step 1.
If **Yes**, save config and continue to generation.

---

## Config Persistence

Save the collected config to `.claude/figma-generator.config.json` in the current workspace:

```json
{
  "projectName": "my-app",
  "projectPath": "C:/Users/<user>/Projects/my-app",
  "angularVersion": 17,
  "outputDir": "./src/app/components/",
  "referenceProjectPath": null,
  "referenceProjectSummary": null,
  "stylesheetFormat": "scss",
  "generateSpecs": true
}
```

- `projectName` — kebab-case name; `null` for existing projects
- `projectPath` — absolute path to the project root; `null` means use the current workspace

On subsequent runs, load this file and pre-fill all defaults. Only prompt again if the user explicitly runs `/setup-wizard` or passes `--reconfigure`.
