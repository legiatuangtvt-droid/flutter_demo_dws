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
  // --- APP CONTEXT ---
  // Assume this device is locked to a specific store.
  static const String _defaultStoreId = 'AMPM_DN_NVC'; // AEON MaxValu Ngô Quyền
  String _storeName = 'AEON MaxValu Ngô Quyền'; // Default display name

  // --- USER CONTEXT ---
  // Initially, no one is logged in.
  String _currentUserName = 'Chưa đăng nhập';
  String _currentUserRole = 'Vui lòng chọn người dùng';

  // --- DATA FROM FIRESTORE ---
  bool _isLoading = true;
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _storeEmployees = []; // Employees for the default store

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
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
          _storeEmployees = _allEmployees; // Initially, the table shows all employees of this store
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching initial store data: $e");
    }
  }

  // This function now acts as a "login" for the selected user
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
                _buildControlPanel(),
                Expanded(child: _buildScheduleTable()),
              ],
            ),
      floatingActionButton: DevFab(onUserSwitch: _updateCurrentUser),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  AppBar _buildAppBar() {
    return AppBar(
      // Show store name prominently in the title
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
    // ... (Drawer UI remains the same)
    return Drawer();
  }

  Widget _buildControlPanel() {
    // The store selector is removed as the store is now fixed for the device
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the week navigation
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}, color: Colors.deepPurple),
              const Text('01/07 - 07/07', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTable() {
    final List<String> timeSlots = List.generate(19, (i) => '${(i + 5).toString().padLeft(2, '0')}:00');

    if (_storeEmployees.isEmpty) {
      return const Center(child: Text('Không có nhân viên nào tại cửa hàng này.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (timeSlots.length * 100.0) + 150.0,
        child: ListView.builder(
          itemCount: _storeEmployees.length + 1,
          itemBuilder: (context, rowIndex) {
            if (rowIndex == 0) return _buildHeaderRow(timeSlots);
            
            final employee = _storeEmployees[rowIndex - 1];
            return _buildDataRow(employee['name'] ?? 'N/A', timeSlots, rowIndex % 2 != 0);
          },
        ),
      ),
    );
  }
  
  Widget _buildHeaderRow(List<String> timeSlots) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Nhân viên', 150),
          ...timeSlots.map((time) => _buildHeaderCell(time, 100)).toList(),
        ],
      ),
    );
  }

  Widget _buildDataRow(String employeeName, List<String> timeSlots, bool isEven) {
    return Container(
      height: 52,
      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
      child: Row(
        children: [
          Container(
            width: 150,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isEven ? Colors.white : const Color(0xFFF8F9FA),
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(employeeName, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          ...timeSlots.map((time) {
            return Container(
              width: 100,
              height: 52,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }
}
