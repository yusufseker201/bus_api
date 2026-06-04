import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/registration_dialog.dart';
import '../widgets/password_reset_dialog.dart';
import 'main_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _queuedProfileRefresh = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SessionState, AppState>(
      builder: (context, session, state, _) {
        if (!session.isReady) {
          _queuedProfileRefresh = false;
          return const _StartupLoadingScaffold();
        }

        if (!session.isLoggedIn) {
          _queuedProfileRefresh = false;
        } else if (!state.isLoading &&
            state.profile == null &&
            !_queuedProfileRefresh) {
          _queuedProfileRefresh = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AppState>().loadInitialData();
            }
          });
        } else if (state.profile != null) {
          _queuedProfileRefresh = false;
        }

        return const MainScreen();
      },
    );
  }
}

class _StartupLoadingScaffold extends StatelessWidget {
  const _StartupLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.shell,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 18),
                Text(
                  'Uygulama hazırlanıyor',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oturum bilgisi ve canlı veri akışı yükleniyor.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleManualLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await context.read<SessionState>().login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      await context.read<AppState>().loadInitialData();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openPasswordResetDialog() async {
    FocusScope.of(context).unfocus();
    final resetIdentifier = await showPasswordResetDialog(
      context,
      initialIdentifier: _emailController.text,
    );

    if (!mounted || resetIdentifier == null) {
      return;
    }

    setState(() {
      _emailController.text = resetIdentifier;
      _passwordController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Şifren güncellendi. Yeni şifrenle giriş yapabilirsin.',
        ),
      ),
    );
  }

  Future<void> _openRegistrationDialog() async {
    FocusScope.of(context).unfocus();
    final registrationResult = await showRegistrationDialog(
      context,
      initialEmail: _emailController.text,
    );

    if (!mounted || registrationResult == null) {
      return;
    }

    setState(() {
      _emailController.text = registrationResult.email;
      _passwordController.clear();
      _isLoading = true;
    });

    try {
      await context.read<SessionState>().login(
            email: registrationResult.email,
            password: registrationResult.password,
          );
      if (!mounted) return;
      await context.read<AppState>().loadInitialData();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.shell,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F5B57),
              Color(0xFF237C72),
              Color(0xFFF7FCFB),
            ],
            stops: [0.0, 0.26, 0.26],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.mint,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: AppTheme.deepTeal,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giriş Yap',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Canlı rapor göndermek ve profil puanını görmek için oturum aç.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-posta / Kullanıcı adı',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.paleMint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_outlined,
                                color: AppTheme.deepTeal),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Giriş yaptıktan sonra yoğunluk bildirimlerin profil puanına işlenir ve canlı bildirim listesinde görünür.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.deepTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleManualLogin,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Devam Et'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isLoading ? null : _openRegistrationDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Kayıt Ol'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            _isLoading ? null : _openPasswordResetDialog,
                        child: const Text('Şifremi Unuttum?'),
                      ),
                      const SizedBox(height: 2),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Panele geri dön'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
