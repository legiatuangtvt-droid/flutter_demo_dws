import 'package:flutter/material.dart';
import 'package:flutter_demo_dws/data/mock_data.dart'; // Import the new data file

// Renamed to better reflect its purpose
class DevFab extends StatelessWidget {
  const DevFab({super.key});

  // Handles the logic when a menu item is selected
  void _handleMenuSelection(String value, BuildContext context) {
    String message;
    switch (value) {
      case 'init_mock_data':
        // Call the function from the new data file
        initializeMockData();
        message = 'Đã gọi hàm khởi tạo dữ liệu. Kiểm tra console để xem kết quả.';
        break;
      case 'switch_user_role':
        message = 'Chức năng "Chuyển đổi vai trò người dùng" đang được xử lý...';
        // TODO: Add logic to switch user role
        break;
      default:
        return; // Do nothing if the value is not recognized
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the FAB with a PopupMenuButton to show a menu on tap.
    return PopupMenuButton<String>(
      tooltip: 'Developer Menu', // The tooltip is now on the PopupMenuButton
      onSelected: (value) => _handleMenuSelection(value, context),
      // Improved item builder with Icons
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'init_mock_data',
          child: Row(
            children: const [
              Icon(Icons.post_add, color: Colors.blue), // Added Icon
              SizedBox(width: 12), // Added spacing
              Text('Khởi tạo dữ liệu mô phỏng'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'switch_user_role',
          child: Row(
            children: const [
              Icon(Icons.switch_account, color: Colors.green), // Added Icon
              SizedBox(width: 12), // Added spacing
              Text('Chuyển đổi vai trò người dùng'),
            ],
          ),
        ),
      ],
      // The child is the FAB itself.
      child: FloatingActionButton(
        onPressed: null, // The parent PopupMenuButton handles the press.
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.developer_mode, color: Colors.white),
      ),
    );
  }
}
