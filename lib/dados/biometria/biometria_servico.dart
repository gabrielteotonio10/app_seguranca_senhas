/// Qual biometria o aparelho oferece (só para escolher textos e ícones).
enum TipoBiometria { rosto, digital, generica, nenhuma }

/// O que voltou da tentativa de autenticação.
enum StatusBiometria {
  sucesso,
  falhou, // rosto/digital não reconhecido
  cancelado, // a pessoa fechou o diálogo
  indisponivel, // sem sensor ou sem biometria cadastrada
  bloqueado, // o próprio sistema bloqueou após muitas falhas
}

/// O contrato que qualquer forma de biometria precisa cumprir.
///
/// O ponto mais importante da apresentação está aqui: o app NUNCA recebe
/// a imagem do rosto nem a digital. Quem compara é o sistema operacional,
/// dentro de um chip isolado (Secure Enclave no iPhone, TEE no Android,
/// TPM no Windows). O app só recebe a resposta: deu certo ou não.
abstract class BiometriaServico {
  /// Nome técnico mostrado em Ajustes.
  String get descricao;

  Future<bool> disponivel();

  Future<TipoBiometria> tipo();

  Future<StatusBiometria> autenticar(String motivo);

  /// Esquece qualquer vínculo criado (usado ao desativar a biometria).
  Future<void> redefinir();
}
