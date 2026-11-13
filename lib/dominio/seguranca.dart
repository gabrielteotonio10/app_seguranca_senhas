import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Regras de segurança do produto. Nada aqui conhece tela, banco ou
/// plataforma: são só funções puras, fáceis de testar.

const tamanhoPin = 6;
const maxTentativasPin = 5;
const duracaoBloqueioPin = Duration(seconds: 30);
const iteracoesHash = 10000;

final _aleatorio = Random.secure();

// ---------------------------------------------------------------------------
// PIN: nunca guardamos o PIN, só um "resumo" (hash) dele.
// ---------------------------------------------------------------------------

/// Sal: bytes aleatórios misturados ao PIN antes do hash. Com ele, dois
/// usuários com o mesmo PIN têm hashes diferentes, e tabelas prontas de
/// hashes (rainbow tables) deixam de servir.
String gerarSalt() {
  final bytes = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
  return base64Encode(bytes);
}

/// SHA-256 repetido [iteracoesHash] vezes ("alongamento de chave"). Cada
/// palpite de um atacante passa a custar milhares de hashes, e não um só.
String hashPin(String pin, String salt) {
  List<int> resumo = utf8.encode('$salt:$pin');
  for (var i = 0; i < iteracoesHash; i++) {
    resumo = sha256.convert(resumo).bytes;
  }
  return base64Encode(resumo);
}

/// Compara em tempo constante: percorre a string inteira mesmo depois de
/// achar uma diferença, para o tempo de resposta não denunciar quantos
/// caracteres estavam certos (ataque de temporização).
bool compararSeguro(String a, String b) {
  if (a.length != b.length) return false;
  var diferenca = 0;
  for (var i = 0; i < a.length; i++) {
    diferenca |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diferenca == 0;
}

const _pinsComuns = {'123123', '121212', '112233', '696969', '159753', '102030', '010203'};

/// Devolve a instrução para corrigir o PIN, ou null se ele é aceitável.
String? problemaNoPin(String pin) {
  if (!RegExp('^\\d{$tamanhoPin}\$').hasMatch(pin)) {
    return 'Use exatamente $tamanhoPin números';
  }
  if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
    return 'Evite números repetidos, como 111111';
  }
  final digitos = pin.split('').map(int.parse).toList();
  final passos = {
    for (var i = 1; i < digitos.length; i++) (digitos[i] - digitos[i - 1]) % 10,
  };
  if (passos.length == 1 && (passos.first == 1 || passos.first == 9)) {
    return 'Evite sequências, como 123456 ou 654321';
  }
  if (_pinsComuns.contains(pin)) {
    return 'Esse PIN é muito usado. Escolha outro';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Senhas guardadas no cofre
// ---------------------------------------------------------------------------

/// Gera uma senha forte com o gerador criptográfico do sistema
/// (Random.secure), garantindo ao menos um caractere de cada grupo.
String gerarSenhaForte({int tamanho = 16}) {
  const grupos = [
    'abcdefghijkmnopqrstuvwxyz', // sem "l", que confunde com "1"
    'ABCDEFGHJKLMNPQRSTUVWXYZ', // sem "I" e "O"
    '23456789', // sem "0" e "1"
    '!@#\$%&*?-_+=',
  ];
  final caracteres = [for (final g in grupos) g[_aleatorio.nextInt(g.length)]];
  final todos = grupos.join();
  while (caracteres.length < tamanho) {
    caracteres.add(todos[_aleatorio.nextInt(todos.length)]);
  }
  caracteres.shuffle(_aleatorio);
  return caracteres.join();
}

enum ForcaSenha {
  muitoFraca('Muito fraca', 0.15),
  fraca('Fraca', 0.35),
  media('Média', 0.6),
  forte('Forte', 0.85),
  muitoForte('Muito forte', 1);

  const ForcaSenha(this.rotulo, this.progresso);
  final String rotulo;
  final double progresso;
}

const _senhasComuns = {
  '123456', '12345678', '123456789', 'senha', 'senha123', 'password',
  'qwerty', 'abc123', '111111', 'admin', 'iloveyou', '102030',
};

/// Estimativa simples de força: tamanho + variedade de caracteres.
ForcaSenha avaliarForca(String senha) {
  if (senha.isEmpty || _senhasComuns.contains(senha.toLowerCase())) {
    return ForcaSenha.muitoFraca;
  }
  if (RegExp(r'^(.)\1*$').hasMatch(senha)) return ForcaSenha.muitoFraca;

  var pontos = 0;
  if (senha.length >= 8) pontos++;
  if (senha.length >= 12) pontos++;
  if (senha.length >= 16) pontos++;
  final grupos = [
    RegExp('[a-z]'),
    RegExp('[A-Z]'),
    RegExp(r'\d'),
    RegExp(r'[^A-Za-z0-9]'),
  ].where((r) => r.hasMatch(senha)).length;
  pontos += grupos - 1;

  return switch (pontos) {
    <= 1 => ForcaSenha.muitoFraca,
    2 => ForcaSenha.fraca,
    3 => ForcaSenha.media,
    4 => ForcaSenha.forte,
    _ => ForcaSenha.muitoForte,
  };
}
