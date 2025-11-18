import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
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
        { "order": "1", "name": "Mở POS", "typeTask": "Fixed", "frequency": "Daily", "frequencyNumber": 1, "reUnit": 10, "manual_number": "POS-001", "manual_link": "", "note": "Tính theo số lượng POS" }
      ]}
  ],
  "roles": [
    { "id": "STAFF", "name": "Staff", "level": 1 }
  ],
  "employee": [  
    { "id": "AMPM_NVT_LEAD_01", "name": "Trần Minh Dũng", "roleId": "STORE_LEADER_G3", "storeId": "AMPM_NVT", "phone": "0911000001", "status": "ACTIVE" }
  ],
  "stores": [
    { "id": "AMPM_NVT", "name": "AEON MaxValu Nguyễn Văn Trỗi", "address": "Quận Phú Nhuận, TP.HCM", "status": "INACTIVE", "areaId": "HCM_CENTRAL" }
  ]
}
''';


/// Parses the local JSON and uploads it to Firestore.
/// Returns a string message indicating the result.
Future<String> initializeMockData() async { // Returns a Future<String>
  debugPrint('--- Starting to upload mock data to Firestore ---');
  final firestore = FirebaseFirestore.instance;
  
  try {
    final Map<String, dynamic> allData = jsonDecode(mockDataJsonString);
    final WriteBatch batch = firestore.batch();
    int totalDocs = 0;

    for (final entry in allData.entries) {
      final collectionName = entry.key;
      final List<dynamic> items = entry.value;

      debugPrint('Preparing to write ${items.length} documents to collection \'$collectionName\'...');

      for (final item in items) {
        if (item is Map<String, dynamic> && item.containsKey('id')) {
          final String docId = item['id'];
          final DocumentReference docRef = firestore.collection(collectionName).doc(docId);
          batch.set(docRef, item);
          totalDocs++;
        } else {
          debugPrint('[WARNING] Skipping item in $collectionName because it has no ID: $item');
        }
      }
    }

    await batch.commit();
    final successMessage = 'Tải lên thành công $totalDocs tài liệu lên Firestore!';
    debugPrint(successMessage);
    return successMessage; // Return success message

  } catch (e) {
    final errorMessage = 'Lỗi khi tải dữ liệu lên: $e';
    debugPrint(errorMessage);
    return errorMessage; // Return error message
  }
}
