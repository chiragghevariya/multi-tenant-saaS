# SaaS Mobile App (Flutter)

Tenant-facing mobile client for the multi-tenant SaaS platform. It talks to the
Phase 2 Laravel **tenant API** (`/api/tenant/*`) and identifies the tenant with
the `X-Tenant` header.

## How tenant identification works
1. On first launch the app asks for a **company slug** (e.g. `alphacorp`) and saves it.
2. Every request sends `X-Tenant: <slug>` (added by a Dio interceptor).
3. After login, every request also sends `Authorization: Bearer <jwt>`.
4. The base URL never changes — only the `X-Tenant` header differs per tenant.

## Run it
This repo contains `pubspec.yaml` + `lib/` only. Generate the platform folders
(android/ios/etc.) once, then run:

```bash
cd mobile_app

# 1. Generate native platform scaffolding (keeps your existing lib/ + pubspec.yaml)
flutter create . --project-name mobile_app

# 2. Point the app at your backend — edit lib/config/api_config.dart:
#    Android emulator: const String baseUrl = 'http://10.0.2.2:8000';
#    iOS simulator:    const String baseUrl = 'http://127.0.0.1:8000';

# 3. Install deps and run
flutter pub get
flutter run
```

Make sure the Laravel backend is running (`php artisan serve`). Log in with a
tenant user, e.g. slug `gammacorp`, email `owner@gamma.test`.

## Structure
```
lib/
  config/api_config.dart      base URL + storage keys
  services/
    storage.dart              SharedPreferences (slug + token)
    api_service.dart          shared Dio client + interceptors
  providers/
    auth_provider.dart        slug, login, profile, logout
    project_provider.dart     dashboard stats, projects, tasks, plan gate
  models/                     TenantUser, Project, Task, DashboardStats
  screens/
    splash_screen.dart        routes based on saved slug/token
    tenant_setup_screen.dart  enter company slug
    login_screen.dart         email + password
    home_screen.dart          bottom nav: Dashboard / Projects / Profile
    tabs/                      the three tab bodies
    project_detail_screen.dart tasks grouped by status
  widgets/
    stat_card.dart            dashboard metric card
    plan_limit_banner.dart    yellow >=80% / red+lock at 100%
    upgrade_dialog.dart       plan options dialog
```
