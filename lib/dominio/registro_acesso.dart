/// Como a pessoa tentou provar a identidade.
enum MetodoAcesso {
  biometria('Biometria'),
  pin('PIN');

  const MetodoAcesso(this.rotulo);
  final String rotulo;
}

/// Uma linha do histórico de acessos (auditoria).
///
/// Toda tentativa, liberada ou negada, vira um registro. É assim que um
/// sistema seguro deixa rastro de quem tentou entrar e quando.
class RegistroAcesso {
  const RegistroAcesso({
    this.id,
    required this.momento,
    required this.metodo,
    required this.sucesso,
    required this.motivo,
  });

  final int? id; // nulo enquanto não foi gravado
  final DateTime momento;
  final MetodoAcesso metodo;
  final bool sucesso;
  final String motivo; // ex.: "Desbloquear o cofre", "Revelar a senha de Gmail"

  RegistroAcesso comId(int novoId) => RegistroAcesso(
        id: novoId,
        momento: momento,
        metodo: metodo,
        sucesso: sucesso,
        motivo: motivo,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'momento': momento.toIso8601String(), // SQLite não tem data: texto ISO
        'metodo': metodo.name,
        'sucesso': sucesso ? 1 : 0, // SQLite não tem booleano: 0 e 1
        'motivo': motivo,
      };

  factory RegistroAcesso.fromMap(Map<String, Object?> m) => RegistroAcesso(
        id: m['id'] as int?,
        momento: DateTime.parse(m['momento'] as String),
        metodo: MetodoAcesso.values.byName(m['metodo'] as String),
        sucesso: (m['sucesso'] as int) == 1,
        motivo: m['motivo'] as String,
      );
}
