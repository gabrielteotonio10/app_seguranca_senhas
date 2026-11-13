import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o hash do PIN e o controle de tentativas no armazenamento
/// cifrado do sistema:
///   - Android: Keystore    - iOS: Keychain
///   - Windows: DPAPI       - Web: WebCrypto
///
/// O PIN em si nunca é gravado. Quem calcula o hash é o domínio
/// (seguranca.dart); este repositório só sabe onde guardar.
class PinRepositorio {
  PinRepositorio([FlutterSecureStorage? armazenamento])
      : _armazenamento = armazenamento ?? const FlutterSecureStorage();

  final FlutterSecureStorage _armazenamento;

  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const _kTentativas = 'pin_tentativas_erradas';
  static const _kBloqueadoAte = 'pin_bloqueado_ate';

  Future<bool> existe() async => await _armazenamento.read(key: _kHash) != null;

  Future<({String hash, String salt})?> ler() async {
    final hash = await _armazenamento.read(key: _kHash);
    final salt = await _armazenamento.read(key: _kSalt);
    if (hash == null || salt == null) return null;
    return (hash: hash, salt: salt);
  }

  Future<void> salvar({required String hash, required String salt}) async {
    await _armazenamento.write(key: _kSalt, value: salt);
    await _armazenamento.write(key: _kHash, value: hash);
  }

  /// As tentativas também ficam gravadas: fechar e abrir o app não zera a
  /// contagem nem o bloqueio contra força bruta.
  Future<int> lerTentativas() async =>
      int.tryParse(await _armazenamento.read(key: _kTentativas) ?? '') ?? 0;

  Future<void> salvarTentativas(int tentativas) =>
      _armazenamento.write(key: _kTentativas, value: '$tentativas');

  Future<DateTime?> lerBloqueadoAte() async {
    final texto = await _armazenamento.read(key: _kBloqueadoAte);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  Future<void> salvarBloqueadoAte(DateTime? ate) async {
    if (ate == null) {
      await _armazenamento.delete(key: _kBloqueadoAte);
    } else {
      await _armazenamento.write(key: _kBloqueadoAte, value: ate.toIso8601String());
    }
  }

  Future<void> apagarTudo() async {
    for (final chave in [_kHash, _kSalt, _kTentativas, _kBloqueadoAte]) {
      await _armazenamento.delete(key: chave);
    }
  }
}
