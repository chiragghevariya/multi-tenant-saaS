<?php

namespace App\Providers;

use App\Models\Tenant;
use Illuminate\Support\ServiceProvider;
use Laravel\Cashier\Cashier;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Tell Cashier that our billable/customer model is Tenant (not the default User).
        // This is what makes $tenant->newSubscription(), $tenant->stripe_id, and the
        // webhook controller all resolve to the Tenant model.
        Cashier::useCustomerModel(Tenant::class);
    }
}
