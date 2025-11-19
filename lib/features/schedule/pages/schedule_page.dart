import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/auth_service.dart';
import '../../../presentation/widgets/dev_menu_fab.dart';
import '../widgets/schedule_table.dart';
import 'login_page.dart';

class SchedulePage extends StatefulWidget {
  final String storeId;
  const SchedulePage({super.key, required this.storeId});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final AuthService _authService = AuthService();

  // Dữ liệu và trạng thái của trang
  String _storeName = 'Loading...';
  AppUser? _currentUser;
  bool _isLoading = true;

  List<Map<String, dynamic>> _storeEmployees = [];
  Map<String, dynamic> _scheduleData = {};
  List<Map<String, dynamic>> _taskGroups = [];

  // Scroll controllers
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _verticalFirstColumnController = ScrollController();

  Timer? _wakelockTimer;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    _horizontalBodyController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalHeaderController.offset != _horizontalBodyController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
      }
    });

    _verticalBodyController.addListener(() {
      if (_verticalFirstColumnController.hasClients &&
          _verticalFirstColumnController.offset != _verticalBodyController.offset) {
        _verticalFirstColumnController.jumpTo(_verticalBodyController.offset);
      }
    });
  }

  @override
  void dispose() {
    _wakelockTimer?.cancel();
    WakelockPlus.disable();
    _horizontalHeaderController.dispose();
    _verticalFirstColumnController.dispose();
    _horizontalBodyController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get(),
        FirebaseFirestore.instance.collection('employee').where('storeId', isEqualTo: widget.storeId).get(),
        FirebaseFirestore.instance.collection('daily_templates').doc('TEST').get(),
        FirebaseFirestore.instance.collection('task_groups').get(),
      ]);

      // ... (logic xử lý dữ liệu không thay đổi nhiều)

      if (mounted) {
        setState(() {
           final storeDoc = results[0] as DocumentSnapshot;
          final employeesSnapshot = results[1] as QuerySnapshot;
          final templateDoc = results[2] as DocumentSnapshot;
          final taskGroupsSnapshot = results[3] as QuerySnapshot;

          final allEmployees = employeesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
          final schedule = (templateDoc.data() as Map<String, dynamic>)['schedule'] ?? {};
          final taskGroups = taskGroupsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

          final scheduledEmployees = <Map<String, dynamic>>[];
          final sortedShiftKeys = schedule.keys.toList()..sort((a, b) => (int.tryParse(a.split('-').last) ?? 0).compareTo(int.tryParse(b.split('-').last) ?? 0));

          for (int i = 0; i < allEmployees.length; i++) {
            if (i < sortedShiftKeys.length) {
              scheduledEmployees.add(allEmployees[i]);
            }
          }

          _storeName = (storeDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown Store';
          _storeEmployees = scheduledEmployees;
          _scheduleData = schedule;
          _taskGroups = taskGroups;
          _isLoading = false;
        });
        _setupWakelockTimer(_scheduleData);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching initial data: $e");
    }
  }

   void _setupWakelockTimer(Map<String, dynamic> schedule) {
    // ... (logic không thay đổi)
  }

  // Hàm mới để điều hướng đến trang đăng nhập
  Future<void> _navigateToLogin() async {
    final result = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (context) => LoginPage(storeId: widget.storeId),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentUser = result;
      });
    }
  }

  // Hàm mới để đăng xuất
  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ScheduleTable(
              storeEmployees: _storeEmployees,
              scheduleData: _scheduleData,
              taskGroups: _taskGroups,
              horizontalBodyController: _horizontalBodyController,
              verticalBodyController: _verticalBodyController,
              horizontalHeaderController: _horizontalHeaderController,
              verticalFirstColumnController: _verticalFirstColumnController,
            ),
      // Chuyển DevFab vào đây và chỉ hiển thị khi cần
      // floatingActionButton: DevFab(onUserSwitch: (user) {}),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
      title: Text(_storeName, style: const TextStyle(fontSize: 16)),
      centerTitle: true,
      actions: [
        // Bọc vùng thông tin người dùng trong GestureDetector
        GestureDetector(
          onTap: _navigateToLogin,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currentUser?.name ?? 'Chưa đăng nhập',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _currentUser?.roleId ?? 'Vui lòng chọn người dùng',
                  style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.name ?? 'Chưa đăng nhập'),
            accountEmail: Text(_currentUser?.roleId ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(_currentUser?.name.isNotEmpty == true ? _currentUser!.name[0] : '?'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Lịch hàng ngày'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Lịch hàng tháng'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          // Thêm nút Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
        ],
      ),
    );
  }
}
