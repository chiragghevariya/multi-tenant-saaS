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
  String? _validationError;

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final slug = _slugController.text.trim();
    if (slug.isEmpty) {
      setState(() => _validationError = 'Company slug is required');
      return;
    }
    
    setState(() {
      _validationError = null;
      _saving = true;
    });

    await context.read<AuthProvider>().saveSlug(slug); // persist the slug
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  // Branded mini logo
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
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withOpacity(isDark ? 0.15 : 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
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
                  const SizedBox(height: 32),

                  // Header
                  Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your company slug to connect to your workspace.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Card containing form
                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _slugController,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            onChanged: (val) {
                              if (_validationError != null && val.trim().isNotEmpty) {
                                setState(() => _validationError = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Workspace Slug',
                              hintText: 'e.g. alphacorp',
                              prefixIcon: Icon(Icons.business_rounded, color: colors.onSurfaceVariant),
                              errorText: _validationError,
                            ),
                            onSubmitted: (_) => _continue(),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _saving ? null : _continue,
                            child: _saving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Continue'),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Need help? Contact your administrator or IT support to obtain your company workspace credentials.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
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
