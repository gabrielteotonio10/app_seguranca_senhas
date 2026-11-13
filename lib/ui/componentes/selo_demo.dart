import 'package:flutter/material.dart';

/// Aviso visível de que o Face ID está sendo simulado. Segurança de
/// verdade não esconde do usuário quando está desligada.
class SeloDemo extends StatelessWidget {
  const SeloDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cores.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 16, color: cores.onTertiaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Modo demonstração: Face ID simulado',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cores.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
