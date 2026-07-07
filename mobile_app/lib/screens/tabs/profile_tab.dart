import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/theme_provider.dart';
import '../splash_screen.dart';

/// Tab 3 — user identity, tenant + plan info, plan limits, and logout.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    // Clear the whole stack and restart from the splash decision.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  double _ratio(int used, int? max) {
    if (max == null || max == 0) return 0.0;
    return (used / max).clamp(0.0, 1.0);
  }

  String _limitText(int used, int? max) {
    return (max == null || max == 0) ? '$used / ∞' : '$used / $max';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final stats = context.watch<ProjectProvider>().stats;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine role styling using M3 containers
    Color roleBg;
    Color roleFg;
    String roleLabel = user?.role ?? 'member';

    if (user?.role == 'tenant_admin') {
      roleBg = colors.primaryContainer;
      roleFg = colors.onPrimaryContainer;
      roleLabel = 'Workspace Admin';
    } else if (user?.role == 'manager') {
      roleBg = colors.secondaryContainer;
      roleFg = colors.onSecondaryContainer;
      roleLabel = 'Manager';
    } else {
      roleBg = colors.tertiaryContainer;
      roleFg = colors.onTertiaryContainer;
      roleLabel = 'Member';
    }

    final userRatio = stats == null ? 0.0 : _ratio(stats.userCount, stats.maxUsers);
    final projectRatio = stats == null ? 0.0 : _ratio(stats.projectCount, stats.maxProjects);
    final dividerColor = theme.dividerColor;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // User Identity Card
        Card(
          elevation: 0,
          color: colors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Premium Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(isDark ? 0.15 : 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (user != null && user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name
                Text(
                  user?.name ?? '—',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Email
                Text(
                  user?.email ?? '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: roleFg,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Workspace / Tenant Details Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'WORKSPACE DETAILS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Tenant Card
        Card(
          elevation: 0,
          color: colors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow('Company Workspace', auth.slug ?? '—', Icons.domain_rounded, context),
                Divider(color: dividerColor, height: 24),
                _infoRow('Subscription Plan', stats?.planName ?? '—', Icons.workspace_premium_rounded, context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Plan Usage Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PLAN RESOURCE USAGE',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Plan Limits Card
        Card(
          elevation: 0,
          color: colors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Users usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Team Member Seats',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          stats == null ? '—' : _limitText(stats.userCount, stats.maxUsers),
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
                        value: stats == null ? 0.0 : (stats.maxUsers == null || stats.maxUsers == 0 ? 1.0 : userRatio),
                        minHeight: 6,
                        backgroundColor: colors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Projects usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Project Slots',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          stats == null ? '—' : _limitText(stats.projectCount, stats.maxProjects),
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
                        value: stats == null ? 0.0 : (stats.maxProjects == null || stats.maxProjects == 0 ? 1.0 : projectRatio),
                        minHeight: 6,
                        backgroundColor: colors.surfaceContainerHigh,
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
        ),
        const SizedBox(height: 20),

        // Theme Settings Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'THEME SETTINGS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Theme Settings selector horizontal control
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _buildThemeSegment(
                  context: context,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  mode: ThemeMode.light,
                  selectedMode: context.watch<ThemeProvider>().themeMode,
                  onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeSegment(
                  context: context,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  mode: ThemeMode.system,
                  selectedMode: context.watch<ThemeProvider>().themeMode,
                  onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeSegment(
                  context: context,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  selectedMode: context.watch<ThemeProvider>().themeMode,
                  onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Logout Button
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: Icon(Icons.logout_rounded, color: colors.error, size: 18),
          label: Text('Sign Out', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.error.withOpacity(0.4), width: 1.5),
            backgroundColor: colors.error.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSegment({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode selectedMode,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = mode == selectedMode;

    final bg = isSelected ? colors.primary : Colors.transparent;
    final fg = isSelected ? colors.onPrimary : colors.primary;
    final border = isSelected ? Border.all(color: Colors.transparent) : Border.all(color: colors.primary.withOpacity(0.4), width: 1);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
