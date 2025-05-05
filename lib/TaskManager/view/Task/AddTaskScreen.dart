import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:projectcuoikyltmb/TaskManager/model/Task.dart';
import 'package:projectcuoikyltmb/TaskManager/model/User.dart';
import 'package:projectcuoikyltmb/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';

// Màn hình để thêm công việc mới
class AddTaskScreen extends StatefulWidget {
  // ID của người dùng hiện tại, dùng để xác định người tạo và gán công việc
  final String currentUserId;

  const AddTaskScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  // Key để quản lý trạng thái của Form (dùng để validate dữ liệu nhập)
  final _formKey = GlobalKey<FormState>();

  // Controller để lấy và quản lý dữ liệu nhập từ TextFormField
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Các giá trị mặc định và trạng thái của công việc
  String _status = 'To do'; // Trạng thái công việc (mặc định: To do)
  int _priority = 1; // Độ ưu tiên (mặc định: 1)
  DateTime? _dueDate; // Ngày đến hạn (mặc định: null)
  String? _assignedTo; // Người được gán công việc (mặc định: null)
  List<String> _imagePaths = []; // Danh sách đường dẫn hình ảnh đính kèm
  List<User> _users = []; // Danh sách người dùng để gán công việc
  bool _isLoading = false; // Trạng thái đang tải (loading)
  bool _isAdmin = false; // Kiểm tra xem người dùng hiện tại có phải admin không

  // Danh sách các tùy chọn trạng thái và độ ưu tiên
  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  // Khởi tạo trạng thái: tải danh sách người dùng khi màn hình được hiển thị
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Hàm tải danh sách người dùng từ cơ sở dữ liệu
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true); // Hiển thị trạng thái đang tải
    try {
      // Lấy thông tin người dùng hiện tại để kiểm tra xem có phải admin không
      User? currentUser = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = currentUser?.isAdmin ?? false;

      // Nếu là admin, lấy danh sách tất cả người dùng (trừ chính mình)
      if (_isAdmin) {
        _users = await UserDatabaseHelper.instance.getAllUsers();
        _users.removeWhere((user) => user.id == widget.currentUserId);
      } else {
        _users = []; // Nếu không phải admin, không hiển thị tùy chọn gán người dùng
      }
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không tải được danh sách người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false); // Tắt trạng thái đang tải
    }
  }

  // Hàm chọn hình ảnh từ thiết bị
  Future<void> _pickImages() async {
    try {
      // Sử dụng FilePicker để chọn nhiều hình ảnh (jpg, jpeg, png)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'], // Chỉ cho phép chọn file hình ảnh
      );

      // Nếu có hình ảnh được chọn, thêm vào danh sách _imagePaths
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không chọn được hình ảnh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn hình ảnh: $e'),
          backgroundColor: Colors.red,
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
      lastDate: DateTime(2100),
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

  // Hàm xử lý thêm công việc mới: tạo Task và lưu vào cơ sở dữ liệu
  Future<void> _handleAddTask() async {
    // Kiểm tra dữ liệu nhập trong form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true); // Hiển thị trạng thái đang tải

        // Tạo đối tượng Task mới với thông tin từ form
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Tạo ID dựa trên thời gian hiện tại
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          assignedTo: _isAdmin ? _assignedTo : widget.currentUserId, // Gán cho người dùng nếu là admin
          createdBy: widget.currentUserId,
          category: null, // Không có category khi tạo mới
          imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null, // Lưu danh sách hình ảnh (nếu có)
          completed: _status == 'Done', // Công việc hoàn thành nếu trạng thái là Done
        );

        // Lưu Task vào cơ sở dữ liệu
        await TaskDatabaseHelper.instance.createTask(newTask);

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm công việc thành công!'), backgroundColor: Colors.green),
        );

        // Quay lại màn hình trước đó và trả về kết quả true
        Navigator.pop(context, true);
      } catch (e) {
        // Hiển thị thông báo lỗi nếu không thêm được công việc
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm công việc: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false); // Tắt trạng thái đang tải
      }
    }
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
                      'Thêm công việc mới',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    // Nút lưu công việc
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: _handleAddTask,
                    ),
                  ],
                ),
              ),
            ),
            // Form nhập thông tin công việc
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
                      TextFormField(
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
                      ),
                      const SizedBox(height: 16),

                      // Trường nhập Mô tả
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả chi tiết (nếu có)',
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
                        maxLines: 3,
                        style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
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
                          // Dropdown chọn Độ ưu tiên
                          Expanded(
                            child: DropdownButtonFormField<int>(
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
                                  child: Text('Ưu tiên $priority', style: const TextStyle(fontFamily: 'Roboto')),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _priority = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ngày đến hạn
                      InkWell(
                        onTap: () => _selectDueDate(context),
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
                                    : DateFormat('dd/MM/yyyy').format(_dueDate!),
                                style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.teal.shade600),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gán cho người dùng (chỉ hiển thị nếu người dùng là admin)
                      if (_users.isNotEmpty && _isAdmin)
                        DropdownButtonFormField<String>(
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
                              child: Text('Không gán cho ai', style: TextStyle(fontFamily: 'Roboto')),
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
                      // Nút chọn hình ảnh
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
                              'Chọn hình ảnh (.jpg, .png)',
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Danh sách hình ảnh đã chọn (hiển thị thumbnail)
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
                                    ClipRRect(
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
                                    // Nút xóa hình ảnh
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
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

                      // Nút thêm công việc
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleAddTask,
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
                                'THÊM CÔNG VIỆC',
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

  // Giải phóng tài nguyên (controller) khi widget bị hủy
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}