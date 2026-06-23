# Project 4: Multi-Tenant SaaS Platform

**Version:** 1.0
**Stack:** Flutter · Vue.js 3 · Laravel 11 · MySQL · Stripe (Cashier)

---

## Overview

A multi-tenant SaaS platform using a single shared database with `tenant_id` column scoping. The system includes a Laravel backend with Stripe subscription billing, a Vue.js super admin dashboard, and a Flutter mobile app for tenant users. Each tenant is identified via an `X-Tenant` request header containing the tenant slug.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Single MySQL Database               │
│                                                 │
│  tenants table     plans table                  │
│  users (tenant_id) projects (tenant_id)         │
│  tasks (tenant_id)                              │
└─────────────────────────────────────────────────┘
         ↑                        ↑
         │                        │
  X-Tenant: alphacorp      Super Admin JWT
  (Flutter App)            (Vue.js Dashboard)
```

**Tenant identification:** Every API request from tenant users includes the header `X-Tenant: {slug}`. The `ResolveTenant` middleware reads this header, finds the tenant in the database, and stores it in `app('currentTenant')` for the duration of the request.

---

## System Components

| Component | Technology | Description |
|-----------|-----------|-------------|
| Backend API | Laravel 11 | REST API, multi-tenancy, billing |
| Super Admin Panel | Vue.js 3 + Tailwind | Manage all tenants and plans |
| Tenant Mobile App | Flutter 3.x | Project and task management per tenant |
| Database | MySQL (single DB) | All data scoped by tenant_id |
| Billing | Stripe Cashier | Subscription plans and webhooks |

---

## Database Schema

### Central Tables (no tenant_id)

| Table | Key Columns |
|-------|------------|
| plans | id, name, stripe_price_id, price, max_users, max_projects, features (JSON) |
| tenants | id, name, slug, email, plan_id, stripe_customer_id, stripe_subscription_id, status, trial_ends_at |

### Tenant-Scoped Tables (all have tenant_id)

| Table | Key Columns |
|-------|------------|
| tenant_users | id, tenant_id, name, email, password, role |
| projects | id, tenant_id, name, description, status, created_by |
| tasks | id, tenant_id, project_id, title, status, assigned_to, due_date |

---

## Subscription Plans

| Plan | Price | Max Users | Max Projects |
|------|-------|-----------|--------------|
| Basic | $29/mo | 5 | 3 |
| Pro | $79/mo | 20 | 10 |
| Enterprise | $199/mo | Unlimited | Unlimited |

---

## Roles

| Role | Scope | Permissions |
|------|-------|-------------|
| super_admin | Platform | Manage all tenants, view all billing |
| tenant_admin | Per tenant | Manage users, projects, tasks within tenant |
| manager | Per tenant | Manage projects and tasks |
| member | Per tenant | View and update assigned tasks |

---

## API Endpoints

### Billing (no X-Tenant header required)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /api/billing/plans | No | List all plans |
| POST | /api/billing/subscribe | Yes | Create Stripe subscription |
| POST | /api/billing/cancel | Yes | Cancel subscription |
| POST | /api/billing/webhook | No | Stripe webhook handler |
| GET | /api/billing/status | Yes | Current subscription status |

### Tenant Auth (X-Tenant header required)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/tenant/auth/login | No | Login scoped to tenant |
| POST | /api/tenant/auth/register | Yes (tenant_admin) | Create tenant user |
| GET | /api/tenant/auth/me | Yes | Authenticated tenant user |

### Tenant Resources (X-Tenant header + JWT required)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET/POST/PUT/DELETE | /api/tenant/users | Yes | Manage tenant users |
| GET/POST/PUT/DELETE | /api/tenant/projects | Yes | Manage projects |
| GET/POST/PUT/DELETE | /api/tenant/projects/{id}/tasks | Yes | Manage tasks |
| GET | /api/tenant/dashboard | Yes | Stats + plan limits |

### Super Admin (separate JWT)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/admin/login | No | Super admin login |
| GET | /api/admin/tenants | Yes | All tenants with stats |
| GET | /api/admin/tenants/{id} | Yes | Tenant detail |
| POST | /api/admin/tenants/{id}/suspend | Yes | Suspend tenant |
| POST | /api/admin/tenants/{id}/activate | Yes | Activate tenant |
| GET | /api/admin/stats | Yes | Platform-level stats |

---

## Build Phases

### Phase 1 — Laravel Backend: Multi-Tenancy & Subscription Plans

```
I am building a multi-tenant SaaS platform backend using Laravel 11.
This is Phase 1: Multi-tenancy setup and subscription billing.

IMPORTANT: Use a SINGLE database for all tenants. Every tenant-scoped
table has a tenant_id column. Do NOT use stancl/tenancy or separate
databases per tenant.

Please create the following step by step:

1. Install packages:
   - laravel/cashier (Stripe subscriptions)
   - spatie/laravel-permission

2. Database migrations:
   - plans (id, name, stripe_price_id, price, max_users,
     max_projects, features JSON)
   - tenants (id, name, slug, email, plan_id, stripe_customer_id,
     stripe_subscription_id, status [active/suspended/trial],
     trial_ends_at, timestamps)
     Note: slug is a unique short identifier, e.g. "alphacorp"

3. Plans Seeder:
   - Basic:      $29/mo, max_users=5,   max_projects=3
   - Pro:        $79/mo, max_users=20,  max_projects=10
   - Enterprise: $199/mo, max_users=0 (unlimited), max_projects=0 (unlimited)
   Note: 0 means unlimited in the feature gate logic

4. ResolveTenant middleware (app/Http/Middleware/ResolveTenant.php):
   - Read X-Tenant header from the request
   - Find tenant by slug in the tenants table
   - Return 404 JSON response if not found
   - Return 403 JSON response if tenant status = suspended
   - Store tenant in app()->instance('currentTenant', $tenant)
   - Register this middleware for all /api/tenant/* routes in
     bootstrap/app.php

5. Stripe Billing endpoints (routes/api.php — no X-Tenant needed):
   - GET  /api/billing/plans
   - POST /api/billing/subscribe
   - POST /api/billing/cancel
   - POST /api/billing/webhook
   - GET  /api/billing/status

6. TenantBillingController:
   - Tenant model must use the Billable trait from laravel/cashier
   - subscribe(): create Stripe subscription and update tenant record
   - webhook(): handle payment_intent.succeeded and
     customer.subscription.deleted events

Add STRIPE_KEY, STRIPE_SECRET, STRIPE_WEBHOOK_SECRET to .env.example.
Add clear comments on every important line.
```

---

### Phase 2 — Laravel Backend: Tenant API & RBAC

```
This is Phase 2 of the multi-tenant SaaS Laravel backend.
Phase 1 is complete: tenants table, plans, Stripe billing, and
ResolveTenant middleware are working.

IMPORTANT: All tenant data is in ONE shared database scoped by tenant_id.
Always filter queries with ->where('tenant_id', app('currentTenant')->id).

Please create the following:

1. New migrations (all in the single shared database):
   - tenant_users (id, tenant_id, name, email, password, role, timestamps)
   - projects (id, tenant_id, name, description, status [active/archived],
     created_by, timestamps)
   - tasks (id, tenant_id, project_id, title, status
     [todo/in_progress/done], assigned_to, due_date, timestamps)

2. TenantUser model (app/Models/TenantUser.php):
   Apply a Global Scope to automatically filter by current tenant:

   protected static function booted() {
       static::addGlobalScope('tenant', function ($query) {
           if (app()->has('currentTenant')) {
               $query->where('tenant_id', app('currentTenant')->id);
           }
       });
   }

   Apply the same global scope pattern to the Project and Task models.

3. Tenant Auth controller (separate from main auth):
   - POST /api/tenant/auth/login
       Validate email + password against tenant_users table
       The global scope automatically limits to the current tenant
       Return JWT token on success
   - POST /api/tenant/auth/register (tenant_admin role only)
   - GET  /api/tenant/auth/me

4. CheckPlanLimit middleware (app/Http/Middleware/CheckPlanLimit.php):
   - Read current tenant's plan from DB (max_users, max_projects)
   - On POST /api/tenant/users: count existing users for this tenant
     If count >= max_users (and max_users != 0): return 403 with message
     "User limit reached for your current plan."
   - On POST /api/tenant/projects: same logic for max_projects
   - Attach this middleware to the relevant routes

5. API endpoints (all require X-Tenant header + valid tenant JWT):
   Users (tenant_admin only for write):
     GET    /api/tenant/users
     POST   /api/tenant/users
     PUT    /api/tenant/users/{id}
     DELETE /api/tenant/users/{id}
   Projects:
     GET    /api/tenant/projects
     POST   /api/tenant/projects
     PUT    /api/tenant/projects/{id}
     DELETE /api/tenant/projects/{id}
   Tasks:
     GET    /api/tenant/projects/{id}/tasks
     POST   /api/tenant/projects/{id}/tasks
     PUT    /api/tenant/projects/{id}/tasks/{taskId}
     DELETE /api/tenant/projects/{id}/tasks/{taskId}
   Dashboard:
     GET    /api/tenant/dashboard
     Returns: user_count, project_count, task_counts_by_status
              (todo/in_progress/done), plan_name,
              plan_limits { max_users, max_projects }

6. Full controller code with tenant scope and role checks.

7. Artisan command to create a tenant and first admin user:
   php artisan tenant:create {name} {slug} {email} {plan_slug}

Add clear comments on every line.
```

---

### Phase 3 — Vue.js Super Admin Dashboard

```
This is Phase 3 — the Vue.js super admin dashboard for the SaaS platform.
Laravel backend from Phases 1 and 2 is complete.

Stack: Vue 3, Vite, Pinia, Vue Router, Axios, Tailwind CSS, Chart.js.

The super admin does NOT send an X-Tenant header. It uses a separate
login stored in the .env file (SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD)
and reads data across all tenants from the shared database.

Please create the full project:

1. Project setup:
   - Vue 3 + Vite
   - Install: pinia, vue-router, axios, tailwindcss, chart.js, vue-chartjs
   - src/api/index.js: Axios instance with JWT Authorization interceptor
   - src/stores/auth.js: Pinia store (login, logout, token persistence)
   - src/router/index.js: named routes with navigation guard
     (redirect to /login if no token)

2. Laravel endpoints to add for super admin (backend):
   Add these to routes/api.php under an admin prefix:
   - POST /api/admin/login
   - GET  /api/admin/stats
       Returns: total_tenants, active_subscriptions, mrr (sum of active
       plan prices), new_tenants_this_month, churned_this_month
   - GET  /api/admin/tenants?search=&plan=&status=
   - GET  /api/admin/tenants/{id}
       Returns tenant + user_count + project_count + subscription info
   - POST /api/admin/tenants/{id}/suspend
   - POST /api/admin/tenants/{id}/activate

3. Vue pages:
   LoginPage (/login):
     Email + password form, POST to /api/admin/login, store JWT

   DashboardPage (/):
     Row of 4 stat cards: Total Tenants, Active Subscriptions,
     Monthly Recurring Revenue ($), New This Month
     Line chart (Chart.js): tenant signups per month, last 6 months
     Table: 10 most recent tenants (name, plan, status, joined date)

   TenantsPage (/tenants):
     Search input + Plan filter dropdown + Status filter dropdown
     Table columns: Name, Slug, Plan, Users, Status, Joined, Actions
     Action buttons per row: View, Suspend / Activate (toggle)

   TenantDetailPage (/tenants/:id):
     Info card: name, slug, email, plan, status, trial end date
     Stats row: user_count / max_users, project_count / max_projects
     Stripe info: subscription ID, subscription status
     Suspend / Activate button

   PlansPage (/plans):
     Card per plan showing: name, price, max_users, max_projects,
     features list from JSON column

4. Sidebar layout (AppLayout.vue):
   - Navigation links: Dashboard, Tenants, Plans, Logout
   - Shows logged-in admin email

5. Primary color: indigo (#4F46E5) via Tailwind.

Add comments on every component and function.
```

---

### Phase 4 — Flutter Mobile: Tenant App

```
This is Phase 4 — the Flutter mobile app for tenant users.
The Laravel backend from Phases 1 and 2 is complete.

Stack: Flutter 3.x, Provider, Dio, shared_preferences.

HOW TENANT IDENTIFICATION WORKS:
- On first launch the user enters their tenant slug (e.g. "alphacorp")
- The app saves this slug to SharedPreferences
- Every API request includes the header: X-Tenant: alphacorp
- The backend URL is the same for all tenants — only the header changes

Please create the full project:

1. Setup:
   - pubspec.yaml dependencies: dio, provider, shared_preferences
   - lib/config/api_config.dart:
       const String baseUrl = 'https://your-api.com';
       Load tenant slug and JWT token from SharedPreferences
   - lib/services/api_service.dart:
       Dio instance
       Interceptor 1: adds header X-Tenant: {savedSlug}
       Interceptor 2: adds header Authorization: Bearer {savedToken}
   - lib/providers/auth_provider.dart
   - lib/providers/project_provider.dart

2. Screens:

   SplashScreen:
     Read slug and token from SharedPreferences
     If both present → HomeScreen
     If no slug → TenantSetupScreen
     If slug but no token → LoginScreen

   TenantSetupScreen:
     Single text field: "Enter your company identifier (e.g. alphacorp)"
     Continue button: save slug to SharedPreferences → LoginScreen

   LoginScreen:
     Email and password fields
     POST /api/tenant/auth/login
     Save returned JWT to SharedPreferences

   HomeScreen (bottom navigation, 3 tabs):

     Tab 1 — Dashboard:
       Stat cards: Total Users, Total Projects, My Open Tasks
       Plan info bar: "{Plan Name} · {user_count}/{max_users} users ·
                       {project_count}/{max_projects} projects"

     Tab 2 — Projects:
       FlatList of projects with status chip (Active / Archived)
       FAB: Add Project
         If project_count >= max_projects (and max_projects != 0):
           FAB shows a lock icon
           Tapping shows UpgradePlanDialog instead of create form

     Tab 3 — Profile:
       User name and role badge
       Tenant name
       Plan name
       Logout button

   ProjectDetailScreen:
     Project name and description
     Tasks grouped in three columns by status:
       Todo | In Progress | Done
     FAB: Add Task

   PlanLimitBanner widget:
     Show yellow bar when usage >= 80% of limit
     Show red bar when at 100%
     Text: "You have reached your plan limit"
     Button: "Upgrade Plan" (opens UpgradePlanDialog)

   UpgradePlanDialog:
     Simple dialog listing the 3 plans with price and limits
     "Contact your administrator" message at the bottom

3. UI accent color: #4F46E5 (matches the admin panel).

Add clear comments on every widget and function.
```

---

### Phase 5 — Seed Data & Documentation

```
This is Phase 5 — seed data and documentation for the SaaS platform.
All code from Phases 1–4 is complete.

1. Database Seeders:
   Run php artisan tenant:create for each tenant, then seed their data.

   3 demo tenants (all data stored in the single shared DB with tenant_id):

   AlphaCorp | slug: alphacorp | Pro plan | admin: alpha@demo.com / password123
     - 18 tenant_users (near the Pro plan limit of 20)
     - 8 projects, 10 tasks each
     - Roles: 1 tenant_admin, 3 managers, 14 members

   BetaStartup | slug: betastartup | Basic plan | admin: beta@demo.com / password123
     - 4 tenant_users
     - 3 projects (at the Basic plan limit of 3)
     - 5 tasks per project
     - Roles: 1 tenant_admin, 1 manager, 2 members

   GammaEnt | slug: gammaent | Enterprise plan | admin: gamma@demo.com / password123
     - 10 tenant_users
     - 6 projects, 8 tasks each
     - Roles: 1 tenant_admin, 2 managers, 7 members

   Note: AlphaCorp is seeded near user limit to demonstrate
         the PlanLimitBanner warning state.
         BetaStartup is seeded at project limit to demonstrate
         the FAB lock state.

2. README.md for the GitHub repository:
   - Project title and description
   - Architecture section:
       Explain single-database multi-tenancy with tenant_id scoping
       Explain X-Tenant header identification
   - Screenshots placeholder section
   - Feature list
   - Tech stack table
   - Setup instructions:
       1. Clone and run composer install
       2. Configure .env (DB, Stripe keys, JWT secret)
       3. php artisan migrate
       4. php artisan db:seed (plans seeder)
       5. php artisan tenant:create alphacorp "AlphaCorp" alpha@demo.com pro
          (repeat for other tenants)
       6. php artisan db:seed --class=TenantDataSeeder
   - Demo tenants table (slug, email, password, plan)
   - Stripe test card: 4242 4242 4242 4242, any future expiry, any CVC
   - API reference table

3. 60-second screen recording script:
   - Specify each screen and action in order
   - Flow: Vue admin login → dashboard stats → tenant list →
     open BetaStartup detail (at project limit) →
     switch to Flutter app → enter slug "betastartup" → login →
     show project tab with FAB lock icon → tap lock → upgrade dialog →
     switch tenant to "alphacorp" → show near-user-limit warning banner
```

---

## Demo Credentials

| Tenant | Slug | Email | Password | Plan |
|--------|------|-------|----------|------|
| AlphaCorp | alphacorp | alpha@demo.com | password123 | Pro |
| BetaStartup | betastartup | beta@demo.com | password123 | Basic |
| GammaEnt | gammaent | gamma@demo.com | password123 | Enterprise |
| Super Admin | — | admin@saas.com | password123 | — |

---

## Environment Variables

```env
APP_NAME=SaaS-Platform
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_DATABASE=saas_platform
DB_USERNAME=root
DB_PASSWORD=

JWT_SECRET=
JWT_TTL=60

STRIPE_KEY=
STRIPE_SECRET=
STRIPE_WEBHOOK_SECRET=
CASHIER_CURRENCY=usd

SUPER_ADMIN_EMAIL=admin@saas.com
SUPER_ADMIN_PASSWORD=password123
```
