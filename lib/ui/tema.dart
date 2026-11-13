import 'package:flutter/material.dart';

/// Uma cor semente define a identidade inteira (Aula 04). As telas pedem a
/// cor pelo papel (primary, error...), nunca por Colors.algumaCoisa, e o
/// modo escuro funciona de graça.
const _semente = Color(0xFF00695C); // verde-petróleo: "seguro", "liberado"

ThemeData criarTema(Brightness brilho) {
  final cores = ColorScheme.fromSeed(seedColor: _semente, brightness: brilho);
  return ThemeData(
    colorScheme: cores,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: cores.surface,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cores.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cores.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: false,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
