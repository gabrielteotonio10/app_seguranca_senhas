import 'package:flutter/foundation.dart';

import '../dados/acessos_repositorio.dart';
import 'registro_acesso.dart';

/// Histórico de tentativas de acesso, compartilhado entre as telas.
class AtividadeStore extends ChangeNotifier {
  AtividadeStore(this._repo);

  final AcessosRepositorio _repo;

  List<RegistroAcesso> _registros = [];
  bool _carregando = true;

  bool get carregando => _carregando;
  List<RegistroAcesso> get registros => List.unmodifiable(_registros);
  int get liberados => _registros.where((r) => r.sucesso).length;
  int get negados => _registros.where((r) => !r.sucesso).length;

  Future<void> carregar() async {
    _registros = await _repo.carregar();
    _carregando = false;
    notifyListeners();
  }

  Future<void> registrar({
    required MetodoAcesso metodo,
    required bool sucesso,
    required String motivo,
  }) async {
    final gravado = await _repo.salvar(RegistroAcesso(
      momento: DateTime.now(),
      metodo: metodo,
      sucesso: sucesso,
      motivo: motivo,
    ));
    _registros = [gravado, ..._registros];
    notifyListeners();
  }

  Future<void> apagarTudo() async {
    await _repo.apagarTudo();
    _registros = [];
    notifyListeners();
  }
}
