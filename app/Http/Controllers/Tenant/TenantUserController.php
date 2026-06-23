<?php

namespace App\Http\Controllers\Tenant;

use App\Http\Controllers\Controller;
use App\Models\TenantUser;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Manage the tenant's users. All writes are restricted to tenant_admin via the
 * tenant.role middleware on the routes. Everything is tenant-scoped automatically.
 */
class TenantUserController extends Controller
{
    // GET /api/tenant/users
    public function index(): JsonResponse
    {
        return response()->json(['data' => TenantUser::orderBy('name')->get()]);
    }

    // POST /api/tenant/users   (tenant_admin only, subject to plan.limit:users)
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => ['required', 'string', 'max:255'],
            'email'    => ['required', 'email', Rule::unique('tenant_users')->where('tenant_id', app('currentTenant')->id)],
            'password' => ['required', 'string', 'min:8'],
            'role'     => ['required', 'in:tenant_admin,manager,member'],
        ]);

        $user = TenantUser::create($data); // tenant_id auto-filled, password auto-hashed

        return response()->json(['data' => $user], 201);
    }

    // PUT /api/tenant/users/{user}   (tenant_admin only)
    public function update(Request $request, TenantUser $user): JsonResponse
    {
        $data = $request->validate([
            'name'     => ['sometimes', 'string', 'max:255'],
            // Unique within the tenant, ignoring this same user's current row.
            'email'    => ['sometimes', 'email', Rule::unique('tenant_users')->where('tenant_id', app('currentTenant')->id)->ignore($user->id)],
            'password' => ['sometimes', 'string', 'min:8'],
            'role'     => ['sometimes', 'in:tenant_admin,manager,member'],
        ]);

        $user->update($data);

        return response()->json(['data' => $user]);
    }

    // DELETE /api/tenant/users/{user}   (tenant_admin only)
    public function destroy(TenantUser $user): JsonResponse
    {
        // Don't let an admin delete their own account in this simple version.
        if (auth('tenant')->id() === $user->id) {
            return response()->json(['message' => 'You cannot delete your own account.'], 422);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted.']);
    }
}
