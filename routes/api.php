<?php

use App\Http\Controllers\Tenant\DashboardController;
use App\Http\Controllers\Tenant\ProjectController;
use App\Http\Controllers\Tenant\TaskController;
use App\Http\Controllers\Tenant\TenantAuthController;
use App\Http\Controllers\Tenant\TenantUserController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminPlanController;
use App\Http\Controllers\Admin\AdminStatsController;
use App\Http\Controllers\Admin\AdminTenantController;
use App\Http\Controllers\TenantBillingController;
use Illuminate\Support\Facades\Route;
use Laravel\Cashier\Http\Middleware\VerifyWebhookSignature;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
| Every route here is automatically prefixed with /api and uses the "api"
| middleware group (configured in bootstrap/app.php).
|
| Tenant identification: routes that act ON BEHALF OF a tenant use the
| "tenant" middleware (App\Http\Middleware\ResolveTenant), which requires
| the "X-Tenant: <slug>" header. The two PUBLIC routes below intentionally
| skip it:
|   - plans   : a public catalogue, no tenant needed
|   - webhook : called by Stripe (no X-Tenant header); verified by signature
*/

// PUBLIC: list available plans.
Route::get('/billing/plans', [TenantBillingController::class, 'plans']);

// PUBLIC: Stripe webhook. No tenant header; instead it is verified using the
// Stripe-Signature header + STRIPE_WEBHOOK_SECRET (VerifyWebhookSignature).
// !! PRODUCTION: STRIPE_WEBHOOK_SECRET MUST be set. An empty secret makes the
//    signature check forgeable — never deploy the webhook without it.
Route::post('/billing/webhook', [TenantBillingController::class, 'handleWebhook'])
    ->middleware(VerifyWebhookSignature::class);

// TENANT-SCOPED billing. Requires the X-Tenant header (ResolveTenant) AND an
// authenticated tenant user (JWT, the Phase 2 "tenant" guard).
//   - subscribe / cancel : billing actions, restricted to tenant_admin
//   - status             : readable by any authenticated tenant user
Route::middleware('tenant')->group(function () {
    Route::middleware(['auth:tenant', 'tenant.role:tenant_admin'])->group(function () {
        // checkout = create a Stripe HOSTED payment page and return its URL (mobile flow).
        // subscribe = server-side create from a payment_method id (card collected in-app).
        Route::post('/billing/checkout',  [TenantBillingController::class, 'checkout']);
        Route::post('/billing/subscribe', [TenantBillingController::class, 'subscribe']);
        Route::post('/billing/cancel',    [TenantBillingController::class, 'cancel']);
    });

    Route::get('/billing/status', [TenantBillingController::class, 'status'])
        ->middleware('auth:tenant');
});

/*
|--------------------------------------------------------------------------
| TENANT APP API (Phase 2)
|--------------------------------------------------------------------------
| All routes are prefixed /api/tenant and require the X-Tenant header
| (the "tenant" middleware → ResolveTenant). Login is the only route that
| does NOT need a JWT; everything inside the auth:tenant group requires a
| valid tenant JWT (Authorization: Bearer <token>).
|
| Middleware order matters: "tenant" (sets app('currentTenant')) runs before
| "auth:tenant" (which loads the tenant user — its global scope needs the
| current tenant to already be set).
*/
Route::prefix('tenant')->middleware('tenant')->group(function () {

    // --- Auth: login is open within the tenant ---
    Route::post('auth/login', [TenantAuthController::class, 'login']);

    // --- Everything below requires a valid tenant JWT ---
    Route::middleware('auth:tenant')->group(function () {

        Route::get('auth/me',      [TenantAuthController::class, 'me']);
        Route::post('auth/logout', [TenantAuthController::class, 'logout']);

        // --- Subscribed-only resource routes (Paywall Gate) ---
        Route::middleware('subscribed')->group(function () {
            // register = a tenant_admin adds a user (also counts against the plan's max_users)
            Route::post('auth/register', [TenantAuthController::class, 'register'])
                ->middleware(['tenant.role:tenant_admin', 'plan.limit:users']);

            // --- Users (tenant_admin manages members) ---
            Route::get('users', [TenantUserController::class, 'index']);
            Route::post('users', [TenantUserController::class, 'store'])
                ->middleware(['tenant.role:tenant_admin', 'plan.limit:users']);
            Route::put('users/{user}', [TenantUserController::class, 'update'])
                ->middleware('tenant.role:tenant_admin');
            Route::delete('users/{user}', [TenantUserController::class, 'destroy'])
                ->middleware('tenant.role:tenant_admin');

            // --- Projects (admins + managers can write; everyone can read) ---
            Route::get('projects', [ProjectController::class, 'index']);
            Route::post('projects', [ProjectController::class, 'store'])
                ->middleware(['tenant.role:tenant_admin,manager', 'plan.limit:projects']);
            Route::put('projects/{project}', [ProjectController::class, 'update'])
                ->middleware('tenant.role:tenant_admin,manager');
            Route::delete('projects/{project}', [ProjectController::class, 'destroy'])
                ->middleware('tenant.role:tenant_admin,manager');

            // --- Tasks (role-restricted writes, hybrid updates) ---
            Route::get('projects/{project}/tasks', [TaskController::class, 'index']);
            Route::post('projects/{project}/tasks', [TaskController::class, 'store'])
                ->middleware('tenant.role:tenant_admin,manager');
            Route::put('projects/{project}/tasks/{task}', [TaskController::class, 'update']);
            Route::delete('projects/{project}/tasks/{task}', [TaskController::class, 'destroy'])
                ->middleware('tenant.role:tenant_admin,manager');

            // --- Dashboard summary ---
            Route::get('dashboard', [DashboardController::class, 'index']);
        });
    });
});

/*
|--------------------------------------------------------------------------
| SUPER ADMIN API (Phase 3)
|--------------------------------------------------------------------------
| Platform-owner endpoints. These DO NOT use the X-Tenant header or the
| "tenant" middleware — the super admin reads ALL tenants from the shared DB.
| Auth is the separate "admin" JWT guard.
*/
Route::prefix('admin')->group(function () {
    // Public, but throttled (max 5 attempts/minute/IP) to slow brute-force attempts.
    Route::post('login', [AdminAuthController::class, 'login'])->middleware('throttle:5,1');

    Route::middleware('auth:admin')->group(function () {
        Route::get('me',      [AdminAuthController::class, 'me']);
        Route::post('logout', [AdminAuthController::class, 'logout']);

        Route::get('stats', [AdminStatsController::class, 'index']);
        Route::get('plans', [AdminPlanController::class, 'index']);

        Route::get('tenants',                    [AdminTenantController::class, 'index']);
        Route::get('tenants/{tenant}',           [AdminTenantController::class, 'show']);
        Route::post('tenants/{tenant}/suspend',  [AdminTenantController::class, 'suspend']);
        Route::post('tenants/{tenant}/activate', [AdminTenantController::class, 'activate']);
    });
});
