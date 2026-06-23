<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * Order matters: plans first (tenants reference a plan), then roles, then
     * the demo tenants.
     */
    public function run(): void
    {
        $this->call([
            PlanSeeder::class,  // Basic / Pro / Enterprise tiers (must run first)
            RoleSeeder::class,  // spatie roles for platform/super-admin use
            DemoSeeder::class,  // 3 demo tenants + users + projects + tasks
        ]);
    }
}
