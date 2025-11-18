import 'package:flutter/material.dart';

class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Logic xử lý khi nhấn vào nút
        // Ví dụ: Mở màn hình chat, hoặc hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chức năng chat chưa được triển khai.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.chat_bubble, color: Colors.white),
    );
  }
}
