import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Task/AddTaskScreen.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Task/EditTaskScreen.dart';
import 'package:projectcuoikyltmb/TaskManager/model/Task.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Task/TaskDetailScreen.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Authentication/LoginScreen.dart';
import 'package:projectcuoikyltmb/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Màn hình hiển thị danh sách công việc
class TaskListScreen extends StatefulWidget {
  // ID của người dùng hiện tại, dùng để lấy danh sách công việc và kiểm tra quyền
  final String currentUserId;

  const TaskListScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Danh sách tất cả công việc
  List<Task> tasks = [];

  // Danh sách công việc đã lọc (dựa trên trạng thái và từ khóa tìm kiếm)
  List<Task> filteredTasks = [];

  // Chế độ hiển thị: true là lưới (grid), false là danh sách (list)
  bool isGrid = false;

  // Trạng thái được chọn để lọc
  String selectedStatus = 'Tất cả';

  // Từ khóa tìm kiếm
  String searchKeyword = '';

  // Trạng thái đang tải (loading)
  bool _isLoading = false;

  // Kiểm tra xem cơ sở dữ liệu đã được khởi tạo chưa
  bool _dbInitialized = false;

  // Kiểm tra xem người dùng hiện tại có phải admin không
  bool _isAdmin = false;

  // Khởi tạo trạng thái: khởi tạo cơ sở dữ liệu và tải danh sách công việc
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Hàm khởi tạo cơ sở dữ liệu và kiểm tra quyền admin
  Future<void> _initializeDatabase() async {
    try {
      setState(() => _isLoading = true); // Hiển thị trạng thái đang tải
      // Khởi tạo cơ sở dữ liệu
      await TaskDatabaseHelper.instance.database;
      setState(() => _dbInitialized = true);

      // Lấy thông tin người dùng để kiểm tra xem có phải admin không
      final user = await UserDatabaseHelper.instance.getUserById(
        widget.currentUserId,
      );
      _isAdmin = user?.isAdmin ?? false;

      // Tải danh sách công việc
      await _loadTasks();
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không khởi tạo được cơ sở dữ liệu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khởi tạo database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false); // Tắt trạng thái đang tải
    }
  }

  // Hàm tải danh sách công việc từ cơ sở dữ liệu
  Future<void> _loadTasks() async {
    if (!_dbInitialized) return;

    try {
      setState(() => _isLoading = true); // Hiển thị trạng thái đang tải

      // Nếu là admin, lấy tất cả công việc; nếu không, chỉ lấy công việc của người dùng hiện tại
      if (_isAdmin) {
        tasks = await TaskDatabaseHelper.instance.getAllTasks();
      } else {
        tasks = await TaskDatabaseHelper.instance.getTasksByUser(
          widget.currentUserId,
        );
      }

      // Áp dụng bộ lọc sau khi tải danh sách
      _applyFilters();
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không tải được danh sách công việc
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải công việc: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false); // Tắt trạng thái đang tải
    }
  }

  // Hàm áp dụng bộ lọc (trạng thái và từ khóa tìm kiếm) cho danh sách công việc
  void _applyFilters() {
    setState(() {
      filteredTasks =
          tasks.where((task) {
            // Kiểm tra trạng thái: nếu chọn 'Tất cả', hiển thị mọi trạng thái
            final matchesStatus =
                selectedStatus == 'Tất cả' || task.status == selectedStatus;
            // Kiểm tra từ khóa: tìm kiếm trong tiêu đề và mô tả
            final matchesSearch =
                searchKeyword.isEmpty ||
                task.title.toLowerCase().contains(
                  searchKeyword.toLowerCase(),
                ) ||
                task.description.toLowerCase().contains(
                  searchKeyword.toLowerCase(),
                );
            return matchesStatus && matchesSearch;
          }).toList();

      // Sắp xếp theo độ ưu tiên (giảm dần)
      filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
    });
  }

  // Hàm kiểm tra xem công việc có được tạo bởi admin không
  Future<bool> _isTaskCreatedByAdmin(String createdById) async {
    final user = await UserDatabaseHelper.instance.getUserById(createdById);
    return user?.isAdmin ?? false;
  }

  // Hàm xóa công việc
  Future<void> _deleteTask(String taskId) async {
    final task = tasks.firstWhere((t) => t.id == taskId);

    // Kiểm tra xem công việc có được tạo bởi admin không
    bool isCreatedByAdmin = await _isTaskCreatedByAdmin(task.createdBy);
    bool isAssignedByAdmin =
        isCreatedByAdmin && task.createdBy != widget.currentUserId;

    // Nếu không phải admin và công việc được gán bởi admin, không cho xóa
    if (!_isAdmin && isAssignedByAdmin) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Thông báo !'),
              content: const Text('Không thể xóa công việc do Admin đã gán!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.teal.shade600),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    // Hiển thị dialog xác nhận xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa công việc này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    // Nếu người dùng xác nhận xóa, tiến hành xóa công việc
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true); // Hiển thị trạng thái đang tải
        await TaskDatabaseHelper.instance.deleteTask(taskId);
        await _loadTasks(); // Tải lại danh sách công việc sau khi xóa
      } catch (e) {
        // Hiển thị thông báo lỗi nếu không xóa được
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa task: $e')));
      } finally {
        setState(() => _isLoading = false); // Tắt trạng thái đang tải
      }
    }
  }

  // Hàm kiểm tra xem ngày đến hạn có trong vòng 2 ngày từ hiện tại không
  bool _isDueDateWithinTwoDays(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference <= 2 && difference >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Thiết lập nền cho toàn bộ màn hình với màu teal nhạt và hình ảnh pattern
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          image: const DecorationImage(
            image: AssetImage('assets/pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.1,
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
                : Column(
                  children: [
                    // Custom AppBar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.pink.shade200],
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Danh sách Công việc',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Hiển thị nhãn "ADMIN" nếu người dùng là admin
                                  if (_isAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Nút làm mới danh sách công việc
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: _loadTasks,
                                ),
                                // Nút chuyển đổi giữa chế độ lưới và danh sách
                                IconButton(
                                  icon: Icon(
                                    isGrid ? Icons.view_list : Icons.grid_view,
                                    color: Colors.white,
                                  ),
                                  onPressed:
                                      () => setState(() => isGrid = !isGrid),
                                ),
                                // Menu tùy chọn (hiện tại chỉ có tùy chọn đăng xuất)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'logout') {
                                      _showLogoutDialog();
                                    }
                                  },
                                  itemBuilder:
                                      (ctx) => [
                                        PopupMenuItem(
                                          value: 'logout',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.exit_to_app,
                                                color: Colors.pink.shade400,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Đăng xuất',
                                                style: TextStyle(
                                                  color: Colors.pink.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Phần tìm kiếm và lọc
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: 4,
                      ),
                      child: Column(
                        children: [
                          // Trường tìm kiếm công việc
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm công việc...',
                              hintStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.teal.shade600,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              searchKeyword = value;
                              _applyFilters(); // Áp dụng bộ lọc sau mỗi lần nhập
                            },
                          ),
                          const SizedBox(height: 8),
                          // Dropdown lọc theo trạng thái
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Lọc theo trạng thái',
                              labelStyle: TextStyle(
                                color: Colors.teal.shade600,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.teal.shade400,
                                  width: 2,
                                ),
                              ),
                            ),
                            items:
                                [
                                      'Tất cả',
                                      'To do',
                                      'In progress',
                                      'Done',
                                      'Cancelled',
                                    ]
                                    .map(
                                      (status) => DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              selectedStatus = value!;
                              _applyFilters(); // Áp dụng bộ lọc khi thay đổi trạng thái
                            },
                          ),
                        ],
                      ),
                    ),
                    // Hiển thị danh sách hoặc lưới công việc
                    Expanded(
                      child:
                          isGrid ? _buildTaskGridView() : _buildTaskListView(),
                    ),
                  ],
                ),
      ),
      // Nút thêm công việc mới
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Chuyển đến màn hình thêm công việc
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AddTaskScreen(currentUserId: widget.currentUserId),
            ),
          );
          // Nếu thêm thành công, tải lại danh sách công việc
          if (result == true) await _loadTasks();
        },
        backgroundColor: Colors.transparent,
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade300, Colors.pink.shade200],
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng danh sách công việc dạng ListView
  Widget _buildTaskListView() {
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        // Kiểm tra xem công việc có trạng thái Done hoặc Cancelled và người dùng có phải admin không
        final isDoneOrCancelled =
            task.status == 'Done' || task.status == 'Cancelled';
        final shouldDisable = !_isAdmin && isDoneOrCancelled;

        return GestureDetector(
          onTap:
              shouldDisable
                  ? null // Vô hiệu hóa nhấp nếu là user thường và task Done/Cancelled
                  : () async {
                    // Chuyển đến màn hình chi tiết công việc
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                    await _loadTasks(); // Tải lại danh sách sau khi quay lại
                  },
          child: Opacity(
            opacity: shouldDisable ? 0.5 : 1.0,
            // Làm mờ nếu là user thường và task Done/Cancelled
            child: Container(
              margin: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 2,
                bottom: 4,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị hình ảnh đầu tiên nếu có
                  if (task.imagePaths != null && task.imagePaths!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(task.imagePaths![0]),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Hiển thị biểu tượng cảnh báo nếu ngày đến hạn gần
                            if (task.dueDate != null &&
                                _isDueDateWithinTwoDays(task.dueDate!))
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.teal.shade900,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trạng thái: ${task.status}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(task.status),
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Text(
                          'Ưu tiên: ${_priorityText(task.priority)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal.shade700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Các nút hành động (chỉnh sửa, xóa)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.teal.shade700),
                        onPressed:
                            shouldDisable
                                ? null // Vô hiệu hóa nút Edit nếu là user thường và task Done/Cancelled
                                : () async {
                                  // Chuyển đến màn hình chỉnh sửa công việc
                                  final updatedTask = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditTaskScreen(
                                            task: task,
                                            currentUserId: widget.currentUserId,
                                          ),
                                    ),
                                  );
                                  // Nếu có thay đổi, cập nhật và tải lại danh sách
                                  if (updatedTask != null) {
                                    await TaskDatabaseHelper.instance
                                        .updateTask(updatedTask);
                                    await _loadTasks();
                                  }
                                },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.pink.shade500),
                        onPressed:
                            shouldDisable
                                ? null // Vô hiệu hóa nút Delete nếu là user thường và task Done/Cancelled
                                : () => _deleteTask(task.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Hàm xây dựng danh sách công việc dạng GridView
  Widget _buildTaskGridView() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // CHỈNH: giảm tỷ lệ để card cao hơn
      ),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        final isDoneOrCancelled =
            task.status == 'Done' || task.status == 'Cancelled';
        final shouldDisable = !_isAdmin && isDoneOrCancelled;

        return GestureDetector(
          onTap:
              shouldDisable
                  ? null
                  : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                    await _loadTasks();
                  },
          child: Opacity(
            opacity: shouldDisable ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (task.dueDate != null &&
                          _isDueDateWithinTwoDays(task.dueDate!))
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade900,
                            fontFamily: 'Roboto',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trạng thái: ${task.status}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStatusColor(task.status),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    'Ưu tiên: ${_priorityText(task.priority)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal.shade700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.teal.shade700,
                          size: 18,
                        ),
                        onPressed:
                            shouldDisable
                                ? null
                                : () async {
                                  final updatedTask = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditTaskScreen(
                                            task: task,
                                            currentUserId: widget.currentUserId,
                                          ),
                                    ),
                                  );
                                  if (updatedTask != null) {
                                    await TaskDatabaseHelper.instance
                                        .updateTask(updatedTask);
                                    await _loadTasks();
                                  }
                                },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.pink.shade500,
                          size: 18,
                        ),
                        onPressed:
                            shouldDisable ? null : () => _deleteTask(task.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Hàm hiển thị dialog xác nhận đăng xuất
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xác nhận đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: Colors.teal.shade600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Xóa dữ liệu SharedPreferences và chuyển về màn hình đăng nhập
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.pink.shade400),
                ),
              ),
            ],
          ),
    );
  }

  // Hàm trả về màu sắc tương ứng với độ ưu tiên
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.orange.shade100;
      case 3:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Hàm trả về văn bản mô tả độ ưu tiên
  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  // Hàm trả về màu sắc tương ứng với trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'To do':
        return Colors.teal.shade700;
      case 'In progress':
        return Colors.orange.shade700;
      case 'Done':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.pink.shade500;
      default:
        return Colors.grey.shade700;
    }
  }
}