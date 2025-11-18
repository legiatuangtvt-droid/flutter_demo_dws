import 'dart:convert';
import 'package:flutter/foundation.dart';

// Raw JSON string containing the new mock data structure.
const String mockDataJsonString = '''
{
  "task_groups": [
    { "id": "POS", "order": 1, "code": "POS", 
      "color": {
        "name": "slate", "bg": "#e2e8f0", "text": "#1e293b", "border": "#94a3b8", "hover": "#cbd5e1",
        "tailwind_bg": "bg-slate-200", "tailwind_text": "text-slate-800", "tailwind_border": "border-slate-500"
      },
      "tasks": [
        { "order": "1", "name": "Mở POS", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 10, "manual_number": "POS-001", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "2", "name": "EOD POS", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 15, "manual_number": "POS-002", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "3", "name": "Chuẩn bị POS", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 5, "manual_number": "POS-003", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "4", "name": "Đổi tiền lẻ", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 2, "reUnit": 5, "manual_number": "POS-004", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "5", "name": "Thế cơm POS Staff", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 30, "manual_number": "POS-005", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "6", "name": "Hỗ trợ POS", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 60, "manual_number": "POS-006", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "7", "name": "Kết ca", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 15, "manual_number": "POS-007", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "8", "name": "Giao ca", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 10, "manual_number": "POS-008", "manual_link": "", "note": "Tính theo số lượng POS" },
        { "order": "9", "name": "POS 1", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 1, "manual_number": "POS-009", "manual_link": "", "note": "Tính theo số lượng khách hàng" },
        { "order": "10", "name": "POS 2", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 1, "manual_number": "POS-010", "manual_link": "", "note": "Tính theo số lượng khách hàng" },
        { "order": "11", "name": "POS 3", "typeTask": "CTM", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 1, "manual_number": "POS-011", "manual_link": "", "note": "Tính theo số lượng khách hàng" },
        { "order": "12", "name": "Thế cơm Leader", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 30, "manual_number": "POS-012", "manual_link": "", "note": "Tính theo số lượng POS" }
      ]}
  ],
  "roles": [
    { "id": "STAFF", "name": "Staff", "level": 1 }
  ]
}
''';


/// A function to simulate initializing data.
///
/// In a real app, you might upload this to Firestore or load it into a state management solution.
/// For now, we'll just parse the JSON and print to the console to confirm it's being called.
void initializeMockData() {
  // Using debugPrint to ensure it shows up in the Flutter console.
  debugPrint('--- Initializing Mock Data from JSON ---');
  
  try {
    final Map<String, dynamic> data = jsonDecode(mockDataJsonString);
    final List taskGroups = data['task_groups'] ?? [];
    final List roles = data['roles'] ?? [];

    debugPrint('Successfully parsed JSON.');
    debugPrint('Found ${taskGroups.length} task groups.');
    debugPrint('Found ${roles.length} roles.');

  } catch (e) {
    debugPrint('Error parsing mock data JSON: $e');
  }

  debugPrint('--- Mock Data Initialization Finished ---');
}
