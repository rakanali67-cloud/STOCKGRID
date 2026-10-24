# StockGrid — Complete System Architecture

> Version 1.1 | Updated 2026-07-31

---

## Table of Contents
1. [System Overview](#1-system-overview)
2. [Frontend Architecture](#2-frontend-architecture)
3. [Backend Architecture](#3-backend-architecture)
4. [Database Architecture](#4-database-architecture)
5. [Authentication Architecture](#5-authentication-architecture)
6. [File Storage Architecture](#6-file-storage-architecture)
7. [Notification Architecture](#7-notification-architecture)
8. [AI / Forecast Architecture](#8-ai--forecast-architecture)
9. [Reporting Architecture](#9-reporting-architecture)
10. [API Gateway Design](#10-api-gateway-design)
11. [Caching Strategy](#11-caching-strategy)
12. [Queue System](#12-queue-system)
13. [Logging & Monitoring](#13-logging--monitoring)
14. [Backup Strategy](#14-backup-strategy)

---

## 1. System Overview

```mermaid
graph TB
    subgraph Client["Client Layer"]
        B[Browser<br/>Chrome / Edge / Safari]
    end

    subgraph Edge["Edge Layer (Future)"]
        CDN[CDN<br/>Static Assets]
        LB[Load Balancer<br/>Nginx / Caddy]
    end

    subgraph App["Application Layer"]
        FLASK[Flask Application<br/>Python 3.11+]
        BLUEPRINTS[32 Blueprints<br/>auth · products · sales · purchase<br/>invoices · bills · payments · …]
    end

    subgraph Data["Data Layer"]
        MYSQL[(MySQL 8.x<br/>Primary DB)]
        FS[Local File System<br/>static/uploads/]
    end

    subgraph External["External Services"]
        SMTP[SMTP Server<br/>Email Alerts]
        AI[AI Forecast<br/>Internal Engine]
    end

    B --> LB
    LB --> FLASK
    FLASK --> BLUEPRINTS
    BLUEPRINTS --> MYSQL
    BLUEPRINTS --> FS
    BLUEPRINTS --> SMTP
    BLUEPRINTS --> AI
    CDN -.->|static files| B
```

---

## 2. Frontend Architecture

```mermaid
graph TB
    subgraph Templates["Jinja2 Template System"]
        BASE[base.html<br/>Shell · Sidebar · Topbar · Theme]
        AUTH[Auth Templates<br/>login · forgot_password<br/>reset_password · accept_invite]
        DATA[Data Page Templates<br/>products · sales · purchase<br/>movements · dashboard · …]
        MODALS[Modal Components<br/>Inline in each template<br/>open/close via JS]
    end

    subgraph Assets["Static Assets"]
        CSS[CSS Custom Properties<br/>--surface · --ink · --line<br/>Light / Dark via body.sg-dark]
        JS[Vanilla JavaScript<br/>No build step · No npm]
        CHARTJS[Chart.js 4.4.1<br/>via CDN]
        CANVAS[Canvas 2D API<br/>Isometric cube animations]
        UPLOADS[Product Images<br/>static/uploads/]
    end

    subgraph State["Client State"]
        LOCALSTORAGE[localStorage<br/>sg-theme · preferences]
        SESSION[Flask Session<br/>user_id · username · csrf_token]
    end

    BASE --> AUTH
    BASE --> DATA
    BASE --> MODALS
    CSS --> BASE
    JS --> BASE
    CHARTJS --> DATA
    CANVAS --> AUTH
    LOCALSTORAGE --> JS
    SESSION --> BASE
```

### Key Frontend Patterns

| Pattern | Implementation |
|---------|---------------|
| Dark Mode | `body.sg-dark` CSS class, toggled via JS, persisted to `localStorage` |
| CSRF | Token injected into all POST forms via `base.html` auto-fill script |
| Loading Screen | Intercepts `<a>` navigation, shows animated cube overlay |
| Responsive | CSS Grid + Flexbox, sidebar collapses on mobile |
| Charts | Chart.js with gradient fills, 30/60/90-day trend windows |

---

## 3. Backend Architecture

```mermaid
graph TB
    subgraph Request["Request Pipeline"]
        REQ[HTTP Request]
        ENSURE_CSRF[before_request:<br/>_ensure_csrf]
        CHECK_CSRF[before_request:<br/>_check_csrf]
        LOGIN_REQUIRED[Decorator:<br/>@login_required]
        ROUTE[Blueprint Route Handler]
        SEC_HEADERS[after_request:<br/>_security_headers]
        RESP[HTTP Response]
    end

    subgraph Blueprints["Registered Blueprints (21)"]
        AUTH[auth · auth_ext]
        CORE[products · categories<br/>suppliers · movements<br/>adjustments · locations]
        ORDERS[purchase · sales]
        ANALYTICS[dashboard · reports<br/>forecast · search]
        SETTINGS[settingshub · org<br/>currencies · payment_terms<br/>users · roles · pages]
        AUTO[reorder_rules]
    end

    subgraph Shared["Shared Utilities"]
        DB[db.py<br/>MySQL Connection Pool<br/>pool_size=32]
        HELPERS[helpers.py<br/>log_history · stock_status<br/>get_thresholds]
        AUDIT[audit_utils.py<br/>audit() → audit_logs table]
        EMAIL[email_utils.py<br/>send_email · maybe_send_alert]
        PDF[pdf_utils.py<br/>fpdf2 · branded PDFs]
        REORDER[reorder_rules.py<br/>check_and_fire]
    end

    REQ --> ENSURE_CSRF --> CHECK_CSRF --> LOGIN_REQUIRED --> ROUTE
    ROUTE --> SEC_HEADERS --> RESP
    ROUTE --> AUTH
    ROUTE --> CORE
    ROUTE --> ORDERS
    ROUTE --> ANALYTICS
    ROUTE --> SETTINGS
    ROUTE --> AUTO
    AUTH & CORE & ORDERS & ANALYTICS & SETTINGS & AUTO --> DB
    CORE & ORDERS --> AUDIT
    CORE & ORDERS --> EMAIL
    ORDERS --> PDF
    CORE --> REORDER
```

### Blueprint Responsibility Map

| Blueprint | Endpoints | Key Features |
|-----------|-----------|-------------|
| `auth` | `/login` `/logout` `/register` | Session management, lockout integration |
| `auth_ext` | `/forgot-password` `/reset-password` `/invite` `/accept-invite` `/verify-email` | Token-based flows, account lockout, invitations |
| `products` | `/products` `/products/add` `/products/<id>` | Soft-delete, barcode, cost_price, CSV import/export |
| `purchase` | `/purchase-orders` `/receive` | Partial receipts per line, auto cost from unit_cost |
| `sales` | `/sales` `/confirm` `/ship` `/cancel` | Stock reservations, reorder triggers on ship |
| `reorder_rules` | `/reorder-rules` | CRUD + `check_and_fire()` public helper |
| `dashboard` | `/` | 6 KPI cards, 5 Chart.js charts, retrospective value trend |
| `reports` | `/reports` | CSV exports, summary tables |
| `forecast` | `/forecast` | AI demand forecast, EOQ, lead-time awareness |

---

## 4. Database Architecture

```mermaid
erDiagram
    users {
        int user_id PK
        varchar username
        varchar password
        varchar email
        varchar role
        tinyint is_active
        tinyint email_verified
        datetime email_verified_at
        datetime deleted_at
    }
    products {
        int product_id PK
        varchar product_name
        varchar sku
        varchar barcode
        int quantity
        decimal selling_price
        decimal cost_price
        int min_stock_level
        int max_stock_level
        enum product_status
        int category_id FK
        int supplier_id FK
        varchar image_url
        datetime deleted_at
    }
    categories {
        int category_id PK
        varchar category_name
        datetime deleted_at
    }
    suppliers {
        int supplier_id PK
        varchar name
        varchar email
        int lead_time_days
        datetime deleted_at
    }
    purchase_orders {
        int po_id PK
        int supplier_id FK
        int user_id FK
        enum status
        decimal total_amount
        datetime received_at
        datetime deleted_at
    }
    po_items {
        int item_id PK
        int po_id FK
        int product_id FK
        int quantity
        decimal unit_cost
        int received_qty
    }
    sales_orders {
        int so_id PK
        int customer_id FK
        int created_by FK
        enum status
        datetime shipped_at
        datetime deleted_at
    }
    sale_items {
        int item_id PK
        int so_id FK
        int product_id FK
        int quantity
        decimal unit_price
    }
    stock_movements {
        int id PK
        int product_id FK
        int user_id FK
        enum direction
        int quantity
        varchar reason
        datetime created_at
    }
    stock_reservations {
        int reservation_id PK
        int product_id FK
        int so_id FK
        int quantity
        datetime reserved_at
        datetime released_at
        enum release_reason
    }
    reorder_rules {
        int rule_id PK
        int product_id FK
        int supplier_id FK
        int trigger_qty
        int reorder_qty
        tinyint auto_create_po
        int cooldown_days
        datetime last_triggered_at
    }
    audit_logs {
        bigint log_id PK
        int user_id FK
        varchar username
        enum action
        varchar entity_type
        int entity_id
        varchar entity_label
        json old_value
        json new_value
        varchar ip_address
        datetime created_at
    }
    login_attempts {
        int id PK
        varchar identifier
        varchar ip_address
        tinyint success
        datetime attempted_at
    }
    password_reset_tokens {
        int token_id PK
        int user_id FK
        varchar token_hash
        datetime expires_at
        datetime used_at
    }

    products ||--o{ po_items : "ordered in"
    products ||--o{ sale_items : "sold in"
    products ||--o{ stock_movements : "tracks"
    products ||--o{ stock_reservations : "reserved by"
    products ||--o{ reorder_rules : "watched by"
    products }o--|| categories : "belongs to"
    products }o--|| suppliers : "sourced from"
    purchase_orders ||--|{ po_items : "contains"
    purchase_orders }o--|| suppliers : "from"
    sales_orders ||--|{ sale_items : "contains"
    sales_orders }o--|| users : "created by"
    stock_reservations }o--|| sales_orders : "for"
    users ||--o{ audit_logs : "generates"
    users ||--o{ login_attempts : "tracked by"
    users ||--o{ password_reset_tokens : "requests"
```

### Key Data Patterns

| Pattern | Implementation |
|---------|---------------|
| Soft Delete | `deleted_at DATETIME NULL` on products, categories, suppliers, customers, orders, users |
| Audit Trail | Dual: `product_history` (stock changes) + `audit_logs` (all entity changes) |
| Stock Reservations | Created on SO CONFIRM, released on SHIP or CANCEL |
| Partial PO Receipts | `po_items.received_qty` tracks per-line receipts; status = PARTIAL or RECEIVED |
| Token Security | Raw token in URL, SHA-256 hash stored in DB — token never touches DB |

---

## 5. Authentication Architecture

```mermaid
sequenceDiagram
    participant U as User Browser
    participant F as Flask
    participant DB as MySQL

    Note over U,DB: Normal Login Flow
    U->>F: POST /login (username, password, _csrf)
    F->>F: Validate CSRF token
    F->>DB: SELECT COUNT failed attempts (15min window)
    alt >= 5 failures
        F-->>U: 403 Account locked (N mins remaining)
    else
        F->>DB: SELECT user WHERE username = ? AND is_active = 1
        alt Password valid
            F->>DB: INSERT login_attempts (success=1)
            F->>DB: INSERT audit_logs (LOGIN)
            F->>U: session[user_id, username, csrf_token]
            F-->>U: 302 → /dashboard
        else Password invalid
            F->>DB: INSERT login_attempts (success=0)
            F-->>U: Flash error, re-render login
        end
    end

    Note over U,DB: Password Reset Flow
    U->>F: POST /forgot-password (email)
    F->>DB: SELECT user WHERE email = ?
    F->>DB: INSERT password_reset_tokens (SHA256 hash, 2hr expiry)
    F->>U: Email with raw token URL (never stored)
    U->>F: GET /reset-password?token=xxx
    F->>DB: SELECT WHERE token_hash = SHA256(xxx) AND used_at IS NULL AND expires_at > NOW()
    U->>F: POST /reset-password (password, password2, token)
    F->>DB: UPDATE users SET password = bcrypt(new_pw)
    F->>DB: UPDATE token SET used_at = NOW()
```

### Security Controls

| Control | Implementation |
|---------|---------------|
| Password Hashing | Werkzeug `generate_password_hash` (bcrypt/pbkdf2) |
| Account Lockout | 5 failures in 15-min window → 30-min lockout |
| CSRF Protection | `secrets.token_hex(32)` per session, `compare_digest` validation |
| Token Security | `secrets.token_urlsafe(48)` raw, SHA-256 hash stored — token never in DB |
| Security Headers | `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy` |
| Session | Flask signed cookie, `secret_key` from env var |
| Soft Delete | Users set `deleted_at` — no permanent data destruction |

---

## 6. File Storage Architecture

```mermaid
graph LR
    subgraph Upload["Upload Flow"]
        FORM[HTML Form<br/>enctype=multipart/form-data]
        ROUTE[products.add / products.update]
        VALIDATE[Validate extension<br/>png · jpg · jpeg · gif · webp]
        SECURE[secure_filename<br/>+ timestamp prefix]
        SAVE[Save to<br/>static/uploads/]
        DB[(Store URL path<br/>products.image_url)]
    end

    subgraph Serve["Serve Flow"]
        TEMPLATE[product_detail.html<br/>products.html]
        STATIC[Flask static route<br/>/static/uploads/filename]
        BROWSER[Browser Cache]
    end

    FORM --> ROUTE --> VALIDATE --> SECURE --> SAVE --> DB
    DB --> TEMPLATE --> STATIC --> BROWSER
```

### Current Limitations & V2 Plan

| Concern | Current State | V2 Plan |
|---------|--------------|---------|
| Storage | Local `static/uploads/` | Object Storage (S3 / Cloudflare R2) |
| CDN | None | Serve images via CDN edge |
| Max file size | Flask default 16MB | Enforce 5MB limit + image compression |
| Multi-tenant | Single directory | Org-scoped subdirectories |

---

## 7. Notification Architecture

```mermaid
graph TB
    subgraph Triggers["Notification Triggers"]
        OUT[Stock OUT movement<br/>movements.py]
        ADJ[Stock Adjustment decrease<br/>adjustments.py]
        SHIP[Sales Order SHIP<br/>sales.py]
        RESET[Password Reset Request<br/>auth_ext.py]
        INVITE[User Invitation<br/>auth_ext.py]
        VERIFY[Email Verification<br/>auth_ext.py]
    end

    subgraph Logic["Alert Logic"]
        LOWSTOCK[maybe_send_alert<br/>Threshold crossing only<br/>old_qty > threshold >= new_qty]
        REORDER[check_and_fire<br/>Trigger qty + cooldown guard<br/>→ auto PO or alert email]
        TRANSACT[Transactional email<br/>password reset · invite · verify]
    end

    subgraph Delivery["Email Delivery"]
        SMTP[smtplib<br/>STARTTLS / SSL]
        CFG[app_settings table<br/>smtp_host · smtp_port<br/>smtp_user · smtp_pass]
        HTML[Branded HTML emails<br/>Blue gradient header<br/>Blue CTA buttons]
    end

    OUT --> LOWSTOCK --> SMTP
    ADJ --> LOWSTOCK
    SHIP --> LOWSTOCK
    OUT --> REORDER --> SMTP
    ADJ --> REORDER
    SHIP --> REORDER
    RESET & INVITE & VERIFY --> TRANSACT --> SMTP
    CFG --> SMTP
    HTML --> SMTP
```

### Email Types

| Type | Trigger | Template |
|------|---------|----------|
| Low Stock Alert | Downward threshold crossing | `_low_stock_html()` in email_utils.py |
| Reorder Alert | `check_and_fire()` without auto PO | `_send_reorder_alert()` in reorder_rules.py |
| Password Reset | `/forgot-password` POST | `_send_reset_email()` in auth_ext.py |
| Email Verification | User registration | `send_verification_email()` in auth_ext.py |
| Invitation | Admin invites user | `invite_user()` in auth_ext.py |

---

## 8. AI / Forecast Architecture

```mermaid
graph TB
    subgraph Input["Data Inputs"]
        HIST[stock_movements<br/>90-day IN/OUT history]
        CURR[products.quantity<br/>Current stock]
        LEAD[suppliers.lead_time_days<br/>Replenishment time]
        META[products.min_stock_level<br/>Safety stock]
    end

    subgraph Engine["Forecast Engine (forecast.py)"]
        DAILY[Compute daily OUT rate<br/>= total_out / days_with_data]
        DFS[Days-to-stockout<br/>= current_qty / daily_rate]
        REORDER_PT[Reorder Point<br/>= daily_rate × lead_time + safety_stock]
        EOQ[EOQ calculation<br/>= sqrt(2 × demand × ordering_cost / holding_cost)]
        PRIORITY[Risk Priority<br/>critical · warning · healthy]
    end

    subgraph Output["Forecast Outputs"]
        TABLE[Forecast Table<br/>per-product risk + ETA]
        ALERTS[Urgent Alerts<br/>DTS < lead_time]
        RECS[Reorder Recommendations<br/>EOQ + suggested PO]
    end

    HIST & CURR & LEAD & META --> DAILY
    DAILY --> DFS & REORDER_PT & EOQ
    DFS & REORDER_PT & EOQ --> PRIORITY
    PRIORITY --> TABLE & ALERTS & RECS
```

### V2 AI Roadmap

| Feature | Technology | Phase |
|---------|-----------|-------|
| Demand forecasting | ARIMA / Prophet | V2 |
| Anomaly detection | Isolation Forest | V2 |
| Smart replenishment | Reinforcement learning | V3 |
| Natural language queries | Claude API (claude-sonnet-4-6) | V3 |
| Computer vision SKU scan | Claude Vision API | V3 |

---

## 9. Reporting Architecture

```mermaid
graph LR
    subgraph Sources["Data Sources"]
        PO[purchase_orders<br/>po_items]
        SO[sales_orders<br/>sale_items]
        PROD[products<br/>stock_movements]
        AUDIT[audit_logs]
    end

    subgraph Reports["Report Types"]
        DASH[Dashboard KPIs<br/>Real-time aggregates]
        CSV[CSV Exports<br/>products · movements<br/>purchase · sales]
        PDF[PDF Documents<br/>PO · SO branded PDFs]
        CHARTS[Chart.js Charts<br/>Value Trend · Movement<br/>Category · Stock Levels]
    end

    subgraph Delivery["Delivery"]
        SCREEN[In-browser tables]
        DOWNLOAD[File download<br/>Content-Disposition header]
        PRINT[PDF inline viewer<br/>Print-ready]
    end

    PO & SO & PROD --> DASH & CSV & PDF & CHARTS
    AUDIT --> DASH
    DASH --> SCREEN
    CSV & PDF --> DOWNLOAD
    PDF --> PRINT
```

### PDF Generation (fpdf2)

```
_SGDoc(FPDF)
├── header()  — Blue gradient bar + org name + logo area
├── footer()  — Page N of M + generated timestamp
├── make_purchase_order_pdf(po, items, total, currency_symbol, org_name)
└── make_sales_order_pdf(so, items, total, currency_symbol, org_name)
```

---

## 10. API Gateway Design

```mermaid
graph TB
    subgraph Current["Current Architecture (V1)"]
        BROWSER[Browser]
        FLASK_WEB[Flask<br/>HTML / Form-based]
        MYSQL_V1[(MySQL)]
    end

    subgraph V2["V2 REST API (Planned)"]
        CLIENT[Web / Mobile / Integrations]
        GATEWAY[API Gateway<br/>Rate limiting · Auth header]
        REST[REST API Blueprint<br/>/api/v1/...]
        JWT[JWT Authentication<br/>Bearer tokens]
        MYSQL_V2[(MySQL)]
    end

    subgraph Endpoints["Planned REST Endpoints"]
        PROD_API[GET /api/v1/products<br/>POST /api/v1/products<br/>PATCH /api/v1/products/:id]
        SO_API[GET /api/v1/sales-orders<br/>POST /api/v1/sales-orders<br/>POST /api/v1/sales-orders/:id/ship]
        PO_API[GET /api/v1/purchase-orders<br/>POST /api/v1/purchase-orders/receive]
        STOCK_API[GET /api/v1/stock/:product_id<br/>POST /api/v1/movements]
        WEBHOOK_API[POST /api/v1/webhooks/register<br/>Low-stock · PO-received events]
    end

    BROWSER --> FLASK_WEB --> MYSQL_V1
    CLIENT --> GATEWAY --> REST --> JWT --> MYSQL_V2
    REST --> PROD_API & SO_API & PO_API & STOCK_API & WEBHOOK_API
```

---

## 11. Caching Strategy

```mermaid
graph TB
    subgraph Current["V1 — No Cache Layer (Request-scoped only)"]
        REQ1[Request]
        PROC1[Flask context_processor<br/>inject_globals — runs ONCE per request]
        DB1[(MySQL — every request hits DB)]
    end

    subgraph V2["V2 — Application-level Cache"]
        REQ2[Request]
        CHECK[Check in-memory cache<br/>Flask-Caching or dict with TTL]
        HIT{Cache hit?}
        DB2[(MySQL)]
        STORE[Store result + TTL]
    end

    subgraph Cacheable["Cacheable Data (TTL)"]
        BASE_CURRENCY[Base currency — 5 min]
        THRESHOLDS[Alert thresholds — 5 min]
        CATEGORY_LIST[Category list — 2 min]
        DASHBOARD_KPI[Dashboard KPIs — 30 sec]
        FORECAST[Forecast results — 10 min]
    end

    subgraph V3["V3 — Redis Cache"]
        REDIS[(Redis)]
        INVALIDATE[Event-driven invalidation<br/>on stock change · PO receive]
    end

    REQ1 --> PROC1 --> DB1
    REQ2 --> CHECK --> HIT
    HIT -->|Yes| STORE
    HIT -->|No| DB2 --> STORE
    BASE_CURRENCY & THRESHOLDS & CATEGORY_LIST & DASHBOARD_KPI & FORECAST --> V2
    V3 -.->|Future| REDIS & INVALIDATE
```

---

## 12. Queue System

```mermaid
graph TB
    subgraph Current["V1 — Synchronous (In-request)"]
        ROUTE[Route Handler]
        EMAIL_SYNC[send_email — blocks request<br/>~2s on slow SMTP]
        PDF_SYNC[make_*_pdf — blocks request<br/>~100ms]
        AUDIT_SYNC[audit() — always async-safe<br/>silently swallows errors]
    end

    subgraph V2["V2 — Task Queue (Celery + Redis)"]
        ROUTE2[Route Handler]
        ENQUEUE[Enqueue task<br/>returns immediately]
        WORKER[Celery Worker<br/>separate process]
        REDIS_Q[(Redis Queue)]
        EMAIL_ASYNC[Email delivery]
        PDF_ASYNC[PDF generation + S3 upload]
        REPORT_ASYNC[Heavy report generation]
        RETRY[Retry on failure<br/>3 attempts, exponential backoff]
    end

    ROUTE --> EMAIL_SYNC & PDF_SYNC & AUDIT_SYNC
    ROUTE2 --> ENQUEUE --> REDIS_Q --> WORKER
    WORKER --> EMAIL_ASYNC & PDF_ASYNC & REPORT_ASYNC & RETRY
```

### Immediate V1 Async Win

Email sending in V1 blocks the HTTP response for up to ~2 seconds on slow SMTP. Quick fix: run `send_email()` in a `threading.Thread(daemon=True)` — requires no new dependencies and eliminates the blocking latency.

---

## 13. Logging & Monitoring

```mermaid
graph TB
    subgraph AppLogs["Application Logs (V1)"]
        FLASK_LOG[Flask dev server stdout<br/>Request log]
        AUDIT_DB[audit_logs table<br/>Business event log]
        LOGIN_DB[login_attempts table<br/>Security log]
    end

    subgraph V2Logs["V2 — Structured Logging"]
        STRUCTLOG[structlog / loguru<br/>JSON structured output]
        LEVELS[DEBUG · INFO · WARNING · ERROR · CRITICAL]
        ROTATION[File rotation<br/>10MB max · 30-day retention]
        CONTEXT[Request context<br/>user_id · ip · endpoint · duration]
    end

    subgraph Monitoring["V2 — Monitoring Stack"]
        HEALTHCHECK[GET /health<br/>DB ping · uptime · version]
        METRICS[Prometheus metrics<br/>request_count · latency_p99<br/>db_pool_used · error_rate]
        GRAFANA[Grafana Dashboard<br/>Request volume · Error rate<br/>Stock alert frequency]
        ALERTS_MON[PagerDuty / Slack alerts<br/>Error rate > 1% · p99 > 2s]
    end

    subgraph ErrorTracking["V2 — Error Tracking"]
        SENTRY[Sentry<br/>Exception capture + stack traces]
        DSN[DSN from env var<br/>SENTRY_DSN]
    end

    FLASK_LOG & AUDIT_DB & LOGIN_DB --> AppLogs
    STRUCTLOG --> LEVELS --> ROTATION
    CONTEXT --> STRUCTLOG
    HEALTHCHECK & METRICS --> Monitoring
    METRICS --> GRAFANA --> ALERTS_MON
    SENTRY --> DSN
```

### Audit Log Schema

```
audit_logs
├── log_id      BIGINT AUTO_INCREMENT
├── user_id     INT (nullable — system actions)
├── username    VARCHAR(150)
├── action      ENUM(CREATE, UPDATE, DELETE, VIEW, LOGIN, LOGOUT,
│               EXPORT, IMPORT, APPROVE, REJECT, INVITE)
├── entity_type VARCHAR(100)  — "product", "sales_order", "user", …
├── entity_id   INT
├── entity_label VARCHAR(255)  — human-readable name
├── old_value   JSON           — before state
├── new_value   JSON           — after state
├── ip_address  VARCHAR(45)
├── user_agent  VARCHAR(500)
└── created_at  DATETIME
```

---

## 14. Backup Strategy

```mermaid
graph TB
    subgraph Current["V1 — Manual Backup"]
        MANUAL[mysqldump<br/>Run manually by admin]
        FILES[Copy static/uploads/<br/>manually]
    end

    subgraph V2["V2 — Automated Backup"]
        subgraph DB_BACKUP["Database Backup"]
            DAILY_DUMP[Daily mysqldump<br/>Cron: 02:00 UTC]
            COMPRESS[gzip compression<br/>~90% size reduction]
            ENCRYPT[AES-256 encryption<br/>before upload]
            OFFSITE[Upload to S3 / Backblaze B2<br/>30-day retention]
            VERIFY[Weekly restore test<br/>Cron: Sunday 03:00]
        end

        subgraph FILE_BACKUP["File Backup"]
            RSYNC[rclone sync<br/>static/uploads/ → S3]
            VERSIONED[S3 versioning enabled<br/>30-day object versions]
        end

        subgraph PITR["Point-in-Time Recovery"]
            BINLOG[MySQL binary logging<br/>binlog_format = ROW]
            BINLOG_SHIP[Ship binlogs to S3<br/>every 15 minutes]
            PITR_WINDOW[Recovery window<br/>up to 7 days PITR]
        end
    end

    subgraph RTO["Recovery Objectives"]
        RPO[RPO = 15 minutes<br/>Max data loss]
        RTO_VAL[RTO = 1 hour<br/>Max downtime]
    end

    MANUAL & FILES --> Current
    DAILY_DUMP --> COMPRESS --> ENCRYPT --> OFFSITE --> VERIFY
    RSYNC --> VERSIONED
    BINLOG --> BINLOG_SHIP --> PITR_WINDOW
    PITR_WINDOW --> RPO
    VERIFY --> RTO_VAL
```

### Backup Runbook (V1 Manual)

```bash
# 1. Dump database
mysqldump -u root -p stockgrid > stockgrid_$(date +%Y%m%d).sql
gzip stockgrid_$(date +%Y%m%d).sql

# 2. Backup uploaded files
tar -czf uploads_$(date +%Y%m%d).tar.gz static/uploads/

# 3. Store offsite (copy to external drive or cloud storage)
# Files: stockgrid_YYYYMMDD.sql.gz + uploads_YYYYMMDD.tar.gz
```

---

## Summary: V1 → V5 Capability Map

| Capability | V1 (Now) | V2 | V3 | V4 | V5 |
|------------|----------|----|----|----|----|
| Auth | Session + lockout + reset | JWT API tokens | SSO (Google/Azure AD) | MFA (TOTP) | Biometric |
| Storage | Local disk | S3/R2 object store | CDN delivery | Multi-region | Edge caching |
| Notifications | SMTP sync | Async queue | Push notifications | Webhooks | Real-time WS |
| AI | Rule-based forecast | Prophet/ARIMA | Claude API NL queries | RL replenishment | Autonomous PO |
| Queue | In-process sync | Celery + Redis | Priority queues | Dead letter queue | Stream processing |
| Cache | None | In-memory TTL | Redis cache | Distributed cache | Edge cache |
| Monitoring | stdout + DB | structlog + Sentry | Prometheus + Grafana | APM (Datadog) | Full observability |
| Backup | Manual | Nightly automated | PITR (15min RPO) | Multi-region replication | Active-active HA |
| API | HTML forms only | REST v1 | GraphQL | WebSocket events | Mobile SDK |

---

*StockGrid Architecture Document — maintained in `/ARCHITECTURE.md`*
