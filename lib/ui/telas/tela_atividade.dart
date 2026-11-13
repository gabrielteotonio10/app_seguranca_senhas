import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/atividade_store.dart';
import '../../dominio/registro_acesso.dart';
import '../componentes/confirmar_identidade.dart';
import '../componentes/largura_maxima.dart';
import '../textos.dart';

/// Auditoria: toda tentativa de acesso, liberada ou negada.
class TelaAtividade extends StatelessWidget {
  const TelaAtividade({super.key});

  Future<void> _limpar(BuildContext context) async {
    final atividade = context.read<AtividadeStore>();
    final querLimpar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Limpar o histórico?'),
        content: const Text(
          'Por segurança, apagar o rastro de acessos também exige confirmar '
          'sua identidade. Um invasor não pode esconder o que fez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (querLimpar != true || !context.mounted) return;
    if (!await confirmarIdentidade(context, motivo: 'Limpar o histórico de acessos')) return;
    await atividade.apagarTudo();
  }

  @override
  Widget build(BuildContext context) {
    final atividade = context.watch<AtividadeStore>();
    if (atividade.carregando) return const Center(child: CircularProgressIndicator());
    final registros = atividade.registros;
    final cores = Theme.of(context).colorScheme;

    return LarguraMaxima(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _Indicador(
                    rotulo: 'Tentativas',
                    valor: registros.length,
                    icone: Icons.touch_app_outlined,
                    cor: cores.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Indicador(
                    rotulo: 'Liberadas',
                    valor: atividade.liberados,
                    icone: Icons.lock_open,
                    cor: cores.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Indicador(
                    rotulo: 'Negadas',
                    valor: atividade.negados,
                    icone: Icons.block,
                    cor: cores.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text('Histórico', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: registros.isEmpty ? null : () => _limpar(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: registros.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum acesso registrado ainda.',
                      style: TextStyle(color: cores.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: registros.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) => _ItemRegistro(registros[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  final String rotulo;
  final int valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icone, color: cor),
            const SizedBox(height: 6),
            Text('$valor', style: textos.headlineSmall?.copyWith(color: cor)),
            Text(rotulo, style: textos.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ItemRegistro extends StatelessWidget {
  const _ItemRegistro(this.registro);

  final RegistroAcesso registro;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final r = registro;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: r.sucesso ? cores.primaryContainer : cores.errorContainer,
        foregroundColor: r.sucesso ? cores.onPrimaryContainer : cores.onErrorContainer,
        child: Icon(r.metodo == MetodoAcesso.biometria ? Icons.face : Icons.dialpad),
      ),
      title: Text(r.motivo),
      subtitle: Text(
        '${r.sucesso ? 'Liberado' : 'Negado'} · ${r.metodo.rotulo} · '
        '${formatarDataHora(r.momento)}',
      ),
    );
  }
}
