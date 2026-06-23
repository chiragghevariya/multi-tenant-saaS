<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * TASKS — tasks belonging to a project. Carries tenant_id (for direct tenant
 * scoping) AND project_id (which project it lives in).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            // Parent project. cascadeOnDelete: deleting a project deletes its tasks.
            $table->foreignId('project_id')->constrained('projects')->cascadeOnDelete();
            $table->string('title');
            $table->string('status')->default('todo'); // todo | in_progress | done
            // Assigned tenant user (optional). nullOnDelete: keep the task if assignee is removed.
            $table->foreignId('assigned_to')->nullable()->constrained('tenant_users')->nullOnDelete();
            $table->date('due_date')->nullable();
            $table->timestamps();

            $table->index('tenant_id');
            $table->index('project_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
