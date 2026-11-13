import 'biometria_servico.dart';

/// Face ID simulado, para apresentar o app em computadores e emuladores
/// sem leitor biométrico. Não oferece segurança real: o app deixa isso
/// claro na tela sempre que este modo está ligado.
class BiometriaSimulada implements BiometriaServico {
  /// Em Ajustes dá para desligar e mostrar o caso de rosto desconhecido.
  bool rostoReconhecido = true;

  @override
  String get descricao => 'Simulação (modo demonstração)';

  @override
  Future<bool> disponivel() async => true;

  @override
  Future<TipoBiometria> tipo() async => TipoBiometria.rosto;

  @override
  Future<StatusBiometria> autenticar(String motivo) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600)); // "escaneando"
    return rostoReconhecido ? StatusBiometria.sucesso : StatusBiometria.falhou;
  }

  @override
  Future<void> redefinir() async {}
}
