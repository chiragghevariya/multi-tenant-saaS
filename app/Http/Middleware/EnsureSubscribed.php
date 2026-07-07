<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Paywall Gate: Prevents unsubscribed tenants from accessing backend resources.
 *
 * It checks that the current tenant:
 *   1. Has a plan associated with their account.
 *   2. Is either on an active Stripe subscription, within their trial period,
 *      or has their status manually set to 'active'.
 *
 * If none of these conditions are met, it aborts with a 403 Forbidden error.
 */
class EnsureSubscribed
{
    public function handle(Request $request, Closure $next): Response
    {
        $tenant = app('currentTenant'); // resolved by ResolveTenant middleware

        // 1. Verify a plan is selected.
        if ($tenant->plan_id === null) {
            abort(403, 'No active plan. Please subscribe.');
        }

        // 2. Check subscription/trial validity.
        // - subscribed('default') checks the `subscriptions` table (via Stripe webhook updates)
        // - onTrial() checks if the tenant has a future trial_ends_at date (generic trial)
        // - status === 'active' allows manual admin bypass or fallback active state
        $hasActiveSubscription = $tenant->subscribed('default');
        $onTrial = $tenant->onTrial();
        $isStatusActive = $tenant->status === 'active';

        if (!$hasActiveSubscription && !$onTrial && !$isStatusActive) {
            abort(403, 'Your trial or subscription has expired. Please subscribe to continue.');
        }

        return $next($request);
    }
}
