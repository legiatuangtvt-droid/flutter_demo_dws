import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Hàm đăng nhập cho Store Manager ở chế độ cấp phát
  Future<dynamic> signInAsStoreManager(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return "Đã có lỗi xảy ra. Vui lòng thử lại.";

      final appUser = await _firestoreService.getUserByEmail(email);
      if (appUser == null) return "Tài khoản không tồn tại trong hệ thống.";

      // Quan trọng: Kiểm tra vai trò của người dùng
      if (appUser.roleId != 'STORE_MANAGER') { // Giả sử roleId của Manager là 'STORE_MANAGER'
        await _firebaseAuth.signOut();
        return "Chỉ có Quản lý Cửa hàng mới có thể thực hiện hành động này.";
      }

      return appUser; // Trả về đối tượng AppUser khi thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Sai thông tin đăng nhập. Vui lòng kiểm tra lại.';
      }
      return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  // Hàm đăng nhập cho nhân viên thông thường
  Future<dynamic> signInWithEmailAndPassword(
      String email, String password, String currentStoreId) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return "Đã có lỗi xảy ra. Vui lòng thử lại.";

      final appUser = await _firestoreService.getUserByEmail(email);
      if (appUser == null) return "Tài khoản không tồn tại trong hệ thống.";

      if (appUser.storeId != currentStoreId) {
        final isScheduled = await _firestoreService.isEmployeeScheduledToday(appUser.id, currentStoreId);
        if (!isScheduled) {
          await _firebaseAuth.signOut();
          return "Bạn không thuộc cửa hàng này hoặc không có lịch làm việc hôm nay.";
        }
      }

      return appUser; // Trả về đối tượng AppUser khi thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Sai thông tin đăng nhập. Vui lòng kiểm tra lại.';
      }
      return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  // Các hàm khác không thay đổi nhiều
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

    Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Không tìm thấy tài khoản nào với email này.";
      }
      return "Đã có lỗi xảy ra. Vui lòng thử lại.";
    }
  }
}
