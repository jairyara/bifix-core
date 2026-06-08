import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/riding_mode.dart';

/// Centralized framing (icon, accent, copy) for each [RidingMode] so onboarding,
/// the dashboard badge and the profile switcher stay consistent.
///
///  - estimation → "Privacidad": we don't track your location.
///  - tracking   → "Asistente": Vikla records your rides for you.
class ModeFraming {
  const ModeFraming({
    required this.icon,
    required this.accent,
    required this.badge,
    required this.title,
    required this.tagline,
    required this.bullets,
    this.footnote,
  });

  final IconData icon;
  final Color accent;
  final String badge;
  final String title;
  final String tagline;
  final List<String> bullets;
  final String? footnote;

  static const _privacyAccent = AppTheme.verdeExito; // Verde Éxito
  static const _assistantAccent = AppTheme.azulDatos; // Azul Datos

  static ModeFraming of(RidingMode mode) {
    switch (mode) {
      case RidingMode.estimation:
        return const ModeFraming(
          icon: Icons.shield_outlined,
          accent: _privacyAccent,
          badge: 'Privacidad',
          title: 'Estimación',
          tagline: 'Tu privacidad primero. No rastreamos tu ubicación: '
              'tú nos dices cuánto ruedas.',
          bullets: [
            'Sin acceso al GPS ni permisos de ubicación',
            'Defines un promedio diario y tus días de uso',
            'Sumas salidas puntuales cuando quieras',
          ],
        );
      case RidingMode.tracking:
        return const ModeFraming(
          icon: Icons.auto_awesome,
          accent: _assistantAccent,
          badge: 'Asistente',
          title: 'Tracking',
          tagline: 'Deja que Vikla lo haga por ti. Registra tus recorridos '
              'automáticamente y mantén tu odómetro al día.',
          bullets: [
            'Inicia y detén; Vikla anota la distancia',
            'Menos registro manual, más precisión',
            'Ideal si ruedas distancias variables',
          ],
          footnote: 'Captura automática por GPS muy pronto.',
        );
    }
  }
}
