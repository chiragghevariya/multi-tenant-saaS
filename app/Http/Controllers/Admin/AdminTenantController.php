<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\JsonResponse;

/**
 * Super admin tenant management. No X-Tenant header — the admin sees ALL tenants.
 *
 * NOTE: TenantUser/Project are tenant-scoped by a global scope that only activates
 * when app('currentTenant') is bound. In admin requests it is NOT bound, so the
 * relationship constraints below (tenant_id = this tenant) give correct per-tenant
 * counts without leaking across tenants.
 */
class AdminTenantController extends Controller
{
    // GET /api/admin/tenants  — all tenants with plan + user count
    public function index(): JsonResponse
    {
        $tenants = Tenant::with('plan')
            ->withCount('tenantUsers')   // adds ->tenant_users_count
            ->latest()
            ->get()
            ->map(fn (Tenant $t) => [
                'id'         => $t->id,
                'name'       => $t->name,
                'slug'       => $t->slug,
                'email'      => $t->email,
                'plan'       => $t->plan?->name,
                'status'     => $t->status,
                'user_count' => $t->tenant_users_count,
                'created_at' => $t->created_at->toDateString(),
            ]);

        return response()->json(['data' => $tenants]);
    }

    // GET /api/admin/tenants/{tenant}  — detail + usage vs limits + Stripe info
    public function show(Tenant $tenant): JsonResponse
    {
        $tenant->load('plan');
        $subscription = $tenant->subscription('default'); // Cashier subscription (may be null)

        return response()->json(['data' => [
            'id'     => $tenant->id,
            'name'   => $tenant->name,
            'slug'   => $tenant->slug,
            'email'  => $tenant->email,
            'status' => $tenant->status,
            'plan'   => $tenant->plan ? [
                'name'         => $tenant->plan->name,
                'price'        => $tenant->plan->price,        // cents
                'max_users'    => $tenant->plan->max_users,    // null = unlimited
                'max_projects' => $tenant->plan->max_projects, // null = unlimited
            ] : null,
            'usage' => [
                'user_count'    => $tenant->tenantUsers()->count(),
                'project_count' => $tenant->projects()->count(),
            ],
            'stripe' => [
                'subscription_id' => $tenant->stripe_subscription_id,
                'status'          => $subscription?->stripe_status,
            ],
        ]]);
    }

    // POST /api/admin/tenants/{tenant}/suspend
    public function suspend(Tenant $tenant): JsonResponse
    {
        $tenant->update(['status' => 'suspended']);

        return response()->json([
            'message' => 'Tenant suspended.',
            'data'    => ['id' => $tenant->id, 'status' => $tenant->status],
        ]);
    }

    // POST /api/admin/tenants/{tenant}/activate
    public function activate(Tenant $tenant): JsonResponse
    {
        $tenant->update(['status' => 'active']);

        return response()->json([
            'message' => 'Tenant activated.',
            'data'    => ['id' => $tenant->id, 'status' => $tenant->status],
        ]);
    }
}
