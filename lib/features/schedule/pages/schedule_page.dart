import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../chat_fab.dart';

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

  // Data from Firestore
  List<Map<String, dynamic>> _storeEmployees = [];
  Map<String, dynamic> _scheduleData = {};
  List<Map<String, dynamic>> _taskGroups = [];

  // Scroll controllers for sticky header and column
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _verticalFirstColumnController = ScrollController();

  // Thêm bộ đếm thời gian cho wakelock
  Timer? _wakelockTimer;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Synchronize horizontal scroll from body to header
    _horizontalBodyController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalHeaderController.offset !=
              _horizontalBodyController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
      }
    });

    // Synchronize vertical scroll from body to first column
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
    // Hủy timer và vô hiệu hóa wakelock khi rời khỏi trang
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

        // Bắt đầu logic của wakelock sau khi có dữ liệu
        _setupWakelockTimer(schedule);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching initial data: $e");
    }
  }

  // Hàm mới để thiết lập Wakelock
  void _setupWakelockTimer(Map<String, dynamic> schedule) {
    if (schedule.isEmpty) return;

    int minMinutes = 24 * 60;
    int maxMinutes = -1;

    // Tìm thời gian bắt đầu sớm nhất và kết thúc muộn nhất
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
        } catch (_) {
          // Bỏ qua nếu có lỗi parsing
        }
      }
    }

    // Nếu không tìm thấy thời gian hợp lệ
    if (maxMinutes == -1) return;

    final now = DateTime.now();
    final workdayStart = DateTime(now.year, now.month, now.day, minMinutes ~/ 60, minMinutes % 60);
    // Thời gian kết thúc ca cuối là thời gian bắt đầu + 15 phút
    final endMinutes = maxMinutes + 15;
    final workdayEnd = DateTime(now.year, now.month, now.day, endMinutes ~/ 60, endMinutes % 60);

    void checkAndApplyWakelock() {
      final currentTime = DateTime.now();
      if (currentTime.isAfter(workdayStart) && currentTime.isBefore(workdayEnd)) {
        WakelockPlus.enable();
        debugPrint("Wakelock ENABLED - In shift hours.");
      } else {
        WakelockPlus.disable();
        debugPrint("Wakelock DISABLED - Outside shift hours.");
      }
    }

    // Kiểm tra ngay lập tức
    checkAndApplyWakelock();

    // Và kiểm tra định kỳ mỗi phút
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
          : _buildScheduleTable(),
      floatingActionButton: DevFab(onUserSwitch: _updateCurrentUser),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      // --- PHẦN CHỈNH SỬA ---
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            padding: EdgeInsets.zero, // Xóa padding mặc định của IconButton
            icon: Container(
              width: 40, // Đặt chiều rộng để tạo hình vuông
              height: 40, // Đặt chiều cao để tạo hình vuông
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.deepPurple,
              ), // Icon sẽ được tự động căn giữa
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations
                .of(context)
                .openAppDrawerTooltip,
          );
        },
      ),
      // --- KẾT THÚC CHỈNH SỬA ---
      title: Text(_storeName, style: const TextStyle(fontSize: 16)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currentUserName, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_currentUserRole, style: const TextStyle(
                  fontSize: 12.0, color: Colors.black54)),
            ],
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
            accountName: Text(_currentUserName, style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: Text(_currentUserRole,
                style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                  _currentUserName.isNotEmpty ? _currentUserName[0] : 'U',
                  style: const TextStyle(
                      fontSize: 24.0, color: Colors.deepPurple)),
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

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // --- STICKY TABLE IMPLEMENTATION (REFACTORED FOR DIAGONAL SCROLL) ---

  // Hàm helper để dựng các ô, giúp code gọn hơn
  Widget _buildCell(String text, double width, double height, Color bgColor,
      {bool isHeader = false, double borderWidth = 1.5}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: Colors.black, width: borderWidth), // <-- ĐỔI THÀNH MÀU ĐEN
          bottom: BorderSide(color: Colors.black, width: borderWidth), // <-- ĐỔI THÀNH MÀU ĐEN
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
      ),
    );
  }

  Widget _buildScheduleTable() {
    if (_storeEmployees.isEmpty) {
      return const Center(
          child: Text('Không có nhân viên nào tại cửa hàng này.'));
    }

    const double firstColWidth = 150.0;
    const double dataColWidth = 70.0;
    const double rowHeight = 100.0;
    const double headerHeight = 48.0;
    const double borderWidth = 1.5;

    // Sắp xếp các ca làm việc, có thể di chuyển ra ngoài nếu không thay đổi
    final sortedShiftKeys = _scheduleData.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a
            .split('-')
            .last) ?? 0;
        final numB = int.tryParse(b
            .split('-')
            .last) ?? 0;
        return numA.compareTo(numB);
      });

    return Column(
      children: [
        // ---- HÀNG HEADER (CỐ ĐỊNH CHIỀU DỌC) ----
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: borderWidth),
            ),
          ),
          child: Row(
            children: [
              // Ô cố định trên cùng bên trái
              _buildCell(
                  'Nhân viên', firstColWidth, headerHeight, Colors.grey.shade300,
                  isHeader: true),
              // Các ô header cuộn ngang
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalHeaderController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  // Body sẽ điều khiển scroll
                  child: Row(
                    children: List.generate(19, (i) {
                      final hour = '${(i + 5).toString().padLeft(2, '0')}:00';
                      return _buildCell(hour, dataColWidth * 4, headerHeight,
                          Colors.grey.shade200, isHeader: true);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ---- KHU VỰC CUỘN ----
        Expanded(
          child: Row(
            children: [
              // ---- CỘT ĐẦU TIÊN (CỐ ĐỊNH CHIỀU NGANG, CUỘN DỌC) ----
              SizedBox(
                width: firstColWidth,
                child: ListView.builder(
                  controller: _verticalFirstColumnController,
                  physics: const NeverScrollableScrollPhysics(), // Body sẽ điều khiển scroll
                  itemCount: _storeEmployees.length,
                  itemBuilder: (context, rowIndex) {
                    final employee = _storeEmployees[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final rowBgColor = isEven
                        ? Colors.white
                        : const Color(0xFFF8F9FA);
                    return _buildCell(employee['name'] ?? 'N/A',
                        firstColWidth, rowHeight, rowBgColor);
                  },
                ),
              ),
              // ---- PHẦN BODY (CUỘN CẢ 2 CHIỀU) ----
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalBodyController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: dataColWidth * 19 * 4,
                    child: ListView.builder(
                      controller: _verticalBodyController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _storeEmployees.length,
                      itemBuilder: (context, rowIndex) {
                        final isEven = rowIndex % 2 == 0;
                        final rowBgColor = isEven
                            ? Colors.white
                            : const Color(0xFFF8F9FA);

                        List<dynamic> employeeTasks = [];
                        if (rowIndex < sortedShiftKeys.length) {
                          final shiftKey = sortedShiftKeys[rowIndex];
                          employeeTasks = _scheduleData[shiftKey] ?? [];
                        }

                        return Row(
                          children: List.generate(19 * 4, (quarterIndex) {
                            final hour = (quarterIndex ~/ 4) + 5;
                            final minute = (quarterIndex % 4) * 15;
                            final currentTime =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                            final task = employeeTasks.firstWhere(
                                (t) => t['startTime'] == currentTime,
                                orElse: () => null);

                            Widget cellContent = const SizedBox();
                            if (task != null) {
                              final Iterable<Map<String, dynamic>>
                              matchingGroups = _taskGroups.where(
                                      (g) => g['id'] == task['groupId']);
                              final Map<String, dynamic>? taskGroup =
                              matchingGroups.isNotEmpty
                                  ? matchingGroups.first
                                  : null;
                              final bgColor = taskGroup != null
                                  ? _getColorFromHex(
                                  taskGroup['color']['bg'])
                                  : Colors.grey.shade300;
                              final borderColor = HSLColor.fromColor(bgColor)
                                  .withLightness(
                                      (HSLColor.fromColor(bgColor).lightness -
                                          0.2)
                                          .clamp(0.0, 1.0))
                                  .toColor();

                              cellContent = Container(
                                margin: const EdgeInsets.all(2.0),
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                      color: borderColor, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    task['taskName'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 5,
                                  ),
                                ),
                              );
                            }

                            // Đây là ô chứa trong body
                            // ---- BẮT ĐẦU CHỈNH SỬA BORDER ----
                            final bool isHourlyBorder = (quarterIndex + 1) % 4 == 0;
                            final Color rightBorderColor = isHourlyBorder ? Colors.black : Colors.grey.shade300;

                            return Container(
                              width: dataColWidth,
                              height: rowHeight,
                              decoration: BoxDecoration(
                                color: rowBgColor,
                                border: Border(
                                  right: BorderSide(color: rightBorderColor, width: borderWidth),
                                  bottom: BorderSide(color: Colors.black, width: borderWidth),
                                ),
                              ),
                              child: cellContent,
                            );
                            // ---- KẾT THÚC CHỈNH SỬA BORDER ----
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
