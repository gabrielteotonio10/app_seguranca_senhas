import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Consulta a base pública "Have I Been Pwned" para saber se uma senha já
/// apareceu em vazamentos de dados (Aula 10: consumo de API REST).
///
/// Anonimato-k: a senha NUNCA sai do aparelho. Calculamos o SHA-1 dela e
/// mandamos só os 5 primeiros caracteres do hash. O servidor devolve
/// centenas de hashes que começam igual, e a comparação final é feita aqui.
/// Nem o servidor fica sabendo qual senha foi consultada.
class VazamentoApi {
  VazamentoApi([http.Client? cliente]) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// Quantas vezes a senha apareceu em vazamentos (0 = nenhuma).
  Future<int> vezesQueVazou(String senha) async {
    final hash = sha1.convert(utf8.encode(senha)).toString().toUpperCase();
    final prefixo = hash.substring(0, 5);
    final sufixo = hash.substring(5);

    final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefixo');
    final resposta = await _cliente.get(url).timeout(const Duration(seconds: 10));
    if (resposta.statusCode != 200) {
      throw Exception('O servidor respondeu ${resposta.statusCode}');
    }

    // Cada linha vem como "SUFIXO_DO_HASH:QUANTIDADE".
    for (final linha in const LineSplitter().convert(resposta.body)) {
      final partes = linha.split(':');
      if (partes.length == 2 && partes[0].trim() == sufixo) {
        return int.tryParse(partes[1].trim()) ?? 0;
      }
    }
    return 0;
  }
}
