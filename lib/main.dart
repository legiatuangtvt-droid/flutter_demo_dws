import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_demo_dws/chat_fab.dart'; // This file now contains DevFab
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
  String? _selectedStore = 'Store A';
  final List<String> _stores = ['Store A', 'Store B', 'Store C'];

  List<DataColumn> _buildTimeColumns() {
    List<DataColumn> columns = [const DataColumn(label: Text('Nhân viên'))];
    for (int i = 5; i <= 23; i++) {
      columns.add(DataColumn(label: Text('${i.toString().padLeft(2, '0')}:00')));
    }
    return columns;
  }

  List<DataRow> _buildEmployeeRows() {
    List<String> employees = ['Nhân viên 1', 'Nhân viên 2', 'Nhân viên 3'];
    return employees.map((employee) {
      List<DataCell> cells = [DataCell(Text(employee))];
      for (int i = 5; i <= 23; i++) {
        cells.add(const DataCell(Text('')));
      }
      return DataRow(cells: cells);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  Text(
                    'Lê Gia Tuấn',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Quản lý',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {},
                    ),
                    const Text('T2 01/07 - CN 07/07'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
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
      // Changed to use the new DevFab
      floatingActionButton: const DevFab(),
    );
  }
}
