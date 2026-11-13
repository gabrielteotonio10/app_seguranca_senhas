import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../dominio/registro_acesso.dart';
import 'acessos_repositorio.dart';

/// Histórico de acessos no SQLite (Android, iOS e macOS).
class AcessosSqlite implements AcessosRepositorio {
  Database? _db;

  Future<Database> _abrir() async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'cofre_id.db'),
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE acessos('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'momento TEXT NOT NULL, '
          'metodo TEXT NOT NULL, '
          'sucesso INTEGER NOT NULL, '
          'motivo TEXT NOT NULL)',
        ),
      );

  @override
  Future<List<RegistroAcesso>> carregar() async {
    final db = await _abrir();
    final linhas = await db.query('acessos', orderBy: 'momento DESC', limit: 200);
    return linhas.map(RegistroAcesso.fromMap).toList();
  }

  @override
  Future<RegistroAcesso> salvar(RegistroAcesso registro) async {
    final db = await _abrir();
    final id = await db.insert('acessos', registro.toMap()..remove('id'));
    return registro.comId(id);
  }

  @override
  Future<void> apagarTudo() async {
    final db = await _abrir();
    await db.delete('acessos');
  }
}
