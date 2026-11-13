import 'package:flutter/foundation.dart';

import '../dados/credenciais_repositorio.dart';
import '../dados/vazamento_api.dart';
import 'credencial.dart';

/// A lista de contas do cofre, acima de todas as telas.
class CofreStore extends ChangeNotifier {
  CofreStore(this._repo, this._vazamentos);

  final CredenciaisRepositorio _repo;
  final VazamentoApi _vazamentos;

  List<Credencial> _credenciais = [];
  bool _carregando = true;

  bool get carregando => _carregando;

  List<Credencial> get credenciais {
    final ordenadas = [..._credenciais]
      ..sort((a, b) => a.servico.toLowerCase().compareTo(b.servico.toLowerCase()));
    return List.unmodifiable(ordenadas);
  }

  /// Chamado só depois do desbloqueio: antes disso, nem a lista de
  /// serviços fica na memória.
  Future<void> carregar() async {
    // _carregando já é true aqui (começa assim, e fechar() volta para true).
    // Avisar agora daria erro: quem chama é o initState, no meio do build.
    _credenciais = await _repo.carregar();
    _carregando = false;
    notifyListeners();
  }

  /// Chamado ao bloquear: tira a lista da memória.
  void fechar() {
    _credenciais = [];
    _carregando = true;
    notifyListeners();
  }

  Future<void> adicionar({
    required String servico,
    required String usuario,
    required String senha,
  }) async {
    final nova = Credencial(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      servico: servico.trim(),
      usuario: usuario.trim(),
      criadaEm: DateTime.now(),
    );
    await _repo.salvar(nova, senha);
    _credenciais = [..._credenciais, nova];
    notifyListeners();
  }

  Future<void> remover(String id) async {
    await _repo.apagar(id);
    _credenciais = _credenciais.where((c) => c.id != id).toList();
    notifyListeners();
  }

  /// A tela só chama depois de confirmarIdentidade() devolver true.
  Future<String?> lerSenha(String id) => _repo.lerSenha(id);

  Future<int> verificarVazamento(String id) async {
    final senha = await _repo.lerSenha(id);
    if (senha == null) throw StateError('Senha não encontrada');
    return _vazamentos.vezesQueVazou(senha);
  }

  Future<void> apagarTudo() async {
    await _repo.apagarTudo();
    _credenciais = [];
    notifyListeners();
  }
}
