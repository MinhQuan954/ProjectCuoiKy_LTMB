import 'package:flutter/material.dart';
import 'package:projectcuoikyltmb/TaskManager/model/User.dart';
import 'package:projectcuoikyltmb/TaskManager/db/UserDatabaseHelper.dart';
import 'package:projectcuoikyltmb/TaskManager/view/Authentication/LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Key để quản lý trạng thái của Form (dùng để validate dữ liệu nhập)
  final _formKey = GlobalKey<FormState>();

  // Controller để lấy và quản lý dữ liệu nhập từ TextFormField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Biến để hiển thị trạng thái đang tải (loading) khi đăng ký
  bool _isLoading = false;

  // Biến để ẩn/hiện mật khẩu trong trường Mật khẩu (mặc định là ẩn)
  bool _obscurePassword = true;

  // Biến để ẩn/hiện mật khẩu trong trường Xác nhận mật khẩu (mặc định là ẩn)
  bool _obscureConfirmPassword = true;

  // Giải phóng tài nguyên (controller) khi widget bị hủy
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm xử lý đăng ký: kiểm tra thông tin, tạo user mới và điều hướng đến màn hình LoginScreen
  void _handleRegister() async {
    // Kiểm tra dữ liệu nhập trong form có hợp lệ không
    if (_formKey.currentState!.validate()) {
      // Hiển thị trạng thái đang tải
      setState(() => _isLoading = true);

      // Lấy dữ liệu từ controller, loại bỏ khoảng trắng thừa
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      // Kiểm tra mật khẩu và xác nhận mật khẩu có khớp nhau không
      if (password != confirmPassword) {
        setState(() => _isLoading = false);
        _showErrorDialog('Mật khẩu xác nhận không khớp!');
        return;
      }

      // Tạo đối tượng User mới với thông tin từ form
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Tạo ID dựa trên thời gian hiện tại
        username: username,
        password: password,
        email: email,
        avatar: null, // Không có avatar khi đăng ký
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isAdmin: false, // Người dùng mới không phải admin
      );

      // Gọi UserDatabaseHelper để lưu user vào cơ sở dữ liệu
      final result = await UserDatabaseHelper.instance.createUser(user);

      // Nếu lưu thành công (result > 0), điều hướng đến màn hình đăng nhập
      if (result > 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Nếu lưu thất bại, hiển thị dialog lỗi
        setState(() => _isLoading = false);
        _showErrorDialog('Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.');
      }
    }
  }

  // Hàm hiển thị dialog lỗi khi đăng ký thất bại
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          // Nội dung dialog: hiển thị thông báo lỗi
          content: Text(message),
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
                        Icons.account_circle,
                        size: 60,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tiêu đề chính
                  Text(
                    'Đăng ký tài khoản mới',
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
                    'Đăng ký để tiến hành quản lý công việc',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.teal.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Thẻ chứa form đăng ký
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
                          // Trường nhập Tên người dùng
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Tên người dùng',
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.teal.shade600),
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
                            // Kiểm tra dữ liệu nhập tên người dùng
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên người dùng';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

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
                              if (!RegExp(r'^[a-zA-Z0-9_]+@gmail\.com$').hasMatch(value)) {
                                return 'Email phải có đuôi @gmail.com và chỉ chứa chữ cái, số, dấu _';
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
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Trường nhập Xác nhận mật khẩu
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Xác nhận mật khẩu',
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.lock_outlined, color: Colors.teal.shade600),
                              // Nút hiển thị/ẩn xác nhận mật khẩu
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.teal.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
                            // Kiểm tra dữ liệu nhập xác nhận mật khẩu
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Nút Đăng ký
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 120,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
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
                                  'ĐĂNG KÝ',
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

                          // Liên kết đến màn hình Đăng nhập
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Đã có tài khoản? ',
                                style: TextStyle(color: Colors.teal.shade600),
                                children: [
                                  TextSpan(
                                    text: 'Đăng nhập',
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