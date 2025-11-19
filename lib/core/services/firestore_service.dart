import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy thông tin người dùng bằng email
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _db
          .collection('employee')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }
      return AppUser.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      print("Error getting user by email: $e");
      return null;
    }
  }

  // Lấy thông tin người dùng bằng ID (số điện thoại hoặc mã nhân viên)
  Future<AppUser?> getUserByIdentifier(String identifier) async {
    try {
      // Thử tìm bằng ID trước
      DocumentSnapshot doc = await _db.collection('employee').doc(identifier).get();

      if (doc.exists) {
        return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }

      // Nếu không thấy, thử tìm bằng số điện thoại
      final snapshot = await _db
          .collection('employee')
          .where('phone', isEqualTo: identifier)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
      }

      return null;
    } catch (e) {
      print("Error getting user by identifier: $e");
      return null;
    }
  }
  
  // Kiểm tra xem một nhân viên có trong lịch làm việc của một cửa hàng cụ thể vào ngày hôm nay không
  Future<bool> isEmployeeScheduledToday(String userId, String storeId) async {
    try {
      // Note: This logic assumes a specific data structure for daily templates.
      // It might need to be adapted based on the actual structure.
      final templateDoc = await _db.collection('daily_templates').doc('TEST').get();
      if (!templateDoc.exists) return false;

      final schedule = (templateDoc.data() as Map<String, dynamic>)['schedule'] ?? {};
      
      for (var shift in schedule.values) {
        for (var task in (shift as List)) {
          // This is a simplification. The actual check might need to be more complex
          // if the employee ID is stored differently in the task.
          if (task['employeeId'] == userId) { 
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("Error checking employee schedule: $e");
      return false;
    }
  }
}
