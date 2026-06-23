import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// First-launch screen: ask the user for their company slug (e.g. "alphacorp").
class TenantSetupScreen extends StatefulWidget {
  const TenantSetupScreen({super.key});

  @override
  State<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends State<TenantSetupScreen> {
  final _slugController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final slug = _slugController.text.trim();
    if (slug.isEmpty) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().saveSlug(slug); // persist the slug
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter your company slug to get started.',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                controller: _slugController,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Company slug',
                  hintText: 'e.g. alphacorp',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _continue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_saving ? 'Saving…' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
