import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<String?> showPasswordResetDialog(
  BuildContext context, {
  String initialIdentifier = '',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PasswordResetDialog(
      initialIdentifier: initialIdentifier,
    ),
  );
}

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    super.key,
    required this.initialIdentifier,
  });

  final String initialIdentifier;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

enum _PasswordResetStep { request, confirm, sent }

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmFormKey = GlobalKey<FormState>();
  final TextEditingController _identifierController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _PasswordResetStep _step = _PasswordResetStep.request;
  bool _isLoading = false;
  String? _errorText;
  String? _statusText;
  String? _resetUid;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _identifierController.text = widget.initialIdentifier.trim();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
      _statusText = null;
    });

    try {
      final challenge = await context.read<AuthService>().requestPasswordReset(
            identifier: _identifierController.text,
          );
      if (!mounted) return;

      if (challenge.canResetNow) {
        setState(() {
          _resetUid = challenge.uid;
          _resetToken = challenge.token;
          _statusText = challenge.message;
          _step = _PasswordResetStep.confirm;
        });
      } else {
        setState(() {
          _statusText = challenge.message;
          _step = _PasswordResetStep.sent;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmReset() async {
    if (!(_confirmFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_resetUid == null || _resetToken == null) {
      setState(() {
        _errorText = 'Sıfırlama bilgileri alınamadı.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await context.read<AuthService>().confirmPasswordReset(
            uid: _resetUid!,
            token: _resetToken!,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(_identifierController.text.trim());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goBackToRequestStep() {
    setState(() {
      _step = _PasswordResetStep.request;
      _errorText = null;
      _statusText = null;
      _resetUid = null;
      _resetToken = null;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String get _titleText {
    switch (_step) {
      case _PasswordResetStep.request:
        return 'Şifremi Unuttum';
      case _PasswordResetStep.confirm:
        return 'Yeni Şifre Belirle';
      case _PasswordResetStep.sent:
        return 'Sıfırlama Hazır';
    }
  }

  Widget _buildNotice({
    required Color backgroundColor,
    required Color iconColor,
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStep(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'E-posta adresini ya da kullanıcı adını gir. Uygulama sana yeni bir şifre belirlemen için güvenli bir sıfırlama akışı hazırlayacak.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-posta / Kullanıcı adı',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen e-posta ya da kullanıcı adını gir.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _requestReset(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _confirmFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Yeni şifreni belirle. Şifreyi değiştirdikten sonra giriş ekranında tekrar oturum açabilirsin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Yeni şifre',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Yeni şifre zorunlu.';
              }
              if (value.length < 8) {
                return 'Şifre en az 8 karakter olmalı.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Yeni şifre tekrar',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarını gir.';
              }
              if (value != _newPasswordController.text) {
                return 'Şifreler eşleşmiyor.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _confirmReset(),
          ),
        ],
      ),
    );
  }

  Widget _buildSentStep(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sıfırlama adımı tamamlandı. Şimdi giriş ekranına dönüp yeni şifrenle oturum açabilirsin.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final isRequestStep = _step == _PasswordResetStep.request;
    final isConfirmStep = _step == _PasswordResetStep.confirm;

    if (_step == _PasswordResetStep.sent) {
      return [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Tamam'),
        ),
      ];
    }

    return [
      if (isConfirmStep)
        TextButton(
          onPressed: _isLoading ? null : _goBackToRequestStep,
          child: const Text('Geri'),
        )
      else
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      FilledButton(
        onPressed: _isLoading
            ? null
            : isRequestStep
                ? _requestReset
                : _confirmReset,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(isRequestStep ? 'Bağlantı Hazırla' : 'Şifreyi Güncelle'),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppTheme.deepTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titleText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorText != null) ...[
              _buildNotice(
                backgroundColor: const Color(0xFFFFECEC),
                iconColor: const Color(0xFFB42318),
                message: _errorText!,
                icon: Icons.error_outline_rounded,
              ),
              const SizedBox(height: 14),
            ],
            if (_statusText != null) ...[
              _buildNotice(
                backgroundColor: AppTheme.paleMint,
                iconColor: AppTheme.deepTeal,
                message: _statusText!,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 14),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                _PasswordResetStep.request => _buildRequestStep(context),
                _PasswordResetStep.confirm => _buildConfirmStep(context),
                _PasswordResetStep.sent => _buildSentStep(context),
              },
            ),
          ],
        ),
      ),
      actions: _buildActions(context),
    );
  }
}
