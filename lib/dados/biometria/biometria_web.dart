import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../preferencias.dart';
import 'biometria_servico.dart';

/// Ponto de entrada usado no navegador (ver biometria_plataforma.dart).
BiometriaServico criarBiometriaDaPlataforma(Preferencias preferencias) =>
    BiometriaWeb(preferencias);

/// Biometria real no navegador, pela API WebAuthn (a mesma das passkeys).
///
/// O navegador chama o autenticador da plataforma: Windows Hello (rosto,
/// digital ou PIN do Windows), Touch ID no Mac ou a biometria do Android.
///
/// 1ª vez: navigator.credentials.create() gera um par de chaves. A chave
///         privada fica presa no hardware; guardamos só o id público.
/// Depois: navigator.credentials.get() pede ao hardware que assine um
///         desafio aleatório. Isso só acontece se a pessoa passar na
///         verificação (userVerification: 'required').
///
/// Num sistema com servidor, o servidor geraria o desafio e conferiria a
/// assinatura com a chave pública. Aqui o cofre é local, então, como no
/// local_auth, confiamos na resposta da plataforma.
class BiometriaWeb implements BiometriaServico {
  BiometriaWeb(this._preferencias);

  final Preferencias _preferencias;
  final _aleatorio = Random.secure();

  // Identificador fixo do "usuário" do cofre: recriar a credencial
  // substitui a anterior em vez de acumular passkeys repetidas.
  static final _idUsuario = Uint8List.fromList(utf8.encode('cofre-id-usuario-local'));

  @override
  String get descricao => 'WebAuthn: Windows Hello / Touch ID pelo navegador';

  @override
  Future<bool> disponivel() async {
    try {
      final resposta = await web.PublicKeyCredential
          .isUserVerifyingPlatformAuthenticatorAvailable()
          .toDart;
      return resposta.toDart;
    } catch (_) {
      return false; // navegador sem WebAuthn ou página fora de HTTPS/localhost
    }
  }

  @override
  Future<TipoBiometria> tipo() async => TipoBiometria.generica;

  @override
  Future<StatusBiometria> autenticar(String motivo) async {
    try {
      final idSalvo = await _preferencias.lerCredencialWeb();
      if (idSalvo == null) {
        // Criar a credencial já exige a verificação biométrica.
        final novoId = await _registrar();
        await _preferencias.salvarCredencialWeb(novoId);
        return StatusBiometria.sucesso;
      }
      final ok = await _verificar(base64Url.decode(idSalvo));
      return ok ? StatusBiometria.sucesso : StatusBiometria.falhou;
    } catch (erro) {
      final texto = erro.toString();
      if (texto.contains('NotAllowedError') || texto.contains('AbortError')) {
        return StatusBiometria.cancelado; // cancelou, esgotou o tempo ou não reconheceu
      }
      if (texto.contains('NotSupportedError') || texto.contains('SecurityError')) {
        return StatusBiometria.indisponivel;
      }
      return StatusBiometria.falhou;
    }
  }

  @override
  Future<void> redefinir() => _preferencias.salvarCredencialWeb(null);

  Uint8List _bytesAleatorios(int quantidade) =>
      Uint8List.fromList(List.generate(quantidade, (_) => _aleatorio.nextInt(256)));

  Future<String> _registrar() async {
    final opcoes = web.CredentialCreationOptions(
      publicKey: web.PublicKeyCredentialCreationOptions(
        rp: web.PublicKeyCredentialRpEntity(name: 'Cofre ID'),
        user: web.PublicKeyCredentialUserEntity(
          id: _idUsuario.toJS,
          name: 'cofre-id',
          displayName: 'Dono do Cofre ID',
        ),
        challenge: _bytesAleatorios(32).toJS,
        pubKeyCredParams: [
          web.PublicKeyCredentialParameters(type: 'public-key', alg: -7), // ES256
          web.PublicKeyCredentialParameters(type: 'public-key', alg: -257), // RS256
        ].toJS,
        authenticatorSelection: web.AuthenticatorSelectionCriteria(
          authenticatorAttachment: 'platform', // o leitor do próprio aparelho
          userVerification: 'required', // exige biometria/PIN do sistema
          residentKey: 'preferred',
        ),
        timeout: 60000,
        attestation: 'none',
      ),
    );
    final credencial = await web.window.navigator.credentials.create(opcoes).toDart;
    if (credencial == null) throw StateError('NotAllowedError');
    final rawId = (credencial as web.PublicKeyCredential).rawId.toDart.asUint8List();
    return base64Url.encode(rawId);
  }

  Future<bool> _verificar(Uint8List idCredencial) async {
    final opcoes = web.CredentialRequestOptions(
      publicKey: web.PublicKeyCredentialRequestOptions(
        challenge: _bytesAleatorios(32).toJS,
        allowCredentials: [
          web.PublicKeyCredentialDescriptor(type: 'public-key', id: idCredencial.toJS),
        ].toJS,
        userVerification: 'required',
        timeout: 60000,
      ),
    );
    final credencial = await web.window.navigator.credentials.get(opcoes).toDart;
    return credencial != null;
  }
}
