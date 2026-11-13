import 'package:flutter_application_1/dominio/seguranca.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hash do PIN', () {
    test('o mesmo PIN com o mesmo sal gera o mesmo hash', () {
      expect(hashPin('258147', 'sal'), hashPin('258147', 'sal'));
    });

    test('sais diferentes geram hashes diferentes para o mesmo PIN', () {
      expect(hashPin('258147', gerarSalt()), isNot(hashPin('258147', gerarSalt())));
    });

    test('o hash não contém o PIN', () {
      expect(hashPin('258147', 'sal'), isNot(contains('258147')));
    });
  });

  test('compararSeguro só aceita strings idênticas', () {
    expect(compararSeguro('abc', 'abc'), isTrue);
    expect(compararSeguro('abc', 'abd'), isFalse);
    expect(compararSeguro('abc', 'abcd'), isFalse);
  });

  group('PIN fraco é recusado', () {
    for (final pin in ['12345', '1234567', '12a456', '111111', '123456', '654321', '890123', '123123']) {
      test(pin, () => expect(problemaNoPin(pin), isNotNull));
    }

    test('PIN razoável é aceito', () => expect(problemaNoPin('258147'), isNull));
  });

  group('força da senha', () {
    test('senhas comuns são muito fracas', () {
      expect(avaliarForca('123456'), ForcaSenha.muitoFraca);
      expect(avaliarForca('Senha123'.toLowerCase()), ForcaSenha.muitoFraca);
    });

    test('senha longa e variada é muito forte', () {
      expect(avaliarForca('xR7#qLp2!vZm9@Wd'), ForcaSenha.muitoForte);
    });

    test('a senha gerada tem o tamanho pedido e todos os grupos', () {
      final senha = gerarSenhaForte(tamanho: 20);
      expect(senha.length, 20);
      expect(senha, matches(RegExp('[a-z]')));
      expect(senha, matches(RegExp('[A-Z]')));
      expect(senha, matches(RegExp(r'\d')));
      expect(senha, matches(RegExp(r'[^A-Za-z0-9]')));
      expect(avaliarForca(senha), ForcaSenha.muitoForte);
    });
  });
}
