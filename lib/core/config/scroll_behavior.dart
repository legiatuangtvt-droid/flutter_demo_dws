import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Lớp này định nghĩa lại hành vi cuộn cho toàn bộ ứng dụng
// để hỗ trợ trượt chéo trên nhiều thiết bị
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
