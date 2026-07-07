<?php

namespace App\Http\Controllers\Tenant;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * CRUD for tasks, nested under a project: /api/tenant/projects/{project}/tasks.
 *
 * Both Project and Task are tenant-scoped, so the {project} and {task} route
 * bindings can only resolve records inside the current tenant.
 */
class TaskController extends Controller
{
    // GET /api/tenant/projects/{project}/tasks
    public function index(Project $project): JsonResponse
    {
        return response()->json(['data' => $project->tasks()->latest()->get()]);
    }

    // POST /api/tenant/projects/{project}/tasks
    public function store(Request $request, Project $project): JsonResponse
    {
        $data = $request->validate([
            'title'       => ['required', 'string', 'max:255'],
            'status'      => ['sometimes', 'in:todo,in_progress,done'],
            // assigned_to must be a user OF THIS TENANT (scoped exists check).
            'assigned_to' => ['nullable', Rule::exists('tenant_users', 'id')->where('tenant_id', app('currentTenant')->id)],
            'due_date'    => ['nullable', 'date'],
        ]);

        $data['project_id'] = $project->id; // tenant_id is auto-filled by the trait

        $task = Task::create($data);

        return response()->json(['data' => $task], 201);
    }

    // PUT /api/tenant/projects/{project}/tasks/{task}
    public function update(Request $request, Project $project, Task $task): JsonResponse
    {
        // Make sure the task really belongs to this project.
        abort_if($task->project_id !== $project->id, 404, 'Task not found in this project.');

        $user = auth('tenant')->user();

        // If the user is a member, restrict their access.
        if ($user->role === 'member') {
            // Member can only update tasks assigned to them.
            abort_unless($task->assigned_to === $user->id, 403, 'You do not have permission to update tasks that are not assigned to you.');

            // Member can only update the status of the task.
            if ($request->hasAny(['title', 'assigned_to', 'due_date'])) {
                abort(403, 'Members are only allowed to update the status of assigned tasks.');
            }
        }

        $data = $request->validate([
            'title'       => ['sometimes', 'string', 'max:255'],
            'status'      => ['sometimes', 'in:todo,in_progress,done'],
            'assigned_to' => ['sometimes', 'nullable', Rule::exists('tenant_users', 'id')->where('tenant_id', app('currentTenant')->id)],
            'due_date'    => ['sometimes', 'nullable', 'date'],
        ]);

        $task->update($data);

        return response()->json(['data' => $task]);
    }

    // DELETE /api/tenant/projects/{project}/tasks/{task}
    public function destroy(Project $project, Task $task): JsonResponse
    {
        abort_if($task->project_id !== $project->id, 404, 'Task not found in this project.');

        $task->delete();

        return response()->json(['message' => 'Task deleted.']);
    }
}
