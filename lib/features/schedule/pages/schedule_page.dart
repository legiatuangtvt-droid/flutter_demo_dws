import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../chat_fab.dart';
import '../widgets/schedule_table.dart'; // Import widget bảng mới

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const String _defaultStoreId = 'AMPM_DN_NVC';
  String _storeName = 'AEON MaxValu Ngô Quyền';
  String _currentUserName = 'Chưa đăng nhập';
  String _currentUserRole = 'Vui lòng chọn người dùng';
  bool _isLoading = true;

  // Data from Firestore - Trạng thái của trang
  List<Map<String, dynamic>> _storeEmployees = [];
  Map<String, dynamic> _scheduleData = {};
  List<Map<String, dynamic>> _taskGroups = [];

  // Scroll controllers - Trạng thái của trang
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _verticalFirstColumnController = ScrollController();

  // Wakelock timer - Trạng thái của trang
  Timer? _wakelockTimer;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    _horizontalBodyController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalHeaderController.offset !=
              _horizontalBodyController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
      }
    });

    _verticalBodyController.addListener(() {
      if (_verticalFirstColumnController.hasClients &&
          _verticalFirstColumnController.offset !=
              _verticalBodyController.offset) {
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
    // ... (logic tải dữ liệu không thay đổi)
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('stores')
            .doc(_defaultStoreId)
            .get(),
        FirebaseFirestore.instance.collection('employee').where(
            'storeId', isEqualTo: _defaultStoreId).get(),
        FirebaseFirestore.instance
            .collection('daily_templates')
            .doc('TEST')
            .get(),
        FirebaseFirestore.instance.collection('task_groups').get(),
      ]);

      final storeDoc = results[0] as DocumentSnapshot;
      final employeesSnapshot = results[1] as QuerySnapshot;
      final templateDoc = results[2] as DocumentSnapshot;
      final taskGroupsSnapshot = results[3] as QuerySnapshot;

      final allEmployees = employeesSnapshot.docs.map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();
      final schedule = (templateDoc.data() as Map<String,
          dynamic>)['schedule'] ??
          {};
      final taskGroups = taskGroupsSnapshot.docs.map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();

      final scheduledEmployees = <Map<String, dynamic>>[];
      final sortedShiftKeys = schedule.keys.toList()
        ..sort((a, b) {
          final numA = int.tryParse(a
              .split('-')
              .last) ?? 0;
          final numB = int.tryParse(b
              .split('-')
              .last) ?? 0;
          return numA.compareTo(numB);
        });

      for (int i = 0; i < allEmployees.length; i++) {
        if (i < sortedShiftKeys.length) {
          scheduledEmployees.add(allEmployees[i]);
        }
      }

      if (mounted) {
        setState(() {
          _storeName =
              (storeDoc.data() as Map<String, dynamic>)['name'] ?? _storeName;
          _storeEmployees = scheduledEmployees;
          _scheduleData = schedule;
          _taskGroups = taskGroups;
          _isLoading = false;
        });

        _setupWakelockTimer(schedule);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching initial data: $e");
    }
  }

  void _setupWakelockTimer(Map<String, dynamic> schedule) {
    // ... (logic wakelock không thay đổi)
    if (schedule.isEmpty) return;

    int minMinutes = 24 * 60;
    int maxMinutes = -1;

    for (var shiftTasks in schedule.values) {
      for (var task in (shiftTasks as List)) {
        try {
          final String startTime = task['startTime'];
          final parts = startTime.split(':');
          if (parts.length == 2) {
            final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
            if (minutes < minMinutes) minMinutes = minutes;
            if (minutes > maxMinutes) maxMinutes = minutes;
          }
        } catch (_) {}
      }
    }

    if (maxMinutes == -1) return;

    final now = DateTime.now();
    final workdayStart = DateTime(now.year, now.month, now.day, minMinutes ~/ 60, minMinutes % 60);
    final endMinutes = maxMinutes + 15;
    final workdayEnd = DateTime(now.year, now.month, now.day, endMinutes ~/ 60, endMinutes % 60);

    void checkAndApplyWakelock() {
      final currentTime = DateTime.now();
      if (currentTime.isAfter(workdayStart) && currentTime.isBefore(workdayEnd)) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }

    checkAndApplyWakelock();

    _wakelockTimer?.cancel();
    _wakelockTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkAndApplyWakelock();
    });
  }

  void _updateCurrentUser(Map<String, dynamic> selectedEmployee) {
    setState(() {
      _currentUserName = selectedEmployee['name'] ?? 'Không rõ';
      _currentUserRole = selectedEmployee['roleId'] ?? 'Không rõ';
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
              // Truyền dữ liệu và controller vào widget con
              storeEmployees: _storeEmployees,
              scheduleData: _scheduleData,
              taskGroups: _taskGroups,
              horizontalBodyController: _horizontalBodyController,
              verticalBodyController: _verticalBodyController,
              horizontalHeaderController: _horizontalHeaderController,
              verticalFirstColumnController: _verticalFirstColumnController,
            ),
      floatingActionButton: DevFab(onUserSwitch: _updateCurrentUser),
    );
  }

  AppBar _buildAppBar() {
    // ... (widget AppBar không thay đổi)
    return AppBar(
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            padding: EdgeInsets.zero,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.deepPurple,
              ),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
      title: Text(_storeName, style: const TextStyle(fontSize: 16)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_currentUserRole, style: const TextStyle(fontSize: 12.0, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    // ... (widget Drawer không thay đổi)
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: Text(_currentUserRole, style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                  _currentUserName.isNotEmpty ? _currentUserName[0] : 'U',
                  style: const TextStyle(fontSize: 24.0, color: Colors.deepPurple)),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Lịch hàng ngày'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Lịch hàng tháng'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
