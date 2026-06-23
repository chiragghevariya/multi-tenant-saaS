import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/project_provider.dart';
import '../../theme.dart';
import '../../widgets/stat_card.dart';

/// Tab 1 — stat cards + a plan info bar.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final stats = provider.stats;

    return RefreshIndicator(
      onRefresh: provider.loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (stats == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Plan info bar, e.g. "Basic Plan · 2/5 users · 3/3 projects"
            _PlanInfoBar(stats: stats),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Total Users', value: '${stats.userCount}', icon: Icons.group)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(label: 'Total Projects', value: '${stats.projectCount}', icon: Icons.folder)),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(label: 'My Open Tasks', value: '${stats.myOpenTasks}', icon: Icons.checklist),
          ],
        ],
      ),
    );
  }
}

class _PlanInfoBar extends StatelessWidget {
  final DashboardStats stats;
  const _PlanInfoBar({required this.stats});

  String _limit(int used, int? max) => max == null ? '$used/∞' : '$used/$max';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kPrimarySoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${stats.planName ?? 'No'} Plan · '
              '${_limit(stats.userCount, stats.maxUsers)} users · '
              '${_limit(stats.projectCount, stats.maxProjects)} projects',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
