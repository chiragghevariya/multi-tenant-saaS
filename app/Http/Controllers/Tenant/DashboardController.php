<?php

namespace App\Http\Controllers\Tenant;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Task;
use App\Models\TenantUser;
use Illuminate\Http\JsonResponse;

/**
 * Tenant dashboard summary. Every count is tenant-scoped automatically.
 */
class DashboardController extends Controller
{
    // GET /api/tenant/dashboard
    public function index(): JsonResponse
    {
        $tenant = app('currentTenant');

        // Count tasks grouped by status, then fill any missing statuses with 0
        // so the shape is always the same for the frontend.
        $rawCounts = Task::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $tasksByStatus = [
            'todo'        => (int) ($rawCounts['todo'] ?? 0),
            'in_progress' => (int) ($rawCounts['in_progress'] ?? 0),
            'done'        => (int) ($rawCounts['done'] ?? 0),
        ];

        // Open tasks assigned to the CURRENT user (todo or in_progress).
        // Used by the mobile app's "My Open Tasks" stat card.
        $myOpenTasks = Task::where('assigned_to', auth('tenant')->id())
            ->whereIn('status', ['todo', 'in_progress'])
            ->count();

        return response()->json([
            'data' => [
                'user_count'           => TenantUser::count(),
                'project_count'        => Project::count(),
                'my_open_tasks'        => $myOpenTasks,
                'task_counts_by_status' => $tasksByStatus,
                'plan_name'            => $tenant->plan?->name,
                'plan_limits'          => [
                    'max_users'    => $tenant->plan?->max_users,    // null = unlimited
                    'max_projects' => $tenant->plan?->max_projects, // null = unlimited
                ],
            ],
        ]);
    }
}
