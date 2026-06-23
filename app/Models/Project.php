<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A project owned by a tenant.
 *
 * BelongsToTenant gives this model automatic tenant scoping (reads) and
 * tenant_id auto-fill (writes) — see the trait for details.
 */
class Project extends Model
{
    use HasFactory;
    use BelongsToTenant;

    // tenant_id is auto-filled by the trait, so it is intentionally NOT here
    // (a client can't spoof it via the request body).
    protected $fillable = [
        'name',
        'description',
        'status',      // active | archived
        'created_by',
    ];

    // A project has many tasks.
    public function tasks(): HasMany
    {
        return $this->hasMany(Task::class);
    }

    // The tenant user who created the project.
    public function creator(): BelongsTo
    {
        return $this->belongsTo(TenantUser::class, 'created_by');
    }
}
