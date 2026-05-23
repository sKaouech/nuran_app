import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/kids_mode_provider.dart';

/// Saisie/définition du PIN parental.
/// - Si `mode == setup` : on définit un nouveau PIN (4 chiffres)
/// - Si `mode == verify` : on vérifie le PIN existant pour sortir du mode kids
enum _PinMode { setup, verify }

class ParentPinPage extends ConsumerStatefulWidget {
  const ParentPinPage._({required this.modeIsSetup, this.onSuccess});

  factory ParentPinPage.setup({VoidCallback? onSuccess}) =>
      ParentPinPage._(modeIsSetup: true, onSuccess: onSuccess);

  factory ParentPinPage.verify({VoidCallback? onSuccess}) =>
      ParentPinPage._(modeIsSetup: false, onSuccess: onSuccess);

  final bool modeIsSetup;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<ParentPinPage> createState() => _ParentPinPageState();
}

class _ParentPinPageState extends ConsumerState<ParentPinPage> {
  final _controller = TextEditingController();
  String? _error;

  _PinMode get _mode => widget.modeIsSetup ? _PinMode.setup : _PinMode.verify;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text;
    if (pin.length != 4) {
      setState(() => _error = 'Le PIN doit faire 4 chiffres');
      return;
    }
    if (_mode == _PinMode.setup) {
      await ref.read(kidsModeProvider.notifier).setPin(pin);
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    } else {
      final ok =
          await ref.read(kidsModeProvider.notifier).tryExitKidsMode(pin);
      if (!ok) {
        setState(() => _error = 'PIN incorrect');
        _controller.clear();
        return;
      }
      if (mounted) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _mode == _PinMode.setup
        ? 'Définir un PIN parental'
        : 'PIN parental requis';
    final subtitle = _mode == _PinMode.setup
        ? '4 chiffres pour protéger les réglages quand votre enfant utilise l\'app.'
        : 'Pour sortir du mode enfant, entrez votre PIN à 4 chiffres.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineMedium?.copyWith(
                letterSpacing: 16,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  letterSpacing: 16,
                ),
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_mode == _PinMode.setup
                    ? 'Définir le PIN'
                    : 'Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
