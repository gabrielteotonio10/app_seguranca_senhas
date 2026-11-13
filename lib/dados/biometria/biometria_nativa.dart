import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../preferencias.dart';
import 'biometria_servico.dart';

/// Ponto de entrada usado fora do navegador (ver biometria_plataforma.dart).
BiometriaServico criarBiometriaDaPlataforma(Preferencias preferencias) =>
    BiometriaNativa();

/// Biometria real do aparelho, pelo pacote local_auth:
///   - iPhone: Face ID / Touch ID
///   - Android: BiometricPrompt (rosto ou digital)
///   - Windows: Windows Hello
class BiometriaNativa implements BiometriaServico {
  final _auth = LocalAuthentication();

  @override
  String get descricao => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'Face ID / Touch ID (local_auth)',
        TargetPlatform.android => 'BiometricPrompt do Android (local_auth)',
        TargetPlatform.windows => 'Windows Hello (local_auth)',
        _ => 'Biometria do sistema (local_auth)',
      };

  @override
  Future<bool> disponivel() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final cadastradas = await _auth.getAvailableBiometrics();
      // No Windows o Hello não informa o tipo; basta o aparelho suportar.
      return cadastradas.isNotEmpty || defaultTargetPlatform == TargetPlatform.windows;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<TipoBiometria> tipo() async {
    try {
      final cadastradas = await _auth.getAvailableBiometrics();
      if (cadastradas.contains(BiometricType.face)) return TipoBiometria.rosto;
      if (cadastradas.contains(BiometricType.fingerprint)) return TipoBiometria.digital;
      return cadastradas.isEmpty ? TipoBiometria.nenhuma : TipoBiometria.generica;
    } catch (_) {
      return TipoBiometria.nenhuma;
    }
  }

  @override
  Future<StatusBiometria> autenticar(String motivo) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: motivo,
        // Só biometria: sem cair no PIN do aparelho. O PIN de reserva é o
        // do próprio app. (O Windows Hello não permite essa restrição.)
        biometricOnly: defaultTargetPlatform != TargetPlatform.windows,
        persistAcrossBackgrounding: true,
      );
      return ok ? StatusBiometria.sucesso : StatusBiometria.falhou;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          StatusBiometria.cancelado,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          StatusBiometria.bloqueado,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable =>
          StatusBiometria.indisponivel,
        _ => StatusBiometria.falhou,
      };
    } catch (_) {
      return StatusBiometria.indisponivel;
    }
  }

  @override
  Future<void> redefinir() async {}
}
