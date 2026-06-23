<?php

namespace App\Http\Middleware;

use App\Models\Tenant;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the "current tenant" for an API request using the X-Tenant header.
 *
 * For every tenant-scoped API call:
 *   1. Client sends header:  X-Tenant: alphacorp
 *   2. We look that slug up in the tenants table.
 *   3. If it's missing OR suspended -> abort 404 (we don't reveal suspended tenants).
 *   4. Otherwise we store the tenant in the container as "currentTenant" so any
 *      controller can grab it with app('currentTenant').
 */
class ResolveTenant
{
    public function handle(Request $request, Closure $next): Response
    {
        // 1. Read the tenant slug from the request header.
        $slug = $request->header('X-Tenant');

        // No header -> the client forgot to identify which tenant it is.
        abort_if(blank($slug), 400, 'Missing X-Tenant header.');

        // 2. Find the tenant by its unique slug.
        $tenant = Tenant::where('slug', $slug)->first();

        // 3a. Unknown tenant -> 404.
        abort_if($tenant === null, 404, 'Tenant not found.');

        // 3b. Suspended tenant -> 404 (per spec, suspended tenants are hidden behind a 404).
        abort_if($tenant->status === 'suspended', 404, 'Tenant not found.');

        // 4. Make the resolved tenant available everywhere for the rest of this request.
        app()->instance('currentTenant', $tenant);

        return $next($request);
    }
}
