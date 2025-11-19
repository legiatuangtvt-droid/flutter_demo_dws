import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/password_field.dart';

class LoginPage extends StatefulWidget {
  final bool isProvisioningMode;
  final String? storeId;

  const LoginPage({
    super.key,
    this.isProvisioningMode = false,
    this.storeId,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.isProvisioningMode) {
      await _provisionDevice();
    } else {
      await _signInAsEmployee();
    }
  }

  Future<void> _provisionDevice() async {
    // Ở chế độ cấp phát, chỉ cho phép Store Manager đăng nhập
    final result = await _authService.signInAsStoreManager(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (result is AppUser) {
      // Lưu storeId của Manager vào thiết bị
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('storeId', result.storeId);

      // Hiển thị thông báo thành công và yêu cầu khởi động lại
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Cấp phát thành công'),
            content: Text('Thiết bị đã được gán cho cửa hàng: ${result.storeId}. Vui lòng khởi động lại ứng dụng.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(), // Chỉ đóng dialog
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result as String?;
      });
    }
  }

  Future<void> _signInAsEmployee() async {
    final result = await _authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      widget.storeId!,
    );

    if (result is AppUser) {
      if (mounted) {
        // Đăng nhập thành công, đóng màn hình login và trả về thông tin user
        Navigator.of(context).pop(result);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isProvisioningMode ? 'Cấp phát Thiết bị' : 'Đăng nhập';
    final subTitle =
        widget.isProvisioningMode ? 'Chỉ dành cho Quản lý Cửa hàng' : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subTitle != null)
                  Text(subTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email / ID Nhân viên',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Vui lòng nhập thông tin' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(controller: _passwordController),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(title),
                      ),
                const SizedBox(height: 24),
                 // Chỉ hiển thị nút này ở chế độ đăng nhập nhân viên
                if (!widget.isProvisioningMode)
                  TextButton(
                    onPressed: () {},
                    child: const Text('Quên mật khẩu?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
