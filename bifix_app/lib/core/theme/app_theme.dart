import 'package:flutter/material.dart';

/// Visual identity for Vikla.
///
/// Brand palette + typography (Montserrat for headings/buttons, DM Sans for
/// body). Both light and dark schemes are derived from the brand colors.
class AppTheme {
  const AppTheme._();

  // --- Brand palette -------------------------------------------------------
  /// Color principal · símbolo · íconos.
  static const Color tealVikla = Color(0xFF32837D);

  /// Hover · estados activos (y primary en modo oscuro).
  static const Color tealClaro = Color(0xFF4AADA8);

  /// Wordmark · textos · fondos oscuros.
  static const Color negroAzulado = Color(0xFF142129);

  /// Fondos claros · tarjetas · fondo app.
  static const Color blancoNiebla = Color(0xFFF4F7F7);

  /// Estados OK · confirmaciones.
  static const Color verdeExito = Color(0xFF2DB87A);

  /// Alertas de mantenimiento · avisos.
  static const Color ambarAlerta = Color(0xFFE8A020);

  /// Gráficas · estadísticas · mapas.
  static const Color azulDatos = Color(0xFF1A3A5C);

  // --- Typography ----------------------------------------------------------
  static const String _heading = 'Montserrat'; // títulos, botones, wordmark
  static const String _body = 'DMSans'; // cuerpo, descripciones, metadatos

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: tealVikla,
      brightness: Brightness.light,
    ).copyWith(
      primary: tealVikla,
      secondary: tealClaro,
      tertiary: azulDatos,
      surface: blancoNiebla,
    );
    return _base(scheme);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: tealVikla,
      brightness: Brightness.dark,
    ).copyWith(
      primary: tealClaro,
      secondary: tealClaro,
      tertiary: azulDatos,
      surface: negroAzulado,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: _body,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// DM Sans across the board, with Montserrat applied to display/headline/
  /// title roles and button labels (`labelLarge`).
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = (scheme.brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(fontFamily: _body);

    TextStyle h(TextStyle? s, FontWeight w) =>
        (s ?? const TextStyle()).copyWith(fontFamily: _heading, fontWeight: w);

    return base.copyWith(
      displayLarge: h(base.displayLarge, FontWeight.w900),
      displayMedium: h(base.displayMedium, FontWeight.w900),
      displaySmall: h(base.displaySmall, FontWeight.w700),
      headlineLarge: h(base.headlineLarge, FontWeight.w700),
      headlineMedium: h(base.headlineMedium, FontWeight.w700),
      headlineSmall: h(base.headlineSmall, FontWeight.w700),
      titleLarge: h(base.titleLarge, FontWeight.w700),
      titleMedium: h(base.titleMedium, FontWeight.w600),
      titleSmall: h(base.titleSmall, FontWeight.w600),
      labelLarge: h(base.labelLarge, FontWeight.w600), // button text
    );
  }
}
