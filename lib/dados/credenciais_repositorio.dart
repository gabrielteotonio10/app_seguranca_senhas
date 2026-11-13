import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dominio/credencial.dart';

/// Onde o cofre mora.
///
/// Por que não SQLite? Porque o arquivo .db do sqflite NÃO é criptografado:
/// quem copiar o arquivo do aparelho lê tudo. Dado sensível vai para o
/// armazenamento cifrado do sistema (Keystore / Keychain / DPAPI / WebCrypto).
///
/// Organização:
///   - `cofre_indice`      -> lista com serviço e usuário (sem senha)
///   - `cofre_senha_<id>`  -> a senha de cada conta, separada
/// Assim a lista pode ser mostrada sem que nenhuma senha seja lida.
class CredenciaisRepositorio {
  CredenciaisRepositorio([FlutterSecureStorage? armazenamento])
      : _armazenamento = armazenamento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _armazenamento;

  static const _kIndice = 'cofre_indice';
  static String _kSenha(String id) => 'cofre_senha_$id';

  Future<List<Credencial>> carregar() async {
    final bruto = await _armazenamento.read(key: _kIndice);
    if (bruto == null) return [];
    final lista = jsonDecode(bruto) as List<dynamic>;
    return lista
        .map((m) => Credencial.fromMap((m as Map).cast<String, Object?>()))
        .toList();
  }

  Future<void> salvar(Credencial credencial, String senha) async {
    final todas = await carregar();
    await _armazenamento.write(key: _kSenha(credencial.id), value: senha);
    await _gravarIndice([...todas, credencial]);
  }

  /// Só deve ser chamado depois que a identidade foi confirmada.
  Future<String?> lerSenha(String id) => _armazenamento.read(key: _kSenha(id));

  Future<void> apagar(String id) async {
    final todas = await carregar();
    await _armazenamento.delete(key: _kSenha(id));
    await _gravarIndice(todas.where((c) => c.id != id).toList());
  }

  Future<void> apagarTudo() async {
    for (final c in await carregar()) {
      await _armazenamento.delete(key: _kSenha(c.id));
    }
    await _armazenamento.delete(key: _kIndice);
  }

  Future<void> _gravarIndice(List<Credencial> credenciais) => _armazenamento.write(
        key: _kIndice,
        value: jsonEncode(credenciais.map((c) => c.toMap()).toList()),
      );
}
