import 'package:flutter/material.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Task/TaskListScreen.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Authentication/RegisterScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key để quản lý trạng thái của Form (dùng để validate dữ liệu nhập)
  final _formKey = GlobalKey<FormState>();

  // Controller để lấy và quản lý dữ liệu nhập từ TextFormField
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Biến để ẩn/hiện mật khẩu (mặc định là ẩn)
  bool _obscurePassword = true;

  // Biến để hiển thị trạng thái đang tải (loading) khi đăng nhập
  bool _isLoading = false;

  // Giải phóng tài nguyên (controller) khi widget bị hủy
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm xử lý đăng nhập: kiểm tra thông tin, lưu userId và điều hướng đến màn hình TaskListScreen
  Future<void> _handleLogin() async {
    // Kiểm tra dữ liệu nhập trong form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      // Hiển thị trạng thái đang tải
      setState(() => _isLoading = true);

      // Lấy email và password từ controller, loại bỏ khoảng trắng thừa
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // Truy vấn cơ sở dữ liệu để kiểm tra thông tin đăng nhập
        final user = await UserDatabaseHelper.instance
            .getUserByEmailAndPassword(email, password);

        // Nếu tìm thấy user (đăng nhập thành công)
        if (user != null) {
          // Lưu thông tin user vào SharedPreferences để sử dụng sau này
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          await prefs.setString('username', user.username);
          await prefs.setBool('isAdmin', user.isAdmin);

          // Điều hướng đến màn hình danh sách công việc (TaskListScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => TaskListScreen(currentUserId: user.id)),
          );
        } else {
          // Nếu đăng nhập thất bại, hiển thị dialog lỗi
          _showLoginErrorDialog();
        }
      } catch (e) {
        // Nếu có lỗi xảy ra trong quá trình đăng nhập, hiển thị dialog lỗi với thông báo chi tiết
        _showLoginErrorDialog(message: 'Đã xảy ra lỗi: $e');
      } finally {
        // Tắt trạng thái đang tải sau khi hoàn tất
        setState(() => _isLoading = false);
      }
    }
  }

  // Hàm hiển thị dialog lỗi khi đăng nhập thất bại
  void _showLoginErrorDialog({String? message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi đăng nhập'),
          // Nội dung dialog: hiển thị thông báo lỗi tùy chỉnh hoặc mặc định
          content: Text(message ??
              'Thông tin đăng nhập không chính xác. Vui lòng kiểm tra lại.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Padding cho nội dung chính của màn hình
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo của ứng dụng
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade200, width: 3),
                    ),
                    child: Transform.scale(
                      // Hiệu ứng phóng to logo khi đang tải
                      scale: _isLoading ? 1.1 : 1.0,
                      child: Icon(
                        Icons.assignment_turned_in,
                        size: 60,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tiêu đề chính
                  Text(
                    'WELCOME !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phụ đề
                  Text(
                    'Đăng nhập để tiến hành quản lý công việc',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.teal.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Thẻ chứa form đăng nhập
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Trường nhập Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.teal.shade600),
                              filled: true,
                              fillColor: Colors.teal.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            // Kiểm tra dữ liệu nhập email
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Trường nhập Mật khẩu
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.lock_outlined, color: Colors.teal.shade600),
                              // Nút hiển thị/ẩn mật khẩu
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.teal.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.teal.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                              ),
                            ),
                            // Kiểm tra dữ liệu nhập mật khẩu
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Nút Đăng nhập
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 120,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal.shade400, Colors.pink.shade300],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'ĐĂNG NHẬP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Liên kết đến màn hình Đăng ký
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Chưa có tài khoản? ',
                                style: TextStyle(color: Colors.teal.shade600),
                                children: [
                                  TextSpan(
                                    text: 'Đăng ký',
                                    style: TextStyle(
                                      color: Colors.pink.shade400,
                                      fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}