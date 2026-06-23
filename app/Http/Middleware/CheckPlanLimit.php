<?php

namespace App\Http\Middleware;

use App\Models\Project;
use App\Models\TenantUser;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Feature gate: stops a tenant from exceeding its plan limits.
 *
 * Use it on "create" routes and tell it which resource to count:
 *   ->middleware('plan.limit:users')      // before creating a user
 *   ->middleware('plan.limit:projects')   // before creating a project
 *
 * It reads max_users / max_projects from the current tenant's plan. A NULL limit
 * means "unlimited" (Enterprise). Counts use the tenant global scope, so they are
 * automatically restricted to the current tenant.
 */
class CheckPlanLimit
{
    public function handle(Request $request, Closure $next, string $resource): Response
    {
        $tenant = app('currentTenant');     // set by ResolveTenant middleware
        $plan   = $tenant->plan;            // belongsTo Plan (may be null)

        // No plan = nothing is allowed until they subscribe.
        abort_if($plan === null, 403, 'No active plan. Please subscribe.');

        // Pick the right limit + current usage for the requested resource.
        if ($resource === 'users') {
            $max     = $plan->max_users;
            $current = TenantUser::count();   // scoped to this tenant
        } elseif ($resource === 'projects') {
            $max     = $plan->max_projects;
            $current = Project::count();      // scoped to this tenant
        } else {
            // Unknown resource name -> don't block.
            return $next($request);
        }

        // NULL = unlimited. Otherwise block once usage has reached the limit.
        if ($max !== null && $current >= $max) {
            abort(403, 'Plan limit reached. Please upgrade.');
        }

        return $next($request);
    }
}
