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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _decideNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _decideNextScreen() async {
    // Extended splash time slightly to allow fade animation to display elegantly
    await Future.delayed(const Duration(milliseconds: 1600));
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

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => next,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kSlate950, kSlate900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium custom branding logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    // Glassmorphic accent overlay
                    Transform.translate(
                      offset: const Offset(12, -12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.bubble_chart_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'SaaS Mobile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Multi-Tenant SaaS Suite',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 64),
                // Sleek, minimal loading indicator
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

