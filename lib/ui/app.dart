import 'package:flutter/material.dart';

import 'rotas.dart';
import 'tema.dart';
import 'telas/tela_abertura.dart';
import 'telas/tela_bloqueio.dart';
import 'telas/tela_como_funciona.dart';
import 'telas/tela_criar_pin.dart';
import 'telas/tela_principal.dart';

class CofreApp extends StatelessWidget {
  const CofreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cofre ID',
      debugShowCheckedModeBanner: false,
      theme: criarTema(Brightness.light),
      darkTheme: criarTema(Brightness.dark),
      initialRoute: Rotas.abertura,
      routes: {
        Rotas.abertura: (_) => const TelaAbertura(),
        Rotas.criarPin: (_) => const TelaCriarPin(),
        Rotas.bloqueio: (_) => const TelaBloqueio(),
        Rotas.principal: (_) => const TelaPrincipal(),
        Rotas.comoFunciona: (_) => const TelaComoFunciona(),
      },
    );
  }
}
