import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/schedule/pages/schedule_page.dart'; // Import trang mới

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Lớp này định nghĩa lại hành vi cuộn cho toàn bộ ứng dụng
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Ghi đè phương thức get dragDevices để bao gồm tất cả các loại thiết bị
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Áp dụng hành vi cuộn mới để hỗ trợ trượt chéo tốt hơn
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
      // Màn hình chính của ứng dụng bây giờ được gọi từ một tệp riêng biệt
      home: const SchedulePage(),
    );
  }
}
