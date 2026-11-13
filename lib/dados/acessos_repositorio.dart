import 'package:flutter/foundation.dart';

import '../dominio/registro_acesso.dart';
import 'acessos_preferencias.dart';
import 'acessos_sqlite.dart';

/// O histórico de acessos é uma tabela de verdade: muitos registros iguais,
/// que crescem com o uso. O lugar dele é o SQLite (Aula 09).
///
/// Mas o sqflite só roda em Android, iOS e macOS. No navegador e no
/// Windows, trocamos a implementação, e nenhuma tela percebe: é a promessa
/// da arquitetura em camadas (Aula 08) sendo cobrada.
abstract class AcessosRepositorio {
  factory AcessosRepositorio.daPlataforma() {
    final temSqflite = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    return temSqflite ? AcessosSqlite() : AcessosPreferencias();
  }

  Future<List<RegistroAcesso>> carregar();
  Future<RegistroAcesso> salvar(RegistroAcesso registro);
  Future<void> apagarTudo();
}
