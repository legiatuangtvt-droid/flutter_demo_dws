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
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _storeEmployees = [];

  // Scroll controllers for the sticky table
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  final ScrollController _horizontalHeadController = ScrollController();
  final ScrollController _verticalHeadController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // Synchronize scroll controllers for the sticky effect
    _horizontalBodyController.addListener(() {
      if (_horizontalHeadController.hasClients && _horizontalHeadController.offset != _horizontalBodyController.offset) {
        _horizontalHeadController.jumpTo(_horizontalBodyController.offset);
      }
    });
    _verticalBodyController.addListener(() {
      if (_verticalHeadController.hasClients && _verticalHeadController.offset != _verticalBodyController.offset) {
        _verticalHeadController.jumpTo(_verticalBodyController.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalBodyController.dispose();
    _verticalBodyController.dispose();
    _horizontalHeadController.dispose();
    _verticalHeadController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stores').doc(_defaultStoreId).get(),
        FirebaseFirestore.instance.collection('employee').where('storeId', isEqualTo: _defaultStoreId).get(),
      ]);

      final storeDoc = results[0] as DocumentSnapshot;
      final employeesSnapshot = results[1] as QuerySnapshot;

      final employees = employeesSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      if (mounted) {
        setState(() {
          _storeName = (storeDoc.data() as Map<String, dynamic>)?['name'] ?? _storeName;
          _allEmployees = employees;
          _storeEmployees = _allEmployees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching initial store data: $e");
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
          : Column(
              children: [
                Expanded(child: _buildScheduleTable()),
              ],
            ),
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

  // --- NEW STICKY TABLE IMPLEMENTATION ---

  Widget _buildScheduleTable() {
    if (_storeEmployees.isEmpty) {
      return const Center(child: Text('Không có nhân viên nào tại cửa hàng này.'));
    }

    final timeSlots = List.generate(19, (i) => '${(i + 5).toString().padLeft(2, '0')}:00');
    const double firstColWidth = 150.0;
    const double dataColWidth = 200.0; // Increased from 100.0 to 200.0
    const double headerHeight = 48.0;

    return Stack(
      children: [
        // Main scrollable data grid (bottom-right)
        SingleChildScrollView(
          controller: _horizontalBodyController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SingleChildScrollView(
            controller: _verticalBodyController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: List.generate(_storeEmployees.length + 1, (rowIndex) {
                if (rowIndex == 0) return SizedBox(height: headerHeight);
                final isEven = rowIndex % 2 != 0;
                return Row(
                  children: [
                    SizedBox(width: firstColWidth),
                    // Each hour cell is now a Row of 4 smaller cells
                    ...timeSlots.map((time) {
                      return Row(
                        children: List.generate(4, (quarterIndex) {
                          return Container(
                            width: dataColWidth / 4, // Now 50.0
                            height: 52,
                            decoration: BoxDecoration(
                              color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                              border: Border(
                                // Use a lighter border for 15-min marks and a regular one for the hour mark
                                right: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: (quarterIndex == 3) ? 1.0 : 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }).toList(),
                  ],
                );
              }),
            ),
          ),
        ),

        // Sticky Header Row (top-right)
        SizedBox(
          height: headerHeight,
          child: SingleChildScrollView(
            controller: _horizontalHeadController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                SizedBox(width: firstColWidth),
                ...timeSlots.map((time) => _buildCell(time, dataColWidth, headerHeight, Colors.grey.shade200, isHeader: true)).toList(),
              ],
            ),
          ),
        ),

        // Sticky First Column (bottom-left)
        SizedBox(
          width: firstColWidth,
          child: SingleChildScrollView(
            controller: _verticalHeadController,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: List.generate(_storeEmployees.length + 1, (rowIndex) {
                 if (rowIndex == 0) return SizedBox(height: headerHeight);
                 final employee = _storeEmployees[rowIndex - 1];
                 final isEven = rowIndex % 2 != 0;
                return _buildCell(employee['name'] ?? 'N/A', firstColWidth, 52, isEven ? Colors.white : const Color(0xFFF8F9FA));
              }),
            ),
          ),
        ),

        // Top-left corner cell
        _buildCell('Nhân viên', firstColWidth, headerHeight, Colors.grey.shade200, isHeader: true),
      ],
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
