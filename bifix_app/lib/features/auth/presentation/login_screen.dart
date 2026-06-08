import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failures.dart';
import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(
      text: AppConfig.useMockApi ? 'demo@vikla.app' : '');
  final _password =
      TextEditingController(text: AppConfig.useMockApi ? 'demo1234' : '');
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) context.go(Routes.home);
    } on AppFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No se pudo iniciar sesión.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.pedal_bike, size: 64, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text('Bienvenido a Vikla',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Cuida el mantenimiento de tu e-bike',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _email,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _password,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          _loading ? null : () => context.push(Routes.register),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    if (AppConfig.useMockApi)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Modo demo: datos de ejemplo precargados',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
