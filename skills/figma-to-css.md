# Skill: Converting Figma Styles to CSS

Reference guide for translating Figma design properties into CSS/SCSS.

## Colors

| Figma | CSS |
|-------|-----|
| Solid fill `#RRGGBB` | `color: #RRGGBB` |
| Solid fill with opacity | `color: rgba(R, G, B, A)` |
| Linear gradient | `background: linear-gradient(deg, stop1, stop2)` |
| Radial gradient | `background: radial-gradient(...)` |

**Named styles** — resolve to the actual value, then define as a CSS custom property:
```scss
// Figma: "Primary/500" → #3B82F6
--color-primary-500: #3B82F6;
```

## Typography

| Figma Property | CSS Property |
|----------------|-------------|
| Font family | `font-family` |
| Font size (px) | `font-size` — convert to `rem` (divide by 16) |
| Font weight | `font-weight` |
| Line height (px or %) | `line-height` — use unitless ratio when possible |
| Letter spacing (px) | `letter-spacing` — convert to `em` (divide by font-size) |
| Text transform | `text-transform` |
| Text decoration | `text-decoration` |

```scss
// Figma: Inter, 16px, 600, 24px line-height, 0.5px letter-spacing
font-family: 'Inter', sans-serif;
font-size: 1rem;       // 16 / 16 = 1
font-weight: 600;
line-height: 1.5;      // 24 / 16 = 1.5
letter-spacing: 0.031em; // 0.5 / 16 = 0.03125
```

## Spacing & Sizing

| Figma | CSS |
|-------|-----|
| Fixed width/height (px) | `width: Npx` / `height: Npx` |
| Fill container (horizontal) | `width: 100%` |
| Fill container (vertical) | `height: 100%` |
| Hug contents | `width: fit-content` / `height: fit-content` |
| Min width / Max width | `min-width` / `max-width` |

## Auto Layout → Flexbox

| Figma Auto Layout | CSS |
|-------------------|-----|
| Direction: Horizontal | `display: flex; flex-direction: row` |
| Direction: Vertical | `display: flex; flex-direction: column` |
| Gap | `gap: Npx` |
| Padding | `padding: top right bottom left` |
| Align items: Center | `align-items: center` |
| Justify content: Space between | `justify-content: space-between` |
| Wrap | `flex-wrap: wrap` |

**No auto layout** — use `position: absolute` only as a last resort. Prefer adding layout context.

## Auto Layout → CSS Grid

Use grid when Figma uses a grid layout (columns + rows with defined tracks):

```scss
display: grid;
grid-template-columns: repeat(3, 1fr);
gap: 16px;
```

## Borders & Strokes

| Figma | CSS |
|-------|-----|
| Stroke inside | `box-shadow: inset 0 0 0 Npx COLOR` |
| Stroke outside | `box-shadow: 0 0 0 Npx COLOR` |
| Stroke center | `border: Npx solid COLOR` |
| Dash pattern | `border-style: dashed` |

## Border Radius

```scss
// All corners equal
border-radius: 8px;

// Individual corners (Figma: TL TR BR BL)
border-radius: 8px 8px 0 0;
```

## Shadows

Figma shadow → CSS `box-shadow`:

```
Figma: X=0, Y=4, Blur=8, Spread=0, Color=#00000040
CSS:   box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.25);
```

For inner shadows use `inset`:
```scss
box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.1);
```

## Opacity

```scss
opacity: 0.5; // Figma layer opacity
```

Note: prefer `rgba()` for color-level opacity to avoid affecting child elements.

## Images & Icons

- Export Figma images as `webp` (photos) or `svg` (icons/illustrations)
- Place in `src/assets/images/` or `src/assets/icons/`
- Reference in SCSS as `background-image: url('/assets/images/hero.webp')`
- In templates: `<img src="/assets/icons/arrow.svg" alt="..." />`

## CSS Custom Properties Convention

Define all tokens in a global `:root` block (`src/styles.scss`):

```scss
:root {
  // Colors
  --color-primary-500: #3B82F6;
  --color-neutral-900: #111827;

  // Typography
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;

  // Spacing
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;

  // Radius
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 16px;
  --radius-full: 9999px;

  // Shadows
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 8px rgba(0, 0, 0, 0.1);
}
```
