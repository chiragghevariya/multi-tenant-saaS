# Multi-Tenant SaaS Platform (Single Database Architecture)

A full, production-style multi-tenant SaaS demo: a **Laravel** API, a **Vue 3** super-admin
dashboard, and a **Flutter** mobile app — sharing one database, with Stripe subscription
billing, role-based access control, and per-plan feature gates.

## Architecture

> **Uses a single database with a `tenant_id` column for scoping.** All tenants share one
> database — simpler to deploy, easier to maintain, and it scales well for most SaaS use
> cases. Every tenant-owned table carries a `tenant_id`, queries are automatically scoped
> to the current tenant, and each request identifies its tenant with an **`X-Tenant`** HTTP
> header. The web super-admin reads across all tenants from the same database.

```
                 ┌─────────────────────────┐
  X-Tenant: ───► │   Laravel API (one DB)  │ ◄─── Super admin (no X-Tenant, sees all)
  alphacorp      │  tenants / tenant_users │
                 │  projects / tasks /...  │
                 └───────────┬─────────────┘
        ┌────────────────────┼─────────────────────┐
   Flutter app          Vue admin panel        Stripe (Cashier)
 (tenant users)       (platform owner)        (subscriptions)
```

## Features
- **Multi-tenancy** — single DB, `tenant_id` scoping via an Eloquent global scope, `X-Tenant` header
- **Stripe billing** — Laravel Cashier, 3 subscription tiers, webhooks
- **RBAC** — tenant roles (tenant_admin / manager / member) + a separate super-admin guard
- **Plan limits / feature gates** — per-plan user & project caps enforced in the API and the apps
- **Flutter mobile app** — tenant-aware, white-label-ready, per-plan feature flags
- **Vue.js admin panel** — tenant management, live stats (MRR), suspend/activate

## Tech stack

| Layer            | Technology                                            |
| ---------------- | ----------------------------------------------------- |
| Backend API      | Laravel 11 (PHP 8.3)                                   |
| Admin dashboard  | Vue 3 + Vite + Pinia + Vue Router + Tailwind + Chart.js |
| Mobile app       | Flutter 3 (Provider, Dio, shared_preferences)         |
| Billing          | Stripe (Laravel Cashier)                              |
| Auth             | JWT (php-open-source-saver/jwt-auth)                   |
| Database         | MySQL — single shared DB (`tenant_id` scoping). SQLite works for quick local dev. |

## Setup

### 1. Backend — clone & install
```bash
composer install
cp .env.example .env
php artisan key:generate
```

### 2. Configure `.env`
- **Database:** set `DB_*` (MySQL) — or leave `DB_CONNECTION=sqlite` for zero-config local dev.
- **Stripe:** `STRIPE_KEY`, `STRIPE_SECRET`, `STRIPE_WEBHOOK_SECRET`, and `STRIPE_PRICE_BASIC/PRO/ENTERPRISE`.
- **JWT:** run `php artisan jwt:secret` (sets `JWT_SECRET`).
- **Super admin (Vue):** `ADMIN_EMAIL` / `ADMIN_PASSWORD`.

### 3. Migrate + seed (creates the demo tenants & data)
```bash
php artisan migrate --seed
```
The `DemoSeeder` builds the 3 demo tenants below, each with users, projects, and tasks.

### 4. Create additional tenants (optional)
```bash
php artisan tenant:create "Acme Inc" acme owner@acme.test pro
```

### 5. Vue admin panel
```bash
cd admin-dashboard
npm install
# set VITE_API_URL in .env (default http://localhost:8000/api)
npm run dev          # http://localhost:5173
```

### 6. Flutter app
```bash
cd mobile_app
flutter create . --project-name mobile_app   # generates android/ios scaffolding
# set baseUrl in lib/config/api_config.dart (Android emulator: http://10.0.2.2:8000)
flutter pub get
flutter run
```

Start the backend with `php artisan serve` (http://localhost:8000) before using the apps.

## Demo accounts

**Tenant users** (mobile app — enter the slug, then log in):

| Company      | Slug          | Plan       | Admin login       | Password      |
| ------------ | ------------- | ---------- | ----------------- | ------------- |
| AlphaCorp    | `alphacorp`   | Pro        | `alpha@demo.com`  | `password123` |
| BetaStartup  | `betastartup` | Basic      | `beta@demo.com`   | `password123` |
| GammaEnt     | `gammaent`    | Enterprise | `gamma@demo.com`  | `password123` |

All seeded tenant users share the password `password123`.

**Super admin** (Vue dashboard): `admin@saas.test` / `password` (from `.env`).

## Stripe test card
```
4242 4242 4242 4242   ·   any future expiry   ·   any CVC   ·   any ZIP
```

## What to look for in the demo
- **AlphaCorp** — 18/20 users → near-limit **warning** banner.
- **BetaStartup** — 3/3 projects → plan-gate **lock** on "Add Project" + upgrade dialog.
- **GammaEnt** — Enterprise, unlimited (no limits hit).
