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

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stores').doc(_defaultStoreId).get(),
        FirebaseFirestore.instance.collection('employee').where('storeId', isEqualTo: _defaultStoreId).get(),
        FirebaseFirestore.instance.collection('daily_templates').doc('TEST').get(),
        FirebaseFirestore.instance.collection('task_groups').get(),
      ]);

      final storeDoc = results[0] as DocumentSnapshot;
      final employeesSnapshot = results[1] as QuerySnapshot;
      final templateDoc = results[2] as DocumentSnapshot;
      final taskGroupsSnapshot = results[3] as QuerySnapshot;

      final employees = employeesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final schedule = (templateDoc.data() as Map<String, dynamic>)?['schedule'] ?? {};
      final taskGroups = taskGroupsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      if (mounted) {
        setState(() {
          _storeName = (storeDoc.data() as Map<String, dynamic>)?['name'] ?? _storeName;
          _storeEmployees = employees;
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
  
  AppBar _buildAppBar() { return AppBar(title: Text(_storeName)); }
  Drawer _buildDrawer() { return Drawer(child: Text("Menu")); }

  // --- STICKY TABLE IMPLEMENTATION ---
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildScheduleTable() {
    if (_storeEmployees.isEmpty) {
      return const Center(child: Text('Không có nhân viên nào tại cửa hàng này.'));
    }

    final timeSlots = List.generate(19 * 4, (i) => i); // 19 hours * 4 quarters
    const double firstColWidth = 150.0;
    const double dataColWidth = 50.0; // 50px per 15-min slot
    const double headerHeight = 48.0;
    const double rowHeight = 60.0; // Increased row height for task text

    final headerWidgets = List.generate(19, (i) {
      final hour = '${(i + 5).toString().padLeft(2, '0')}:00';
      return _buildCell(hour, dataColWidth * 4, headerHeight, Colors.grey.shade200, isHeader: true);
    });

    return SingleChildScrollView(
      controller: _verticalBodyController,
      child: SingleChildScrollView(
        controller: _horizontalBodyController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(children: [_buildCell('Nhân viên', firstColWidth, headerHeight, Colors.grey.shade200, isHeader: true), ...headerWidgets]),
            // Data Rows
            ...List.generate(_storeEmployees.length, (rowIndex) {
              final employee = _storeEmployees[rowIndex];
              final isEven = rowIndex % 2 == 0;

              // Simple logic to assign a shift to an employee
              final shiftIndex = (rowIndex % (_scheduleData.keys.length)) + 1;
              final shiftKey = 'shift-$shiftIndex';
              final List<dynamic> employeeTasks = _scheduleData[shiftKey] ?? [];

              return Row(
                children: [
                  _buildCell(employee['name'] ?? 'N/A', firstColWidth, rowHeight, isEven ? Colors.white : const Color(0xFFF8F9FA)),
                  ...timeSlots.map((quarterIndex) {
                    final hour = (quarterIndex ~/ 4) + 5;
                    final minute = (quarterIndex % 4) * 15;
                    final currentTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                    
                    // Find if a task starts at this exact time
                    final task = employeeTasks.firstWhere((t) => t['startTime'] == currentTime, orElse: () => null);
                    
                    Widget cellContent = const SizedBox();
                    if (task != null) {
                      // Correctly find the task group, allowing for null if not found.
                      final Iterable<Map<String, dynamic>> matchingGroups = _taskGroups.where((g) => g['id'] == task['groupId']);
                      final Map<String, dynamic>? taskGroup = matchingGroups.isNotEmpty ? matchingGroups.first : null;

                      final color = taskGroup != null ? _getColorFromHex(taskGroup['color']['bg']) : Colors.grey.shade300;
                      cellContent = Container(
                        margin: const EdgeInsets.all(2.0),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Center( // Center the Text widget
                          child: Text(
                            task['taskName'],
                            textAlign: TextAlign.center, // And align the text itself
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: dataColWidth,
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                        border: Border(right: BorderSide(color: Colors.grey.shade200, width: (quarterIndex % 4 == 3) ? 1.0 : 0.5)),
                      ),
                      child: cellContent,
                    );
                  })
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, double height, Color color, {bool isHeader = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
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
  }
}
