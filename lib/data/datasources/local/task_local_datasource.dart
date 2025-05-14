import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/task_model.dart';
import '../../../core/errors/exceptions.dart'; // Assuming this path is correct

const String _tasksTable = 'tasks';

abstract class TaskLocalDataSource {
  Future<List<Task>> getTasks();
  Future<Task> getTaskById(String id);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> clearAllTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  Database? _database;
  static const int _dbVersion = 2; // Incremented for schema change
  static const String _dbName = 'tasks_database.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tasksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL,
        createdDate TEXT NOT NULL,
        priority TEXT NOT NULL,
        tags TEXT DEFAULT ''
      )
    ''');
    await db.execute('CREATE INDEX idx_task_isCompleted ON $_tasksTable(isCompleted)');
    await db.execute('CREATE INDEX idx_task_priority ON $_tasksTable(priority)');
    await db.execute('CREATE INDEX idx_task_tags ON $_tasksTable(tags)');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE $_tasksTable ADD COLUMN tags TEXT DEFAULT ''");
        await db.execute('CREATE INDEX IF NOT EXISTS idx_task_tags ON $_tasksTable(tags)');
        print("Database upgraded: 'tags' column added.");
      } catch (e) {
        print("Error upgrading database to add 'tags' column: $e");
      }
    }
  }

  @override
  Future<void> addTask(Task task) async {
    final db = await database;
    try {
      await db.insert(
        _tasksTable,
        task.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to add task: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await database;
    try {
      final count = await db.delete(
        _tasksTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw CacheException('Task with id $id not found for deletion.');
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to delete task: ${e.toString()}');
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(_tasksTable, orderBy: 'createdDate DESC');
      return List.generate(maps.length, (i) {
        return Task.fromDbMap(maps[i]);
      });
    } catch (e) {
      throw CacheException('Failed to get tasks: ${e.toString()}');
    }
  }
  
  @override
  Future<Task> getTaskById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tasksTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Task.fromDbMap(maps.first);
      } else {
        throw CacheException('Task with id $id not found.');
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get task by id: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = await database;
    try {
      final count = await db.update(
        _tasksTable,
        task.toDbMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      if (count == 0) {
        throw CacheException('Task with id ${task.id} not found for update.');
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to update task: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllTasks() async {
     final db = await database;
    try {
      await db.delete(_tasksTable);
    } catch (e) {
      throw CacheException('Failed to clear tasks: ${e.toString()}');
    }
  }

  Future<void> close() async {
    final db = await database; // Ensure _database is initialized
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }
}