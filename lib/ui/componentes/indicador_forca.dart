import 'package:flutter/material.dart';

import '../../dominio/seguranca.dart';

/// Barra que mostra a força da senha enquanto a pessoa digita.
class IndicadorForca extends StatelessWidget {
  const IndicadorForca({super.key, required this.senha});

  final String senha;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final forca = avaliarForca(senha);
    final cor = switch (forca) {
      ForcaSenha.muitoFraca || ForcaSenha.fraca => cores.error,
      ForcaSenha.media => cores.tertiary,
      ForcaSenha.forte || ForcaSenha.muitoForte => cores.primary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: senha.isEmpty ? 0 : forca.progresso),
          duration: const Duration(milliseconds: 250),
          builder: (context, valor, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor,
              minHeight: 6,
              color: cor,
              backgroundColor: cores.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          senha.isEmpty ? 'Força da senha' : 'Força: ${forca.rotulo}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: senha.isEmpty ? cores.onSurfaceVariant : cor,
              ),
        ),
      ],
    );
  }
}
