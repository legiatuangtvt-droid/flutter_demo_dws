import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_demo_dws/chat_fab.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          titleTextStyle: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      home: const SchedulePage(),
    );
  }
}

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

  // Scroll controllers
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Synchronize scroll controllers
    _horizontalBodyController.addListener(() {
      // This part requires a separate controller for the header, which adds complexity.
      // For now, we accept header scrolls with the body.
    });
  }

  @override
  void dispose() {
    _horizontalBodyController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  // Dán đoạn code này vào class _SchedulePageState, thay thế cho hàm _fetchInitialData() hiện tại.

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
      final schedule = (templateDoc.data() as Map<String, dynamic>)['schedule'] ??
          {};
      final taskGroups = taskGroupsSnapshot.docs.map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();

      // --- PHẦN CHỈNH SỬA ---
      // Lọc danh sách nhân viên để chỉ giữ lại những người có ca làm việc trong `schedule`.
      // Logic này giả định rằng nhân viên được gán vào các ca theo thứ tự (nhân viên thứ 0 -> ca 'shift-1', nhân viên thứ 1 -> ca 'shift-2', v.v.).
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

      // Chỉ thêm nhân viên nếu họ nằm trong phạm vi số lượng ca làm việc đã được định nghĩa.
      for (int i = 0; i < allEmployees.length; i++) {
        if (i < sortedShiftKeys.length) {
          scheduledEmployees.add(allEmployees[i]);
        }
      }
      // --- KẾT THÚC CHỈNH SỬA ---

      if (mounted) {
        setState(() {
          _storeName =
              (storeDoc.data() as Map<String, dynamic>)['name'] ?? _storeName;
          // Sử dụng danh sách nhân viên đã được lọc
          _storeEmployees = scheduledEmployees;
          _scheduleData = schedule;
          _taskGroups = taskGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching initial data: $e");
    }
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: Text(_currentUserRole, style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(_currentUserName.isNotEmpty ? _currentUserName[0] : 'U', style: const TextStyle(fontSize: 24.0, color: Colors.deepPurple)),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Lịch hàng ngày'),
            selected: true, // Highlight this item
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Lịch hàng tháng'),
            onTap: () {
              // TODO: Navigate to the monthly schedule page
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --- STICKY TABLE IMPLEMENTATION ---
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildScheduleTable() {if (_storeEmployees.isEmpty) {
    return const Center(child: Text('Không có nhân viên nào tại cửa hàng này.'));
  }

  final timeSlots = List.generate(19 * 4, (i) => i); // 19 hours * 4 quarters
  const double firstColWidth = 150.0;
  const double dataColWidth = 50.0; // 50px per 15-min slot
  const double headerHeight = 48.0;
  const double rowHeight = 60.0; // Increased row height for task text

  // Header cho các cột giờ
  final headerWidgets = List.generate(19, (i) {
    final hour = '${(i + 5).toString().padLeft(2, '0')}:00';
    return _buildCell(hour, dataColWidth * 4, headerHeight, Colors.grey.shade200, isHeader: true);
  });

  return Container(
    margin: const EdgeInsets.all(8.0), // Giữ lại margin để bảng không dính sát vào cạnh màn hình
    child: SingleChildScrollView(
      controller: _verticalBodyController,
      child: SingleChildScrollView(
        controller: _horizontalBodyController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng Header
            Row(children: [
              _buildCell('Nhân viên', firstColWidth, headerHeight, Colors.grey.shade200, isHeader: true),
              ...headerWidgets
            ]),

            // Các hàng dữ liệu
            ...List.generate(_storeEmployees.length, (rowIndex) {
              final employee = _storeEmployees[rowIndex];
              final isEven = rowIndex % 2 == 0;
              final rowBgColor = isEven ? Colors.white : const Color(0xFFF8F9FA);

              List<dynamic> employeeTasks = []; // Mặc định là rỗng

              final sortedShiftKeys = _scheduleData.keys.toList()
                ..sort((a, b) {
                  final numA = int.tryParse(a.split('-').last) ?? 0;
                  final numB = int.tryParse(b.split('-').last) ?? 0;
                  return numA.compareTo(numB);
                });

              if (rowIndex < sortedShiftKeys.length) {
                final shiftKey = sortedShiftKeys[rowIndex];
                employeeTasks = _scheduleData[shiftKey] ?? [];
              }

              return Row(
                children: [
                  // Ô tên nhân viên
                  _buildCell(employee['name'] ?? 'N/A', firstColWidth, rowHeight, rowBgColor),

                  // Các ô 15 phút
                  ...timeSlots.map((quarterIndex) {
                    final hour = (quarterIndex ~/ 4) + 5;
                    final minute = (quarterIndex % 4) * 15;
                    final currentTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                    final task = employeeTasks.firstWhere((t) => t['startTime'] == currentTime, orElse: () => null);

                    Widget cellContent = const SizedBox();

                    if (task != null) {
                      final Iterable<Map<String, dynamic>> matchingGroups = _taskGroups.where((g) => g['id'] == task['groupId']);
                      final Map<String, dynamic>? taskGroup = matchingGroups.isNotEmpty ? matchingGroups.first : null;
                      final bgColor = taskGroup != null ? _getColorFromHex(taskGroup['color']['bg']) : Colors.grey.shade300;
                      final borderColor = HSLColor.fromColor(bgColor).withLightness((HSLColor.fromColor(bgColor).lightness - 0.2).clamp(0.0, 1.0)).toColor();

                      cellContent = Container(
                        margin: const EdgeInsets.all(2.0),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            task['taskName'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      );
                    }

                    // --- PHẦN CHỈNH SỬA CHÍNH ---
                    return Container(
                      width: dataColWidth,
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color: rowBgColor,
                        border: Border(
                          // Đường viền dọc bên phải
                          right: BorderSide(
                            color: (quarterIndex % 4 == 3) ? Colors.black : Colors.grey.shade300,
                            width: (quarterIndex % 4 == 3) ? 1.5 : 0.5,
                          ),
                          // Đường viền ngang bên dưới
                          bottom: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      child: cellContent,
                    );
                    // --- KẾT THÚC CHỈNH SỬA ---
                  })
                ],
              );
            }),
          ],
        ),
      ),
    ),
  );
  }


// Dán và thay thế hàm _buildCell() hiện tại
  Widget _buildCell(String text, double width, double height, Color color, {bool isHeader = false}) {
    // --- PHẦN CHỈNH SỬA CHÍNH ---
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        // Vẽ viền đen cho tất cả các cạnh
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.black54 : Colors.black87,
          ),
        ),
      ),
    );
    // --- KẾT THÚC CHỈNH SỬA ---
  }
}

