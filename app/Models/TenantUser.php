<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;

/**
 * A user who logs into a tenant's workspace (NOT a platform/super-admin user).
 *
 * - BelongsToTenant: automatic tenant scoping + tenant_id auto-fill.
 * - JWTSubject: lets this model be authenticated by the "tenant" JWT guard
 *   (configured in config/auth.php).
 *
 * Because the global scope limits every query to the current tenant, a JWT issued
 * for one tenant can never resolve a user under a different X-Tenant header — IDs
 * are globally unique, so the lookup simply finds nothing → 401.
 */
class TenantUser extends Authenticatable implements JWTSubject
{
    use HasFactory;
    use BelongsToTenant;

    // The default model name would map to "tenant_users" anyway, but we're explicit.
    protected $table = 'tenant_users';

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',     // tenant_admin | manager | member
        // tenant_id is auto-filled by BelongsToTenant — not mass-assignable.
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'password' => 'hashed', // automatically bcrypt-hashes on assignment
    ];

    /*
    |--------------------------------------------------------------------------
    | JWTSubject — required by the jwt guard
    |--------------------------------------------------------------------------
    */

    // The value stored in the token's "sub" claim (this user's primary key).
    public function getJWTIdentifier(): mixed
    {
        return $this->getKey();
    }

    // Extra claims baked into the token (handy for debugging / quick checks).
    public function getJWTCustomClaims(): array
    {
        return [
            'tenant_id' => $this->tenant_id,
            'role'      => $this->role,
        ];
    }

    // Projects this user created.
    public function projects(): HasMany
    {
        return $this->hasMany(Project::class, 'created_by');
    }

    // Simple role check: $user->hasRole('tenant_admin', 'manager')
    public function hasRole(string ...$roles): bool
    {
        return in_array($this->role, $roles, true);
    }
}
