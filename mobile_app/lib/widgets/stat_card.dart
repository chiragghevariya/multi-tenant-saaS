import 'package:flutter/material.dart';

/// A small metric card used on the Dashboard tab.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = colors.surfaceContainerLowest;
    final cardBorder = colors.outlineVariant;
    final iconBg = colors.primaryContainer;
    final iconFg = colors.primary;
    final titleColor = colors.onSurface;
    final subtitleColor = colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(height: 16),
          // Value metric
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: titleColor,
              letterSpacing: -1.0,
              fontSize: 28, // Maintain layout proportion
            ),
          ),
          const SizedBox(height: 4),
          // Label text
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
