<?php

namespace App\Http\Controllers\Tenant;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * CRUD for projects. Every query is automatically tenant-scoped by the
 * BelongsToTenant trait on the Project model, so there is no manual
 * ->where('tenant_id', ...) here — it is added for you.
 *
 * Route-model binding ({project}) also runs through the tenant scope, so a
 * project id from another tenant resolves to 404 (no cross-tenant access).
 */
class ProjectController extends Controller
{
    // GET /api/tenant/projects
    public function index(): JsonResponse
    {
        // withCount('tasks') adds a "tasks_count" attribute to each project.
        $projects = Project::withCount('tasks')->latest()->get();

        return response()->json(['data' => $projects]);
    }

    // POST /api/tenant/projects   (tenant_admin|manager, subject to plan.limit:projects)
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status'      => ['sometimes', 'in:active,archived'],
        ]);

        // Record who created it (the logged-in tenant user). tenant_id is auto-filled.
        $data['created_by'] = auth('tenant')->id();

        $project = Project::create($data);

        return response()->json(['data' => $project], 201);
    }

    // PUT /api/tenant/projects/{project}
    public function update(Request $request, Project $project): JsonResponse
    {
        $data = $request->validate([
            'name'        => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'status'      => ['sometimes', 'in:active,archived'],
        ]);

        $project->update($data);

        return response()->json(['data' => $project]);
    }

    // DELETE /api/tenant/projects/{project}
    public function destroy(Project $project): JsonResponse
    {
        $project->delete(); // cascade removes its tasks (see migration)

        return response()->json(['message' => 'Project deleted.']);
    }
}
