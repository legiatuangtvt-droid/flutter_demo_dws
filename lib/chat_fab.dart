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
      final results = await Future.wait([
        firestore.collection('roles').orderBy('name').get(), // Sort roles by name
        firestore.collection('employee').get(),
      ]);

      final rolesSnapshot = results[0] as QuerySnapshot;
      final employeesSnapshot = results[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          _roles = rolesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          _employees = employeesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error fetching data in parallel: $e");
    }
  }

  void _onRoleChanged(String? newRoleId) {
    if (newRoleId == null) return;
    setState(() {
      _selectedRoleId = newRoleId;
      _selectedEmployeeId = null;
      _filteredEmployees = _employees.where((emp) => emp['roleId'] == newRoleId).toList();
      // Sort employees by name
      _filteredEmployees.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chuyển đổi vai trò người dùng'),
      // Use a container with a fixed height to prevent resizing
      content: Container(
        height: 180, 
        width: double.maxFinite,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu...'),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRoleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn vai trò',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
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
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: _selectedRoleId == null,
                      fillColor: _selectedRoleId == null ? Colors.grey.shade200 : null,
                    ),
                    onChanged: _selectedRoleId == null ? null : (String? newValue) {
                      setState(() {
                        _selectedEmployeeId = newValue;
                      });
                    },
                    items: _filteredEmployees.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['id'],
                        child: Text(employee['name'] ?? 'N/A'),
                      );
                    }).toList(),
                    hint: _selectedRoleId != null && _filteredEmployees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text('Không có nhân viên'),
                          )
                        : null,
                  ),
                ],
              ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Hủy'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Áp dụng'),
          onPressed: (_selectedEmployeeId != null)
              ? () {
                  // TODO: Implement the actual user switching logic here
                  print('Switching to user: $_selectedEmployeeId with role: $_selectedRoleId');
                  Navigator.of(context).pop();
                }
              : null, 
        ),
      ],
    );
  }
}
