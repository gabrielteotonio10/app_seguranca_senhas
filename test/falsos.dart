import 'package:flutter_application_1/dados/acessos_repositorio.dart';
import 'package:flutter_application_1/dados/biometria/biometria_servico.dart';
import 'package:flutter_application_1/dominio/registro_acesso.dart';

/// "Testar é trocar o repositório por um de mentira" (Aula 08).

class AcessosEmMemoria implements AcessosRepositorio {
  final registros = <RegistroAcesso>[];

  @override
  Future<List<RegistroAcesso>> carregar() async => List.of(registros);

  @override
  Future<RegistroAcesso> salvar(RegistroAcesso registro) async {
    final gravado = registro.comId(registros.length + 1);
    registros.insert(0, gravado);
    return gravado;
  }

  @override
  Future<void> apagarTudo() async => registros.clear();
}

class BiometriaFalsa implements BiometriaServico {
  BiometriaFalsa({this.temSensor = true, this.resposta = StatusBiometria.sucesso});

  bool temSensor;
  StatusBiometria resposta;
  int chamadas = 0;

  @override
  String get descricao => 'Biometria falsa de teste';

  @override
  Future<bool> disponivel() async => temSensor;

  @override
  Future<TipoBiometria> tipo() async => TipoBiometria.rosto;

  @override
  Future<StatusBiometria> autenticar(String motivo) async {
    chamadas++;
    return resposta;
  }

  @override
  Future<void> redefinir() async {}
}
