# Agent: API Analyzer

Reads backend code or API contract files and produces a structured API spec that the Angular Generator agent uses to generate services, models, interceptors, and UI components.

---

## Responsibilities

1. Locate and read API contract sources (OpenAPI, source code, plain text)
2. Extract all endpoints with method, path, auth requirement, request shape, response shape
3. Group endpoints by domain/resource
4. Infer TypeScript interface shapes from JSON schemas or code DTOs
5. Identify authentication mechanism (JWT Bearer, API key, session cookie)
6. Write `.claude/api-spec.json` and `.claude/api-summary.md`

---

## Step 1 — Locate the API Source

Try in order until one succeeds:

### OpenAPI / Swagger (preferred — most complete)

Look for these files in the provided path:
```
openapi.yaml / openapi.json
swagger.yaml / swagger.json
api-spec.yaml / api-spec.json
docs/api.yaml
src/main/resources/api.yaml  (Spring Boot)
```

Use `Glob` with pattern `**/{openapi,swagger,api-spec,api}.{yaml,yml,json}`.

If a Swagger UI URL was provided, fetch the raw spec:
- Try `<base-url>/v3/api-docs` (OpenAPI 3.x)
- Try `<base-url>/v2/api-docs` (Swagger 2.x)
- Try `<base-url>/swagger.json`

### NestJS Backend

Look for files matching `**/*.controller.ts` and `**/*.dto.ts`.

For each controller file, extract:
- Class-level route prefix from `@Controller('prefix')`
- Method decorators: `@Get()`, `@Post()`, `@Put()`, `@Patch()`, `@Delete()`
- Path params: `@Param('id')`, route strings with `:id`
- Query params: `@Query('page')`
- Request body: `@Body() dto: CreateXDto` — then read the DTO file
- Response type from return type annotation or `@ApiResponse` decorator
- Auth guard: `@UseGuards(JwtAuthGuard)` → `requiresAuth: true`

### Spring Boot Backend

Look for files matching `**/*Controller.java` and `**/*Dto.java` / `**/*Request.java` / `**/*Response.java`.

Extract from annotations:
- `@RequestMapping("/base")`, `@GetMapping("/path")`, `@PostMapping`, etc.
- `@RequestBody`, `@PathVariable`, `@RequestParam`
- Return types from method signatures
- `@PreAuthorize` / `@Secured` → `requiresAuth: true`

### FastAPI Backend

Look for files matching `**/*.py` with route decorators.

Extract:
- `@app.get("/path")`, `@router.post("/path")`, etc.
- Function parameters: `id: int` (path param), `q: str = Query(...)`, `body: ModelClass = Body(...)`
- Pydantic models (class inheriting `BaseModel`) → TypeScript interface
- `Depends(get_current_user)` → `requiresAuth: true`

### Express / Node.js Backend

Look for files matching `**/routes/**/*.js`, `**/routes/**/*.ts`, `**/*router*.ts`.

Extract:
- `router.get('/path', ...)`, `app.post('/path', ...)`
- `req.params`, `req.query`, `req.body` usage → infer shape from usage or JSDoc
- `authenticateToken` / `verifyJWT` middleware → `requiresAuth: true`

### Plain Text Description

Parse for:
- HTTP method keywords: GET, POST, PUT, PATCH, DELETE
- URL patterns: `/api/resource`, `/v1/endpoint`
- Request/response body descriptions
- Ask user clarifying questions if types are ambiguous

---

## Step 2 — Extract API Contract

For each endpoint, build a contract entry:

```json
{
  "id": "get-orders",
  "method": "GET",
  "path": "/api/orders",
  "summary": "List all orders with pagination",
  "requiresAuth": true,
  "queryParams": [
    { "name": "page", "type": "number", "required": false, "default": 1 },
    { "name": "size", "type": "number", "required": false, "default": 20 }
  ],
  "pathParams": [],
  "requestBody": null,
  "response": {
    "type": "object",
    "schema": {
      "data": "Order[]",
      "total": "number",
      "page": "number",
      "size": "number"
    }
  },
  "errorResponses": [
    { "status": 401, "description": "Unauthorized" },
    { "status": 403, "description": "Forbidden" }
  ],
  "domain": "orders"
}
```

---

## Step 3 — Infer TypeScript Interfaces

For every unique response schema or request body, generate a TypeScript interface.

### Type Mapping Rules

| Backend type | TypeScript |
|--------------|-----------|
| `string`, `String`, `str` | `string` |
| `number`, `int`, `long`, `float`, `double`, `Integer`, `Long` | `number` |
| `boolean`, `Boolean`, `bool` | `boolean` |
| `array` / `List<T>` / `T[]` | `T[]` |
| `object` / `Map` / `dict` | `Record<string, unknown>` or named interface |
| `LocalDate`, `LocalDateTime`, `datetime`, `Date` | `string` (ISO 8601) |
| `UUID` | `string` |
| `null` / `Optional<T>` / `T | None` | `T \| null` |
| Enum | `'value1' \| 'value2' \| 'value3'` |

### Naming Rules

- Response schema for `Order` → interface `Order`
- Create request DTO → interface `CreateOrderDto`
- Update request DTO → interface `UpdateOrderDto`
- List response wrapper → interface `OrderListResponse { data: Order[]; total: number; page: number; size: number; }`

---

## Step 4 — Group by Domain

Group endpoints into logical service domains:

```json
{
  "domains": [
    {
      "name": "auth",
      "baseUrl": "/api/auth",
      "endpoints": ["post-login", "post-register", "post-logout", "post-refresh"],
      "service": "AuthService",
      "models": ["LoginDto", "RegisterDto", "AuthResponse", "User"]
    },
    {
      "name": "orders",
      "baseUrl": "/api/orders",
      "endpoints": ["get-orders", "get-order-by-id", "post-order", "patch-order", "delete-order"],
      "service": "OrdersService",
      "models": ["Order", "OrderItem", "CreateOrderDto", "UpdateOrderDto", "OrderListResponse"]
    }
  ]
}
```

---

## Step 5 — Auth Detection

Determine the auth mechanism:

| Signal | Auth type |
|--------|-----------|
| `Authorization: Bearer` in docs, `JwtAuthGuard`, `@PreAuthorize`, `Depends(get_current_user)` | JWT Bearer |
| `X-API-Key` header | API Key |
| `HttpOnly` cookie, `Set-Cookie` on login, `withCredentials: true` | Session cookie |
| No auth detected | None |

Set in spec:
```json
{
  "auth": {
    "type": "jwt-bearer",
    "tokenStorage": "localStorage",
    "withCredentials": false,
    "headerName": "Authorization",
    "headerFormat": "Bearer {token}"
  }
}
```

---

## Step 6 — CORS Analysis

Extract from backend code or config:

```json
{
  "cors": {
    "allowedOrigins": ["http://localhost:4200", "https://app.yourcompany.com"],
    "allowedMethods": ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    "allowedHeaders": ["Authorization", "Content-Type", "Accept"],
    "allowCredentials": false,
    "maxAge": 3600,
    "missingConfig": false,
    "warnings": []
  }
}
```

If CORS config is missing or incomplete, add a warning:
```json
"warnings": [
  "No CORS configuration found — backend team must add allowedOrigins for production domain",
  "Production origin must be https:// — http:// origins will be blocked by browsers"
]
```

---

## Output Files

### `.claude/api-spec.json`

```json
{
  "projectName": "string",
  "apiVersion": "1.0.0",
  "baseUrl": "https://api.example.com",
  "auth": { ... },
  "cors": { ... },
  "domains": [ ... ],
  "endpoints": [ ... ],
  "models": {
    "Order": { ... },
    "CreateOrderDto": { ... }
  }
}
```

### `.claude/api-summary.md`

```markdown
# API Spec: <Project Name>

## Auth
- Type: JWT Bearer
- Header: `Authorization: Bearer <token>`
- withCredentials: false
- Token storage: localStorage

## CORS
- allowCredentials: false (matches withCredentials: false on frontend)
- Allowed origins: http://localhost:4200, https://app.yourcompany.com
- ⚠ Warnings: (list any)

## Domains & Endpoints

### auth (4 endpoints)
- POST /api/auth/login
- POST /api/auth/register
- POST /api/auth/logout
- POST /api/auth/refresh

### orders (5 endpoints)
- GET    /api/orders
- GET    /api/orders/:id
- POST   /api/orders
- PATCH  /api/orders/:id
- DELETE /api/orders/:id

## Models (8 total)
Order, OrderItem, CreateOrderDto, UpdateOrderDto, OrderListResponse,
LoginDto, RegisterDto, AuthResponse

## Files to Generate
Core:
  src/app/core/interceptors/auth.interceptor.ts
  src/app/core/interceptors/error.interceptor.ts
  src/app/core/services/auth.service.ts
  src/app/core/services/orders.service.ts
  src/app/core/models/order.model.ts
  src/app/core/models/auth.model.ts
  src/environments/environment.ts
  src/environments/environment.prod.ts
  proxy.conf.json

Feature components:
  src/app/features/orders/order-list/
  src/app/features/orders/order-detail/
  src/app/features/auth/login/
```

---

## Error Handling

- If no API source files found: ask the user "Could not find an OpenAPI spec or backend controller files. Please provide: a file path, a Swagger URL, or paste the API description."
- If API spec is unparseable (malformed YAML/JSON): report the parse error with line number.
- If some endpoints have no response schema: mark `response.type: "unknown"` and generate `Observable<unknown>` in the service.
- If CORS config is absent from backend code: note it in warnings, generate the Angular proxy config as the dev workaround.
