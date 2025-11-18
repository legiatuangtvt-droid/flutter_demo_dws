import 'package:flutter/material.dart';

// Renamed to better reflect its purpose
class DevFab extends StatelessWidget {
  const DevFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Logic for developer functions can be added here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu chức năng cho nhà phát triển.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      backgroundColor: Colors.orange[800], // Changed color to distinguish it
      tooltip: 'Developer Menu', // Added a tooltip
      child: const Icon(Icons.developer_mode, color: Colors.white), // Changed icon
    );
  }
}
