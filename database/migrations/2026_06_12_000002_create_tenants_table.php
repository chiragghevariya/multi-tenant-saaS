<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TENANTS TABLE — one row per customer organisation/workspace.
 *
 * We use a SINGLE shared database. A tenant is just a row here, and every
 * tenant-owned record elsewhere carries a `tenant_id` pointing back to this table.
 *
 * This table is ALSO the Stripe "billable" (Cashier). That is why it carries the
 * four Cashier columns (stripe_id, pm_type, pm_last_four, trial_ends_at). See
 * App\Models\Tenant which uses the Laravel\Cashier\Billable trait.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();                          // Primary key (Cashier links subscriptions to this via tenant_id)
            $table->string('name');                // Company / workspace name, e.g. "Alpha Corp"
            $table->string('slug')->unique();      // Short unique key sent in the "X-Tenant" header, e.g. "alphacorp"
            $table->string('email')->unique();     // Owner/billing email (Cashier uses it as the Stripe customer email)

            // Which plan this tenant is currently on. Nullable: a tenant can exist (on trial)
            // before picking a paid plan. nullOnDelete = keep the tenant if a plan row is removed.
            $table->foreignId('plan_id')->nullable()->constrained('plans')->nullOnDelete();

            // ---- Stripe / Cashier billing columns ----
            // Cashier names the Stripe CUSTOMER id "stripe_id" (this is your "stripe_customer_id").
            $table->string('stripe_id')->nullable()->index();   // Stripe customer id (cus_...) — written by Cashier
            $table->string('pm_type')->nullable();              // Default card brand, e.g. "visa" (Cashier)
            $table->string('pm_last_four', 4)->nullable();      // Last 4 digits of default card (Cashier)

            // Convenience mirror of the active Stripe subscription id (sub_...). Cashier's own
            // `subscriptions` table is the source of truth; we copy it here for quick admin reads.
            $table->string('stripe_subscription_id')->nullable();

            // Lifecycle status. Allowed values: "active", "suspended", "trial".
            // New tenants start in "trial" until they subscribe.
            $table->string('status')->default('trial');

            $table->timestamp('trial_ends_at')->nullable();     // Trial end (also read by Cashier's generic-trial helpers)
            $table->timestamps();                               // created_at / updated_at
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenants');
    }
};
