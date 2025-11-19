import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/schedule/pages/schedule_page.dart';
import 'features/auth/pages/login_page.dart'; // Import trang login
import 'core/config/scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kiểm tra xem thiết bị đã được cấp phát cho cửa hàng nào chưa
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('storeId');

  runApp(MyApp(storeId: storeId));
}

class MyApp extends StatelessWidget {
  final String? storeId;
  const MyApp({super.key, this.storeId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          titleTextStyle: TextStyle(
              fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      // Quyết định màn hình khởi động dựa trên việc storeId có tồn tại hay không
      home: storeId == null
          ? const LoginPage(isProvisioningMode: true) // Chế độ cấp phát cho Store Manager
          : SchedulePage(storeId: storeId!),      // Chế độ hoạt động bình thường
    );
  }
}
