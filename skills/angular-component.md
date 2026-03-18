# Skill: Writing Angular 17 Components

Reference guide for generating correct Angular 17 standalone components.

## File Structure

Every component lives in its own folder:

```
src/app/components/
  button/
    button.component.ts
    button.component.html
    button.component.scss
```

## Component Class Skeleton

```typescript
import { Component, input, output } from '@angular/core';

@Component({
  selector: 'app-button',
  standalone: true,
  imports: [],
  templateUrl: './button.component.html',
  styleUrl: './button.component.scss'
})
export class ButtonComponent {
  label = input.required<string>();
  variant = input<'primary' | 'secondary' | 'ghost'>('primary');
  disabled = input<boolean>(false);
  clicked = output<void>();

  handleClick(): void {
    if (!this.disabled()) {
      this.clicked.emit();
    }
  }
}
```

## Template Syntax (Angular 17)

Use the new control flow syntax — never `*ngIf` or `*ngFor`.

```html
<!-- Conditional -->
@if (isVisible()) {
  <span>Visible</span>
} @else {
  <span>Hidden</span>
}

<!-- List -->
@for (item of items(); track item.id) {
  <li>{{ item.name }}</li>
} @empty {
  <li>No items</li>
}

<!-- Switch -->
@switch (variant()) {
  @case ('primary') { <span class="primary">...</span> }
  @case ('secondary') { <span class="secondary">...</span> }
  @default { <span>...</span> }
}
```

## Signals API

```typescript
import { signal, computed, effect } from '@angular/core';

count = signal(0);
doubled = computed(() => this.count() * 2);

constructor() {
  effect(() => console.log('count changed:', this.count()));
}
```

## SCSS Conventions

```scss
:host {
  display: block; // or inline-flex, flex, grid — match Figma layout
}

.button {
  // Use CSS custom properties for tokens
  background-color: var(--color-primary-500);
  border-radius: var(--radius-md);
  padding: var(--spacing-sm) var(--spacing-md);
  font-size: var(--font-size-base);

  &:hover {
    background-color: var(--color-primary-600);
  }

  &--secondary {
    background-color: transparent;
    border: 1px solid var(--color-primary-500);
  }
}
```

## Accessibility Checklist

- Use semantic HTML (`<button>`, `<nav>`, `<main>`, `<header>`, `<section>`)
- Add `aria-label` when element purpose is not clear from text content
- Ensure interactive elements are keyboard-focusable
- Provide `alt` text for all `<img>` elements
- Use `role` attributes when native semantics are unavailable

## Common Patterns

### Image with fallback input
```typescript
imageSrc = input<string>('assets/placeholder.png');
imageAlt = input.required<string>();
```

### Emit typed event data
```typescript
itemSelected = output<{ id: string; label: string }>();
```

### Two-way binding with model()
```typescript
import { model } from '@angular/core';
value = model<string>('');
```
