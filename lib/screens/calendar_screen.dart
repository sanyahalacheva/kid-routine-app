import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/task.dart';
import 'day_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime currentMonth = DateTime.now();

  final List<String> weekdayLabels = const ['П', 'В', 'С', 'Ч', 'П', 'С', 'Н'];

  String formatDate(DateTime date) {
    return "${date.day}-${date.month}-${date.year}";
  }

  double getCompletionForDay(String dateKey, Map<String, List<Task>> tasksByDate) {
    final tasks = tasksByDate[dateKey];
    if (tasks == null || tasks.isEmpty) return 0;

    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }

  String getMonthName(int month) {
    const months = [
      '',
      'Януари',
      'Февруари',
      'Март',
      'Април',
      'Май',
      'Юни',
      'Юли',
      'Август',
      'Септември',
      'Октомври',
      'Ноември',
      'Декември',
    ];

    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDate = Provider.of<AppData>(context).tasksByDate;

    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    // DateTime.weekday:
    // Понеделник = 1 ... Неделя = 7
    final int firstWeekday = firstDayOfMonth.weekday;

    // Колко празни клетки преди 1-во число
    final int leadingEmptyCells = firstWeekday - 1;

    // Общо клетки = празни отпред + реални дни
    final int totalCells = leadingEmptyCells + daysInMonth;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentMonth =
                            DateTime(currentMonth.year, currentMonth.month - 1);
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  Text(
                    "${getMonthName(currentMonth.month)} ${currentMonth.year}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentMonth =
                            DateTime(currentMonth.year, currentMonth.month + 1);
                      });
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Заглавия на дните от седмицата
            Row(
              children: weekdayLabels.map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  // Празни клетки преди началото на месеца
                  if (index < leadingEmptyCells) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                    );
                  }

                  final day = index - leadingEmptyCells + 1;
                  final date =
                      DateTime(currentMonth.year, currentMonth.month, day);
                  final key = formatDate(date);

                  final percent = getCompletionForDay(key, tasksByDate);

                  final today = DateTime.now();
                  final bool isToday = today.day == date.day &&
                      today.month == date.month &&
                      today.year == date.year;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DayDetailScreen(
                            dateKey: key,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday ? Colors.indigo : Colors.grey.shade300,
                          width: isToday ? 2 : 1,
                        ),
                        color: percent == 1
                            ? Colors.green.withOpacity(0.25)
                            : percent > 0
                                ? Colors.blue.withOpacity(
                                    percent.clamp(0.0, 1.0),
                                  )
                                : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "$day",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isToday ? Colors.indigo : Colors.black87,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              "${(percent * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}