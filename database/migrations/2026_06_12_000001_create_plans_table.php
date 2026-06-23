<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * PLANS TABLE — the global catalogue of subscription tiers (Basic / Pro / Enterprise).
 *
 * This table is NOT tenant-scoped: every tenant chooses from the same shared list.
 * It is the single source of truth for what each tier costs and what limits/features
 * it unlocks. Runs first because the `tenants` table references it.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->id();                                        // Internal primary key
            $table->string('name');                             // Human label, e.g. "Pro"
            $table->string('slug')->unique();                   // Stable machine key, e.g. "pro" (handy for APIs & seeders)
            $table->string('stripe_price_id')->nullable();      // Stripe Price id (price_...). Nullable until you create products in Stripe.
            $table->unsignedInteger('price');                   // Price in CENTS (2900 = $29.00) — integers avoid float rounding & match Stripe
            $table->unsignedInteger('max_users')->nullable();   // Seat limit; NULL = unlimited (Enterprise)
            $table->unsignedInteger('max_projects')->nullable();// Project limit; NULL = unlimited (Enterprise)
            $table->json('features')->nullable();               // Feature flags as JSON, e.g. {"api_access": true} — powers Flutter per-plan flags
            $table->timestamps();                               // created_at / updated_at
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
