import 'package:flutter/material.dart';

// Renamed to better reflect its purpose
class DevFab extends StatelessWidget {
  const DevFab({super.key});

  // Handles the logic when a menu item is selected
  void _handleMenuSelection(String value, BuildContext context) {
    String message;
    switch (value) {
      case 'init_mock_data':
        message = 'Chức năng "Khởi tạo dữ liệu mô phỏng" đang được xử lý...';
        // TODO: Add logic to initialize mock data
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
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'init_mock_data',
          child: Text('Khởi tạo dữ liệu mô phỏng'),
        ),
        const PopupMenuItem<String>(
          value: 'switch_user_role',
          child: Text('Chuyển đổi vai trò người dùng'),
        ),
      ],
      // The child is the FAB itself.
      // We provide a non-null onPressed to the FAB to ensure it's enabled and shows a ripple effect.
      // The PopupMenuButton's own gesture detector will handle opening the menu.
      child: FloatingActionButton(
        onPressed: null, // The parent PopupMenuButton handles the press.
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.developer_mode, color: Colors.white),
      ),
    );
  }
}
