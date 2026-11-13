import 'package:flutter/foundation.dart';

import '../dados/biometria/biometria_servico.dart';
import '../dados/biometria/biometria_simulada.dart';
import '../dados/pin_repositorio.dart';
import '../dados/preferencias.dart';
import 'atividade_store.dart';
import 'registro_acesso.dart';
import 'seguranca.dart';

enum ResultadoPin { correto, incorreto, bloqueado }

/// Quem está com a chave do cofre: PIN, biometria, bloqueio automático e
/// proteção contra força bruta. Todas as regras de acesso moram aqui, e
/// as telas só perguntam e mostram.
class SessaoStore extends ChangeNotifier {
  SessaoStore({
    required this._pins,
    required this._preferencias,
    required BiometriaServico biometriaReal,
    required this._atividade,
    BiometriaSimulada? biometriaSimulada,
  })  : _real = biometriaReal,
        _simulada = biometriaSimulada ?? BiometriaSimulada();

  final PinRepositorio _pins;
  final Preferencias _preferencias;
  final BiometriaServico _real;
  final BiometriaSimulada _simulada;
  final AtividadeStore _atividade;

  bool _temPin = false;
  bool _desbloqueado = false;
  bool _biometriaAtiva = false;
  bool _modoDemo = false;
  int _bloqueioSegundos = 30;
  bool _biometriaRealDisponivel = false;
  TipoBiometria _tipoReal = TipoBiometria.nenhuma;
  int _tentativasPin = 0;
  DateTime? _bloqueadoAte;
  bool _autenticando = false;
  DateTime? _saiuEm;

  // ---------------------------------------------------------------- leitura

  bool get temPin => _temPin;
  bool get desbloqueado => _desbloqueado;
  bool get biometriaAtiva => _biometriaAtiva;
  bool get modoDemo => _modoDemo;
  int get bloqueioSegundos => _bloqueioSegundos;
  bool get biometriaRealDisponivel => _biometriaRealDisponivel;
  bool get rostoSimuladoReconhecido => _simulada.rostoReconhecido;

  BiometriaServico get _biometria => _modoDemo ? _simulada : _real;

  bool get biometriaDisponivel => _modoDemo || _biometriaRealDisponivel;

  /// Biometria ligada E possível neste aparelho agora.
  bool get usarBiometria => _biometriaAtiva && biometriaDisponivel;

  String get descricaoBiometria => _biometria.descricao;

  TipoBiometria get tipoBiometria => _modoDemo ? TipoBiometria.rosto : _tipoReal;

  String get nomeBiometria => switch (tipoBiometria) {
        TipoBiometria.rosto => 'Face ID',
        TipoBiometria.digital => 'impressão digital',
        _ => 'biometria',
      };

  int get tentativasRestantes => maxTentativasPin - _tentativasPin;

  /// Quanto falta para liberar o PIN depois de muitos erros (null = livre).
  Duration? get tempoRestanteBloqueio {
    final ate = _bloqueadoAte;
    if (ate == null) return null;
    final resta = ate.difference(DateTime.now());
    return resta.isNegative ? null : resta;
  }

  // -------------------------------------------------------------- abertura

  Future<void> carregar() async {
    _temPin = await _pins.existe();
    _biometriaAtiva = await _preferencias.lerBiometriaAtiva();
    _modoDemo = await _preferencias.lerModoDemo();
    _bloqueioSegundos = await _preferencias.lerBloqueioSegundos();
    _tentativasPin = await _pins.lerTentativas();
    _bloqueadoAte = await _pins.lerBloqueadoAte();
    _biometriaRealDisponivel = await _real
        .disponivel()
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
    _tipoReal = _biometriaRealDisponivel ? await _real.tipo() : TipoBiometria.nenhuma;
    notifyListeners();
  }

  // -------------------------------------------------------------------- PIN

  Future<void> criarPin(String pin) async {
    final salt = gerarSalt();
    await _pins.salvar(hash: hashPin(pin, salt), salt: salt);
    await _pins.salvarTentativas(0);
    await _pins.salvarBloqueadoAte(null);
    _temPin = true;
    _tentativasPin = 0;
    _bloqueadoAte = null;
    _desbloqueado = true;
    notifyListeners();
  }

  Future<ResultadoPin> verificarPin(String pin, {required String motivo}) async {
    if (tempoRestanteBloqueio != null) return ResultadoPin.bloqueado;
    _bloqueadoAte = null; // um bloqueio antigo que já venceu

    final guardado = await _pins.ler();
    final correto =
        guardado != null && compararSeguro(hashPin(pin, guardado.salt), guardado.hash);
    await _atividade.registrar(metodo: MetodoAcesso.pin, sucesso: correto, motivo: motivo);

    if (correto) {
      _tentativasPin = 0;
    } else {
      _tentativasPin++;
      if (_tentativasPin >= maxTentativasPin) {
        _tentativasPin = 0;
        _bloqueadoAte = DateTime.now().add(duracaoBloqueioPin);
      }
    }
    await _pins.salvarTentativas(_tentativasPin);
    await _pins.salvarBloqueadoAte(_bloqueadoAte);
    notifyListeners();

    if (correto) return ResultadoPin.correto;
    return _bloqueadoAte != null ? ResultadoPin.bloqueado : ResultadoPin.incorreto;
  }

  // -------------------------------------------------------------- biometria

  Future<StatusBiometria> autenticarBiometria(String motivo) async {
    if (!biometriaDisponivel) return StatusBiometria.indisponivel;
    _autenticando = true;
    try {
      final status = await _biometria.autenticar(motivo);
      if (status != StatusBiometria.cancelado && status != StatusBiometria.indisponivel) {
        await _atividade.registrar(
          metodo: MetodoAcesso.biometria,
          sucesso: status == StatusBiometria.sucesso,
          motivo: motivo,
        );
      }
      return status;
    } finally {
      _autenticando = false;
      _saiuEm = null; // o diálogo do sistema pode "pausar" o app: não é saída
    }
  }

  /// Para ligar, a pessoa precisa provar na hora que a biometria funciona.
  Future<StatusBiometria> ativarBiometria() async {
    final status = await autenticarBiometria('Ativar o desbloqueio por $nomeBiometria');
    if (status == StatusBiometria.sucesso) {
      _biometriaAtiva = true;
      await _preferencias.salvarBiometriaAtiva(true);
      notifyListeners();
    }
    return status;
  }

  Future<void> desativarBiometria() async {
    await _biometria.redefinir();
    _biometriaAtiva = false;
    await _preferencias.salvarBiometriaAtiva(false);
    notifyListeners();
  }

  Future<void> definirModoDemo(bool ativo) async {
    _modoDemo = ativo;
    await _preferencias.salvarModoDemo(ativo);
    notifyListeners();
  }

  void definirRostoSimulado(bool reconhecido) {
    _simulada.rostoReconhecido = reconhecido;
    notifyListeners();
  }

  // ------------------------------------------------- bloqueio automático

  Future<void> definirBloqueioAutomatico(int segundos) async {
    _bloqueioSegundos = segundos;
    await _preferencias.salvarBloqueioSegundos(segundos);
    notifyListeners();
  }

  void marcarDesbloqueado() {
    _desbloqueado = true;
    _saiuEm = null;
    notifyListeners();
  }

  void bloquear() {
    _desbloqueado = false;
    _saiuEm = null;
    notifyListeners();
  }

  /// O app foi para segundo plano (outra aba, outro app, tela apagada).
  void registrarSaida() {
    if (_autenticando || !_desbloqueado) return;
    _saiuEm ??= DateTime.now();
  }

  /// O app voltou: passou tempo demais fora? Então tranca.
  bool deveBloquearAoVoltar() {
    final saiu = _saiuEm;
    _saiuEm = null;
    if (_autenticando || !_desbloqueado || saiu == null) return false;
    return DateTime.now().difference(saiu).inSeconds >= _bloqueioSegundos;
  }

  // ---------------------------------------------------------------- reset

  Future<void> apagarTudo() async {
    await _real.redefinir();
    await _pins.apagarTudo();
    await _preferencias.apagarTudo();
    _temPin = false;
    _desbloqueado = false;
    _biometriaAtiva = false;
    _modoDemo = false;
    _bloqueioSegundos = 30;
    _tentativasPin = 0;
    _bloqueadoAte = null;
    _simulada.rostoReconhecido = true;
    notifyListeners();
  }
}
