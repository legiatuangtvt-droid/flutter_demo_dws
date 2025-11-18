import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    { "id": "STAFF", "name": "Staff", "level": 1 },
    { "id": "STORE_LEADER_G2", "name": "Store Leader G2 (Phó cửa hàng)", "level": 10 },
    { "id": "STORE_LEADER_G3", "name": "Store Leader G3 (Trưởng cửa hàng)", "level": 11 },
    { "id": "STORE_INCHARGE", "name": "Store In-charge (SI)", "level": 12 },
    { "id": "AREA_MANAGER", "name": "Area Manager", "level": 20 },
    { "id": "REGIONAL_MANAGER", "name": "Regional Manager", "level": 30 },
    { "id": "HQ_STAFF", "name": "HQ Staff", "level": 50 },
    { "id": "ADMIN", "name": "Admin System", "level": 99 }
  ],
  "employee": [  
    { "id": "AMPM_NVT_LEAD_01", "name": "Trần Minh Dũng", "roleId": "STORE_LEADER_G3", "storeId": "AMPM_NVT", "phone": "0911000001", "status": "ACTIVE" }
  ],
  "stores": [
    { "id": "AMPM_NVT", "name": "AEON MaxValu Nguyễn Văn Trỗi", "address": "Quận Phú Nhuận, TP.HCM", "status": "INACTIVE", "areaId": "HCM_CENTRAL" }
  ]
}
''';


/// Deletes all documents in the specified collections and then uploads the new mock data.
/// Returns a string message indicating the result.
Future<String> initializeMockData() async {
  debugPrint('--- Starting to clear and upload mock data to Firestore ---');
  final firestore = FirebaseFirestore.instance;
  
  try {
    final Map<String, dynamic> allData = jsonDecode(mockDataJsonString);
    final WriteBatch batch = firestore.batch();
    int totalDocsWritten = 0;
    int totalDocsDeleted = 0;

    for (final entry in allData.entries) {
      final collectionName = entry.key;
      final List<dynamic> items = entry.value;

      // --- DELETION PART ---
      debugPrint('Querying existing documents in \'$collectionName\' for deletion...');
      final QuerySnapshot snapshot = await firestore.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        totalDocsDeleted++;
      }
      debugPrint('Found and queued ${snapshot.docs.length} documents for deletion in \'$collectionName\'.');

      // --- WRITING PART ---
      for (final item in items) {
        if (item is Map<String, dynamic> && item.containsKey('id')) {
          final String docId = item['id'];
          final DocumentReference docRef = firestore.collection(collectionName).doc(docId);
          batch.set(docRef, item);
          totalDocsWritten++;
        } else {
          debugPrint('[WARNING] Skipping item in $collectionName because it has no ID: $item');
        }
      }
    }

    // Commit the batch to execute all deletes and writes at once
    await batch.commit();
    
    final successMessage = 'Đồng bộ hóa thành công: Đã xóa $totalDocsDeleted và tải lên $totalDocsWritten tài liệu!';
    debugPrint(successMessage);
    return successMessage; // Return success message

  } catch (e) {
    final errorMessage = 'Lỗi khi đồng bộ hóa dữ liệu: $e';
    debugPrint(errorMessage);
    return errorMessage; // Return error message
  }
}
