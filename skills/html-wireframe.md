# Skill: HTML Wireframe Generation

Reference guide for producing self-contained, pixel-precise HTML wireframes that designers can import into Figma using the **html.to.design** plugin.

---

## Purpose

These are not prototypes. They are **greyscale structural wireframes** — the kind designers hand off to stakeholders before visual design begins. Every element is a grey box with a label. No colour, no images, no brand identity.

They must:
- Render accurately in a browser at a fixed viewport width
- Be fully self-contained (single `.html` file per screen, inline `<style>`)
- Import cleanly via html.to.design at the target viewport width

---

## Global Wireframe Palette

Use only these values — never any colour from the UX spec at this stage:

```css
--wf-bg:          #F7F7F7;   /* page background */
--wf-surface:     #FFFFFF;   /* card / panel background */
--wf-border:      #D9D9D9;   /* all borders */
--wf-block-dark:  #C4C4C4;   /* nav, header, sidebar */
--wf-block-mid:   #DCDCDC;   /* cards, inputs, buttons */
--wf-block-light: #EBEBEB;   /* table rows, list items */
--wf-placeholder: #BDBDBD;   /* image / icon placeholder fill */
--wf-text-dark:   #333333;   /* headings, labels */
--wf-text-mid:    #666666;   /* body text */
--wf-text-light:  #999999;   /* captions, hints */
--wf-accent:      #A0A0A0;   /* active nav, primary button */
--wf-white:       #FFFFFF;
```

---

## HTML File Template

Every screen is one self-contained `.html` file:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=1440" />
  <title>Wireframe — [Screen Name]</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    /* ── Palette ── */
    :root {
      --wf-bg:           #F7F7F7;
      --wf-surface:      #FFFFFF;
      --wf-border:       #D9D9D9;
      --wf-block-dark:   #C4C4C4;
      --wf-block-mid:    #DCDCDC;
      --wf-block-light:  #EBEBEB;
      --wf-placeholder:  #BDBDBD;
      --wf-text-dark:    #333333;
      --wf-text-mid:     #666666;
      --wf-text-light:   #999999;
      --wf-accent:       #A0A0A0;
    }

    body {
      font-family: 'Arial', sans-serif;
      font-size: 13px;
      background: var(--wf-bg);
      color: var(--wf-text-dark);
      width: 1440px;   /* fixed — html.to.design captures at this width */
      min-height: 900px;
    }

    /* ── Paste component styles below ── */
  </style>
</head>
<body>
  <!-- screen markup here -->
</body>
</html>
```

**Viewport widths by device:**

| Target | `width` value |
|--------|--------------|
| Desktop (default) | `1440px` |
| Laptop | `1280px` |
| Tablet | `768px` |
| Mobile | `375px` |

---

## Wireframe Component Library

### Navigation — Top Bar

```html
<style>
.wf-topnav {
  display: flex; align-items: center; justify-content: space-between;
  height: 60px; padding: 0 24px;
  background: var(--wf-block-dark); border-bottom: 1px solid var(--wf-border);
  position: sticky; top: 0; z-index: 100;
}
.wf-topnav__logo {
  width: 120px; height: 28px;
  background: var(--wf-accent); border-radius: 4px;
}
.wf-topnav__links { display: flex; gap: 8px; }
.wf-topnav__link {
  padding: 6px 14px; border-radius: 4px;
  background: transparent; color: var(--wf-text-dark);
  font-size: 13px; cursor: pointer;
}
.wf-topnav__link--active { background: var(--wf-accent); color: var(--wf-white); }
.wf-topnav__actions { display: flex; gap: 8px; align-items: center; }
</style>

<nav class="wf-topnav">
  <div class="wf-topnav__logo"></div>
  <div class="wf-topnav__links">
    <span class="wf-topnav__link wf-topnav__link--active">Dashboard</span>
    <span class="wf-topnav__link">Orders</span>
    <span class="wf-topnav__link">Products</span>
  </div>
  <div class="wf-topnav__actions">
    <div class="wf-icon-btn"></div>
    <div class="wf-avatar"></div>
  </div>
</nav>
```

---

### Navigation — Left Sidebar

```html
<style>
.wf-sidebar {
  width: 240px; min-height: 100vh;
  background: var(--wf-block-dark);
  border-right: 1px solid var(--wf-border);
  display: flex; flex-direction: column;
  padding: 16px 0;
  flex-shrink: 0;
}
.wf-sidebar__logo {
  width: 100px; height: 24px; margin: 0 16px 24px;
  background: var(--wf-accent); border-radius: 4px;
}
.wf-sidebar__item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 16px; cursor: pointer;
  color: var(--wf-text-dark); font-size: 13px;
}
.wf-sidebar__item--active {
  background: var(--wf-block-mid);
  border-left: 3px solid var(--wf-accent);
}
.wf-sidebar__icon {
  width: 16px; height: 16px; border-radius: 3px;
  background: var(--wf-placeholder); flex-shrink: 0;
}
.wf-sidebar__footer {
  margin-top: auto; padding: 12px 16px;
  border-top: 1px solid var(--wf-border);
  display: flex; align-items: center; gap: 8px;
}
</style>

<aside class="wf-sidebar">
  <div class="wf-sidebar__logo"></div>
  <div class="wf-sidebar__item wf-sidebar__item--active">
    <div class="wf-sidebar__icon"></div> Dashboard
  </div>
  <div class="wf-sidebar__item">
    <div class="wf-sidebar__icon"></div> Orders
  </div>
  <div class="wf-sidebar__item">
    <div class="wf-sidebar__icon"></div> Products
  </div>
  <div class="wf-sidebar__footer">
    <div class="wf-avatar wf-avatar--sm"></div>
    <div>
      <div class="wf-text-line" style="width:80px"></div>
      <div class="wf-text-line wf-text-line--sm" style="width:60px;margin-top:4px"></div>
    </div>
  </div>
</aside>
```

---

### Stat / KPI Card

```html
<style>
.wf-card {
  background: var(--wf-surface); border: 1px solid var(--wf-border);
  border-radius: 6px; padding: 20px;
}
.wf-card--stat {
  display: flex; flex-direction: column; gap: 8px;
}
.wf-stat-icon {
  width: 36px; height: 36px; border-radius: 6px;
  background: var(--wf-block-mid);
}
.wf-stat-value {
  font-size: 28px; font-weight: 700;
  color: var(--wf-text-dark); line-height: 1;
}
.wf-stat-label { font-size: 12px; color: var(--wf-text-light); }
.wf-stat-trend {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px 8px; border-radius: 99px;
  background: var(--wf-block-light);
  font-size: 11px; color: var(--wf-text-mid);
}
</style>

<div class="wf-card wf-card--stat">
  <div class="wf-stat-icon"></div>
  <div class="wf-stat-value">2,847</div>
  <div class="wf-stat-label">Total Orders</div>
  <span class="wf-stat-trend">↑ +12% this month</span>
</div>
```

---

### Data Table

```html
<style>
.wf-table-wrap {
  background: var(--wf-surface); border: 1px solid var(--wf-border);
  border-radius: 6px; overflow: hidden;
}
.wf-table-toolbar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 12px 16px; border-bottom: 1px solid var(--wf-border);
}
.wf-table { width: 100%; border-collapse: collapse; }
.wf-table th {
  background: var(--wf-block-light); padding: 10px 16px;
  text-align: left; font-size: 11px; font-weight: 600;
  color: var(--wf-text-light); text-transform: uppercase; letter-spacing: 0.05em;
  border-bottom: 1px solid var(--wf-border);
}
.wf-table td {
  padding: 12px 16px; border-bottom: 1px solid var(--wf-block-light);
  font-size: 13px; color: var(--wf-text-mid);
}
.wf-table tr:last-child td { border-bottom: none; }
.wf-table tr:hover td { background: var(--wf-block-light); }
</style>

<div class="wf-table-wrap">
  <div class="wf-table-toolbar">
    <div class="wf-input" style="width:240px"></div>
    <div style="display:flex;gap:8px">
      <div class="wf-btn">Filter</div>
      <div class="wf-btn wf-btn--primary">+ New Order</div>
    </div>
  </div>
  <table class="wf-table">
    <thead>
      <tr>
        <th>Order ID</th><th>Customer</th><th>Date</th><th>Status</th><th>Amount</th><th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <!-- repeat wf-table-row 5–8 times -->
      <tr>
        <td>#00123</td>
        <td><div class="wf-text-line" style="width:100px"></div></td>
        <td>Jan 12, 2025</td>
        <td><span class="wf-badge">Processing</span></td>
        <td>$142.00</td>
        <td><div style="display:flex;gap:6px"><div class="wf-icon-btn"></div><div class="wf-icon-btn"></div></div></td>
      </tr>
    </tbody>
  </table>
</div>
```

---

### Form

```html
<style>
.wf-form { display: flex; flex-direction: column; gap: 16px; }
.wf-field { display: flex; flex-direction: column; gap: 6px; }
.wf-label { font-size: 12px; font-weight: 600; color: var(--wf-text-dark); }
.wf-input {
  height: 38px; border: 1px solid var(--wf-border); border-radius: 4px;
  background: var(--wf-surface); padding: 0 12px;
  font-size: 13px; color: var(--wf-text-light);
  display: flex; align-items: center;
}
.wf-input::after { content: attr(data-placeholder); }
.wf-textarea {
  height: 96px; border: 1px solid var(--wf-border); border-radius: 4px;
  background: var(--wf-surface); padding: 10px 12px;
  resize: none;
}
.wf-select {
  height: 38px; border: 1px solid var(--wf-border); border-radius: 4px;
  background: var(--wf-surface); padding: 0 12px;
  display: flex; align-items: center; justify-content: space-between;
}
.wf-select::after { content: '▾'; color: var(--wf-text-light); }
.wf-hint { font-size: 11px; color: var(--wf-text-light); }
.wf-form-actions {
  display: flex; gap: 8px; justify-content: flex-end;
  padding-top: 8px; border-top: 1px solid var(--wf-border);
}
</style>

<form class="wf-form">
  <div class="wf-field">
    <label class="wf-label">Email address</label>
    <div class="wf-input" data-placeholder="Enter your email"></div>
  </div>
  <div class="wf-field">
    <label class="wf-label">Password</label>
    <div class="wf-input" data-placeholder="••••••••"></div>
    <span class="wf-hint">Minimum 8 characters</span>
  </div>
  <div class="wf-form-actions">
    <div class="wf-btn">Cancel</div>
    <div class="wf-btn wf-btn--primary">Save changes</div>
  </div>
</form>
```

---

### Image Placeholder

```html
<style>
.wf-img {
  background: var(--wf-placeholder);
  border-radius: 4px;
  position: relative;
  overflow: hidden;
  display: flex; align-items: center; justify-content: center;
}
/* Diagonal cross lines — CSS only, no SVG */
.wf-img::before, .wf-img::after {
  content: '';
  position: absolute; inset: 0;
  background:
    linear-gradient(to bottom right, transparent calc(50% - 0.5px), #b0b0b0 calc(50% - 0.5px), #b0b0b0 calc(50% + 0.5px), transparent calc(50% + 0.5px));
}
.wf-img::after {
  background:
    linear-gradient(to top right, transparent calc(50% - 0.5px), #b0b0b0 calc(50% - 0.5px), #b0b0b0 calc(50% + 0.5px), transparent calc(50% + 0.5px));
}
.wf-img__label {
  position: relative; z-index: 1;
  font-size: 11px; color: var(--wf-text-mid);
  background: rgba(255,255,255,0.75); padding: 2px 6px; border-radius: 2px;
}

/* Avatar variant */
.wf-avatar {
  width: 36px; height: 36px; border-radius: 50%;
  background: var(--wf-placeholder);
  flex-shrink: 0;
}
.wf-avatar--sm { width: 28px; height: 28px; }
.wf-avatar--lg { width: 56px; height: 56px; }

/* Icon button */
.wf-icon-btn {
  width: 28px; height: 28px; border-radius: 4px;
  background: var(--wf-block-mid);
}
</style>

<!-- Hero image placeholder 100% wide, 360px tall -->
<div class="wf-img" style="width:100%;height:360px">
  <span class="wf-img__label">Hero Image 1440×360</span>
</div>

<!-- Thumbnail 200×140 -->
<div class="wf-img" style="width:200px;height:140px">
  <span class="wf-img__label">Thumbnail</span>
</div>
```

---

### Buttons

```html
<style>
.wf-btn {
  display: inline-flex; align-items: center; justify-content: center;
  height: 36px; padding: 0 16px; border-radius: 4px;
  font-size: 13px; font-weight: 500; cursor: pointer;
  background: var(--wf-block-mid); color: var(--wf-text-dark);
  border: 1px solid var(--wf-border);
}
.wf-btn--primary {
  background: var(--wf-accent); color: var(--wf-white); border-color: var(--wf-accent);
}
.wf-btn--danger {
  background: var(--wf-block-mid); color: var(--wf-text-dark);
  border: 1px solid var(--wf-text-mid);
}
.wf-btn--lg { height: 44px; padding: 0 24px; font-size: 14px; }
</style>

<div class="wf-btn">Secondary</div>
<div class="wf-btn wf-btn--primary">Primary Action</div>
<div class="wf-btn wf-btn--danger">Delete</div>
```

---

### Badge / Status Chip

```html
<style>
.wf-badge {
  display: inline-flex; align-items: center;
  padding: 2px 8px; border-radius: 99px;
  font-size: 11px; font-weight: 500;
  background: var(--wf-block-light); color: var(--wf-text-mid);
  border: 1px solid var(--wf-border);
}
</style>

<span class="wf-badge">Processing</span>
<span class="wf-badge">Shipped</span>
<span class="wf-badge">Cancelled</span>
```

---

### Text Lines (placeholder body text)

```html
<style>
.wf-text-line {
  height: 12px; border-radius: 2px;
  background: var(--wf-block-mid); display: block;
}
.wf-text-line--sm { height: 10px; background: var(--wf-block-light); }
.wf-text-line--lg { height: 16px; }
/* Stack multiple lines to simulate a paragraph */
.wf-para { display: flex; flex-direction: column; gap: 6px; }
</style>

<!-- Paragraph placeholder -->
<div class="wf-para">
  <div class="wf-text-line" style="width:100%"></div>
  <div class="wf-text-line" style="width:92%"></div>
  <div class="wf-text-line" style="width:78%"></div>
</div>
```

---

### Modal / Dialog

```html
<style>
.wf-modal-backdrop {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.3);
  display: flex; align-items: center; justify-content: center;
  z-index: 200;
}
.wf-modal {
  background: var(--wf-surface); border: 1px solid var(--wf-border);
  border-radius: 8px; width: 480px; overflow: hidden;
}
.wf-modal__header {
  padding: 16px 20px; border-bottom: 1px solid var(--wf-border);
  display: flex; align-items: center; justify-content: space-between;
  font-weight: 600; font-size: 15px;
}
.wf-modal__body { padding: 20px; }
.wf-modal__footer {
  padding: 12px 20px; border-top: 1px solid var(--wf-border);
  display: flex; justify-content: flex-end; gap: 8px;
}
</style>

<div class="wf-modal-backdrop">
  <div class="wf-modal">
    <div class="wf-modal__header">
      Confirm Action
      <div class="wf-icon-btn"></div>
    </div>
    <div class="wf-modal__body">
      <div class="wf-para">
        <div class="wf-text-line" style="width:100%"></div>
        <div class="wf-text-line" style="width:85%"></div>
      </div>
    </div>
    <div class="wf-modal__footer">
      <div class="wf-btn">Cancel</div>
      <div class="wf-btn wf-btn--primary">Confirm</div>
    </div>
  </div>
</div>
```

---

### Empty State

```html
<style>
.wf-empty {
  display: flex; flex-direction: column; align-items: center;
  justify-content: center; gap: 16px;
  padding: 64px 24px; text-align: center;
}
.wf-empty__illustration {
  width: 80px; height: 80px; border-radius: 12px;
  background: var(--wf-block-light);
  display: flex; align-items: center; justify-content: center;
}
.wf-empty__title { font-size: 16px; font-weight: 600; color: var(--wf-text-dark); }
.wf-empty__desc { font-size: 13px; color: var(--wf-text-light); max-width: 320px; }
</style>

<div class="wf-empty">
  <div class="wf-empty__illustration">
    <div class="wf-img" style="width:48px;height:48px;border-radius:8px"></div>
  </div>
  <div class="wf-empty__title">No orders yet</div>
  <div class="wf-empty__desc">Create your first order to get started.</div>
  <div class="wf-btn wf-btn--primary">+ Create Order</div>
</div>
```

---

### Pagination

```html
<style>
.wf-pagination {
  display: flex; align-items: center; justify-content: space-between;
  padding: 12px 16px; border-top: 1px solid var(--wf-border);
  font-size: 12px; color: var(--wf-text-light);
}
.wf-pagination__pages { display: flex; gap: 4px; }
.wf-page-btn {
  width: 28px; height: 28px; border-radius: 4px;
  background: var(--wf-block-light); border: 1px solid var(--wf-border);
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; cursor: pointer;
}
.wf-page-btn--active { background: var(--wf-accent); color: var(--wf-white); border-color: var(--wf-accent); }
</style>

<div class="wf-pagination">
  <span>Showing 1–10 of 48 results</span>
  <div class="wf-pagination__pages">
    <div class="wf-page-btn">‹</div>
    <div class="wf-page-btn wf-page-btn--active">1</div>
    <div class="wf-page-btn">2</div>
    <div class="wf-page-btn">3</div>
    <div class="wf-page-btn">›</div>
  </div>
</div>
```

---

## Screen Layout Templates

### Dashboard (sidebar + content)

```html
<body style="display:flex; flex-direction:column; width:1440px; min-height:900px;">
  <!-- Top nav (sticky) -->
  <nav class="wf-topnav">...</nav>

  <div style="display:flex; flex:1;">
    <!-- Left sidebar -->
    <aside class="wf-sidebar">...</aside>

    <!-- Main content -->
    <main style="flex:1; padding:24px; display:flex; flex-direction:column; gap:24px; overflow:auto;">
      <!-- Page title -->
      <div>
        <h1 style="font-size:24px;font-weight:700;color:var(--wf-text-dark)">Dashboard</h1>
        <p style="font-size:13px;color:var(--wf-text-light);margin-top:4px">Welcome back, John</p>
      </div>

      <!-- Stat cards row -->
      <div style="display:grid; grid-template-columns:repeat(4,1fr); gap:16px;">
        <!-- 4× wf-card wf-card--stat -->
      </div>

      <!-- Section heading -->
      <h2 style="font-size:16px;font-weight:600;color:var(--wf-text-dark)">Recent Orders</h2>

      <!-- Data table -->
      <div class="wf-table-wrap">...</div>
    </main>
  </div>
</body>
```

### Auth / Login (centered card)

```html
<body style="display:flex; align-items:center; justify-content:center;
             min-height:900px; background:var(--wf-bg); width:1440px;">
  <div style="width:400px; display:flex; flex-direction:column; gap:24px;">
    <!-- Logo -->
    <div style="text-align:center;">
      <div style="width:48px;height:48px;border-radius:10px;
                  background:var(--wf-accent);margin:0 auto 12px;"></div>
      <h1 style="font-size:20px;font-weight:700;">Sign in to your account</h1>
    </div>
    <!-- Card -->
    <div class="wf-card" style="padding:28px;">
      <form class="wf-form">...</form>
    </div>
    <!-- Footer links -->
    <p style="text-align:center;font-size:12px;color:var(--wf-text-light)">
      Don't have an account?
      <span style="color:var(--wf-accent);cursor:pointer">Sign up</span>
    </p>
  </div>
</body>
```

### Landing Page (full-width sections)

```html
<body style="width:1440px;">
  <nav class="wf-topnav">...</nav>

  <!-- Hero -->
  <section style="padding:80px 120px; text-align:center; background:var(--wf-surface);">
    <h1 style="font-size:48px;font-weight:800;color:var(--wf-text-dark);max-width:700px;margin:0 auto 16px;">
      [Main headline goes here]
    </h1>
    <div class="wf-para" style="max-width:480px;margin:0 auto 32px;"></div>
    <div style="display:flex;gap:12px;justify-content:center;">
      <div class="wf-btn wf-btn--primary wf-btn--lg">Get started free</div>
      <div class="wf-btn wf-btn--lg">Watch demo</div>
    </div>
    <div class="wf-img" style="width:100%;height:400px;margin-top:48px;border-radius:8px;"></div>
  </section>

  <!-- Feature grid (3 col) -->
  <section style="padding:64px 120px; background:var(--wf-bg);">
    <h2 style="text-align:center;font-size:28px;font-weight:700;margin-bottom:40px;">Features</h2>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:24px;">
      <!-- 3× feature card -->
    </div>
  </section>
</body>
```

---

## File Naming Convention

```
.claude/wireframes/html/
  01-landing.html
  02-login.html
  03-signup.html
  04-dashboard.html
  05-orders.html
  06-order-detail.html
  07-settings.html
  ...
```

Number prefix matches the screen order in `wireframe-spec.json`.

---

## html.to.design Import Instructions

Include these instructions in `.claude/wireframes/html/IMPORT.md`:

```markdown
# Import Wireframes into Figma via html.to.design

## Option A — File import (recommended)
1. Install the html.to.design plugin in Figma
   (Figma Community → search "html.to.design")
2. Open your Figma file
3. Plugins → html.to.design → Import
4. Select "HTML file" tab
5. Upload each .html file from this folder
6. Set width to 1440 (or match the screen's viewport)
7. Click Import — each screen becomes a Figma frame

## Option B — Live URL
1. Serve this folder locally:
   npx serve .claude/wireframes/html -p 5500
2. In html.to.design, paste: http://localhost:5500/04-dashboard.html
3. Import at width 1440

## After import
- Each screen lands as a Frame named after the HTML file
- Group all screens in a page called "Wireframes"
- Use as the structural base for visual design
```

---

## Quality Rules

- Every element must have visible boundaries (border or background)
- No element should be invisible or zero-size
- Text content must be legible — use real labels, not `lorem ipsum`
- Stat values use realistic numbers (e.g. `2,847`, `$14,320`)
- Table rows use realistic data (names, dates, status labels)
- All interactive elements (buttons, inputs, nav items) must be visually distinct
- Viewport width must match the `<meta name="viewport" content="width=XXXX">` value
- File must render correctly when opened directly in a browser (`file://`)
