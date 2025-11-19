import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo_dws/data/mock_data.dart'; // Giả sử tệp này tồn tại

// Enum để định nghĩa các loại thông báo
enum SnackBarType { success, error, info }

class DevFab extends StatelessWidget {
  final void Function(Map<String, dynamic> selectedEmployee)? onUserSwitch;

  const DevFab({super.key, this.onUserSwitch});

  // Hàm mới sử dụng SnackBar
  void _showSnackBar(BuildContext context, String message, {SnackBarType type = SnackBarType.info}) {
    Color backgroundColor;
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade700;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade700;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue.shade700;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'init_mock_data':
        // initializeMockData() cần được điều chỉnh để nhận BuildContext
        // initializeMockData((message, {type = ToastType.info}) => _showSnackBar(context, message, type: type));
        _showSnackBar(context, "Khởi tạo dữ liệu mô phỏng...", type: SnackBarType.info);
        break;

      case 'switch_user_role':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _SwitchUserRoleDialog(onApply: onUserSwitch);
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
  final void Function(Map<String, dynamic> selectedEmployee)? onApply;
  const _SwitchUserRoleDialog({this.onApply});

  @override
  State<_SwitchUserRoleDialog> createState() => __SwitchUserRoleDialogState();
}

class __SwitchUserRoleDialogState extends State<_SwitchUserRoleDialog> {
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
        firestore.collection('roles').orderBy('name').get(),
        firestore.collection('employee').get(),
      ]);

      final rolesSnapshot = results[0] as QuerySnapshot;
      final employeesSnapshot = results[1] as QuerySnapshot;

      if (mounted) {
        setState(() {
          _roles = rolesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
          _employees = employeesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching data: $e");
    }
  }

  void _onRoleChanged(String? newRoleId) {
    if (newRoleId == null) return;
    setState(() {
      _selectedRoleId = newRoleId;
      _selectedEmployeeId = null;
      _filteredEmployees = _employees.where((emp) => emp['roleId'] == newRoleId).toList();
      _filteredEmployees.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    });
  }

  void _applyAndClose() {
    if (_selectedEmployeeId == null || widget.onApply == null) return;

    final selectedEmployee = _employees.firstWhere(
      (emp) => emp['id'] == _selectedEmployeeId,
      orElse: () => {},
    );

    if (selectedEmployee.isNotEmpty) {
      widget.onApply!(selectedEmployee);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chuyển đổi vai trò người dùng'),
      content: SizedBox(
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
                        value: role['id'] ?? '',
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
                        value: employee['id'] ?? '',
                        child: Text(employee['name'] ?? 'N/A'),
                      );
                    }).toList(),
                    hint: _selectedRoleId != null && _filteredEmployees.isEmpty
                        ? const Padding(padding: EdgeInsets.only(left: 8.0), child: Text('Không có nhân viên'),)
                        : null,
                  ),
                ],
              ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Áp dụng'),
          onPressed: _selectedEmployeeId != null ? _applyAndClose : null,
        ),
      ],
    );
  }
}
