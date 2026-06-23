<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Simple role gate for tenant users (no spatie — we use the tenant_users.role column).
 *
 * Usage — pass one or more allowed roles:
 *   ->middleware('tenant.role:tenant_admin')
 *   ->middleware('tenant.role:tenant_admin,manager')
 *
 * Must run AFTER auth:tenant so there is an authenticated tenant user to check.
 */
class EnsureTenantRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = auth('tenant')->user();

        abort_if($user === null, 401, 'Unauthenticated.');

        // The user's role must be one of the allowed roles for this route.
        abort_unless(in_array($user->role, $roles, true), 403, 'You do not have permission to perform this action.');

        return $next($request);
    }
}
