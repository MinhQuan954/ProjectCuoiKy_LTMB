class User {
  final String id;
  String username;
  String password;
  String email;
  String? avatar;
  final DateTime createdAt;
  DateTime lastActive;
  bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.lastActive,
    this.isAdmin = false,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      avatar: map['avatar'],
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
      isAdmin: map['isAdmin'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isAdmin': isAdmin ? 1 : 0,
    };
  }


  // copyWith
  User copyWith({
    String? username,
    String? password,
    String? email,
    String? avatar,
    DateTime? lastActive,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, password: $password, email: $email, '
        'avatar: $avatar, createdAt: $createdAt, lastActive: $lastActive)';
  }
}
