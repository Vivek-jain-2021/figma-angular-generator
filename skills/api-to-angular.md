# Skill: Backend API to Angular

Reference guide for reading API contracts and generating Angular HTTP services, interceptors, environment config, and UI components.

---

## Environment Configuration

Angular projects use `src/environments/environment.ts` (dev) and `src/environments/environment.prod.ts` (prod).

```typescript
// src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api'   // ← set via Angular build --define or proxy
};
```

```typescript
// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.yourapp.com/api'  // MUST be https:// in cloud
};
```

Never hardcode API URLs in services. Always import from `environment`.

---

## JWT Auth Interceptor

Add an HTTP interceptor that attaches the Bearer token to every outgoing request.

```typescript
// src/app/core/interceptors/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.getToken();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` }
    });
  }
  return next(req);
};
```

Register in `app.config.ts`:

```typescript
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { authInterceptor } from './core/interceptors/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};
```

**Key rule:** `withCredentials` is NOT set (defaults to `false`) — this matches `allowCredentials(false)` on the backend.

---

## Token Storage

### localStorage (default — simpler)

```typescript
// src/app/core/services/auth.service.ts
import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly TOKEN_KEY = 'auth_token';
  private _isLoggedIn = signal(!!localStorage.getItem(this.TOKEN_KEY));
  isLoggedIn = this._isLoggedIn.asReadonly();

  setToken(token: string): void {
    localStorage.setItem(this.TOKEN_KEY, token);
    this._isLoggedIn.set(true);
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  clearToken(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    this._isLoggedIn.set(false);
  }
}
```

### httpOnly Cookie (high security — no JS token access)
When using httpOnly cookies: set `withCredentials: true` in HttpClient calls (and on every `HttpRequest`) AND the backend must set `allowCredentials(true)` and an explicit origin (wildcard `*` is banned with credentials).

---

## Error Handling Interceptor

```typescript
// src/app/core/interceptors/error.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const auth = inject(AuthService);

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        auth.clearToken();
        router.navigate(['/login']);
      }
      if (err.status === 403) {
        router.navigate(['/forbidden']);
      }
      const message = err.error?.message ?? err.message ?? 'Unknown error';
      return throwError(() => new Error(message));
    })
  );
};
```

---

## HTTP Service Pattern

One service file per domain entity/resource. Each service wraps `HttpClient` calls.

```typescript
// src/app/core/services/orders.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Order, OrderListResponse, CreateOrderDto } from '../models/order.model';

@Injectable({ providedIn: 'root' })
export class OrdersService {
  private http = inject(HttpClient);
  private base = `${environment.apiUrl}/orders`;

  list(page = 1, size = 20): Observable<OrderListResponse> {
    const params = new HttpParams().set('page', page).set('size', size);
    return this.http.get<OrderListResponse>(this.base, { params });
  }

  getById(id: string): Observable<Order> {
    return this.http.get<Order>(`${this.base}/${id}`);
  }

  create(dto: CreateOrderDto): Observable<Order> {
    return this.http.post<Order>(this.base, dto);
  }

  update(id: string, dto: Partial<CreateOrderDto>): Observable<Order> {
    return this.http.patch<Order>(`${this.base}/${id}`, dto);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`);
  }
}
```

---

## TypeScript Model / Interface Generation

Map API response types to TypeScript interfaces. Use `| null` for nullable fields.

```typescript
// src/app/core/models/order.model.ts
export interface Order {
  id: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  customerId: string;
  items: OrderItem[];
  total: number;
  currency: string;
  createdAt: string;    // ISO 8601 date string
  updatedAt: string;
}

export interface OrderItem {
  productId: string;
  name: string;
  quantity: number;
  unitPrice: number;
}

export interface OrderListResponse {
  data: Order[];
  total: number;
  page: number;
  size: number;
}

export interface CreateOrderDto {
  customerId: string;
  items: Pick<OrderItem, 'productId' | 'quantity'>[];
}
```

---

## Angular Component with Service Injection

Components use `inject()` and Angular signals. Use `toSignal()` for RxJS→signal bridges.

```typescript
// src/app/features/orders/order-list/order-list.component.ts
import { Component, inject, signal, computed } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { OrdersService } from '../../../core/services/orders.service';
import { Order } from '../../../core/models/order.model';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-order-list',
  standalone: true,
  imports: [],
  templateUrl: './order-list.component.html',
  styleUrl: './order-list.component.scss'
})
export class OrderListComponent {
  private ordersService = inject(OrdersService);

  loading = signal(false);
  error = signal<string | null>(null);
  orders = signal<Order[]>([]);
  total = signal(0);
  page = signal(1);

  ngOnInit(): void {
    this.loadOrders();
  }

  loadOrders(): void {
    this.loading.set(true);
    this.error.set(null);
    this.ordersService.list(this.page()).subscribe({
      next: (res) => {
        this.orders.set(res.data);
        this.total.set(res.total);
        this.loading.set(false);
      },
      error: (err: Error) => {
        this.error.set(err.message);
        this.loading.set(false);
      }
    });
  }
}
```

---

## CORS — Frontend Responsibilities

| Concern | Angular action |
|---------|----------------|
| JWT token | `Authorization: Bearer <token>` via `authInterceptor` on every request |
| withCredentials | `false` — do NOT set on `HttpClient` calls (matches backend `allowCredentials(false)`) |
| Backend URL | Always read from `environment.apiUrl` — never hardcoded |
| HTTPS in production | `environment.prod.ts` `apiUrl` must start with `https://` |
| Token storage | `localStorage` (default); switch to `withCredentials: true` + httpOnly cookie for high-security apps (requires backend change too) |

### Dev proxy (avoids CORS during local development)

Create `proxy.conf.json` in project root:

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

Configure in `angular.json` under `serve.options`:

```json
"proxyConfig": "proxy.conf.json"
```

Then `environment.ts` can use `apiUrl: '/api'` (same-origin in dev, no CORS needed).

---

## CORS — Backend Checklist (for handoff)

When handing requirements to the backend team, include:

```
CORS configuration required:
  allowedOrigins:   https://yourapp.com (exact HTTPS origin, not wildcard in prod)
  allowedMethods:   GET, POST, PUT, PATCH, DELETE, OPTIONS
  allowedHeaders:   Authorization, Content-Type, Accept
  allowCredentials: false  (matches Angular withCredentials: false)
  maxAge:           3600   (preflight cache in seconds)

Local dev origins to whitelist:
  http://localhost:4200
  http://localhost:4300
```

---

## API Input Sources Supported

| Source | How to read |
|--------|-------------|
| OpenAPI / Swagger YAML | `Read` the file; parse `paths`, `components/schemas` |
| OpenAPI / Swagger JSON | `Read` the file; same structure |
| Swagger UI URL | `WebFetch` `<url>/v3/api-docs` or `/swagger.json` |
| Backend source code (NestJS) | Read controller files; extract decorators (`@Get`, `@Post`, `@Body`, `@Param`) and DTO classes |
| Backend source code (Spring Boot) | Read `@RestController` files; extract `@RequestMapping`, `@GetMapping`, `@PostMapping`, DTO/entity classes |
| Backend source code (FastAPI) | Read route files; extract `@app.get/post/put/delete`, Pydantic models |
| Backend source code (Express) | Read router files; extract `router.get/post/put/delete` and req.body shapes |
| Plain text description | Parse manually; ask clarifying questions for missing types |

---

## File Layout Convention

```
src/app/
  core/
    interceptors/
      auth.interceptor.ts       ← JWT Bearer + withCredentials:false
      error.interceptor.ts      ← 401→logout, 403→forbidden
    services/
      auth.service.ts           ← token storage + isLoggedIn signal
      <entity>.service.ts       ← one file per API resource
    models/
      <entity>.model.ts         ← TypeScript interfaces per entity
  environments/
    environment.ts              ← dev: apiUrl, flags
    environment.prod.ts         ← prod: apiUrl (https://), flags
  features/
    <feature>/
      <feature-name>.component.ts
      <feature-name>.component.html
      <feature-name>.component.scss
```
