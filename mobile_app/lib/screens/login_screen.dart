import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'tenant_setup_screen.dart';

/// Tenant user login. Sends POST /tenant/auth/login (the X-Tenant header is
/// added automatically by the Dio interceptor).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _slug;

  @override
  void initState() {
    super.initState();
    // Show which company we're signing into.
    context.read<AuthProvider>().currentSlug().then((s) {
      if (mounted) setState(() => _slug = s);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final ok = await context.read<AuthProvider>().login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _changeCompany() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TenantSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the button shows a spinner / errors reactively.
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sign in', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Company: ${_slug ?? '—'}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),
              if (auth.error != null)
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: auth.loading ? null : _login,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(auth.loading ? 'Signing in…' : 'Sign in'),
                ),
              ),
              TextButton(onPressed: _changeCompany, child: const Text('Change company')),
            ],
          ),
        ),
      ),
    );
  }
}
