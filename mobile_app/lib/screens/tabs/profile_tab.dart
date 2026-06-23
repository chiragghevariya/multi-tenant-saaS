import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme.dart';
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

  String _limit(int used, int? max) => max == null ? '$used / ∞' : '$used / $max';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final stats = context.watch<ProjectProvider>().stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        // Avatar with the user's first initial.
        CircleAvatar(
          radius: 32,
          backgroundColor: kPrimary,
          child: Text(
            (user != null && user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(user?.name ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        // Role badge.
        Center(child: Chip(label: Text(user?.role ?? 'member'), backgroundColor: kPrimarySoft)),
        const SizedBox(height: 24),

        // Tenant + plan info.
        _infoRow('Company', auth.slug ?? '—'),
        _infoRow('Plan', stats?.planName ?? '—'),
        _infoRow('Users', stats == null ? '—' : _limit(stats.userCount, stats.maxUsers)),
        _infoRow('Projects', stats == null ? '—' : _limit(stats.projectCount, stats.maxProjects)),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
