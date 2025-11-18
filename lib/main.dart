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
  // User Context
  String _currentUserName = 'Khách';
  String _currentUserRole = 'N/A';

  // Data from Firestore
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _allEmployees = [];

  // Filtered data for UI
  List<Map<String, dynamic>> _accessibleStores = [];
  List<Map<String, dynamic>> _storeEmployees = [];
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('stores').get(),
        FirebaseFirestore.instance.collection('areas').get(),
        FirebaseFirestore.instance.collection('employee').get(),
      ]);

      final stores = (results[0] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final areas = (results[1] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final employees = (results[2] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      if (mounted) {
        setState(() {
          _allStores = stores;
          _allAreas = areas;
          _allEmployees = employees;

          // Initially, assume an admin/guest view
          _accessibleStores = _allStores;
          if (_accessibleStores.isNotEmpty) {
            _selectedStoreId = _accessibleStores.first['id'];
            _updateDisplayedEmployees(_selectedStoreId);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCurrentUser(Map<String, dynamic> selectedEmployee) {
    List<Map<String, dynamic>> newAccessibleStores = [];
    final String roleId = selectedEmployee['roleId'] ?? '';

    switch (roleId) {
      case 'STAFF':
      case 'STORE_LEADER_G2':
      case 'STORE_LEADER_G3':
        final storeId = selectedEmployee['storeId'];
        newAccessibleStores = _allStores.where((s) => s['id'] == storeId).toList();
        break;
      case 'STORE_INCHARGE':
        final List managedStoreIds = selectedEmployee['managedStoreIds'] ?? [];
        newAccessibleStores = _allStores.where((s) => managedStoreIds.contains(s['id'])).toList();
        break;
      case 'AREA_MANAGER':
        final List managedAreaIds = selectedEmployee['managedAreaIds'] ?? [];
        newAccessibleStores = _allStores.where((s) => managedAreaIds.contains(s['areaId'])).toList();
        break;
      case 'REGIONAL_MANAGER':
        final regionId = selectedEmployee['managedRegionId'];
        final areaIdsInRegion = _allAreas.where((a) => a['regionId'] == regionId).map((a) => a['id']).toList();
        newAccessibleStores = _allStores.where((s) => areaIdsInRegion.contains(s['areaId'])).toList();
        break;
      default: // Admin, HQ
        newAccessibleStores = _allStores;
        break;
    }

    setState(() {
      _currentUserName = selectedEmployee['name'] ?? 'Không rõ';
      _currentUserRole = roleId;
      _accessibleStores = newAccessibleStores;
      _selectedStoreId = _accessibleStores.isNotEmpty ? _accessibleStores.first['id'] : null;
      _updateDisplayedEmployees(_selectedStoreId); // Update table based on new context
    });
  }

  void _updateDisplayedEmployees(String? storeId) {
    if (storeId == null) {
      _storeEmployees = [];
      return;
    }
    setState(() {
      _storeEmployees = _allEmployees.where((emp) => emp['storeId'] == storeId).toList();
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

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Lịch hàng ngày'),
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
            decoration: const BoxDecoration(color: Colors.deepPurple),
          ),
          ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Lịch hàng ngày'), selected: true, onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Lịch hàng tháng'), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    final isStoreDropdownDisabled = _accessibleStores.length <= 1;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStoreId,
                  decoration: InputDecoration(
                    labelText: 'Cửa hàng',
                    border: InputBorder.none,
                    isDense: true,
                    enabled: !isStoreDropdownDisabled,
                  ),
                  items: _accessibleStores.map<DropdownMenuItem<String>>((store) {
                    return DropdownMenuItem<String>(value: store['id'], child: Text(store['name'] ?? 'N/A', overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: isStoreDropdownDisabled ? null : (storeId) {
                    setState(() => _selectedStoreId = storeId);
                    _updateDisplayedEmployees(storeId);
                  },
                ),
              ),
              const VerticalDivider(width: 20),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}, color: Colors.deepPurple),
                  const Text('01/07 - 07/07', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}, color: Colors.deepPurple),
                ],
              ),
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
    // ... (no changes here)
    return Container();
  }

  Widget _buildDataRow(String employeeName, List<String> timeSlots, bool isEven) {
    // ... (no changes here)
    return Container();
  }

  Widget _buildHeaderCell(String text, double width) {
    // ... (no changes here)
    return Container();
  }
}
