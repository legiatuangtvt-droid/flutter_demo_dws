import 'package:flutter/material.dart';

// Widget này chỉ chịu trách nhiệm hiển thị bảng lịch trình
class ScheduleTable extends StatelessWidget {
  final List<Map<String, dynamic>> storeEmployees;
  final Map<String, dynamic> scheduleData;
  final List<Map<String, dynamic>> taskGroups;
  final ScrollController horizontalBodyController;
  final ScrollController verticalBodyController;
  final ScrollController horizontalHeaderController;
  final ScrollController verticalFirstColumnController;

  const ScheduleTable({
    super.key,
    required this.storeEmployees,
    required this.scheduleData,
    required this.taskGroups,
    required this.horizontalBodyController,
    required this.verticalBodyController,
    required this.horizontalHeaderController,
    required this.verticalFirstColumnController,
  });

  @override
  Widget build(BuildContext context) {
    if (storeEmployees.isEmpty) {
      return const Center(
          child: Text('Không có nhân viên nào tại cửa hàng này.'));
    }

    const double firstColWidth = 150.0;
    const double dataColWidth = 70.0;
    const double rowHeight = 100.0;
    const double headerHeight = 48.0;
    const double borderWidth = 1.5;

    final sortedShiftKeys = scheduleData.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.split('-').last) ?? 0;
        final numB = int.tryParse(b.split('-').last) ?? 0;
        return numA.compareTo(numB);
      });

    return Column(
      children: [
        // ---- HÀNG HEADER (CỐ ĐỊNH CHIỀU DỌC) ----
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: borderWidth),
            ),
          ),
          child: Row(
            children: [
              // Ô cố định trên cùng bên trái
              _buildCell(
                  'Nhân viên', firstColWidth, headerHeight, Colors.grey.shade300,
                  isHeader: true),
              // Các ô header cuộn ngang
              Expanded(
                child: SingleChildScrollView(
                  controller: horizontalHeaderController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(19, (i) {
                      final hour = '${(i + 5).toString().padLeft(2, '0')}:00';
                      return _buildCell(hour, dataColWidth * 4, headerHeight,
                          Colors.grey.shade200, isHeader: true);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ---- KHU VỰC CUỘN ----
        Expanded(
          child: Row(
            children: [
              // ---- CỘT ĐẦU TIÊN (CỐ ĐỊNH CHIỀU NGANG, CUỘN DỌC) ----
              SizedBox(
                width: firstColWidth,
                child: ListView.builder(
                  controller: verticalFirstColumnController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: storeEmployees.length,
                  itemBuilder: (context, rowIndex) {
                    final employee = storeEmployees[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final rowBgColor =
                        isEven ? Colors.white : const Color(0xFFF8F9FA);
                    return _buildCell(employee['name'] ?? 'N/A',
                        firstColWidth, rowHeight, rowBgColor);
                  },
                ),
              ),
              // ---- PHẦN BODY (CUỘN CẢ 2 CHIỀU) ----
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: horizontalBodyController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: dataColWidth * 19 * 4,
                    child: ListView.builder(
                      controller: verticalBodyController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: storeEmployees.length,
                      itemBuilder: (context, rowIndex) {
                        final isEven = rowIndex % 2 == 0;
                        final rowBgColor =
                            isEven ? Colors.white : const Color(0xFFF8F9FA);

                        List<dynamic> employeeTasks = [];
                        if (rowIndex < sortedShiftKeys.length) {
                          final shiftKey = sortedShiftKeys[rowIndex];
                          employeeTasks = scheduleData[shiftKey] ?? [];
                        }

                        return Row(
                          children: List.generate(19 * 4, (quarterIndex) {
                            final hour = (quarterIndex ~/ 4) + 5;
                            final minute = (quarterIndex % 4) * 15;
                            final currentTime =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                            final task = employeeTasks.firstWhere(
                                (t) => t['startTime'] == currentTime,
                                orElse: () => null);

                            Widget cellContent = const SizedBox();
                            if (task != null) {
                              final Iterable<Map<String, dynamic>>
                                  matchingGroups = taskGroups.where(
                                      (g) => g['id'] == task['groupId']);
                              final Map<String, dynamic>? taskGroup =
                                  matchingGroups.isNotEmpty
                                      ? matchingGroups.first
                                      : null;
                              final bgColor = taskGroup != null
                                  ? _getColorFromHex(
                                      taskGroup['color']['bg'])
                                  : Colors.grey.shade300;
                              final borderColor = HSLColor.fromColor(bgColor)
                                  .withLightness(
                                      (HSLColor.fromColor(bgColor).lightness -
                                          0.2)
                                          .clamp(0.0, 1.0))
                                  .toColor();

                              cellContent = Container(
                                margin: const EdgeInsets.all(2.0),
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                      color: borderColor, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    task['taskName'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 5,
                                  ),
                                ),
                              );
                            }

                            final bool isHourlyBorder = (quarterIndex + 1) % 4 == 0;
                            final Color rightBorderColor = isHourlyBorder ? Colors.black : Colors.grey.shade300;

                            return Container(
                              width: dataColWidth,
                              height: rowHeight,
                              decoration: BoxDecoration(
                                color: rowBgColor,
                                border: Border(
                                  right: BorderSide(
                                      color: rightBorderColor, width: borderWidth),
                                  bottom: BorderSide(
                                      color: Colors.black, width: borderWidth),
                                ),
                              ),
                              child: cellContent,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper functions moved from the state class

Color _getColorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}

Widget _buildCell(String text, double width, double height, Color bgColor,
    {bool isHeader = false, double borderWidth = 1.5}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: bgColor,
      border: Border(
        right: BorderSide(color: Colors.black, width: borderWidth),
        bottom: BorderSide(color: Colors.black, width: borderWidth),
      ),
    ),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 4.0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        fontSize: isHeader ? 14 : 12,
      ),
    ),
  );
}
