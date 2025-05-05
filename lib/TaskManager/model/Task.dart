class Task {
  final String id;
  String title;
  String description;
  String status;
  int priority;
  DateTime? dueDate;
  final DateTime createdAt;
  DateTime updatedAt;
  String? assignedTo;
  final String createdBy;
  String? category;
  List<String>? imagePaths;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    required this.createdBy,
    this.category,
    this.imagePaths,
    required this.completed,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      priority: map['priority'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      assignedTo: map['assignedTo'],
      createdBy: map['createdBy'],
      category: map['category'],
      imagePaths: map['imagePaths'] != null
          ? (map['imagePaths'] as String).split(',')
          : null, // Cập nhật tên
      completed: map['completed'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'category': category,
      'imagePaths': imagePaths?.join(','),
      'completed': completed ? 1 : 0,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    String? status,
    int? priority,
    DateTime? dueDate,
    DateTime? updatedAt,
    String? assignedTo,
    String? category,
    List<String>? imagePaths,
    bool? completed,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy,
      category: category ?? this.category,
      imagePaths: imagePaths ?? this.imagePaths,
      completed: completed ?? this.completed,
    );
  }
}