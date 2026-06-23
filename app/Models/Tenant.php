<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Cashier\Billable;   // Gives a tenant all of Stripe's subscription super-powers

/**
 * A customer organisation/workspace.
 *
 * The Tenant is our Stripe "billable" — i.e. the Stripe customer. The Billable
 * trait adds methods like newSubscription(), subscribed(), subscription(),
 * invoices(), etc. (Cashier is told this is the customer model in
 * AppServiceProvider via Cashier::useCustomerModel(Tenant::class).)
 *
 * Cashier automatically uses $tenant->name and $tenant->email when creating the
 * Stripe customer, so we don't need to override stripeName()/stripeEmail().
 */
class Tenant extends Model
{
    use HasFactory;
    use Billable;

    protected $fillable = [
        'name',
        'slug',
        'email',
        'plan_id',
        'stripe_subscription_id',
        'status',
        'trial_ends_at',
        // NOTE: stripe_id / pm_type / pm_last_four are managed by Cashier itself, not mass-assigned here.
    ];

    protected $casts = [
        'trial_ends_at' => 'datetime',
    ];

    // The plan this tenant is currently subscribed to (may be null while on trial).
    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    // All users that belong to this tenant.
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    // --- Tenant-owned app data (Phase 2). Used by the super admin to count usage. ---

    public function tenantUsers(): HasMany
    {
        return $this->hasMany(TenantUser::class);
    }

    public function projects(): HasMany
    {
        return $this->hasMany(Project::class);
    }

    public function tasks(): HasMany
    {
        return $this->hasMany(Task::class);
    }
}
