import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/cofre_store.dart';
import '../../dominio/sessao_store.dart';
import '../rotas.dart';
import 'tela_ajustes.dart';
import 'tela_atividade.dart';
import 'tela_cofre.dart';
import 'tela_nova_credencial.dart';

/// O cofre aberto: três seções numa barra que troca o corpo sem empilhar
/// (Aula 06). Em tela larga a barra vira um trilho na lateral.
///
/// Também vigia o ciclo de vida do app: se ele ficar em segundo plano por
/// mais tempo que o configurado, o cofre tranca sozinho.
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> with WidgetsBindingObserver {
  int _aba = 0;

  static const _secoes = [
    (titulo: 'Cofre', icone: Icons.lock_outline, iconeAtivo: Icons.lock),
    (titulo: 'Atividade', icone: Icons.receipt_long_outlined, iconeAtivo: Icons.receipt_long),
    (titulo: 'Ajustes', icone: Icons.settings_outlined, iconeAtivo: Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Só agora, com o cofre destrancado, a lista vai para a memória.
    context.read<CofreStore>().carregar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final sessao = context.read<SessaoStore>();
    switch (estado) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        sessao.registrarSaida();
      case AppLifecycleState.resumed:
        if (sessao.deveBloquearAoVoltar()) _bloquear();
      default:
        break;
    }
  }

  void _bloquear() {
    context.read<CofreStore>().fechar();
    context.read<SessaoStore>().bloquear();
    // Remove TODAS as telas da pilha: nada do cofre fica por baixo.
    Navigator.of(context).pushNamedAndRemoveUntil(Rotas.bloqueio, (_) => false);
  }

  Future<void> _novaSenha() async {
    // Aula 06: await no push, valor no pop.
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelaNovaCredencial()),
    );
    if (!mounted) return;
    if (salvou == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha guardada no cofre')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modoDemo = context.watch<SessaoStore>().modoDemo;
    final largo = MediaQuery.sizeOf(context).width >= 720;
    final corpo = switch (_aba) {
      0 => const TelaCofre(),
      1 => const TelaAtividade(),
      _ => const TelaAjustes(),
    };
    void trocar(int i) => setState(() => _aba = i);

    return Scaffold(
      appBar: AppBar(
        title: Text(_secoes[_aba].titulo),
        actions: [
          if (modoDemo)
            const Tooltip(
              message: 'Modo demonstração: Face ID simulado',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.science_outlined),
              ),
            ),
          IconButton(
            tooltip: 'Bloquear agora',
            onPressed: _bloquear,
            icon: const Icon(Icons.lock_person_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: largo
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _aba,
                  onDestinationSelected: trocar,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final s in _secoes)
                      NavigationRailDestination(
                        icon: Icon(s.icone),
                        selectedIcon: Icon(s.iconeAtivo),
                        label: Text(s.titulo),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: corpo),
              ],
            )
          : corpo,
      bottomNavigationBar: largo
          ? null
          : NavigationBar(
              selectedIndex: _aba,
              onDestinationSelected: trocar,
              destinations: [
                for (final s in _secoes)
                  NavigationDestination(
                    icon: Icon(s.icone),
                    selectedIcon: Icon(s.iconeAtivo),
                    label: s.titulo,
                  ),
              ],
            ),
      floatingActionButton: _aba == 0
          ? FloatingActionButton.extended(
              onPressed: _novaSenha,
              icon: const Icon(Icons.add),
              label: const Text('Nova senha'),
            )
          : null,
    );
  }
}
