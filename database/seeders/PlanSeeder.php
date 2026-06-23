<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

/**
 * Seeds the three subscription tiers.
 *
 * NOTE on stripe_price_id: these come from your Stripe dashboard (Products ->
 * Prices). Set them in .env (STRIPE_PRICE_BASIC / _PRO / _ENTERPRISE) and they
 * get picked up here. Until you do, they stay null and the /subscribe endpoint
 * will politely refuse with "plan not available for purchase yet".
 */
class PlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'name'            => 'Basic',
                'slug'            => 'basic',
                'stripe_price_id' => env('STRIPE_PRICE_BASIC'),       // price_... from Stripe
                'price'           => 2900,                            // $29.00 in cents
                'max_users'       => 5,
                'max_projects'    => 3,
                'features'        => [
                    'api_access'       => false,
                    'priority_support' => false,
                    'custom_branding'  => false,
                ],
            ],
            [
                'name'            => 'Pro',
                'slug'            => 'pro',
                'stripe_price_id' => env('STRIPE_PRICE_PRO'),
                'price'           => 7900,                            // $79.00
                'max_users'       => 20,
                'max_projects'    => 10,
                'features'        => [
                    'api_access'       => true,
                    'priority_support' => true,
                    'custom_branding'  => false,
                ],
            ],
            [
                'name'            => 'Enterprise',
                'slug'            => 'enterprise',
                'stripe_price_id' => env('STRIPE_PRICE_ENTERPRISE'),
                'price'           => 19900,                           // $199.00
                'max_users'       => null,                            // null = unlimited
                'max_projects'    => null,                            // null = unlimited
                'features'        => [
                    'api_access'       => true,
                    'priority_support' => true,
                    'custom_branding'  => true,
                ],
            ],
        ];

        // updateOrCreate keyed by slug -> seeder is safe to run repeatedly (idempotent).
        foreach ($plans as $plan) {
            Plan::updateOrCreate(['slug' => $plan['slug']], $plan);
        }
    }
}
