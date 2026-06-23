<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A task inside a project, owned by a tenant.
 */
class Task extends Model
{
    use HasFactory;
    use BelongsToTenant;

    protected $fillable = [
        'project_id',
        'title',
        'status',       // todo | in_progress | done
        'assigned_to',
        'due_date',
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    // The project this task belongs to.
    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    // The tenant user this task is assigned to (optional).
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(TenantUser::class, 'assigned_to');
    }
}
