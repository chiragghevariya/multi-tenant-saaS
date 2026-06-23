<?php

namespace App\Http\Controllers\Tenant;

use App\Http\Controllers\Controller;
use App\Models\TenantUser;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Login / register / profile for TENANT users (the "tenant" JWT guard).
 *
 * Every request must carry the X-Tenant header (ResolveTenant middleware) so we
 * know which tenant we're authenticating against.
 */
class TenantAuthController extends Controller
{
    /**
     * POST /api/tenant/auth/login   (public within a tenant)
     * Validate email + password against tenant_users for the CURRENT tenant.
     */
    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        // attempt() on the 'tenant' guard:
        //  - the TenantUser global scope restricts the lookup to the current tenant
        //  - returns a JWT string on success, or false on bad credentials
        $token = auth('tenant')->attempt($credentials);

        if (! $token) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        return $this->tokenResponse($token);
    }

    /**
     * POST /api/tenant/auth/register   (tenant_admin only; plan.limit:users)
     * Creates a new user inside the current tenant.
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => ['required', 'string', 'max:255'],
            // Unique WITHIN this tenant — scoping by tenant_id lets two tenants reuse
            // an email and returns a clean 422 (the DB also has a unique index as a backstop).
            'email'    => ['required', 'email', Rule::unique('tenant_users')->where('tenant_id', app('currentTenant')->id)],
            'password' => ['required', 'string', 'min:8'],
            'role'     => ['required', 'in:tenant_admin,manager,member'],
        ]);

        $user = TenantUser::create($data); // tenant_id auto-filled, password auto-hashed

        return response()->json(['data' => $user], 201);
    }

    /**
     * GET /api/tenant/auth/me   (requires tenant JWT)
     * Returns the currently authenticated tenant user.
     */
    public function me(): JsonResponse
    {
        return response()->json(['data' => auth('tenant')->user()]);
    }

    /**
     * POST /api/tenant/auth/logout   (requires tenant JWT)
     * Invalidates the current token.
     */
    public function logout(): JsonResponse
    {
        auth('tenant')->logout();

        return response()->json(['message' => 'Logged out.']);
    }

    /**
     * Standard JSON shape for a freshly issued token.
     */
    protected function tokenResponse(string $token): JsonResponse
    {
        return response()->json([
            'access_token' => $token,
            'token_type'   => 'bearer',
            'expires_in'   => config('jwt.ttl') * 60, // jwt.ttl is in minutes → seconds
            'user'         => auth('tenant')->user(),
        ]);
    }
}
