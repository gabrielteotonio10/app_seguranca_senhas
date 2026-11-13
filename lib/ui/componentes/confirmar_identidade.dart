import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dados/biometria/biometria_servico.dart';
import '../../dominio/sessao_store.dart';
import 'painel_autenticacao.dart';
import 'selo_demo.dart';

/// Autenticação "de reforço": mesmo com o cofre aberto, ver, copiar ou
/// apagar uma senha exige provar de novo que é você. Devolve true só se
/// a identidade foi confirmada.
Future<bool> confirmarIdentidade(
  BuildContext context, {
  required String motivo,
  Future<StatusBiometria> Function()? acaoBiometrica,
  bool permitirPin = true,
}) async {
  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FolhaConfirmacao(
      motivo: motivo,
      acaoBiometrica: acaoBiometrica,
      permitirPin: permitirPin,
    ),
  );
  return confirmou ?? false;
}

class _FolhaConfirmacao extends StatelessWidget {
  const _FolhaConfirmacao({
    required this.motivo,
    required this.acaoBiometrica,
    required this.permitirPin,
  });

  final String motivo;
  final Future<StatusBiometria> Function()? acaoBiometrica;
  final bool permitirPin;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final modoDemo = context.watch<SessaoStore>().modoDemo;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Confirme que é você', style: textos.titleLarge),
          const SizedBox(height: 4),
          Text(
            motivo,
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          PainelAutenticacao(
            motivo: motivo,
            tamanhoScanner: 120,
            acaoBiometrica: acaoBiometrica,
            permitirPin: permitirPin,
            aoConfirmar: () => Navigator.pop(context, true),
          ),
          if (modoDemo) ...[
            const SizedBox(height: 12),
            const SeloDemo(),
          ],
        ],
      ),
    );
  }
}
