<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Super admin authentication (the "admin" JWT guard).
 *
 * The super admin is NOT a tenant user. Credentials come from .env
 * (config/admin.php). On success we issue a JWT against the users table.
 */
class AdminAuthController extends Controller
{
    // POST /api/admin/login
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        // Compare against the single super-admin credentials from .env.
        // hash_equals() is a timing-safe string comparison.
        $emailOk = hash_equals((string) config('admin.email'), (string) $request->input('email'));
        $passOk  = hash_equals((string) config('admin.password'), (string) $request->input('password'));

        if (! $emailOk || ! $passOk) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        // Make sure a User row exists to act as the JWT "subject" (created once).
        $admin = User::firstOrCreate(
            ['email' => config('admin.email')],
            ['name' => 'Super Admin', 'password' => Hash::make(config('admin.password'))]
        );

        // Issue a JWT on the "admin" guard.
        $token = auth('admin')->login($admin);

        return $this->tokenResponse($token, $admin);
    }

    // GET /api/admin/me  (verify the token / load the admin)
    public function me(): JsonResponse
    {
        $admin = auth('admin')->user();

        return response()->json(['data' => ['name' => $admin->name, 'email' => $admin->email]]);
    }

    // POST /api/admin/logout
    public function logout(): JsonResponse
    {
        auth('admin')->logout();

        return response()->json(['message' => 'Logged out.']);
    }

    protected function tokenResponse(string $token, User $admin): JsonResponse
    {
        return response()->json([
            'access_token' => $token,
            'token_type'   => 'bearer',
            'expires_in'   => config('jwt.ttl') * 60, // seconds
            'user'         => ['name' => $admin->name, 'email' => $admin->email],
        ]);
    }
}
