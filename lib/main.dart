import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dados/acessos_repositorio.dart';
import 'dados/biometria/biometria_plataforma.dart';
import 'dados/credenciais_repositorio.dart';
import 'dados/pin_repositorio.dart';
import 'dados/preferencias.dart';
import 'dados/vazamento_api.dart';
import 'dominio/atividade_store.dart';
import 'dominio/cofre_store.dart';
import 'dominio/sessao_store.dart';
import 'ui/app.dart';

/// Cofre ID: um cofre de senhas que abre com Face ID.
///
/// Camadas (Aula 08):
///   lib/ui       -> telas e componentes (some se o app virar site ou TV)
///   lib/dominio  -> regras e lojas com ChangeNotifier (o produto)
///   lib/dados    -> de onde o dado vem: armazenamento cifrado, SQLite,
///                   shared_preferences, API REST e biometria do sistema
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final preferencias = Preferencias();

  runApp(
    // As lojas ficam penduradas acima de todas as telas (Aula 07).
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AtividadeStore(AcessosRepositorio.daPlataforma())..carregar(),
        ),
        ChangeNotifierProvider(
          create: (context) => SessaoStore(
            pins: PinRepositorio(),
            preferencias: preferencias,
            biometriaReal: criarBiometriaDaPlataforma(preferencias),
            atividade: context.read<AtividadeStore>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CofreStore(CredenciaisRepositorio(), VazamentoApi()),
        ),
      ],
      child: const CofreApp(),
    ),
  );
}
