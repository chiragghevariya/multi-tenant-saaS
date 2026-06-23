import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Opens a simple dialog listing the available plans (from the public
/// /billing/plans endpoint). Informational only — real checkout is on the web.
Future<void> showUpgradeDialog(BuildContext context) {
  return showDialog(context: context, builder: (_) => const _UpgradeDialog());
}

class _UpgradeDialog extends StatefulWidget {
  const _UpgradeDialog();

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  List<dynamic>? _plans;
  String? _error;

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

  String _price(dynamic cents) => '\$${((cents ?? 0) / 100).round()}';
  String _limit(dynamic v) => v == null ? 'Unlimited' : '$v';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upgrade your plan'),
      content: SizedBox(
        width: double.maxFinite,
        child: _error != null
            ? Text(_error!)
            : _plans == null
                ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _plans!.map((p) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${p['name']} — ${_price(p['price'])}/mo'),
                        subtitle: Text(
                          '${_limit(p['max_users'])} users · ${_limit(p['max_projects'])} projects',
                        ),
                      );
                    }).toList(),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
