import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/cofre_store.dart';
import '../../dominio/credencial.dart';
import '../../dominio/sessao_store.dart';
import '../componentes/largura_maxima.dart';
import 'tela_detalhe_credencial.dart';

/// Lista de contas guardadas. Só mostra serviço e usuário: nenhuma senha
/// é lida para desenhar esta tela.
class TelaCofre extends StatelessWidget {
  const TelaCofre({super.key});

  @override
  Widget build(BuildContext context) {
    final cofre = context.watch<CofreStore>();
    if (cofre.carregando) return const Center(child: CircularProgressIndicator());
    final credenciais = cofre.credenciais;

    return LarguraMaxima(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _CartaoProtecao(total: credenciais.length),
          ),
          Expanded(
            child: credenciais.isEmpty
                ? const _CofreVazio()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                    itemCount: credenciais.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) => _ItemCredencial(credenciais[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemCredencial extends StatelessWidget {
  const _ItemCredencial(this.credencial);

  final Credencial credencial;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cores.secondaryContainer,
        foregroundColor: cores.onSecondaryContainer,
        child: Text(credencial.inicial),
      ),
      title: Text(credencial.servico),
      subtitle: Text(credencial.usuario, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      // A tela de detalhe depende de um item: vai com push, dado no construtor.
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TelaDetalheCredencial(credencial: credencial)),
      ),
    );
  }
}

class _CartaoProtecao extends StatelessWidget {
  const _CartaoProtecao({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final metodo = sessao.usarBiometria ? sessao.nomeBiometria : 'PIN';

    return Card(
      color: cores.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.verified_user, size: 36, color: cores.onPrimaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protegido por $metodo',
                    style: textos.titleMedium?.copyWith(color: cores.onPrimaryContainer),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 1
                        ? '1 senha guardada com criptografia do sistema'
                        : '$total senhas guardadas com criptografia do sistema',
                    style: textos.bodySmall?.copyWith(color: cores.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CofreVazio extends StatelessWidget {
  const _CofreVazio();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_outlined, size: 64, color: cores.outline),
            const SizedBox(height: 16),
            Text('Seu cofre está vazio', style: textos.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Toque em "Nova senha" para guardar a primeira conta.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
