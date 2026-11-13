import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/atividade_store.dart';
import '../../dominio/cofre_store.dart';
import '../../dominio/sessao_store.dart';
import '../componentes/confirmar_identidade.dart';
import '../componentes/largura_maxima.dart';
import '../rotas.dart';

class TelaAjustes extends StatelessWidget {
  const TelaAjustes({super.key});

  static const _opcoesBloqueio = {
    0: 'Imediato',
    30: '30 segundos',
    60: '1 minuto',
    300: '5 minutos',
  };

  Future<void> _alternarBiometria(BuildContext context, bool ativar) async {
    final sessao = context.read<SessaoStore>();
    final mensageiro = ScaffoldMessenger.of(context);

    if (!ativar) {
      // Desligar uma proteção também exige provar quem é.
      final ok = await confirmarIdentidade(
        context,
        motivo: 'Desativar o desbloqueio por ${sessao.nomeBiometria}',
      );
      if (ok) await sessao.desativarBiometria();
      return;
    }

    // Para ligar, a biometria precisa funcionar agora (sem PIN como atalho).
    final ok = await confirmarIdentidade(
      context,
      motivo: 'Ativar o desbloqueio por ${sessao.nomeBiometria}',
      acaoBiometrica: sessao.ativarBiometria,
      permitirPin: false,
    );
    mensageiro.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Desbloqueio por ${sessao.nomeBiometria} ativado'
          : 'A biometria não foi ativada. Tente de novo quando quiser.'),
    ));
  }

  Future<void> _apagarTudo(BuildContext context) async {
    final sessao = context.read<SessaoStore>();
    final cofre = context.read<CofreStore>();
    final atividade = context.read<AtividadeStore>();
    final navegador = Navigator.of(context);

    final querApagar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Senhas, PIN, histórico e ajustes serão removidos deste aparelho. '
          'Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
              foregroundColor: Theme.of(contexto).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (querApagar != true || !context.mounted) return;
    if (!await confirmarIdentidade(context, motivo: 'Apagar todos os dados do cofre')) return;

    await cofre.apagarTudo();
    await atividade.apagarTudo();
    await sessao.apagarTudo();
    navegador.pushNamedAndRemoveUntil(Rotas.abertura, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoStore>();
    final cores = Theme.of(context).colorScheme;

    return LarguraMaxima(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _TituloSecao('Desbloqueio'),
          SwitchListTile(
            secondary: const Icon(Icons.face_outlined),
            title: Text('Usar ${sessao.nomeBiometria}'),
            subtitle: Text(
              sessao.biometriaDisponivel
                  ? 'Para abrir o cofre e revelar senhas'
                  : 'Nenhuma biometria neste aparelho. Ligue o modo demonstração abaixo.',
            ),
            value: sessao.usarBiometria,
            onChanged: sessao.biometriaDisponivel
                ? (v) => _alternarBiometria(context, v)
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Bloqueio automático'),
            subtitle: const Text('Tranca o cofre quando você sai do app'),
            trailing: DropdownButton<int>(
              value: _opcoesBloqueio.containsKey(sessao.bloqueioSegundos)
                  ? sessao.bloqueioSegundos
                  : 30,
              underline: const SizedBox.shrink(),
              items: [
                for (final opcao in _opcoesBloqueio.entries)
                  DropdownMenuItem(value: opcao.key, child: Text(opcao.value)),
              ],
              onChanged: (v) {
                if (v != null) sessao.definirBloqueioAutomatico(v);
              },
            ),
          ),
          const Divider(),
          const _TituloSecao('Apresentação'),
          SwitchListTile(
            secondary: const Icon(Icons.science_outlined),
            title: const Text('Modo demonstração'),
            subtitle: const Text(
              'Simula o Face ID em computadores e emuladores sem biometria. '
              'Não use para guardar senhas reais.',
            ),
            value: sessao.modoDemo,
            onChanged: sessao.definirModoDemo,
          ),
          if (sessao.modoDemo)
            SwitchListTile(
              secondary: Icon(
                sessao.rostoSimuladoReconhecido
                    ? Icons.sentiment_satisfied_alt
                    : Icons.sentiment_dissatisfied,
              ),
              title: const Text('Rosto reconhecido'),
              subtitle: const Text('Desligue para simular um rosto desconhecido'),
              value: sessao.rostoSimuladoReconhecido,
              onChanged: sessao.definirRostoSimulado,
            ),
          const Divider(),
          const _TituloSecao('Sobre'),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('Biometria em uso'),
            subtitle: Text(
              sessao.biometriaDisponivel ? sessao.descricaoBiometria : 'Nenhuma disponível',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Como funciona a segurança'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, Rotas.comoFunciona),
          ),
          const Divider(),
          const _TituloSecao('Zona de perigo'),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: cores.error),
            title: Text('Apagar todos os dados', style: TextStyle(color: cores.error)),
            subtitle: const Text('Remove senhas, PIN, histórico e ajustes deste aparelho'),
            onTap: () => _apagarTudo(context),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}
