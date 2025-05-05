import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projectcuoikyltmb/TaskManager/model/Task.dart';
import 'package:intl/intl.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';

// Màn hình hiển thị chi tiết công việc
class TaskDetailScreen extends StatefulWidget {
  // Công việc cần hiển thị chi tiết
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // Biến lưu công việc, được khởi tạo từ Task truyền vào
  late Task task;

  // Định dạng ngày tháng để hiển thị
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Biến lưu tên người được gán công việc
  String? assigneeName;

  // Khởi tạo trạng thái: lấy dữ liệu từ Task và tải tên người được gán
  @override
  void initState() {
    super.initState();
    task = widget.task;
    _loadAssigneeName(); // Tải tên người được gán khi khởi tạo
  }

  // Hàm tải tên người được gán từ cơ sở dữ liệu
  Future<void> _loadAssigneeName() async {
    if (task.assignedTo != null && task.assignedTo!.isNotEmpty) {
      try {
        // Lấy thông tin người dùng từ ID
        final user = await UserDatabaseHelper.instance.getUserById(task.assignedTo!);
        setState(() {
          assigneeName = user?.username ?? 'Không xác định';
        });
      } catch (e) {
        // Nếu có lỗi, hiển thị thông báo mặc định
        setState(() {
          assigneeName = 'Không xác định';
        });
      }
    } else {
      // Nếu không có người được gán, hiển thị thông báo mặc định
      setState(() {
        assigneeName = 'Chưa được gán';
      });
    }
  }

  // Hàm cập nhật trạng thái công việc
  void _updateStatus(String newStatus) {
    setState(() {
      task = task.copyWith(status: newStatus, updatedAt: DateTime.now());
    });
  }

  // Hàm hiển thị hình ảnh lớn hơn khi nhấp vào thumbnail
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                // Hiển thị biểu tượng lỗi nếu không tải được hình ảnh
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm xây dựng danh sách hình ảnh đính kèm
  Widget _buildImages() {
    if (task.imagePaths == null || task.imagePaths!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Không có hình ảnh đính kèm.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: task.imagePaths!.length,
            itemBuilder: (context, index) {
              final path = task.imagePaths![index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => _showFullImage(path), // Nhấp để xem hình ảnh lớn hơn
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      // Hiển thị thông báo lỗi nếu không tải được hình ảnh
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'Không tải được ảnh',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Hàm xây dựng thẻ thông tin (info card) để hiển thị các chi tiết của công việc
  Widget _buildInfoCard(String title, String content, {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                // Hiển thị biểu tượng cảnh báo nếu ngày đến hạn gần (trong vòng 2 ngày)
                if (title == 'Ngày tới hạn' &&
                    task.dueDate != null &&
                    _isDueDateWithinTwoDays(task.dueDate!))
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Chi tiết Công việc'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị tiêu đề công việc
              _buildInfoCard(
                'Tiêu đề',
                task.title,
              ),
              // Hiển thị mô tả công việc
              _buildInfoCard(
                'Mô tả',
                task.description.isNotEmpty ? task.description : 'Không có mô tả',
              ),
              // Hiển thị trạng thái công việc với màu sắc tương ứng
              _buildInfoCard(
                'Trạng thái',
                task.status,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Hiển thị độ ưu tiên
              _buildInfoCard(
                'Ưu tiên',
                '${task.priority}',
              ),
              // Hiển thị ngày đến hạn
              _buildInfoCard(
                'Ngày tới hạn',
                task.dueDate != null
                    ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
                    : 'Chưa đặt ngày tới hạn',
              ),
              // Hiển thị tên người được gán
              _buildInfoCard(
                'Được gán cho',
                assigneeName ?? 'Đang tải...',
              ),
              // Hiển thị ngày tạo
              _buildInfoCard(
                'Ngày tạo',
                _dateFormat.format(task.createdAt),
              ),
              // Hiển thị ngày cập nhật
              _buildInfoCard(
                'Ngày cập nhật',
                _dateFormat.format(task.updatedAt),
              ),
              const SizedBox(height: 8),
              // Tiêu đề phần hình ảnh đính kèm
              const Text(
                'Hình ảnh đính kèm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // Hiển thị danh sách hình ảnh
              _buildImages(),
              const SizedBox(height: 24),
              // Thẻ để cập nhật trạng thái công việc
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cập nhật trạng thái',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dropdown để cập nhật trạng thái
                      DropdownButtonFormField<String>(
                        value: task.status,
                        items: ['To do', 'In progress', 'Done', 'Cancelled']
                            .map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                status,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateStatus(value);
                          }
                        },
                        style: const TextStyle(color: Colors.black87),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm trả về màu sắc tương ứng với trạng thái công việc
  Color _getStatusColor(String status) {
    switch (status) {
      case 'To do':
        return Colors.blue;
      case 'In progress':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}