<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds tenant scoping to the default users table.
 *
 * This is the heart of "single database, tenant_id scoping": every user belongs
 * to exactly one tenant. A NULL tenant_id marks a platform-level "super admin"
 * who is not tied to any single tenant.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Link each user to a tenant. Nullable so super-admins (no tenant) are allowed.
            // nullOnDelete: if a tenant is deleted, its users are kept but un-linked.
            $table->foreignId('tenant_id')->nullable()->after('id')->constrained('tenants')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['tenant_id']);   // Remove the foreign key first
            $table->dropColumn('tenant_id');      // Then drop the column
        });
    }
};
