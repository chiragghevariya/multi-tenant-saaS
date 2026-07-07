import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../widgets/plan_limit_banner.dart';
import '../../widgets/upgrade_dialog.dart';
import '../project_detail_screen.dart';

/// Tab 2 — project list + an "Add Project" FAB that LOCKS at the plan limit.
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Create-project dialog.
  Future<void> _showCreateDialog(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'e.g. Mobile redesign',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Describe the goals or scope of this project',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (create != true) return;
    final err = await provider.createProject(nameCtrl.text, descCtrl.text);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: colors.onError),
              const SizedBox(width: 8),
              Expanded(child: Text(err, style: TextStyle(color: colors.onError))),
            ],
          ),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final atLimit = provider.atProjectLimit; // PLAN GATE
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Filter projects based on local search query
    final filteredProjects = provider.projects.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatches = (p.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || descMatches;
    }).toList();

    final inputBorderColor = colors.outlineVariant;
    final titleColor = colors.onSurface;
    final subtitleColor = colors.onSurfaceVariant;
    final emptyIconColor = colors.onSurfaceVariant.withOpacity(0.3);

    final fabBg = atLimit ? colors.surfaceContainerHigh : colors.primary;
    final fabFg = atLimit ? colors.onSurfaceVariant : colors.onPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: provider.loadAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plan lock banner
            if (provider.stats != null)
              PlanLimitBanner(
                used: provider.stats!.projectCount,
                max: provider.stats!.maxProjects,
                label: 'projects',
              ),

            // Search Bar Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  labelText: 'Search projects…',
                  prefixIcon: Icon(Icons.search_rounded, color: subtitleColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: subtitleColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  fillColor: colors.surfaceContainer,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                ),
              ),
            ),

            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                  : provider.error != null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded, color: colors.error, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  provider.error!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredProjects.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.folder_open_rounded,
                                    color: emptyIconColor,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ? 'No matching projects' : 'No projects yet',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: titleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try searching for something else'
                                        : 'Create your first project to get started',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredProjects.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ProjectTile(project: filteredProjects[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: fabBg,
        elevation: 4,
        icon: Icon(atLimit ? Icons.lock_outline_rounded : Icons.add_rounded, color: fabFg, size: 20),
        label: Text(
          atLimit ? 'Limit reached' : 'Add Project',
          style: TextStyle(color: fabFg, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
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
    final active = project.status == 'active';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // M3 Container color mappings
    Color bgBadge;
    Color fgBadge;

    if (archived) {
      bgBadge = colors.surfaceContainerHigh;
      fgBadge = colors.onSurfaceVariant;
    } else if (active) {
      bgBadge = colors.secondaryContainer;
      fgBadge = colors.onSecondaryContainer;
    } else {
      bgBadge = colors.tertiaryContainer;
      fgBadge = colors.onTertiaryContainer;
    }

    final tileTitleColor = colors.onSurface;
    final tileSubtitleColor = colors.onSurfaceVariant;
    final leadingBg = colors.primaryContainer;
    final leadingFg = colors.onPrimaryContainer;
    final chevronColor = colors.outlineVariant;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Project initial icon holder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: archived ? colors.surfaceContainerHigh : leadingBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    project.name.isNotEmpty ? project.name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      color: archived ? colors.onSurfaceVariant : leadingFg,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Task Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tileTitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 14, color: tileSubtitleColor),
                        const SizedBox(width: 4),
                        Text(
                          '${project.tasksCount} tasks',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tileSubtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgBadge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fgBadge,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: chevronColor),
            ],
          ),
        ),
      ),
    );
  }
}
