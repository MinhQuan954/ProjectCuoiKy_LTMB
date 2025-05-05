import '../model/User.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDatabaseHelper {
  static final UserDatabaseHelper instance = UserDatabaseHelper._init();
  static Database? _database;

  // Constructor private theo Singleton Pattern
  UserDatabaseHelper._init();

  // Getter để lấy database (nếu chưa có thì tạo mới)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  // Hàm khởi tạo database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Hàm tạo bảng trong database khi mở lần đầu
  Future _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar TEXT,
        createdAt TEXT NOT NULL,
        lastActive TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tạo các chỉ mục (index) giúp tối ưu tìm kiếm
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_email ON users(email)');

    // Thêm dữ liệu mẫu vào bảng users
    await _insertSampleData(db);
  }

  // Phương thức chèn dữ liệu mẫu vào bảng users
  Future _insertSampleData(Database db) async {
    final List<Map<String, dynamic>> sampleUsers = [
      {
        'id': 'user1',
        'username': 'Hoàng Minh Quân',
        'password': '123456a@',
        'email': 'minhquan09504@gmail.com',
        'avatar': null,
        'createdAt': DateTime(2023, 1, 1).toIso8601String(),
        'lastActive': DateTime(2023, 4, 1).toIso8601String(),
        'isAdmin': 1,
      },
      {
        'id': 'user2',
        'username': 'Lâm Quốc Bảo',
        'password': '123456a@',
        'email': 'baocanada@gmail.com',
        'avatar': null,
        'createdAt': DateTime(2023, 2, 10).toIso8601String(),
        'lastActive': DateTime(2023, 4, 10).toIso8601String(),
        'isAdmin': 0,
      },
      {
        'id': 'user3',
        'username': 'Hoàng Tuấn Phúc',
        'password': '123456a@',
        'email': 'phucphowr@gmail.com',
        'avatar': null,
        'createdAt': DateTime(2023, 3, 5).toIso8601String(),
        'lastActive': DateTime(2023, 4, 5).toIso8601String(),
        'isAdmin': 0,
      },
      {
        'id': 'user4',
        'username': 'Ngô Minh Tân',
        'password': '123456a@',
        'email': 'tannhii@gmail.com',
        'avatar': null,
        'createdAt': DateTime(2023, 4, 7).toIso8601String(),
        'lastActive': DateTime(2023, 4, 12).toIso8601String(),
        'isAdmin': 0,
      },
      {
        'id': 'user5',
        'username': 'Nguyễn Thái Bình',
        'password': '123456a@',
        'email': 'binhpko@gmail.com',
        'avatar': null,
        'createdAt': DateTime(2023, 5, 10).toIso8601String(),
        'lastActive': DateTime(2023, 5, 15).toIso8601String(),
        'isAdmin': 0,
      },
    ];

    // Chèn vào cơ sở dữ liệu
    for (final userData in sampleUsers) {
      await db.insert('users', userData);
    }
  }

  // Đóng database khi không cần nữa
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // ---------- CRUD - Các hàm xử lý dữ liệu ----------

  // Thêm mới một User
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  // Lấy tất cả Users
  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Lấy một User theo id
  Future<User?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
  // Thêm phương thức để kiểm tra thông tin đăng nhập (email và mật khẩu)
  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật một User
  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Xóa một User
  Future<int> deleteUser(String id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Tìm kiếm và lọc dữ liệu ----------

  // Tìm kiếm User theo username (có keyword)
  Future<List<User>> searchUsersByUsername(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Lấy tất cả Users trừ một User cụ thể
  Future<List<User>> getAllUsersExcept(String exceptUserId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id != ?',
      whereArgs: [exceptUserId],
    );
    return result.map((map) => User.fromMap(map)).toList();
  }
}
