# Upwork Portfolio Assets

## 1. Portfolio description (~200 words)

**Multi-Tenant SaaS Platform — Delivered Project**

I designed and built a production-ready multi-tenant SaaS platform end to end: a Laravel REST
API, a Vue.js super-admin dashboard, and a Flutter mobile app — unified by a **single
shared-database architecture** with `tenant_id` scoping. Every tenant's data lives in one
database, isolated at the query layer and identified per request through a clean **`X-Tenant`
header** — no fragile per-tenant databases, far simpler to deploy and maintain.

The backend handles **Stripe subscription billing** (Laravel Cashier) across three tiers and
enforces **per-plan feature gates** in real time: when a tenant reaches its user or project
limit, the API and both apps respond instantly with upgrade prompts. **Role-based access
control** (tenant admin / manager / member) secures every endpoint via JWT, with a separate
super-admin guard for platform operators.

The Vue admin panel gives the platform owner live MRR, tenant management, and suspend/activate
controls. The Flutter app is tenant-aware and white-label-ready, with per-plan feature flags
driving the UI.

**Result:** the client launched on schedule and onboarded **50+ business clients within the
first three months**, with billing, provisioning, and access control fully automated.

*Stack: Laravel, Vue 3, Flutter, Stripe, MySQL, JWT.*

---

## 2. Ten Upwork job titles this demo is perfect for

1. Laravel Developer for Multi-Tenant SaaS Platform
2. Full-Stack SaaS MVP — Laravel + Vue + Flutter
3. Stripe Subscription Billing Integration (Laravel Cashier)
4. Multi-Tenant Architecture Expert (Single Database / `tenant_id`)
5. Flutter Mobile App Developer for an Existing REST API
6. Vue.js Admin Dashboard for a SaaS Product
7. SaaS Backend with Role-Based Access Control (RBAC) & JWT
8. Build a White-Label SaaS Application (Web + Mobile)
9. Laravel API Developer for Mobile + Web Clients
10. SaaS Plan Limits & Feature-Gating Implementation

---

## 3. 60-second demo video script

**Goal:** show the web admin, then the mobile app, ending on the plan-gate lock.

| Time | On screen | Say |
| ---- | --------- | --- |
| 0:00–0:08 | Vue admin **login** (`admin@saas.test`) | "This is the platform owner's super-admin panel. I sign in with separate admin credentials — no tenant header needed." |
| 0:08–0:18 | Admin **dashboard** | "Live platform stats: total tenants, active subscriptions, monthly recurring revenue, and a signups chart — all read from one shared database." |
| 0:18–0:25 | **Tenants** list | "Every tenant in one view, with plan and user counts. I can search, filter, and suspend or activate any account." |
| 0:25–0:30 | Switch to **Flutter app** | "Now the tenant-facing mobile app. Same backend — the only thing that changes per tenant is the X-Tenant header." |
| 0:30–0:40 | **AlphaCorp** login (`alpha@demo.com`) | "AlphaCorp is on the Pro plan. Notice the dashboard: 18 of 20 users — the app shows a near-limit warning automatically." |
| 0:40–0:50 | **BetaStartup** login (`beta@demo.com`) | "BetaStartup is on Basic, and it's already used all 3 of its projects." |
| 0:50–0:58 | Tap **Add Project** → lock + **upgrade dialog** | "When a tenant hits a plan limit, the create button locks and an upgrade dialog appears — the feature gate is enforced end to end." |
| 0:58–0:60 | Logo / title card | "One database, full multi-tenancy, billing and plan limits — fully automated." |

**Tip:** record the Vue panel in a browser and the Flutter app in an emulator side by side, or
cut between the two at the 0:25 mark.
