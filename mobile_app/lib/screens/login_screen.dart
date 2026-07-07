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
  bool _obscureText = true;

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
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      return;
    }
    final ok = await context.read<AuthProvider>().login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _changeCompany() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TenantSetupScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final infoCardBg = isDark ? colors.surfaceContainer : colors.primaryContainer.withOpacity(0.4);
    final infoCardBorder = colors.primary.withOpacity(0.12);
    final infoCardTextColor = colors.onSurfaceVariant;
    final infoCardValueColor = colors.primary;
    final iconColor = colors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo branding
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(8, -8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.onPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.onPrimary.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.bubble_chart_rounded,
                          color: colors.onPrimary,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Company Information Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: infoCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: infoCardBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.domain_rounded, color: infoCardValueColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Workspace: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: infoCardTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _slug ?? '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: infoCardValueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@company.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded, color: iconColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _password,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: iconColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: iconColor,
                                ),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Error Alert box
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colors.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: colors.onErrorContainer, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colors.onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          FilledButton(
                            onPressed: auth.loading ? null : _login,
                            child: auth.loading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Change company link
                  TextButton.icon(
                    onPressed: _changeCompany,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Change Workspace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
