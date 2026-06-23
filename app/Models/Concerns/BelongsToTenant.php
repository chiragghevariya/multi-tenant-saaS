<?php

namespace App\Models\Concerns;

use App\Models\Tenant;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Shared "this model belongs to a tenant" behaviour.
 *
 * Use it on every tenant-owned model (TenantUser, Project, Task). It does TWO
 * things automatically so you can never forget to scope by tenant:
 *
 *   1) READS  — adds "WHERE tenant_id = <current tenant>" to every query
 *               (a global scope), so Project::all() only ever returns the
 *               current tenant's projects.
 *   2) WRITES — fills tenant_id from the current tenant when creating a row,
 *               so you don't pass it in by hand.
 *
 * "Current tenant" is the one resolved by the ResolveTenant middleware from the
 * X-Tenant header and stored as app('currentTenant'). When there is no current
 * tenant (e.g. a console command), the scope/auto-fill simply do nothing — the
 * artisan command sets tenant_id explicitly instead.
 */
trait BelongsToTenant
{
    // Laravel calls boot<TraitName>() automatically when the model boots.
    protected static function bootBelongsToTenant(): void
    {
        // 1) READS: global scope.
        static::addGlobalScope('tenant', function (Builder $query) {
            if (app()->bound('currentTenant')) {
                // Qualify the column (table.tenant_id) so it is safe inside joins.
                $query->where($query->getModel()->getTable().'.tenant_id', app('currentTenant')->id);
            }
        });

        // 2) WRITES: auto-fill tenant_id on create (unless already set).
        static::creating(function ($model) {
            if (app()->bound('currentTenant') && empty($model->tenant_id)) {
                $model->tenant_id = app('currentTenant')->id;
            }
        });
    }

    // Every tenant-owned model belongs to a Tenant.
    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
