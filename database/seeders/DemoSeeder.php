<?php

namespace Database\Seeders;

use App\Models\Plan;
use App\Models\Project;
use App\Models\Task;
use App\Models\Tenant;
use App\Models\TenantUser;
use Illuminate\Database\Seeder;

/**
 * Creates 3 demo tenants with realistic data tuned to SHOW OFF the UI:
 *
 *   AlphaCorp   (Pro,        20 users) -> 18 users  (near-limit warning), 8/10 projects
 *   BetaStartup (Basic,       5 users) ->  4 users, 3/3 projects (AT LIMIT -> plan-gate lock)
 *   GammaEnt    (Enterprise, unlimited)-> 10 users, 6 projects
 *
 * Every user's password is "password123". Roles: 1 tenant_admin, 1-2 managers, rest members.
 * This replaces running `php artisan tenant:create` by hand — it does the same thing
 * (tenant + first admin) plus the demo users/projects/tasks, with fixed passwords.
 *
 * Idempotent: safe to run repeatedly (keyed by slug / email / project name).
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        // name, slug, plan slug, admin email, total users, managers, projects, tasks/project
        $this->seedTenant('AlphaCorp', 'alphacorp', 'pro', 'alpha@demo.com', 18, 2, 8, 10);
        $this->seedTenant('BetaStartup', 'betastartup', 'basic', 'beta@demo.com', 4, 1, 3, 5);
        $this->seedTenant('GammaEnt', 'gammaent', 'enterprise', 'gamma@demo.com', 10, 2, 6, 8);
    }

    private function seedTenant(
        string $name,
        string $slug,
        string $planSlug,
        string $adminEmail,
        int $totalUsers,
        int $managers,
        int $projects,
        int $tasksPerProject,
    ): void {
        $plan = Plan::where('slug', $planSlug)->firstOrFail();

        // 1. The tenant itself (central record).
        $tenant = Tenant::updateOrCreate(
            ['slug' => $slug],
            [
                'name'          => $name,
                'email'         => $adminEmail,
                'plan_id'       => $plan->id,
                'status'        => 'active',
                'trial_ends_at' => now()->addDays(14),
            ],
        );

        // 2. Make this the "current tenant" so the BelongsToTenant trait auto-fills
        //    tenant_id on every tenant_user / project / task we create below.
        app()->instance('currentTenant', $tenant);

        // 3. Users — first the named admin, then managers, then members.
        $users = [$this->makeUser($adminEmail, "$name Admin", 'tenant_admin')];
        for ($i = 2; $i <= $totalUsers; $i++) {
            $role = $i <= (1 + $managers) ? 'manager' : 'member';
            $users[] = $this->makeUser("user$i@$slug.demo", "$name User $i", $role);
        }
        $userIds = array_map(fn (TenantUser $u) => $u->id, $users);
        $adminId = $users[0]->id;

        // 4. Projects + tasks.
        $statuses = ['todo', 'in_progress', 'done'];
        for ($p = 1; $p <= $projects; $p++) {
            $project = Project::updateOrCreate(
                ['name' => "Project $p"], // scoped to this tenant by the global scope
                [
                    'description' => "Demo project $p for $name.",
                    'status'      => $p % 5 === 0 ? 'archived' : 'active', // a little variety
                    'created_by'  => $adminId,
                ],
            );

            // Create tasks up to the target count (skip any that already exist).
            $existing = $project->tasks()->count();
            for ($t = $existing + 1; $t <= $tasksPerProject; $t++) {
                Task::create([
                    'project_id' => $project->id,
                    'title'      => "Task $t of Project $p",
                    'status'     => $statuses[$t % 3],
                    // Assign every other task to the admin so the demo admin's
                    // "My Open Tasks" card shows a real number.
                    'assigned_to' => $t % 2 === 0 ? $adminId : $userIds[$t % count($userIds)],
                    'due_date'    => now()->addDays($t)->toDateString(),
                ]);
            }
        }
    }

    private function makeUser(string $email, string $name, string $role): TenantUser
    {
        return TenantUser::updateOrCreate(
            ['email' => $email], // scoped to the current tenant
            [
                'name'     => $name,
                'password' => 'password123', // hashed automatically by the model cast
                'role'     => $role,
            ],
        );
    }
}
