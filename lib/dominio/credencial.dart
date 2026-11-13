/// Uma conta guardada no cofre.
///
/// Repare que a senha NÃO é um campo desta classe: ela fica no
/// armazenamento cifrado do sistema e só é lida depois que a pessoa
/// confirma a identidade (Face ID ou PIN). Assim, a lista que aparece na
/// tela nunca carrega segredo nenhum na memória.
class Credencial {
  const Credencial({
    required this.id,
    required this.servico,
    required this.usuario,
    required this.criadaEm,
  });

  final String id;
  final String servico;
  final String usuario;
  final DateTime criadaEm;

  /// Letra que aparece no avatar da lista.
  String get inicial => servico.trim().isEmpty ? '?' : servico.trim()[0].toUpperCase();

  Map<String, Object?> toMap() => {
        'id': id,
        'servico': servico,
        'usuario': usuario,
        'criadaEm': criadaEm.toIso8601String(),
      };

  factory Credencial.fromMap(Map<String, Object?> m) => Credencial(
        id: m['id'] as String,
        servico: m['servico'] as String,
        usuario: m['usuario'] as String,
        criadaEm: DateTime.parse(m['criadaEm'] as String),
      );
}
