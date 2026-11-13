import 'package:flutter_application_1/dados/biometria/biometria_servico.dart';
import 'package:flutter_application_1/dados/pin_repositorio.dart';
import 'package:flutter_application_1/dados/preferencias.dart';
import 'package:flutter_application_1/dominio/atividade_store.dart';
import 'package:flutter_application_1/dominio/seguranca.dart';
import 'package:flutter_application_1/dominio/sessao_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'falsos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AcessosEmMemoria acessos;
  late BiometriaFalsa biometria;
  late SessaoStore sessao;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    acessos = AcessosEmMemoria();
    biometria = BiometriaFalsa();
    sessao = SessaoStore(
      pins: PinRepositorio(),
      preferencias: Preferencias(),
      biometriaReal: biometria,
      atividade: AtividadeStore(acessos),
    );
    await sessao.carregar();
  });

  test('o PIN correto libera e o errado não', () async {
    await sessao.criarPin('258147');
    expect(await sessao.verificarPin('258147', motivo: 'teste'), ResultadoPin.correto);
    expect(await sessao.verificarPin('000001', motivo: 'teste'), ResultadoPin.incorreto);
  });

  test('o PIN fica guardado como hash, nunca em texto puro', () async {
    await sessao.criarPin('258147');
    final guardado = await PinRepositorio().ler();
    expect(guardado, isNotNull);
    expect(guardado!.hash, isNot(contains('258147')));
  });

  test('erros demais bloqueiam o PIN, até o correto', () async {
    await sessao.criarPin('258147');
    for (var i = 0; i < maxTentativasPin - 1; i++) {
      expect(await sessao.verificarPin('999990', motivo: 'teste'), ResultadoPin.incorreto);
    }
    expect(await sessao.verificarPin('999990', motivo: 'teste'), ResultadoPin.bloqueado);
    expect(sessao.tempoRestanteBloqueio, isNotNull);
    expect(await sessao.verificarPin('258147', motivo: 'teste'), ResultadoPin.bloqueado);
  });

  test('o bloqueio sobrevive a fechar e abrir o app', () async {
    await sessao.criarPin('258147');
    for (var i = 0; i < maxTentativasPin; i++) {
      await sessao.verificarPin('999990', motivo: 'teste');
    }
    final reaberta = SessaoStore(
      pins: PinRepositorio(),
      preferencias: Preferencias(),
      biometriaReal: biometria,
      atividade: AtividadeStore(acessos),
    );
    await reaberta.carregar();
    expect(reaberta.tempoRestanteBloqueio, isNotNull);
  });

  test('toda tentativa vira registro de auditoria', () async {
    await sessao.criarPin('258147');
    await sessao.verificarPin('999990', motivo: 'Desbloquear o cofre');
    await sessao.verificarPin('258147', motivo: 'Desbloquear o cofre');
    expect(acessos.registros.map((r) => r.sucesso), [true, false]);
  });

  test('a biometria só é ativada se funcionar na hora', () async {
    biometria.resposta = StatusBiometria.falhou;
    expect(await sessao.ativarBiometria(), StatusBiometria.falhou);
    expect(sessao.usarBiometria, isFalse);

    biometria.resposta = StatusBiometria.sucesso;
    expect(await sessao.ativarBiometria(), StatusBiometria.sucesso);
    expect(sessao.usarBiometria, isTrue);
  });

  test('o modo demonstração usa a simulação, não o sensor', () async {
    biometria.temSensor = false;
    await sessao.carregar();
    expect(sessao.biometriaDisponivel, isFalse);

    await sessao.definirModoDemo(true);
    expect(sessao.biometriaDisponivel, isTrue);
    expect(sessao.nomeBiometria, 'Face ID');

    sessao.definirRostoSimulado(false);
    expect(await sessao.autenticarBiometria('teste'), StatusBiometria.falhou);
    expect(biometria.chamadas, 0);
  });

  test('o cofre tranca ao voltar só depois do tempo configurado', () async {
    await sessao.criarPin('258147'); // já entra desbloqueado
    await sessao.definirBloqueioAutomatico(30);
    sessao.registrarSaida();
    expect(sessao.deveBloquearAoVoltar(), isFalse);

    await sessao.definirBloqueioAutomatico(0);
    sessao.registrarSaida();
    expect(sessao.deveBloquearAoVoltar(), isTrue);
  });
}
