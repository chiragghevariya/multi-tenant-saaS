import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../theme.dart';
import '../../widgets/plan_limit_banner.dart';
import '../../widgets/upgrade_dialog.dart';
import '../project_detail_screen.dart';

/// Tab 2 — project list + an "Add Project" FAB that LOCKS at the plan limit.
class ProjectsTab extends StatelessWidget {
  const ProjectsTab({super.key});

  // Create-project dialog.
  Future<void> _showCreateDialog(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (create != true) return;
    final err = await provider.createProject(nameCtrl.text, descCtrl.text);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final atLimit = provider.atProjectLimit; // PLAN GATE

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: provider.loadAll,
        child: Column(
          children: [
            // Warning/lock banner near or at the project limit.
            if (provider.stats != null)
              PlanLimitBanner(
                used: provider.stats!.projectCount,
                max: provider.stats!.maxProjects,
                label: 'projects',
              ),
            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.projects.isEmpty
                      ? const Center(child: Text('No projects yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.projects.length,
                          itemBuilder: (_, i) => _ProjectTile(project: provider.projects[i]),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: atLimit ? Colors.grey : kPrimary,
        icon: Icon(atLimit ? Icons.lock : Icons.add),
        label: Text(atLimit ? 'Limit reached' : 'Add Project'),
        onPressed: () {
          // At the limit → show upgrade options instead of the create form.
          if (atLimit) {
            showUpgradeDialog(context);
          } else {
            _showCreateDialog(context);
          }
        },
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final archived = project.status == 'archived';
    return Card(
      child: ListTile(
        title: Text(project.name),
        subtitle: Text('${project.tasksCount} tasks'),
        trailing: Chip(
          label: Text(project.status),
          backgroundColor: archived ? Colors.grey.shade300 : const Color(0xFFD1FAE5),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
        ),
      ),
    );
  }
}
