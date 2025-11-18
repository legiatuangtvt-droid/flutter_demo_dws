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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  // State for the current user display
  String _currentUserName = 'Lê Gia Tuấn';
  String _currentUserRole = 'Quản lý';

  // State for data management
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _allAreas = [];
  List<Map<String, dynamic>> _allRegions = [];
  
  // State for UI controls
  List<Map<String, dynamic>> _accessibleStores = [];
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
        FirebaseFirestore.instance.collection('regions').get(),
      ]);

      final stores = (results[0] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final areas = (results[1] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
      final regions = (results[2] as QuerySnapshot).docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();

      if (mounted) {
        setState(() {
          _allStores = stores;
          _allAreas = areas;
          _allRegions = regions;
          _accessibleStores = _allStores; // Initially, show all stores
          if (_accessibleStores.isNotEmpty) {
            _selectedStoreId = _accessibleStores.first['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching initial data: $e");
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

      case 'HQ_STAFF':
      case 'ADMIN':
      default:
        newAccessibleStores = _allStores;
        break;
    }

    setState(() {
      _currentUserName = selectedEmployee['name'] ?? 'Không rõ';
      _currentUserRole = roleId;
      _accessibleStores = newAccessibleStores;

      // Set selected store to the first accessible one, or null if none are accessible
      _selectedStoreId = _accessibleStores.isNotEmpty ? _accessibleStores.first['id'] : null;
    });
  }


  List<DataColumn> _buildTimeColumns() {
    return [const DataColumn(label: Text('Nhân viên')), ...List.generate(19, (i) => DataColumn(label: Text('${(i + 5).toString().padLeft(2, '0')}:00')))];
  }

  List<DataRow> _buildEmployeeRows() {
    return List.generate(3, (index) => DataRow(cells: [DataCell(Text('Nhân viên ${index + 1}')), ...List.generate(19, (_) => const DataCell(Text('')))]));
  }

  @override
  Widget build(BuildContext context) {
    final bool isStoreDropdownDisabled = _accessibleStores.length <= 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hàng ngày'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold)), Text(_currentUserRole, style: const TextStyle(fontSize: 12.0))],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(decoration: BoxDecoration(color: Colors.deepPurple), child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24))),
            ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Lịch hàng ngày'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Lịch hàng tháng'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isLoading
                    ? const Expanded(child: Center(child: Text("Đang tải cửa hàng...")))
                    : DropdownButton<String>(
                        value: _selectedStoreId,
                        items: _accessibleStores.map<DropdownMenuItem<String>>((store) {
                          return DropdownMenuItem<String>(value: store['id'], child: Text(store['name'] ?? 'N/A'));
                        }).toList(),
                        // Disable dropdown if there's only one or zero options
                        onChanged: isStoreDropdownDisabled ? null : (String? newValue) {
                          setState(() => _selectedStoreId = newValue);
                        },
                      ),
                Row(children: [IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}), const Text('T2 01/07 - CN 07/07'), IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {})]),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(scrollDirection: Axis.vertical, child: DataTable(border: TableBorder.all(color: Colors.grey.shade300, width: 1), columnSpacing: 10, columns: _buildTimeColumns(), rows: _buildEmployeeRows())),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: DevFab(onUserSwitch: _updateCurrentUser),
    );
  }
}
