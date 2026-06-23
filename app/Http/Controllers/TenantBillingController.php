<?php

namespace App\Http\Controllers;

use App\Models\Plan;
use App\Models\Tenant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Laravel\Cashier\Exceptions\IncompletePayment;
use Laravel\Cashier\Http\Controllers\WebhookController as CashierWebhookController;
use Stripe\Exception\ApiErrorException;

/**
 * Handles everything billing-related for a tenant.
 *
 * It EXTENDS Cashier's WebhookController so we inherit a battle-tested,
 * signature-verified Stripe webhook handler (handleWebhook + all the handleCustomer*
 * methods). We add our own endpoints (plans, subscribe, cancel, status) and override
 * two webhook handlers to keep the tenants table in sync with Stripe.
 */
class TenantBillingController extends CashierWebhookController
{
    /**
     * Cashier's WebhookController constructor applies the Stripe-signature middleware
     * to EVERY method of the controller. We do NOT want that on plans/subscribe/cancel/
     * status, so we override the constructor to do nothing and instead apply that
     * middleware ONLY on the webhook route (see routes/api.php).
     */
    public function __construct()
    {
        // intentionally empty
    }

    /**
     * GET /api/billing/plans  (PUBLIC — no tenant needed)
     * Lists the subscription plans for pricing pages / signup screens.
     */
    public function plans(): JsonResponse
    {
        // Return all plans (cheapest first) with only the fields a client needs.
        $plans = Plan::orderBy('price')->get([
            'id', 'name', 'slug', 'stripe_price_id',
            'price', 'max_users', 'max_projects', 'features',
        ]);

        return response()->json(['data' => $plans]);
    }

    /**
     * POST /api/billing/subscribe  (TENANT-SCOPED — needs X-Tenant header)
     * Creates a Stripe subscription for the current tenant.
     *
     * Expected JSON body:
     *   { "plan_id": 2, "payment_method": "pm_card_visa" }
     * (payment_method is the Stripe PaymentMethod id collected on the frontend by Stripe.js)
     */
    public function subscribe(Request $request): JsonResponse
    {
        // Validate the incoming request.
        $data = $request->validate([
            'plan_id'        => ['required', 'integer', 'exists:plans,id'],
            'payment_method' => ['required', 'string'], // pm_... id from Stripe.js
        ]);

        /** @var Tenant $tenant */
        $tenant = app('currentTenant');           // set by the ResolveTenant middleware
        $plan   = Plan::findOrFail($data['plan_id']);

        // A plan must be wired to a real Stripe Price before anyone can subscribe to it.
        abort_if(blank($plan->stripe_price_id), 422, 'This plan is not available for purchase yet.');

        // Don't let a tenant subscribe twice.
        if ($tenant->subscribed('default')) {
            return response()->json(['message' => 'Tenant already has an active subscription.'], 409);
        }

        try {
            // 1. Ensure the tenant exists as a Stripe customer (creates cus_... and stores stripe_id).
            $tenant->createOrGetStripeCustomer();

            // 2. Create the "default" subscription from the plan's Stripe price + the card.
            $subscription = $tenant->newSubscription('default', $plan->stripe_price_id)
                ->create($data['payment_method']);
        } catch (IncompletePayment $exception) {
            // Card needs extra authentication (e.g. 3D Secure). Tell the frontend to confirm it.
            return response()->json([
                'message'        => 'Payment requires confirmation.',
                'payment_intent' => $exception->payment->id,
            ], 402);
        } catch (ApiErrorException $exception) {
            // Any other Stripe error (declined card, bad price id, etc.).
            return response()->json(['message' => $exception->getMessage()], 422);
        }

        // 3. Mirror the new state onto the tenant row for easy reads / the admin dashboard.
        $tenant->update([
            'plan_id'                => $plan->id,
            'status'                 => 'active',
            'stripe_subscription_id' => $subscription->stripe_id, // sub_...
        ]);

        return response()->json([
            'message' => 'Subscription created successfully.',
            'data'    => $this->statusPayload($tenant->fresh()),
        ], 201);
    }

    /**
     * POST /api/billing/cancel  (TENANT-SCOPED)
     * Cancels the current tenant's subscription at the END of the billing period
     * (the tenant keeps access until then — Stripe's "grace period").
     */
    public function cancel(): JsonResponse
    {
        /** @var Tenant $tenant */
        $tenant = app('currentTenant');

        // Nothing to cancel?
        abort_unless($tenant->subscribed('default'), 404, 'No active subscription to cancel.');

        // cancel() = cancel at period end. Use cancelNow() to revoke access immediately instead.
        $tenant->subscription('default')->cancel();

        // Status stays "active" during the grace period; the Stripe webhook
        // (customer.subscription.deleted) flips it to "suspended" once it truly ends.
        return response()->json([
            'message' => 'Subscription will be canceled at the end of the billing period.',
            'data'    => $this->statusPayload($tenant->fresh()),
        ]);
    }

    /**
     * GET /api/billing/status  (TENANT-SCOPED)
     * Returns the current tenant's plan + subscription status.
     */
    public function status(): JsonResponse
    {
        /** @var Tenant $tenant */
        $tenant = app('currentTenant');

        return response()->json(['data' => $this->statusPayload($tenant)]);
    }

    /**
     * Builds a consistent "billing status" payload reused by several endpoints.
     */
    protected function statusPayload(Tenant $tenant): array
    {
        $subscription = $tenant->subscription('default'); // may be null if the tenant never subscribed

        return [
            'tenant' => [
                'name'          => $tenant->name,
                'slug'          => $tenant->slug,
                'status'        => $tenant->status,           // active / suspended / trial
                'trial_ends_at' => $tenant->trial_ends_at,
            ],
            'plan' => $tenant->plan ? [
                'name'         => $tenant->plan->name,
                'price'        => $tenant->plan->price,        // cents
                'max_users'    => $tenant->plan->max_users,    // null = unlimited
                'max_projects' => $tenant->plan->max_projects, // null = unlimited
                'features'     => $tenant->plan->features,
            ] : null,
            'subscription' => $subscription ? [
                'active'          => $tenant->subscribed('default'),
                'stripe_status'   => $subscription->stripe_status,
                'on_trial'        => $subscription->onTrial(),
                'on_grace_period' => $subscription->onGracePeriod(),
                'ends_at'         => $subscription->ends_at,
            ] : null,
        ];
    }

    /*
    |----------------------------------------------------------------------------
    | Webhook overrides
    |----------------------------------------------------------------------------
    | POST /api/billing/webhook is handled by the inherited handleWebhook() method.
    | Cashier already updates its own `subscriptions` table for these events; we call
    | the parent first, then additionally sync OUR tenants table.
    */

    /**
     * Stripe subscription statuses that still count as "good standing".
     *
     * IMPORTANT: past_due / incomplete / paused are TRANSIENT — Stripe is still
     * retrying payment or waiting on authentication. We must NOT suspend a paying
     * tenant for a temporary hiccup, otherwise a single failed charge would lock
     * them out (ResolveTenant 404s suspended tenants). Only truly terminal states
     * (canceled / unpaid / incomplete_expired) drop a tenant to "suspended".
     */
    protected const STRIPE_GOOD_STANDING = ['active', 'trialing', 'past_due', 'incomplete', 'paused'];

    /**
     * Fired when a subscription is fully canceled/expired in Stripe.
     */
    protected function handleCustomerSubscriptionDeleted(array $payload)
    {
        $response = parent::handleCustomerSubscriptionDeleted($payload); // let Cashier update its tables

        $tenant = $this->tenantFromWebhook($payload, 'subscription.deleted');

        // Subscription has truly ended -> suspend the tenant and clear the mirrored id.
        $tenant?->update(['status' => 'suspended', 'stripe_subscription_id' => null]);

        return $response;
    }

    /**
     * Fired when a subscription changes (renewed, plan swapped, payment recovered,
     * payment failed/retrying, etc.).
     */
    protected function handleCustomerSubscriptionUpdated(array $payload)
    {
        $response = parent::handleCustomerSubscriptionUpdated($payload);

        $tenant = $this->tenantFromWebhook($payload, 'subscription.updated');

        if ($tenant) {
            $stripeStatus = $payload['data']['object']['status'] ?? null;

            $tenant->update([
                // Suspend only when Stripe reports a non-recoverable status (see STRIPE_GOOD_STANDING).
                'status'                 => in_array($stripeStatus, self::STRIPE_GOOD_STANDING, true) ? 'active' : 'suspended',
                'stripe_subscription_id' => $payload['data']['object']['id'] ?? $tenant->stripe_subscription_id,
            ]);
        }

        return $response;
    }

    /**
     * Resolve the local Tenant for a Stripe webhook payload by its customer id.
     * Logs (instead of silently ignoring) when no matching tenant is found, which
     * usually means a misrouted webhook or a stale Stripe customer.
     */
    protected function tenantFromWebhook(array $payload, string $event): ?Tenant
    {
        $customerId = $payload['data']['object']['customer'] ?? null;

        $tenant = $customerId ? Tenant::where('stripe_id', $customerId)->first() : null;

        if (! $tenant) {
            Log::warning("Stripe webhook ({$event}) received for unknown tenant", ['customer' => $customerId]);
        }

        return $tenant;
    }
}
