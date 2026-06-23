<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

/**
 * Seeds the three RBAC roles used across the platform:
 *   - super admin  : platform owner (manages ALL tenants) — typically a user with tenant_id = null
 *   - tenant admin : owns/manages a single tenant
 *   - tenant user  : a regular member inside a tenant
 *
 * (These are spatie/laravel-permission roles. Assign them with $user->assignRole('tenant admin').)
 */
class RoleSeeder extends Seeder
{
    public function run(): void
    {
        // 'web' is spatie's default guard. firstOrCreate keeps this idempotent.
        foreach (['super admin', 'tenant admin', 'tenant user'] as $role) {
            Role::firstOrCreate(['name' => $role, 'guard_name' => 'web']);
        }
    }
}
