import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:projectcuoikyltmb/TaskManager/model/Task.dart';
import 'package:projectcuoikyltmb/TaskManager/model/User.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';

// Màn hình chỉnh sửa công việc đã có sẵn
class EditTaskScreen extends StatefulWidget {
  // Công việc cần chỉnh sửa
  final Task task;
  // ID của người dùng hiện tại, dùng để kiểm tra quyền chỉnh sửa
  final String currentUserId;

  const EditTaskScreen({
    Key? key,
    required this.task,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  // Key để quản lý trạng thái của Form (dùng để validate dữ liệu nhập)
  final _formKey = GlobalKey<FormState>();

  // Controller để lấy và quản lý dữ liệu nhập từ TextFormField
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // Các giá trị hiện tại của công việc, được khởi tạo từ Task truyền vào
  late String _status;
  late int _priority;
  late DateTime? _dueDate;
  late String? _assignedTo;
  late List<String> _imagePaths;

  // Danh sách người dùng để gán công việc (chỉ dành cho admin)
  List<User> _users = [];

  // Trạng thái đang tải (loading)
  bool _isLoading = false;

  // Kiểm tra xem người dùng hiện tại có phải admin không
  bool _isAdmin = false;

  // Kiểm tra xem người dùng có quyền chỉnh sửa toàn bộ các trường không
  bool _canEditAllFields = true;

  // Định dạng ngày tháng để hiển thị
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Danh sách các tùy chọn trạng thái và độ ưu tiên
  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  // Khởi tạo trạng thái: lấy dữ liệu từ Task và kiểm tra quyền chỉnh sửa
  @override
  void initState() {
    super.initState();
    // Khởi tạo các giá trị từ Task truyền vào
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
    _assignedTo = widget.task.assignedTo;
    _imagePaths = widget.task.imagePaths ?? [];

    // Tải danh sách người dùng và kiểm tra quyền chỉnh sửa
    _loadUsersAndCheckPermissions();
  }

  // Giải phóng tài nguyên (controller) khi widget bị hủy
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Hàm tải danh sách người dùng và kiểm tra quyền chỉnh sửa
  Future<void> _loadUsersAndCheckPermissions() async {
    setState(() => _isLoading = true); // Hiển thị trạng thái đang tải
    try {
      // Lấy thông tin người dùng hiện tại để kiểm tra xem có phải admin không
      User? currentUser = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = currentUser?.isAdmin ?? false;

      // Kiểm tra quyền chỉnh sửa toàn bộ trường
      if (_isAdmin) {
        _canEditAllFields = true; // Admin có thể chỉnh sửa tất cả
      } else {
        if (widget.task.createdBy == widget.currentUserId) {
          _canEditAllFields = true; // Người tạo công việc có thể chỉnh sửa tất cả
        } else {
          // Nếu không phải người tạo, kiểm tra xem công việc có được tạo bởi admin không
          bool isCreatedByAdmin = await _isTaskCreatedByAdmin(widget.task.createdBy);
          _canEditAllFields = !isCreatedByAdmin; // Không thể chỉnh sửa nếu công việc do admin tạo
        }
      }

      // Nếu là admin, tải danh sách người dùng để gán công việc
      if (_isAdmin) {
        _users = await UserDatabaseHelper.instance.getAllUsersExcept(widget.currentUserId);
      } else {
        _users = []; // Nếu không phải admin, không hiển thị tùy chọn gán người dùng
      }
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không tải được dữ liệu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false); // Tắt trạng thái đang tải
    }
  }

  // Hàm kiểm tra xem công việc có được tạo bởi admin không
  Future<bool> _isTaskCreatedByAdmin(String createdById) async {
    final user = await UserDatabaseHelper.instance.getUserById(createdById);
    return user?.isAdmin ?? false;
  }

  // Hàm chọn hình ảnh từ thiết bị
  Future<void> _pickImages() async {
    try {
      // Sử dụng FilePicker để chọn nhiều hình ảnh (jpg, jpeg, png)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      // Nếu có hình ảnh được chọn, thêm vào danh sách _imagePaths
      if (result != null) {
        setState(() {
          _imagePaths.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không chọn được hình ảnh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn hình ảnh: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Hàm xóa hình ảnh khỏi danh sách
  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  // Hàm chọn ngày đến hạn cho công việc
  Future<void> _selectDueDate(BuildContext context) async {
    // Hiển thị DatePicker để người dùng chọn ngày
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    // Nếu ngày được chọn hợp lệ, cập nhật _dueDate
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // Hàm lưu các thay đổi: cập nhật Task và trả về kết quả
  void _handleSave() {
    // Kiểm tra dữ liệu nhập trong form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      // Tạo bản sao của Task với các giá trị đã chỉnh sửa
      final updatedTask = widget.task.copyWith(
        title: _canEditAllFields ? _titleController.text : widget.task.title,
        description: _canEditAllFields ? _descriptionController.text : widget.task.description,
        status: _status,
        priority: _canEditAllFields ? _priority : widget.task.priority,
        dueDate: _canEditAllFields ? _dueDate : widget.task.dueDate,
        updatedAt: DateTime.now(),
        assignedTo: _canEditAllFields && _isAdmin ? _assignedTo : widget.task.assignedTo,
        imagePaths: _canEditAllFields && _imagePaths.isNotEmpty ? _imagePaths : widget.task.imagePaths,
        completed: _status == 'Done',
      );

      // Trả về Task đã cập nhật và thoát màn hình
      Navigator.pop(context, updatedTask);
    }
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
              child: Text(
                'Đóng',
                style: TextStyle(
                  color: Colors.teal.shade600,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        child: _isLoading
            ? Center(
          // Hiển thị loading indicator khi đang tải dữ liệu
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
          ),
        )
            : Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade300, Colors.pink.shade200],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút quay lại
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Tiêu đề AppBar
                    Text(
                      'Chỉnh sửa công việc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    // Nút lưu thay đổi
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ),
            // Form chỉnh sửa thông tin công việc
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề phần thông tin cơ bản
                      Text(
                        'Thông tin cơ bản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trường nhập Tiêu đề
                      _canEditAllFields
                          ? TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Nhập tiêu đề công việc',
                          labelStyle: TextStyle(color: Colors.teal.shade600),
                          hintStyle: TextStyle(color: Colors.teal.shade600),
                          prefixIcon: Icon(Icons.title, color: Colors.teal.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                        // Kiểm tra dữ liệu nhập tiêu đề
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      )
                          : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          labelStyle: TextStyle(color: Colors.teal.shade600),
                          prefixIcon: Icon(Icons.title, color: Colors.teal.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trường nhập Mô tả
                      _canEditAllFields
                          ? TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả chi tiết...',
                          labelStyle: TextStyle(color: Colors.teal.shade600),
                          hintStyle: TextStyle(color: Colors.teal.shade600),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description, color: Colors.teal.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                      )
                          : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          labelStyle: TextStyle(color: Colors.teal.shade600),
                          prefixIcon: Icon(Icons.description, color: Colors.teal.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          widget.task.description ?? 'Không có mô tả',
                          style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tiêu đề phần cài đặt công việc
                      Text(
                        'Cài đặt công việc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trạng thái và Độ ưu tiên
                      Row(
                        children: [
                          // Dropdown chọn Trạng thái
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Trạng thái',
                                labelStyle: TextStyle(color: Colors.teal.shade600),
                                prefixIcon: Icon(Icons.info, color: Colors.teal.shade600),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: const TextStyle(fontFamily: 'Roboto')),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown chọn Độ ưu tiên (chỉ hiển thị nếu có quyền chỉnh sửa)
                          Expanded(
                            child: _canEditAllFields
                                ? DropdownButtonFormField<int>(
                              value: _priority,
                              decoration: InputDecoration(
                                labelText: 'Độ ưu tiên',
                                labelStyle: TextStyle(color: Colors.teal.shade600),
                                prefixIcon: Icon(Icons.priority_high, color: Colors.teal.shade600),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              items: _priorityOptions.map((priority) {
                                return DropdownMenuItem<int>(
                                  value: priority,
                                  child: Text('Mức $priority', style: const TextStyle(fontFamily: 'Roboto')),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _priority = value;
                                  });
                                }
                              },
                            )
                                : InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Độ ưu tiên',
                                labelStyle: TextStyle(color: Colors.teal.shade600),
                                prefixIcon: Icon(Icons.priority_high, color: Colors.teal.shade600),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              child: Text(
                                'Mức $_priority',
                                style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ngày đến hạn (chỉ hiển thị nếu có quyền chỉnh sửa)
                      _canEditAllFields
                          ? InkWell(
                        onTap: () => _selectDueDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày đến hạn',
                            labelStyle: TextStyle(color: Colors.teal.shade600),
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.teal.shade600),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dueDate == null
                                    ? 'Chọn ngày'
                                    : _dateFormat.format(_dueDate!),
                                style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.teal.shade600),
                            ],
                          ),
                        ),
                      )
                          : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày đến hạn',
                          labelStyle: TextStyle(color: Colors.teal.shade600),
                          prefixIcon: Icon(Icons.calendar_today, color: Colors.teal.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: Text(
                          _dueDate == null ? 'Chưa đặt ngày' : _dateFormat.format(_dueDate!),
                          style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gán cho người dùng (chỉ hiển thị nếu người dùng là admin)
                      if (_users.isNotEmpty && _isAdmin)
                        _canEditAllFields
                            ? DropdownButtonFormField<String>(
                          value: _assignedTo,
                          decoration: InputDecoration(
                            labelText: 'Gán cho người dùng',
                            labelStyle: TextStyle(color: Colors.teal.shade600),
                            prefixIcon: Icon(Icons.person_add, color: Colors.teal.shade600),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Không gán', style: TextStyle(fontFamily: 'Roboto')),
                            ),
                            ..._users.map((user) {
                              return DropdownMenuItem<String>(
                                value: user.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.teal.shade100,
                                      child: Text(
                                        user.username[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.teal.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(user.username, style: const TextStyle(fontFamily: 'Roboto')),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _assignedTo = value;
                            });
                          },
                        )
                            : InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Gán cho người dùng',
                            labelStyle: TextStyle(color: Colors.teal.shade600),
                            prefixIcon: Icon(Icons.person_add, color: Colors.teal.shade600),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_assignedTo != null)
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.teal.shade100,
                                  child: Text(
                                    _users
                                        .firstWhere((user) => user.id == _assignedTo)
                                        .username[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.teal.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 10),
                              Text(
                                _assignedTo != null
                                    ? _users.firstWhere((user) => user.id == _assignedTo).username
                                    : 'Không gán',
                                style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                              ),
                            ],
                          ),
                        ),
                      if (_users.isNotEmpty && _isAdmin) const SizedBox(height: 20),

                      // Phần hình ảnh đính kèm
                      Text(
                        'Hình ảnh đính kèm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade800,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Nút thêm hình ảnh (chỉ hiển thị nếu user có quyền chỉnh sửa)
                      if (_canEditAllFields)
                        OutlinedButton(
                          onPressed: _pickImages,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.teal.shade600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: Colors.teal.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Thêm hình ảnh (.jpg, .png)',
                                style: TextStyle(
                                  color: Colors.teal.shade600,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Danh sách hình ảnh đã chọn (luôn hiển thị, có thể nhấp để xem lớn hơn)
                      if (_imagePaths.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePaths.length,
                            itemBuilder: (context, index) {
                              final path = _imagePaths[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    // Nhấp vào hình ảnh để xem lớn hơn
                                    GestureDetector(
                                      onTap: () => _showFullImage(path),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(path),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          // Hiển thị biểu tượng lỗi nếu không tải được hình ảnh
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Nút xóa hình ảnh (chỉ hiển thị nếu có quyền chỉnh sửa)
                                    if (_canEditAllFields)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Nút lưu thay đổi
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.teal.shade200,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.teal.shade300, Colors.pink.shade200],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Text(
                                'LƯU THAY ĐỔI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}