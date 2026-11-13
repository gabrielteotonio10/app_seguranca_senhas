import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/sessao_store.dart';
import '../rotas.dart';

/// Primeira tela: carrega a sessão e decide o caminho.
///   - nunca configurado -> criar PIN
///   - já configurado    -> tela de bloqueio (Face ID)
class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura> {
  String? _erro;

  @override
  void initState() {
    super.initState();
    _decidir(); // carregar dados vai no initState, nunca no build (Aula 07)
  }

  Future<void> _decidir() async {
    setState(() => _erro = null);
    final sessao = context.read<SessaoStore>();
    try {
      await sessao.carregar();
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível abrir o cofre.\n$e');
      return;
    }
    if (!mounted) return;
    // pushReplacement: voltar para a abertura não faria sentido.
    Navigator.pushReplacementNamed(
      context,
      sessao.temPin ? Rotas.bloqueio : Rotas.criarPin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 72, color: cores.primary),
              const SizedBox(height: 16),
              Text('Cofre ID', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (_erro == null)
                const CircularProgressIndicator()
              else ...[
                Text(_erro!, textAlign: TextAlign.center, style: TextStyle(color: cores.error)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _decidir, child: const Text('Tentar de novo')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
