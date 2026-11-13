import 'package:flutter/material.dart';

/// No navegador ou no tablet a tela é larga: o conteúdo fica centralizado
/// numa coluna confortável em vez de esticar de ponta a ponta.
class LarguraMaxima extends StatelessWidget {
  const LarguraMaxima({super.key, required this.child, this.largura = 720});

  final Widget child;
  final double largura;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largura),
          child: child,
        ),
      );
}
