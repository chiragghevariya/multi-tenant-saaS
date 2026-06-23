<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\JsonResponse;

/**
 * Platform-wide statistics for the super admin dashboard.
 */
class AdminStatsController extends Controller
{
    // GET /api/admin/stats
    public function index(): JsonResponse
    {
        $now          = now();
        $startOfMonth = $now->copy()->startOfMonth();

        $totalTenants        = Tenant::count();
        $activeSubscriptions = Tenant::where('status', 'active')->count();

        // MRR = sum of the monthly price (in dollars) of all ACTIVE tenants' plans.
        // The join drops tenants without a plan; status is qualified to avoid ambiguity.
        $mrrCents = Tenant::where('tenants.status', 'active')
            ->join('plans', 'plans.id', '=', 'tenants.plan_id')
            ->sum('plans.price');
        $mrr = round($mrrCents / 100, 2);

        $newThisMonth = Tenant::where('created_at', '>=', $startOfMonth)->count();

        // Approximation: tenants that became "suspended" this month (we don't store a churn date).
        $churnedThisMonth = Tenant::where('status', 'suspended')
            ->where('updated_at', '>=', $startOfMonth)
            ->count();

        // Tenant signups per month for the last 6 months (powers the line chart).
        $signups = [];
        for ($i = 5; $i >= 0; $i--) {
            $month = $now->copy()->subMonths($i);
            $signups[] = [
                'month' => $month->format('M Y'),
                'count' => Tenant::whereYear('created_at', $month->year)
                    ->whereMonth('created_at', $month->month)
                    ->count(),
            ];
        }

        // Most recent tenants for the dashboard table.
        $recentTenants = Tenant::with('plan')->latest()->take(5)->get()
            ->map(fn (Tenant $t) => [
                'id'         => $t->id,
                'name'       => $t->name,
                'plan'       => $t->plan?->name,
                'status'     => $t->status,
                'created_at' => $t->created_at->toDateString(),
            ]);

        return response()->json(['data' => [
            'total_tenants'        => $totalTenants,
            'active_subscriptions' => $activeSubscriptions,
            'mrr'                  => $mrr,
            'new_this_month'       => $newThisMonth,
            'churned_this_month'   => $churnedThisMonth,
            'signups_per_month'    => $signups,       // [{month, count}, ...]
            'recent_tenants'       => $recentTenants, // [{id, name, plan, status, created_at}, ...]
        ]]);
    }
}
