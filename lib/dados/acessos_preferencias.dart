import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/registro_acesso.dart';
import 'acessos_repositorio.dart';

/// Histórico de acessos onde o sqflite não roda (navegador e Windows).
///
/// shared_preferences não é banco de dados (Aula 09): ele lê tudo de uma
/// vez para a memória. Por isso guardamos só os [_limite] acessos mais
/// recentes, e a lista nunca cresce sem controle.
class AcessosPreferencias implements AcessosRepositorio {
  static const _chave = 'historico_acessos';
  static const _limite = 100;

  @override
  Future<List<RegistroAcesso>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final linhas = prefs.getStringList(_chave) ?? [];
    return linhas
        .map((l) => RegistroAcesso.fromMap((jsonDecode(l) as Map).cast<String, Object?>()))
        .toList();
  }

  @override
  Future<RegistroAcesso> salvar(RegistroAcesso registro) async {
    final prefs = await SharedPreferences.getInstance();
    final gravado = registro.comId(DateTime.now().microsecondsSinceEpoch);
    final linhas = [
      jsonEncode(gravado.toMap()),
      ...prefs.getStringList(_chave) ?? <String>[],
    ].take(_limite).toList();
    await prefs.setStringList(_chave, linhas);
    return gravado;
  }

  @override
  Future<void> apagarTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
