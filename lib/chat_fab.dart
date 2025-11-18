import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_demo_dws/data/mock_data.dart';

class DevFab extends StatelessWidget {
  const DevFab({super.key});

  // This helper function remains the same.
  void _showToast(String message, {ToastType type = ToastType.info}) {
    Color backgroundColor;
    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade700;
        break;
      case ToastType.error:
        backgroundColor = Colors.red.shade700;
        break;
      case ToastType.info:
      default:
        backgroundColor = Colors.blue.shade700;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // Increased length for better readability
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // The selection handler is now simpler.
  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'init_mock_data':
        // Pass the _showToast function directly as a callback.
        initializeMockData(_showToast);
        break;

      case 'switch_user_role':
        _showToast('Chức năng "Chuyển đổi vai trò người dùng" chưa được triển khai.', type: ToastType.info);
        // TODO: Add logic to switch user role
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Developer Menu',
      onSelected: (value) => _handleMenuSelection(value, context),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'init_mock_data',
          child: Row(
            children: const [
              Icon(Icons.post_add, color: Colors.blue),
              SizedBox(width: 12),
              Text('Khởi tạo dữ liệu mô phỏng'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'switch_user_role',
          child: Row(
            children: const [
              Icon(Icons.switch_account, color: Colors.green),
              SizedBox(width: 12),
              Text('Chuyển đổi vai trò người dùng'),
            ],
          ),
        ),
      ],
      child: FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.developer_mode, color: Colors.white),
      ),
    );
  }
}
