import 'package:flutter/material.dart';
import 'package:flutter_application_1/dados/credenciais_repositorio.dart';
import 'package:flutter_application_1/dados/pin_repositorio.dart';
import 'package:flutter_application_1/dados/preferencias.dart';
import 'package:flutter_application_1/dados/vazamento_api.dart';
import 'package:flutter_application_1/dominio/atividade_store.dart';
import 'package:flutter_application_1/dominio/cofre_store.dart';
import 'package:flutter_application_1/dominio/sessao_store.dart';
import 'package:flutter_application_1/ui/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'falsos.dart';

void main() {
  testWidgets('primeiro uso: recusa PIN fraco, cria o PIN e abre o cofre vazio',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final preferencias = Preferencias();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AtividadeStore(AcessosEmMemoria())..carregar()),
          ChangeNotifierProvider(
            create: (context) => SessaoStore(
              pins: PinRepositorio(),
              preferencias: preferencias,
              biometriaReal: BiometriaFalsa(temSensor: false),
              atividade: context.read<AtividadeStore>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => CofreStore(CredenciaisRepositorio(), VazamentoApi()),
          ),
        ],
        child: const CofreApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Sem PIN cadastrado, a abertura leva para a criação do PIN.
    expect(find.text('Crie seu PIN'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '123456');
    await tester.enterText(campos.at(1), '123456');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Evite sequências, como 123456 ou 654321'), findsOneWidget);

    await tester.enterText(campos.at(0), '258147');
    await tester.enterText(campos.at(1), '258147');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Sem sensor, o app oferece o Face ID simulado ou seguir só com PIN.
    expect(find.text('Usar Face ID simulado'), findsOneWidget);
    await tester.tap(find.text('Agora não, usar só o PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Seu cofre está vazio'), findsOneWidget);
    expect(find.text('Protegido por PIN'), findsOneWidget);
  });
}
