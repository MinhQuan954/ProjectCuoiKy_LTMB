import 'dart:io';
import '../model/Task.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TaskDatabaseHelper {
  static final TaskDatabaseHelper instance = TaskDatabaseHelper._init();
  static Database? _database;

  TaskDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Kiểm tra xem database đã tồn tại chưa
    bool dbExists = await databaseExists(path);

    if (!dbExists) {
      // Nếu không tồn tại, tạo database mới
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      return await openDatabase(path, version: 1, onCreate: _createDB);
    } else {
      // Nếu đã tồn tại, mở database
      return await openDatabase(path);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        assignedTo TEXT,
        createdBy TEXT NOT NULL,
        category TEXT,
        imagePaths TEXT, -- Đổi tên từ 'attachments' thành 'imagePaths'
        completed INTEGER NOT NULL
      )
    ''');

    // Tạo index để tối ưu hiệu suất
    await db.execute('CREATE INDEX idx_tasks_createdBy ON tasks(createdBy)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_priority ON tasks(priority)');
  }

  Future<int> createTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksByUser(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'createdBy = ? OR assignedTo = ?',
      whereArgs: [userId, userId],
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}