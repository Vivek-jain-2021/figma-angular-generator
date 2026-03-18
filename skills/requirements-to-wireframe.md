# Skill: Requirements to Wireframe

Reference guide for transforming GUI requirements into FigJam wireframes and Figma designs. Claude makes autonomous UX, layout, and styling decisions.

---

## Input Sources

| Source Type | How to Read It |
|-------------|----------------|
| Plain text / paste | Use directly |
| Jira URL | `WebFetch` the page; extract description, acceptance criteria, sub-tasks |
| PDF file | `Read` the file — Claude extracts text content |
| Word doc (.docx) | `Bash: python3 -c "import docx; ..."` or `Bash: cat` if converted; ask user to paste if unreadable |
| Markdown / TXT file | `Read` directly |
| Multiple files | Process each source, then merge into one UX spec |

---

## Requirements Extraction

From any input, extract and categorize:

### Screens
List every distinct page or view: `Login`, `Dashboard`, `Profile Settings`, `Order Detail`, etc.

### User Flows
Sequences of actions:
```
Guest → Landing page → Sign Up → Email Verification → Onboarding → Dashboard
User → Dashboard → Click Order → Order Detail → Track Shipment
```

### Features Per Screen
For each screen, list:
- Primary action (the main thing the user does)
- Data displayed
- Form fields (if any)
- Navigation links
- States (empty, loading, error, success)

### Data Entities
Objects the UI manipulates: User, Product, Order, Notification, etc.

### Constraints
Non-functional requirements: mobile-first, accessibility (WCAG AA), brand colors if specified, max steps in a flow, etc.

---

## UX Design Decisions (Claude's Autonomy)

When requirements do not specify design details, Claude decides using these principles:

### Layout Patterns by Screen Type

| Screen Type | Pattern |
|-------------|---------|
| Dashboard | Sidebar nav + content area; stat cards at top; data table or list below |
| Login / Auth | Centered card; logo at top; form in middle; CTA button; secondary link below |
| Landing page | Full-width hero + CTA; feature grid (3-col); testimonials; footer |
| Data table | Sticky header; filters + search bar above table; pagination below |
| Detail page | Breadcrumb; hero section; 2-col layout (main content + sidebar) |
| Form / Settings | Single-col form; grouped sections; save/cancel at bottom |
| Onboarding | Step indicator; one action per step; skip + back options |
| Empty state | Centered illustration placeholder; headline; primary CTA |
| Error page | Large status code; message; link home |
| Profile | Avatar + name header; tab navigation; content per tab |

### Navigation Patterns

- **≤5 top-level routes**: Top navigation bar
- **5–10 top-level routes**: Left sidebar (collapsible on mobile)
- **>10 routes or nested hierarchy**: Left sidebar with sections + nested items
- **Mobile-first apps**: Bottom tab bar (max 5 tabs) + hamburger overflow

### Typography Hierarchy (Claude defaults)

```
Page Title:    32–40px, weight 700
Section Title: 20–24px, weight 600
Card Title:    16–18px, weight 600
Body:          14–16px, weight 400
Caption/Label: 12px, weight 400–500
Button:        14–16px, weight 500–600
```

### Spacing Scale (Claude defaults)

```
xs: 4px   — icon gaps, tight labels
sm: 8px   — inner padding of small elements
md: 16px  — standard card padding, form field gap
lg: 24px  — section gap
xl: 32px  — page section gap
2xl: 48px — hero padding
3xl: 64px — full-page section separation
```

### Color Palette Decision Rules

If the requirements specify brand colors — use them.

Otherwise, Claude picks a palette that fits the product domain:

| Domain | Palette Direction |
|--------|------------------|
| Finance / Enterprise | Navy, slate, white; accent: teal or amber |
| Healthcare | Soft blue, white, light green; accent: warm orange |
| E-commerce | White, light grey, accent: brand color (blue or orange) |
| SaaS / Productivity | White/light mode default; accent: indigo or violet |
| Creative / Media | Dark mode; accent: vivid gradient |
| Social / Consumer | Bright whites, soft gradients, accent: brand blue or pink |

### Component Selection Rules

Always prefer standard, accessible patterns:

- **Primary action**: Filled button (`btn-primary`)
- **Secondary action**: Outlined or ghost button
- **Destructive action**: Red/danger outlined button, confirm dialog before executing
- **Data entry**: Labeled input with placeholder, inline validation message below
- **Selection**: Radio buttons (mutually exclusive) / Checkboxes (multi-select) / Select dropdown (>5 options)
- **Status indicators**: Colored badge (`success`, `warning`, `error`, `info`)
- **Data display**: Table for structured data, card grid for visual items, list for simple rows
- **Feedback**: Toast notifications (top-right, auto-dismiss 4s); Modal for confirmations

---

## Wireframe Structure for FigJam

When generating a FigJam diagram, structure it as:

### 1. User Flow Diagram
A flowchart showing navigation paths between screens. Use standard node types:
- **Rectangle**: Screen / Page
- **Rounded Rectangle**: Action / Interaction
- **Diamond**: Decision point (conditional branch)
- **Arrow**: Navigation direction

Example Mermaid-compatible structure:
```
flowchart TD
  A[Landing Page] --> B[Login]
  A --> C[Sign Up]
  B --> D[Dashboard]
  C --> E[Email Verification]
  E --> D
  D --> F[Profile]
  D --> G[Settings]
```

### 2. Screen Wireframes (per screen)
For each screen, describe the wireframe as a labeled layout:
```
┌──────────────────────────────────┐
│  [LOGO]     Nav: Home Dashboard  │  ← Header / Top nav
├──────────────────────────────────┤
│  [Sidebar]  │  [Main Content]    │  ← Two-col layout
│  - Nav 1    │  ┌───┐ ┌───┐ ┌───┐│
│  - Nav 2    │  │ C │ │ C │ │ C ││  ← Stat cards
│  - Nav 3    │  └───┘ └───┘ └───┘│
│             │  [Data Table]      │  ← Table
│             │  [Pagination]      │
└──────────────────────────────────┘
```

### 3. Component Inventory
List all reusable UI components identified:
- Shared: Button, Input, Badge, Avatar, Modal, Toast, Table, Pagination
- Screen-specific: HeroSection, StatCard, OrderRow, ProductCard, etc.

---

## Figma Wireframe Conventions

When creating wireframes in Figma (not FigJam):
- Use **#F5F5F5** grey for backgrounds
- Use **#E0E0E0** for empty content placeholders (images, avatars)
- Use **#333333** for text
- Use **#1A73E8** (Google Blue) or **#6200EE** (Material Purple) as placeholder primary color
- Label every element clearly
- Group related elements (use Figma frames, not loose groups)
- Name every frame descriptively: `Screen/Dashboard`, `Screen/Login`, `Component/Button/Primary`

---

## Output Artifacts

After analysis and design, produce:

1. **UX Spec** (structured JSON or markdown) — screens, flows, components, design decisions
2. **FigJam User Flow Diagram** — created via `mcp__claude_ai_Figma__generate_diagram`
3. **Wireframe description** — per-screen layout written in markdown, suitable for developer handoff or conversion to Figma frames
4. **Component inventory** — list of components to build
5. **Design tokens** — color palette, typography scale, spacing scale as CSS custom properties
