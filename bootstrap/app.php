<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',   // Enables the /api routes (api middleware group + /api prefix)
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Register ResolveTenant under the short alias "tenant" so API routes can
        // opt in with ->middleware('tenant'). We apply it per-route (in routes/api.php)
        // rather than to the whole api group, because the public "plans" and Stripe
        // "webhook" routes must NOT require an X-Tenant header.
        $middleware->alias([
            'tenant'     => \App\Http\Middleware\ResolveTenant::class,   // resolves X-Tenant header
            'plan.limit' => \App\Http\Middleware\CheckPlanLimit::class,  // plan.limit:users / plan.limit:projects
            'tenant.role' => \App\Http\Middleware\EnsureTenantRole::class, // tenant.role:tenant_admin,manager
        ]);

        // CRITICAL ordering: ResolveTenant MUST run before the JWT "auth:tenant"
        // middleware. The tenant guard loads the TenantUser, whose global scope needs
        // app('currentTenant') to already be set — otherwise it can't scope the lookup
        // to the tenant and a token from tenant A would resolve under tenant B.
        // Laravel's middleware priority normally runs authentication first, so we
        // explicitly insert ResolveTenant ahead of it.
        $middleware->prependToPriorityList(
            \Illuminate\Contracts\Auth\Middleware\AuthenticatesRequests::class, // i.e. auth:tenant
            \App\Http\Middleware\ResolveTenant::class,
        );
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
