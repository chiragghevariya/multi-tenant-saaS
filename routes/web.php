<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/*
|--------------------------------------------------------------------------
| Stripe Checkout return pages (Approach A)
|--------------------------------------------------------------------------
| The mobile app opens the hosted Stripe Checkout URL in the device browser.
| After paying (or cancelling) Stripe redirects here. These are just simple
| confirmation pages the user reads before returning to the app manually —
| the tenant's plan/status is updated by the Stripe WEBHOOK, not by this page.
*/
Route::get('/billing/checkout/success', function () {
    return response(checkoutReturnPage(
        title:   'Payment successful ✅',
        heading: 'You\'re all set!',
        message: 'Your subscription is active. You can now close this page and return to the app.',
        color:   '#16a34a',
    ));
})->name('billing.checkout.success');

Route::get('/billing/checkout/cancel', function () {
    return response(checkoutReturnPage(
        title:   'Payment cancelled',
        heading: 'Checkout cancelled',
        message: 'No charge was made. You can close this page and try again from the app.',
        color:   '#6b7280',
    ));
})->name('billing.checkout.cancel');

/** Minimal self-contained HTML for the Checkout return pages (no Blade view needed). */
function checkoutReturnPage(string $title, string $heading, string $message, string $color): string
{
    $title   = e($title);
    $heading = e($heading);
    $message = e($message);
    $color   = e($color);

    return <<<HTML
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>{$title}</title>
        </head>
        <body style="margin:0;font-family:-apple-system,Segoe UI,Roboto,sans-serif;background:#f8fafc;display:flex;min-height:100vh;align-items:center;justify-content:center;">
            <div style="max-width:360px;padding:32px;text-align:center;background:#fff;border-radius:16px;box-shadow:0 6px 24px rgba(0,0,0,.08);">
                <h1 style="margin:0 0 12px;font-size:22px;color:{$color};">{$heading}</h1>
                <p style="margin:0;color:#475569;line-height:1.5;">{$message}</p>
            </div>
        </body>
        </html>
        HTML;
}
