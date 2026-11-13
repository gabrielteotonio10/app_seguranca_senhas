import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/sessao_store.dart';
import '../componentes/painel_autenticacao.dart';
import '../componentes/selo_demo.dart';
import '../rotas.dart';

/// A porta do cofre. Abre com Face ID; o PIN fica como alternativa.
class TelaBloqueio extends StatelessWidget {
  const TelaBloqueio({super.key});

  void _entrar(BuildContext context) {
    context.read<SessaoStore>().marcarDesbloqueado();
    // pushReplacement: depois de entrar, "voltar" não pode reabrir o bloqueio.
    Navigator.pushReplacementNamed(context, Rotas.principal);
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final modoDemo = context.watch<SessaoStore>().modoDemo;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 32, color: cores.primary),
                  const SizedBox(height: 12),
                  Text('Cofre ID', style: textos.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Cofre bloqueado',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),
                  PainelAutenticacao(
                    motivo: 'Desbloquear o cofre',
                    tamanhoScanner: 160,
                    aoConfirmar: () => _entrar(context),
                  ),
                  if (modoDemo) ...[
                    const SizedBox(height: 24),
                    const SeloDemo(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
