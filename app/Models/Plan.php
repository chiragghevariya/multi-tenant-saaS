<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A subscription tier (Basic / Pro / Enterprise).
 */
class Plan extends Model
{
    use HasFactory;

    // Columns safe to mass-assign (from the seeder or the Vue admin dashboard).
    protected $fillable = [
        'name',
        'slug',
        'stripe_price_id',
        'price',
        'max_users',
        'max_projects',
        'features',
    ];

    // Automatic type conversion when reading/writing these columns.
    protected $casts = [
        'features' => 'array',   // JSON <-> PHP array, so $plan->features['api_access'] just works
        'price'    => 'integer', // Always treat price (cents) as an int
    ];

    // One plan can be used by many tenants.
    public function tenants(): HasMany
    {
        return $this->hasMany(Tenant::class);
    }

    // Convenience accessor for display: $plan->price_in_dollars (e.g. 29.0).
    public function getPriceInDollarsAttribute(): float
    {
        return $this->price / 100;
    }
}
