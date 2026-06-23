<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TENANT_USERS — the people who log into a tenant's workspace.
 *
 * This is SEPARATE from the default `users` table (which holds platform/super-admin
 * accounts). Every row is scoped to a tenant via tenant_id. Roles are stored in a
 * simple `role` string column (tenant_admin / manager / member) — no spatie here.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenant_users', function (Blueprint $table) {
            $table->id();
            // Owning tenant. cascadeOnDelete: removing a tenant removes its users.
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            $table->string('name');
            $table->string('email');
            $table->string('password');                 // stored hashed (see TenantUser cast)
            $table->string('role')->default('member');  // tenant_admin | manager | member
            $table->timestamps();

            // Email is unique PER TENANT — two different tenants may use the same email.
            $table->unique(['tenant_id', 'email']);
            $table->index('tenant_id');                 // fast tenant-scoped lookups
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_users');
    }
};
