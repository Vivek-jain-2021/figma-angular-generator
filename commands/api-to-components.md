# /api-to-components

Analyze backend API contracts and generate Angular HTTP services, models, interceptors, environment config, and feature components.

## Usage

```
/api-to-components [source] [options]
```

### Source (pick one or combine)

```
/api-to-components --spec ./openapi.yaml
/api-to-components --spec https://api.yourapp.com/v3/api-docs
/api-to-components --backend ./backend/src
/api-to-components --text "POST /api/orders with body { customerId, items[] }"
```

Multiple sources are allowed:
```
/api-to-components --spec ./openapi.yaml --backend ./backend/src
```

### Options

| Flag | Effect |
|------|--------|
| `--spec <path\|url>` | OpenAPI/Swagger YAML or JSON file or URL |
| `--backend <path>` | Path to backend source directory (NestJS, Spring, FastAPI, Express) |
| `--text "<description>"` | Describe the API in plain text |
| `--domain <name>` | Generate only this domain (e.g. `--domain orders`) |
| `--no-components` | Generate only services and models, skip UI components |
| `--no-interceptors` | Skip auth and error interceptor generation |
| `--cookie-auth` | Use httpOnly cookie auth instead of localStorage JWT |
| `--reconfigure` | Re-run setup wizard before generating |

---

## Step 1 — Load Config

Check for `.claude/figma-generator.config.json`. Load silently if found:
```
Using config: Angular 17 | SCSS | ./src/app/
```
If missing, that is fine — services and models do not require it. Components will use default paths.

---

## Step 2 — Analyze API

Run the `api-analyzer` agent on all provided sources.

The agent will:
- Read OpenAPI specs, backend controllers, DTOs, and config
- Extract all endpoints, request/response schemas, auth type, CORS settings
- Produce `.claude/api-spec.json` and `.claude/api-summary.md`

Print the summary:

```
API analyzed:
  Domains:    3  (auth, orders, products)
  Endpoints:  14
  Models:     11
  Auth:       JWT Bearer → localStorage
  CORS:       allowCredentials: false  ✓

⚠ CORS warnings:
  - Production HTTPS origin not found in allowedOrigins. Backend must add:
    APP_CORS_ALLOWED_ORIGINS=https://yourapp.com

  - No proxy.conf.json found — will be generated for local dev.
```

Ask the user: **"Does this look right? Type 'yes' to continue, or list any corrections."**

---

## Step 3 — Generate Core Infrastructure

### 3a. Environment Files

Generate or update `src/environments/environment.ts` and `environment.prod.ts`.

```typescript
// src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: '/api'  // proxied in dev via proxy.conf.json
};
```

```typescript
// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.yourapp.com'  // read from CORS allowedOrigins or ask user
};
```

If the user passed `--cookie-auth`, do NOT add anything for withCredentials here — it is handled per-request in the interceptor.

### 3b. Dev Proxy

Generate `proxy.conf.json` if it does not exist:

```json
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  }
}
```

Check `angular.json` for `serve.options`. If `proxyConfig` is not set, add it:
```json
"proxyConfig": "proxy.conf.json"
```

Print: `✓ proxy.conf.json → /api proxied to http://localhost:8080 (dev only)`

### 3c. Auth Interceptor

Unless `--no-interceptors` was passed, generate:

`src/app/core/interceptors/auth.interceptor.ts`

- **localStorage JWT (default)**:
  - Reads token from `AuthService.getToken()`
  - Sets `Authorization: Bearer <token>` on every request
  - Does NOT set `withCredentials` (stays `false`)

- **httpOnly cookie (`--cookie-auth`)**:
  - Does NOT set Authorization header
  - Sets `withCredentials: true` on every request
  - Prints a note: "Backend must set allowCredentials(true) and an explicit origin (no wildcard)"

### 3d. Error Interceptor

Unless `--no-interceptors` was passed, generate:

`src/app/core/interceptors/error.interceptor.ts`

- `401 Unauthorized` → clear token + navigate to `/login`
- `403 Forbidden` → navigate to `/forbidden`
- `0` (network error / CORS blocked) → emit a user-friendly "Network error — check your connection" message
- All other errors → extract `error.message` from response body

### 3e. Auth Service

Generate `src/app/core/services/auth.service.ts`:
- `setToken(token)` / `getToken()` / `clearToken()` using localStorage
- `isLoggedIn` as a readonly `signal<boolean>`
- `login(dto)` → calls `POST /api/auth/login`, stores token, returns `Observable<AuthResponse>`
- `logout()` → calls `POST /api/auth/logout` (if endpoint exists), clears token

### 3f. App Config Registration

Update or create `src/app/app.config.ts` to register interceptors:

```typescript
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { errorInterceptor } from './core/interceptors/error.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor, errorInterceptor]))
  ]
};
```

---

## Step 4 — Generate Models

For each model in `.claude/api-spec.json`, generate a TypeScript interface file.

Group related models in the same file by domain:

```
src/app/core/models/
  auth.model.ts       ← LoginDto, RegisterDto, AuthResponse, User
  order.model.ts      ← Order, OrderItem, CreateOrderDto, UpdateOrderDto, OrderListResponse
  product.model.ts    ← Product, CreateProductDto, ProductListResponse
```

Rules (see `skills/api-to-angular.md`):
- Map backend types to TypeScript types
- Enums become union types: `'pending' | 'processing' | 'shipped'`
- `Optional<T>` / nullable → `T | null`
- Date fields → `string` (ISO 8601), add a JSDoc comment: `/** ISO 8601 date string */`

---

## Step 5 — Generate HTTP Services

For each domain in the spec, generate one service file:

```
src/app/core/services/
  auth.service.ts
  orders.service.ts
  products.service.ts
```

Each service (see `skills/api-to-angular.md`):
- Uses `inject(HttpClient)` — no constructor injection
- Reads `environment.apiUrl` for the base URL
- Has one method per endpoint
- Query params use `HttpParams`
- Returns typed `Observable<T>` — never `Observable<any>`

---

## Step 6 — Generate Feature Components

Skip this step if `--no-components` was passed.

For each domain, generate smart + presentational components:

### Smart (Container) Component — one per list/detail view

```
src/app/features/<domain>/
  <domain>-list/
    <domain>-list.component.ts   ← inject service, manage loading/error/data signals
    <domain>-list.component.html ← @if (loading) skeleton; @if (error) error banner; table/grid
    <domain>-list.component.scss
  <domain>-detail/
    <domain>-detail.component.ts
    <domain>-detail.component.html
    <domain>-detail.component.scss
```

#### List component template pattern:

```html
@if (loading()) {
  <div class="skeleton-rows">
    @for (n of [1,2,3,4,5]; track n) {
      <div class="skeleton-row"></div>
    }
  </div>
} @else if (error()) {
  <div class="error-banner" role="alert">
    <span>{{ error() }}</span>
    <button (click)="reload()">Retry</button>
  </div>
} @else if (items().length === 0) {
  <div class="empty-state">
    <p>No {{ domainLabel }} found.</p>
    <button (click)="onCreate()">Create first {{ domainLabel }}</button>
  </div>
} @else {
  <table>
    <thead>...</thead>
    <tbody>
      @for (item of items(); track item.id) {
        <tr>...</tr>
      }
    </tbody>
  </table>
  <app-pagination [total]="total()" [page]="page()" (pageChange)="onPageChange($event)" />
}
```

### Presentational (Dumb) Components

Generate shared presentational components as needed:
- `app-status-badge` — colored badge for status enum values
- `app-pagination` — prev/next/page number controls
- `app-loading-skeleton` — animated placeholder rows
- `app-error-banner` — error message with retry button
- `app-empty-state` — empty state with CTA button

Place under `src/app/shared/components/`.

---

## Step 7 — CORS Handoff Note

Always write `.claude/cors-handoff.md` with backend instructions:

```markdown
# CORS Configuration Required

The Angular frontend requires the following CORS settings on the backend:

## Required Settings

| Setting | Value |
|---------|-------|
| allowedOrigins | http://localhost:4200 (dev), https://yourapp.com (prod) |
| allowedMethods | GET, POST, PUT, PATCH, DELETE, OPTIONS |
| allowedHeaders | Authorization, Content-Type, Accept |
| allowCredentials | false |
| maxAge | 3600 |

## Production Rule
The frontend origin MUST use https://. HTTP origins will be blocked by browsers
when the site is served over HTTPS (mixed content + CORS).

## NestJS example
```typescript
app.enableCors({
  origin: process.env.APP_CORS_ALLOWED_ORIGINS?.split(',') ?? ['http://localhost:4200'],
  methods: ['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
  allowedHeaders: ['Authorization','Content-Type','Accept'],
  credentials: false,
  maxAge: 3600,
});
```

## Spring Boot example
```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
  CorsConfiguration config = new CorsConfiguration();
  config.setAllowedOrigins(List.of("http://localhost:4200", "https://yourapp.com"));
  config.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
  config.setAllowedHeaders(List.of("Authorization","Content-Type","Accept"));
  config.setAllowCredentials(false);
  config.setMaxAge(3600L);
  UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
  source.registerCorsConfiguration("/**", config);
  return source;
}
```

## FastAPI example
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("APP_CORS_ALLOWED_ORIGINS", "http://localhost:4200").split(","),
    allow_methods=["GET","POST","PUT","PATCH","DELETE","OPTIONS"],
    allow_headers=["Authorization","Content-Type","Accept"],
    allow_credentials=False,
    max_age=3600,
)
```
```

---

## Step 8 — Final Report

```
API integration complete.

  Core infrastructure:
    ✓ src/environments/environment.ts
    ✓ src/environments/environment.prod.ts
    ✓ proxy.conf.json  (dev proxy: /api → http://localhost:8080)
    ✓ src/app/core/interceptors/auth.interceptor.ts
    ✓ src/app/core/interceptors/error.interceptor.ts
    ✓ src/app/core/services/auth.service.ts
    ✓ src/app/app.config.ts  (interceptors registered)

  Services (3):
    ✓ src/app/core/services/auth.service.ts
    ✓ src/app/core/services/orders.service.ts
    ✓ src/app/core/services/products.service.ts

  Models (11):
    ✓ src/app/core/models/auth.model.ts
    ✓ src/app/core/models/order.model.ts
    ✓ src/app/core/models/product.model.ts

  Feature components (6):
    ✓ src/app/features/orders/order-list/
    ✓ src/app/features/orders/order-detail/
    ✓ src/app/features/products/product-list/
    ✓ src/app/features/products/product-detail/
    ✓ src/app/features/auth/login/
    ✓ src/app/features/auth/register/

  Shared components (4):
    ✓ src/app/shared/components/status-badge/
    ✓ src/app/shared/components/pagination/
    ✓ src/app/shared/components/loading-skeleton/
    ✓ src/app/shared/components/error-banner/

  Handoff:
    ✓ .claude/cors-handoff.md  (share with backend team)

⚠  Action required:
  1. Set production API URL in src/environments/environment.prod.ts
  2. Share .claude/cors-handoff.md with backend team
  3. Add https://yourapp.com to backend APP_CORS_ALLOWED_ORIGINS
```

---

## Notes

- All HTTP calls use `withCredentials: false` matching `allowCredentials(false)` on the backend. Only change to `true` if switching to httpOnly cookie auth (requires backend change too).
- The dev proxy (`proxy.conf.json`) avoids CORS entirely during local development — the browser sees all requests as same-origin.
- In production, Angular is a static app served separately from the API — the backend MUST have the exact HTTPS frontend origin in `allowedOrigins`.
- If the API already has CORS configured but is missing `Authorization` in `allowedHeaders`, preflight OPTIONS requests will be blocked — confirm with backend team.
