<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use Illuminate\Http\JsonResponse;

/**
 * Read-only list of plans for the admin PlansPage.
 */
class AdminPlanController extends Controller
{
    // GET /api/admin/plans
    public function index(): JsonResponse
    {
        $plans = Plan::orderBy('price')->get([
            'id', 'name', 'slug', 'price', 'max_users', 'max_projects', 'features',
        ]);

        return response()->json(['data' => $plans]);
    }
}
