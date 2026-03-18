# /requirements-to-figma

Convert GUI requirements from any source into wireframes and publish them to FigJam.

## Usage

```
/requirements-to-figma [source] [options]
```

### Source (pick one or combine)

```
/requirements-to-figma --jira https://yourorg.atlassian.net/browse/PROJ-123
/requirements-to-figma --file ./docs/requirements.pdf
/requirements-to-figma --file ./specs/UI-Brief.docx
/requirements-to-figma --text "Users need to login, browse products, add to cart, and checkout."
/requirements-to-figma --figjam https://www.figma.com/board/abc123/MyBoard
```

Multiple sources are allowed:
```
/requirements-to-figma --jira https://... --file ./docs/extra-specs.pdf
```

### Options

| Flag | Effect |
|------|--------|
| `--jira <url>` | Fetch and parse a Jira ticket |
| `--file <path>` | Read a PDF, Word doc, Markdown, or text file |
| `--text "<text>"` | Use inline text as requirements |
| `--figjam <url>` | Push wireframes into an existing FigJam board |
| `--no-figjam` | Skip FigJam creation; output wireframes as markdown only |
| `--reconfigure` | Reset saved project config before running |

---

## Step 1 — Load Project Config

Check for `.claude/figma-generator.config.json`. If it exists, load it silently:
```
Using config: Angular 17 | SCSS | ./src/app/components/
```
If it does not exist, that is fine — wireframe generation does not require it.

---

## Step 2 — Parse Requirements

Run the `requirements-analyzer` agent with all provided sources.

- Agent extracts screens, flows, features, constraints
- Agent fills design gaps autonomously (navigation pattern, color palette, typography, spacing)
- Agent writes `.claude/wireframe-spec.json` and `.claude/wireframe-summary.md`

Print the summary to the user when done:

```
Requirements analyzed:
  Screens:        8
  User flows:     4
  Components:     14 (5 shared + 9 screen-specific)
  Domain:         SaaS
  Navigation:     Sidebar
  Color palette:  Indigo/slate (SaaS defaults)
  Font:           Inter
  Radius:         soft (6px)
  Density:        comfortable
```

Ask the user: **"Does this look right? Type 'yes' to continue, or describe any corrections."**

Apply any corrections to `.claude/wireframe-spec.json` before proceeding.

---

## Step 3 — Design Wireframes

For each screen in the spec, generate a detailed wireframe description.

Use the layout patterns, component rules, and UX guidelines from `skills/requirements-to-wireframe.md`.

Claude makes all visual decisions autonomously. Do not ask the user for styling preferences unless brand colors were not provided — in that case ask once: "Any brand colors to use? (press Enter to skip)"

### Wireframe Format

For each screen, produce:

```markdown
## Screen: Dashboard

**Layout:** Left sidebar (240px) + main content area
**Background:** #F8FAFC

### Header (full width, sticky)
- Logo + app name (left)
- Search bar (center, 480px wide)
- Avatar + notification bell (right)

### Sidebar
- Navigation items: Overview, Orders, Products, Customers, Reports, Settings
- Active state: Indigo left border + light indigo background
- Bottom: User avatar + name + logout button

### Main Content
- Page title: "Dashboard" (h1, 28px, weight 700)
- Subtitle: "Welcome back, [name]" (14px, text-secondary)
- Stat Cards Row (4 cards, equal width):
  - Total Orders | Revenue This Month | Active Users | Pending Issues
  - Each card: icon (top-left) | value (large, bold) | label | trend chip (↑ +12%)
- Section: "Recent Orders" (h2)
  - Search + filter bar above table
  - Table columns: Order ID | Customer | Date | Status | Amount | Actions
  - Pagination (bottom, 10 rows/page default)

### States
- Loading: skeleton loaders for cards and table rows
- Empty: "No orders yet" illustration + "Create your first order" button
- Error: inline error banner below header
```

---

## Step 4 — Generate HTML Wireframes

For each screen in the spec, generate a self-contained `.html` wireframe file.

Use the component library, layout templates, and conventions from `skills/html-wireframe.md`.

### Rules

- One file per screen — fully self-contained, single `<style>` block, no external deps
- Greyscale palette only — no brand colours, no images, no fonts from CDN
- Use realistic placeholder content: real labels, plausible numbers, actual status values
- Set `<meta name="viewport" content="width=1440">` on all desktop screens
- Match the layout pattern for the screen type (sidebar+content, centered card, full-width sections, etc.)
- All interactive elements must be visually distinct (buttons, inputs, nav items, table rows)

### Output files

Write all HTML files to `.claude/wireframes/html/`:

```
.claude/wireframes/html/
  01-landing.html
  02-login.html
  03-dashboard.html
  04-orders.html
  05-order-detail.html
  ...
  IMPORT.md          ← html.to.design import instructions
```

Print after writing:

```
HTML wireframes generated:
  .claude/wireframes/html/01-landing.html
  .claude/wireframes/html/02-login.html
  .claude/wireframes/html/03-dashboard.html
  ...

Import into Figma:
  1. Install html.to.design plugin in Figma
  2. Plugins → html.to.design → Import → HTML file
  3. Upload each .html file, set width to 1440
  See .claude/wireframes/html/IMPORT.md for full instructions.
```

---

## Step 5 — Generate FigJam Diagram

Unless `--no-figjam` was passed, create a FigJam board with:

### A. User Flow Diagram

Call `mcp__claude_ai_Figma__generate_diagram` with a Mermaid flowchart representing all user flows.

Build the diagram from `userFlows` in `.claude/wireframe-spec.json`:

```
flowchart TD
  A[Landing Page] --> B{Has account?}
  B -->|Yes| C[Login]
  B -->|No| D[Sign Up]
  C --> E[Dashboard]
  D --> F[Email Verification]
  F --> E
  E --> G[Orders]
  E --> H[Settings]
  G --> I[Order Detail]
```

If `--figjam <url>` was provided, extract the board's `fileKey` from the URL and use it. Otherwise, create a new diagram (the tool will return the FigJam URL).

### B. Screen Inventory Diagram

Generate a second diagram showing the component hierarchy and which screens each component belongs to:

```
flowchart LR
  subgraph Shared
    Button
    Input
    Badge
    Modal
    Toast
    Table
  end
  subgraph Screens
    Login --> Button
    Login --> Input
    Dashboard --> Table
    Dashboard --> Badge
    Dashboard --> StatCard
    OrderDetail --> Badge
    OrderDetail --> Modal
  end
```

### Diagram Output

After calling `mcp__claude_ai_Figma__generate_diagram`:

```
FigJam wireframes created:
  User Flow Diagram:      https://www.figma.com/board/<key>/...
  Component Hierarchy:    (same board, second frame)
```

---

## Step 6 — Output Handoff Package

Write the full wireframe handoff to `.claude/wireframes/`:

```
.claude/wireframes/
  wireframe-spec.json         ← structured UX spec
  wireframe-summary.md        ← human-readable summary
  screens/
    01-landing.md             ← per-screen wireframe description
    02-login.md
    03-dashboard.md
    ...
  html/
    01-landing.html           ← self-contained HTML wireframe (import via html.to.design)
    02-login.html
    03-dashboard.html
    ...
    IMPORT.md                 ← step-by-step Figma import instructions
  design-tokens.md            ← color palette, typography, spacing as CSS variables
  component-inventory.md      ← all components with props and usage
```

### design-tokens.md format

```scss
:root {
  /* Colors */
  --color-primary:        #4F46E5;
  --color-primary-dark:   #3730A3;
  --color-primary-light:  #E0E7FF;
  --color-surface:        #FFFFFF;
  --color-surface-alt:    #F8FAFC;
  --color-text-primary:   #111827;
  --color-text-secondary: #6B7280;
  --color-border:         #E5E7EB;
  --color-success:        #10B981;
  --color-warning:        #F59E0B;
  --color-error:          #EF4444;
  --color-info:           #3B82F6;

  /* Typography */
  --font-family:          'Inter', sans-serif;
  --font-size-xs:         0.75rem;
  --font-size-sm:         0.875rem;
  --font-size-base:       1rem;
  --font-size-lg:         1.125rem;
  --font-size-xl:         1.25rem;
  --font-size-2xl:        1.5rem;
  --font-size-3xl:        1.875rem;
  --font-size-4xl:        2.25rem;

  /* Spacing */
  --spacing-xs:  4px;
  --spacing-sm:  8px;
  --spacing-md:  16px;
  --spacing-lg:  24px;
  --spacing-xl:  32px;
  --spacing-2xl: 48px;
  --spacing-3xl: 64px;

  /* Border Radius */
  --radius-sm:   4px;
  --radius-md:   6px;
  --radius-lg:   12px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-xs:  0 1px 2px rgba(0,0,0,0.05);
  --shadow-sm:  0 1px 3px rgba(0,0,0,0.10);
  --shadow-md:  0 4px 6px rgba(0,0,0,0.07);
  --shadow-lg:  0 10px 15px rgba(0,0,0,0.10);
  --shadow-xl:  0 20px 25px rgba(0,0,0,0.10);
}
```

---

## Step 7 — Final Report

```
Wireframes ready.

  Screens:         8
  User flows:      4
  Components:      14

  HTML wireframes: .claude/wireframes/html/   (8 files — import via html.to.design)
  FigJam board:    https://www.figma.com/board/...
  Handoff files:   .claude/wireframes/

Next steps:
  1. Import HTML wireframes into Figma:
       - Install html.to.design plugin in Figma
       - Plugins → html.to.design → Import → HTML file
       - Upload each .html file from .claude/wireframes/html/
       - See .claude/wireframes/html/IMPORT.md for full instructions

  2. Review the FigJam user flow diagram and share with stakeholders

  3. Open .claude/wireframes/wireframe-summary.md for the full UX spec

  4. Once designs are finalised in Figma, run:
       /generate-component <figma-url>   to produce Angular components
       /generate-page <figma-url>        to produce full Angular pages

  5. Reference .claude/wireframes/design-tokens.md when building your Angular theme
```

---

## Options Reference

| Flag | Effect |
|------|--------|
| `--no-html` | Skip HTML wireframe generation |
| `--no-figjam` | Skip FigJam diagram; output markdown wireframes only |
| `--mobile` | Generate HTML wireframes at 375px viewport instead of 1440px |
| `--tablet` | Generate HTML wireframes at 768px viewport |

---

## Notes

- Claude makes all UX and visual decisions autonomously unless the user provides explicit constraints.
- HTML wireframes use only greyscale — no brand colours, no real images, no web fonts.
- The HTML files are self-contained and open directly in any browser (`file://`).
- html.to.design captures each HTML file as a Figma frame at the specified viewport width.
- Designers can then apply the visual design layer on top of the imported wireframe frames.
- If requirements describe existing screens to be redesigned, Claude notes the current pattern and proposes an improved version.
- Jira tickets that link to external Google Docs or Confluence pages: Claude will attempt `WebFetch` on those URLs too.
- If the FigJam board URL was provided but is inaccessible (permissions), Claude outputs the diagram as Mermaid code in the terminal and skips FigJam creation.
