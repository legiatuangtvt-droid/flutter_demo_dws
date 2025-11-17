import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
      home: const SchedulePage(), // Changed this from MyHomePage
    );
  }
}

// New page widget
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String? _selectedStore = 'Store A'; // Placeholder
  final List<String> _stores = ['Store A', 'Store B', 'Store C']; // Placeholder

  // Helper to build the time columns for the DataTable
  List<DataColumn> _buildTimeColumns() {
    List<DataColumn> columns = [const DataColumn(label: Text('Nhân viên'))];
    for (int i = 5; i <= 23; i++) {
      columns.add(DataColumn(label: Text('${i.toString().padLeft(2, '0')}:00')));
    }
    return columns;
  }

  // Helper to build placeholder rows
  List<DataRow> _buildEmployeeRows() {
    // This would come from your data source
    List<String> employees = ['Nhân viên 1', 'Nhân viên 2', 'Nhân viên 3'];
    return employees.map((employee) {
      List<DataCell> cells = [DataCell(Text(employee))];
      // Add empty cells for time slots
      for (int i = 5; i <= 23; i++) {
        cells.add(const DataCell(Text(''))); // Placeholder for shifts
      }
      return DataRow(cells: cells);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Top Bar
      appBar: AppBar(
        title: const Text('Lịch hàng ngày'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Lê Gia Tuấn', // Placeholder name
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Quản lý', // Placeholder position
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 2. Sidebar Menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Lịch hàng ngày'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Already on this page, do nothing
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Lịch hàng tháng'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to monthly calendar page (not implemented)
              },
            ),
          ],
        ),
      ),
      // 3. Main Content
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // --- Function Bar ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Store Selector
                DropdownButton<String>(
                  value: _selectedStore,
                  items: _stores.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStore = newValue;
                    });
                  },
                ),
                // Week Navigator
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () { /* Logic for previous week */ },
                    ),
                    const Text('T2 01/07 - CN 07/07'), // Placeholder date range
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () { /* Logic for next week */ },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // --- Table ---
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    columnSpacing: 10,
                    columns: _buildTimeColumns(),
                    rows: _buildEmployeeRows(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
