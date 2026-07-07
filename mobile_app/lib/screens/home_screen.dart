import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/projects_tab.dart';

/// Main screen after login: bottom navigation with 3 tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Projects', 'Profile'];
  // IndexedStack keeps each tab's state alive when switching.
  static const _tabs = [DashboardTab(), ProjectsTab(), ProfileTab()];

  @override
  void initState() {
    super.initState();
    // Load user + dashboard + projects once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
      context.read<ProjectProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slug = context.watch<AuthProvider>().slug ?? 'SaaS';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final badgeBg = isDark ? colors.surfaceContainer : colors.primaryContainer.withOpacity(0.4);
    final badgeBorder = colors.primary.withOpacity(0.12);
    final badgeText = colors.primary;
    final dividerColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _titles[_index],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.8,
              ),
            ),
            const Spacer(),
            // Modern Tenant Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: badgeText,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slug,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: badgeText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: dividerColor,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: dividerColor, width: 1),
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard_rounded, size: 22),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open_rounded, size: 22),
              selectedIcon: Icon(Icons.folder_rounded, size: 22),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              selectedIcon: Icon(Icons.person_rounded, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
