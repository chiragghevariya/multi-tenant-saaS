import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/stat_card.dart';

/// Tab 1 — stat cards + a plan info bar.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final stats = provider.stats;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: provider.loadAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Greeting Section
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${user?.name.split(" ").first ?? 'User'} 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is a quick overview of your workspace.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (stats == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
              child: Center(
                child: provider.error != null
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded, color: colors.error, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Sync Connection Failed',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: provider.loadAll,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Try Again'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
              ),
            )
          else ...[
            // Premium Plan Progress Card
            _PlanInfoBar(stats: stats),
            const SizedBox(height: 20),
            
            // Grid section for stats
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Team Members',
                    value: '${stats.userCount}',
                    icon: Icons.group_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Total Projects',
                    value: '${stats.projectCount}',
                    icon: Icons.folder_open_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatCard(
              label: 'My Open Tasks',
              value: '${stats.myOpenTasks}',
              icon: Icons.assignment_turned_in_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanInfoBar extends StatelessWidget {
  final DashboardStats stats;
  const _PlanInfoBar({required this.stats});

  double _ratio(int used, int? max) {
    if (max == null || max == 0) return 0.0;
    return (used / max).clamp(0.0, 1.0);
  }

  String _limitText(int used, int? max) {
    return (max == null || max == 0) ? '$used / ∞' : '$used / $max';
  }

  @override
  Widget build(BuildContext context) {
    final userRatio = _ratio(stats.userCount, stats.maxUsers);
    final projectRatio = _ratio(stats.projectCount, stats.maxProjects);
    
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dividerColor = theme.dividerColor;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: colors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${stats.planName ?? 'Standard'} Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: dividerColor, height: 28),
            
            // User Usage Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Users Seats Used',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _limitText(stats.userCount, stats.maxUsers),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.maxUsers == null || stats.maxUsers == 0 ? 1.0 : userRatio,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Usage Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Slots Used',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _limitText(stats.projectCount, stats.maxProjects),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.maxProjects == null || stats.maxProjects == 0 ? 1.0 : projectRatio,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      projectRatio >= 1.0 ? colors.error : (projectRatio >= 0.8 ? colors.error.withOpacity(0.5) : colors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
