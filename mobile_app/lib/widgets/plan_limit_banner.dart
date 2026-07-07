import 'package:flutter/material.dart';
import '../theme.dart';
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
    final maxVal = max;
    if (maxVal == null || maxVal == 0) return const SizedBox.shrink(); // unlimited → nothing
    final ratio = used / maxVal;
    if (ratio < 0.8) return const SizedBox.shrink(); // plenty of room left

    final atLimit = used >= maxVal;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color border;
    Color fg;
    Color titleColor = colors.onSurface;

    if (atLimit) {
      if (isDark) {
        bg = const Color(0xFF2D1A1A); // Dark Red
        border = kError.withOpacity(0.3);
        fg = const Color(0xFFF87171); // Red 400
      } else {
        bg = kErrorSoft; // Soft Red
        border = kError.withOpacity(0.2);
        fg = kError; // Red 500
      }
    } else {
      if (isDark) {
        bg = const Color(0xFF2C200A); // Dark Amber
        border = kWarning.withOpacity(0.3);
        fg = const Color(0xFFFBBF24); // Amber 400
      } else {
        bg = kWarningSoft; // Soft Amber
        border = kWarning.withOpacity(0.2);
        fg = const Color(0xFFD97706); // Amber 600
      }
    }

    final upgradeButtonColor = colors.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(atLimit ? Icons.lock_outline_rounded : Icons.info_outline_rounded, color: fg, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  atLimit
                      ? 'Reached your $label limit ($used/$maxVal)'
                      : 'Nearing your $label limit ($used/$maxVal)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: upgradeButtonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => showUpgradeDialog(context),
                child: const Text('Upgrade'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Clean progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: fg.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
        ],
      ),
    );
  }
}
