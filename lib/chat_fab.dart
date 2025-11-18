import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_demo_dws/data/mock_data.dart';

class DevFab extends StatelessWidget {
  const DevFab({super.key});

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
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'init_mock_data':
        initializeMockData(_showToast);
        break;

      case 'switch_user_role':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const _SwitchUserRoleDialog();
          },
        );
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

// --- Dialog for Switching User Role ---

class _SwitchUserRoleDialog extends StatefulWidget {
  const _SwitchUserRoleDialog();

  @override
  State<_SwitchUserRoleDialog> createState() => __SwitchUserRoleDialogState();
}

class __SwitchUserRoleDialogState extends State<_SwitchUserRoleDialog> {
  // State variables
  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];

  String? _selectedRoleId;
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final rolesSnapshot = await firestore.collection('roles').get();
      final employeesSnapshot = await firestore.collection('employee').get();

      setState(() {
        _roles = rolesSnapshot.docs.map((doc) => doc.data()).toList();
        _employees = employeesSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error, maybe show a toast
    }
  }

  void _onRoleChanged(String? newRoleId) {
    if (newRoleId == null) return;
    setState(() {
      _selectedRoleId = newRoleId;
      _selectedEmployeeId = null; // Reset employee selection
      _filteredEmployees = _employees.where((emp) => emp['roleId'] == newRoleId).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chuyển đổi vai trò người dùng'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRoleId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Chọn vai trò'),
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role['id'],
                        child: Text(role['name'] ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: _onRoleChanged,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Chọn nhân viên',
                      enabled: _selectedRoleId != null, // Disable if no role is selected
                    ),
                    items: _filteredEmployees.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['id'],
                        child: Text(employee['name'] ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEmployeeId = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),
      actions: <Widget>[
        TextButton(
          child: const Text('Hủy'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: const Text('Áp dụng'),
          onPressed: (_selectedEmployeeId != null)
              ? () {
                  // TODO: Implement the actual user switching logic here
                  print('Switching to user: $_selectedEmployeeId with role: $_selectedRoleId');
                  Navigator.of(context).pop();
                }
              : null, // Disable button if no employee is selected
        ),
      ],
    );
  }
}
