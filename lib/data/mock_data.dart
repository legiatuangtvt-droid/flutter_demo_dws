import 'package:flutter/foundation.dart';

// A simple model for an employee
class Employee {
  final String id;
  final String name;

  const Employee({required this.id, required this.name});
}

// A simple model for a shift
class Shift {
  final String employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final String storeId;

  const Shift({
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    required this.storeId,
  });
}

// --- MOCK DATA ---

final List<Employee> mockEmployees = [
  const Employee(id: 'emp1', name: 'Nguyễn Văn A'),
  const Employee(id: 'emp2', name: 'Trần Thị B'),
  const Employee(id: 'emp3', name: 'Lê Gia Tuấn'),
];

final List<Shift> mockShifts = [
  // Shifts for today
  Shift(
    employeeId: 'emp1',
    startTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
    endTime: DateTime.now().copyWith(hour: 16, minute: 0, second: 0),
    storeId: 'Store A',
  ),
  Shift(
    employeeId: 'emp2',
    startTime: DateTime.now().copyWith(hour: 14, minute: 0, second: 0),
    endTime: DateTime.now().copyWith(hour: 22, minute: 0, second: 0),
    storeId: 'Store A',
  ),
  Shift(
    employeeId: 'emp3',
    startTime: DateTime.now().copyWith(hour: 9, minute: 0, second: 0),
    endTime: DateTime.now().copyWith(hour: 17, minute: 0, second: 0),
    storeId: 'Store B',
  ),
];

/// A function to simulate initializing data.
///
/// In a real app, you might upload this to Firestore or load it into a state management solution.
/// For now, we'll just print to the console to confirm it's being called.
void initializeMockData() {
  // Using debugPrint to ensure it shows up in the Flutter console.
  debugPrint('--- Initializing Mock Data ---');
  debugPrint('Found ${mockEmployees.length} employees.');
  debugPrint('Found ${mockShifts.length} shifts.');
  debugPrint('--- Mock Data Initialized ---');
}
