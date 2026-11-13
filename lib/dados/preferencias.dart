import 'package:shared_preferences/shared_preferences.dart';

/// Configurações do app: dados pequenos, de chave e valor, e que NÃO são
/// segredo. Por isso vão para o shared_preferences (Aula 09), e não para o
/// armazenamento cifrado.
class Preferencias {
  static const _kBiometriaAtiva = 'biometria_ativa';
  static const _kModoDemo = 'modo_demonstracao';
  static const _kBloqueioSegundos = 'bloqueio_automatico_segundos';
  static const _kCredencialWeb = 'webauthn_credencial_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> lerBiometriaAtiva() async =>
      (await _prefs).getBool(_kBiometriaAtiva) ?? false;

  Future<void> salvarBiometriaAtiva(bool ativa) async =>
      (await _prefs).setBool(_kBiometriaAtiva, ativa);

  Future<bool> lerModoDemo() async => (await _prefs).getBool(_kModoDemo) ?? false;

  Future<void> salvarModoDemo(bool ativo) async =>
      (await _prefs).setBool(_kModoDemo, ativo);

  Future<int> lerBloqueioSegundos() async =>
      (await _prefs).getInt(_kBloqueioSegundos) ?? 30;

  Future<void> salvarBloqueioSegundos(int segundos) async =>
      (await _prefs).setInt(_kBloqueioSegundos, segundos);

  /// Identificador PÚBLICO da credencial WebAuthn criada no navegador.
  /// Não é segredo: a chave privada fica presa no Windows Hello / Touch ID.
  Future<String?> lerCredencialWeb() async => (await _prefs).getString(_kCredencialWeb);

  Future<void> salvarCredencialWeb(String? id) async {
    final prefs = await _prefs;
    if (id == null) {
      await prefs.remove(_kCredencialWeb);
    } else {
      await prefs.setString(_kCredencialWeb, id);
    }
  }

  Future<void> apagarTudo() async {
    final prefs = await _prefs;
    for (final chave in [_kBiometriaAtiva, _kModoDemo, _kBloqueioSegundos, _kCredencialWeb]) {
      await prefs.remove(chave);
    }
  }
}
