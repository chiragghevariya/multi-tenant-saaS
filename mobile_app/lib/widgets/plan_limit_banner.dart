import 'package:flutter/material.dart';
import 'upgrade_dialog.dart';

/// A usage banner:
///   - hidden when usage is below 80% (or the plan is unlimited)
///   - YELLOW warning at >= 80%
///   - RED bar with a lock icon at 100% (>= limit)
/// Always offers an "Upgrade Plan" button.
class PlanLimitBanner extends StatelessWidget {
  final int used;
  final int? max; // null = unlimited
  final String label; // e.g. "projects"

  const PlanLimitBanner({super.key, required this.used, required this.max, required this.label});

  @override
  Widget build(BuildContext context) {
    final max = this.max;
    if (max == null || max == 0) return const SizedBox.shrink(); // unlimited → nothing
    final ratio = used / max;
    if (ratio < 0.8) return const SizedBox.shrink(); // plenty of room left

    final atLimit = used >= max;
    final bg = atLimit ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7); // red / yellow
    final fg = atLimit ? const Color(0xFFB91C1C) : const Color(0xFF92400E);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(atLimit ? Icons.lock : Icons.warning_amber_rounded, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              atLimit
                  ? 'You have reached your $label limit ($used/$max).'
                  : 'You are nearing your $label limit ($used/$max).',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: () => showUpgradeDialog(context), child: const Text('Upgrade Plan')),
        ],
      ),
    );
  }
}
