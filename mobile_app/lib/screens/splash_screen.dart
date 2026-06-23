import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'tenant_setup_screen.dart';

/// Decides where to go on launch based on what's saved:
///   no slug            → TenantSetupScreen
///   slug but no token  → LoginScreen
///   slug + token       → HomeScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 600)); // brief splash
    final slug = await Storage.getSlug();
    final token = await Storage.getToken();
    if (!mounted) return;

    Widget next;
    if (slug == null || slug.isEmpty) {
      next = const TenantSetupScreen();
    } else if (token == null || token.isEmpty) {
      next = const LoginScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kPrimary,
      body: Center(
        child: Text(
          'SaaS',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
