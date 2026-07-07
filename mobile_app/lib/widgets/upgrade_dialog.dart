import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Opens a dialog listing the available plans (from the public /billing/plans
/// endpoint). A tenant_admin can tap "Upgrade" on a plan to start a Stripe
/// Checkout session — the app opens Stripe's hosted payment page in the browser.
/// Non-admins only see the plans plus a "contact your administrator" note.
Future<void> showUpgradeDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _UpgradeDialog(),
  );
}

class _UpgradeDialog extends StatefulWidget {
  const _UpgradeDialog();

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  List<dynamic>? _plans;
  String? _error;      // load error (plans couldn't be fetched)
  String? _actionError; // checkout error (shown at the bottom)
  int? _busyPlanId;     // the plan whose "Upgrade" is currently in progress

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.dio.get('/billing/plans');
      if (mounted) setState(() => _plans = res.data['data'] as List);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load plans.');
    }
  }

  /// Start a plan change for [planId].
  Future<void> _upgrade(int planId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busyPlanId = planId;
      _actionError = null;
    });

    try {
      final res = await ApiService.instance.dio
          .post('/billing/checkout', data: {'plan_id': planId});
      final data = res.data['data'] as Map<String, dynamic>?;

      if (data?['swapped'] == true) {
        navigator.pop();
        messenger.showSnackBar(const SnackBar(
          content: Text('Plan changed. Pull down to refresh.'),
        ));
        return;
      }

      final url = data?['checkout_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No checkout URL returned.');
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('Could not open the browser.');

      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Complete payment in your browser, then pull down to refresh.'),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = apiError(e, 'Could not start checkout.'));
      }
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  String _price(dynamic cents) => '\$${((cents ?? 0) / 100).round()}';
  String _limit(dynamic v) => v == null ? 'Unlimited' : '$v';

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.user?.role == 'tenant_admin';
    final stats = context.watch<ProjectProvider>().stats;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryThemeColor = colors.primary;
    final titleColor = colors.onSurface;
    final subtitleColor = colors.onSurfaceVariant;
    final cardBorderDefault = colors.outlineVariant;
    
    // Warning banner styling using status Warning colors
    Color warnBg;
    Color warnText;
    Color warnBorder;

    if (isDark) {
      warnBg = const Color(0xFF2C200A); // Dark Amber
      warnText = const Color(0xFFFBBF24); // Amber 400
      warnBorder = kWarning.withOpacity(0.3);
    } else {
      warnBg = kWarningSoft; // Soft Amber
      warnText = const Color(0xFFD97706); // Amber 600 (darker for contrast on light bg)
      warnBorder = kWarning.withOpacity(0.2);
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: primaryThemeColor, size: 24),
          const SizedBox(width: 8),
          const Text('Upgrade Your Plan'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      content: SizedBox(
        width: 340,
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, color: colors.error, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _plans == null
                ? SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._plans!.map((p) {
                          final id = p['id'] as int;
                          final name = p['name'] as String;
                          final busy = _busyPlanId == id;
                          
                          // Check if it's the current active plan
                          final isCurrent = stats != null &&
                              stats.planName?.toLowerCase() == name.toLowerCase();

                          // Dynamic card colors
                          Color planCardBg;
                          Color planCardBorder;
                          Color planNameColor;

                          if (isCurrent) {
                            planCardBg = colors.primaryContainer.withOpacity(0.25);
                            planCardBorder = primaryThemeColor;
                            planNameColor = primaryThemeColor;
                          } else {
                            planCardBg = colors.surfaceContainerLow;
                            planCardBorder = cardBorderDefault;
                            planNameColor = titleColor;
                          }

                          final selectBtnBg = isCurrent
                              ? colors.surfaceContainerHighest
                              : primaryThemeColor;
                          final selectBtnFg = isCurrent
                              ? colors.onSurfaceVariant
                              : colors.onPrimary;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: planCardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: planCardBorder,
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: planNameColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_price(p['price'])}/mo',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Limits: ${_limit(p['max_users'])} users · ${_limit(p['max_projects'])} projects',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor, fontSize: 13),
                                ),
                                if (isAdmin || isCurrent) ...[
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: selectBtnBg,
                                      foregroundColor: selectBtnFg,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: (isCurrent || _busyPlanId != null) ? null : () => _upgrade(id),
                                    child: busy
                                        ? SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2, 
                                              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                                            ),
                                          )
                                        : Text(isCurrent ? 'Current Plan' : 'Select Plan'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        if (!isAdmin)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: warnBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: warnBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: warnText, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Contact your administrator to upgrade the plan.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: warnText,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_actionError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _actionError!,
                              style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
