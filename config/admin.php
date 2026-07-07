<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Super Admin Credentials
    |--------------------------------------------------------------------------
    | The single platform owner ("super admin") logs in with these credentials,
    | which live in .env (NOT in a tenant). Change them there, never in code.
    */

    'email'    => env('SUPER_ADMIN_EMAIL', 'admin@saas.test'),
    'password' => env('SUPER_ADMIN_PASSWORD', 'password'),

];
