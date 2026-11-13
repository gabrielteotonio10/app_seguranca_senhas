/// Telas que não dependem de dado nenhum: entram no mapa de rotas
/// nomeadas (Aula 06). As que precisam de um item (o detalhe de uma
/// credencial) são abertas com push, levando o dado no construtor.
abstract final class Rotas {
  static const abertura = '/';
  static const criarPin = '/criar-pin';
  static const bloqueio = '/bloqueio';
  static const principal = '/principal';
  static const comoFunciona = '/como-funciona';
}
