<?php

namespace App\Console\Commands;

use App\Models\Plan;
use App\Models\Tenant;
use App\Models\TenantUser;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Creates a tenant and its first admin user in one go.
 *
 *   php artisan tenant:create "Acme Inc" acme owner@acme.test pro
 *
 * Arguments: {name} {slug} {email} {plan_slug}
 */
class CreateTenant extends Command
{
    protected $signature = 'tenant:create {name} {slug} {email} {plan_slug}';

    protected $description = 'Create a tenant and its first admin (tenant_admin) user';

    public function handle(): int
    {
        // 1. Look up the plan by slug.
        $plan = Plan::where('slug', $this->argument('plan_slug'))->first();

        if (! $plan) {
            $this->error("Plan '{$this->argument('plan_slug')}' not found. Try: basic, pro, enterprise.");
            return self::FAILURE;
        }

        // 2. Make sure the slug isn't taken.
        if (Tenant::where('slug', $this->argument('slug'))->exists()) {
            $this->error("A tenant with slug '{$this->argument('slug')}' already exists.");
            return self::FAILURE;
        }

        // 3. Generate a random first password (shown once below).
        $password = Str::password(16);

        // 4. Create the tenant + first admin user atomically.
        $tenant = DB::transaction(function () use ($plan, $password) {
            $tenant = Tenant::create([
                'name'          => $this->argument('name'),
                'slug'          => $this->argument('slug'),
                'email'         => $this->argument('email'),
                'plan_id'       => $plan->id,
                'status'        => 'active',
                'trial_ends_at' => now()->addDays(14),
            ]);

            // Bind this tenant as the "current tenant" so the BelongsToTenant trait
            // auto-fills tenant_id on the new TenantUser below.
            app()->instance('currentTenant', $tenant);

            TenantUser::create([
                'name'     => 'Admin',
                'email'    => $this->argument('email'),
                'password' => $password,        // hashed automatically by the model cast
                'role'     => 'tenant_admin',
            ]);

            return $tenant;
        });

        // 5. Report the result.
        $this->info("Tenant '{$tenant->name}' created (slug: {$tenant->slug}, plan: {$plan->name}).");
        $this->newLine();
        $this->line('  Admin login:');
        $this->line("    X-Tenant: {$tenant->slug}");
        $this->line("    email:    {$tenant->email}");
        $this->line("    password: {$password}");
        $this->newLine();
        $this->warn('Save this password now — it will not be shown again.');

        return self::SUCCESS;
    }
}
