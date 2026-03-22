import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../data/app_data.dart';
import '../models/task.dart';
import '../widgets/wheel_widget.dart';
import '../widgets/reward_popup.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  String? startDate;
  int duration = 7;
  int requiredPercent = 80;

  List<String> rewards = [];

  bool isCompleted = false;
  String? selectedReward;

  final TextEditingController rewardController = TextEditingController();

  late AnimationController _spinController;

  double _currentRotation = 0;
  double _animationStart = 0;
  double _animationEnd = 0;

  bool _isSpinning = false;

  final List<Color> wheelColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFA94D),
    const Color(0xFFFFE066),
    const Color(0xFF69DB7C),
    const Color(0xFF4DABF7),
    const Color(0xFF748FFC),
    const Color(0xFFB197FC),
    const Color(0xFFF783AC),
  ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addListener(() {
        final curvedValue = Curves.easeOutCubic.transform(_spinController.value);

        setState(() {
          _currentRotation =
              _animationStart + (_animationEnd - _animationStart) * curvedValue;
        });
      });

    loadWheel();
  }

  @override
  void dispose() {
    _spinController.dispose();
    rewardController.dispose();
    super.dispose();
  }

  String formatDateKey(DateTime date) {
    return "${date.day}-${date.month}-${date.year}";
  }

  String formatDisplayDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  DateTime? get parsedStartDate {
    if (startDate == null) return null;
    return DateTime.tryParse(startDate!);
  }

  DateTime? get endDate {
    if (parsedStartDate == null) return null;
    return parsedStartDate!.add(Duration(days: duration - 1));
  }

  double calculatePeriodProgress(Map<String, List<Task>> tasksByDate) {
    if (parsedStartDate == null) return 0;

    int countedDays = 0;
    double totalPercent = 0;

    for (int i = 0; i < duration; i++) {
      final day = parsedStartDate!.add(Duration(days: i));
      final key = formatDateKey(day);

      final tasks = tasksByDate[key];

      if (tasks != null && tasks.isNotEmpty) {
        final completed = tasks.where((t) => t.isCompleted).length;
        final percent = completed / tasks.length;

        totalPercent += percent;
        countedDays++;
      }
    }

    if (countedDays == 0) return 0;
    return totalPercent / countedDays;
  }

  Future<void> saveWheel() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      "startDate": startDate,
      "duration": duration,
      "requiredPercent": requiredPercent,
      "rewards": rewards,
      "isCompleted": isCompleted,
      "selectedReward": selectedReward,
      "currentRotation": _currentRotation,
    };

    await prefs.setString("wheel_data", jsonEncode(data));
  }

  Future<void> loadWheel() async {
    final prefs = await SharedPreferences.getInstance();

    final dataString = prefs.getString("wheel_data");
    if (dataString == null) return;

    final data = jsonDecode(dataString);

    setState(() {
      startDate = data["startDate"];
      duration = data["duration"] ?? 7;
      requiredPercent = data["requiredPercent"] ?? 80;
      rewards = List<String>.from(data["rewards"] ?? []);
      isCompleted = data["isCompleted"] ?? false;
      selectedReward = data["selectedReward"];
      _currentRotation = (data["currentRotation"] ?? 0).toDouble();
    });
  }

  void addReward() {
    final value = rewardController.text.trim();

    if (value.isEmpty) return;
    if (rewards.length >= 8) return;

    setState(() {
      rewards.add(value);
      rewardController.clear();
    });

    saveWheel();
  }

  void removeReward(int index) {
    setState(() {
      rewards.removeAt(index);
    });

    saveWheel();
  }

  bool canSpin(double progress) {
    return startDate != null &&
        rewards.length >= 2 &&
        (progress * 100) >= requiredPercent &&
        !_isSpinning &&
        !isCompleted;
  }

  Color getRewardColor(String reward) {
    final index = rewards.indexOf(reward);
    if (index == -1) return const Color(0xFFFFA94D);
    return wheelColors[index % wheelColors.length];
  }

  Future<void> spinWheel(double progress) async {
    if (!canSpin(progress)) return;

    final random = math.Random();
    final selectedIndex = random.nextInt(rewards.length);

    final sectorAngle = (2 * math.pi) / rewards.length;

    final normalizedCurrent = _currentRotation % (2 * math.pi);

    final deltaToTarget = (2 * math.pi -
            ((normalizedCurrent +
                    selectedIndex * sectorAngle +
                    sectorAngle / 2) %
                (2 * math.pi))) %
        (2 * math.pi);

    final extraSpins = 2 * math.pi * (5 + random.nextInt(3));
    final targetRotation = _currentRotation + extraSpins + deltaToTarget;

    setState(() {
      _isSpinning = true;
      _animationStart = _currentRotation;
      _animationEnd = targetRotation;
    });

    await _spinController.forward(from: 0);

    final wonReward = rewards[selectedIndex];

    setState(() {
      _currentRotation = targetRotation;
      selectedReward = wonReward;
      isCompleted = true;
      _isSpinning = false;
    });

    await saveWheel();

     if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "reward",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return RewardPopup(
          rewardText: wonReward,
          rewardColor: getRewardColor(wonReward),
        );
      },
    );
  }

  void showCreateOrEditRoundDialog({bool resetForNewRound = false}) {
    int tempDuration = duration;
    int tempPercent = requiredPercent;

    DateTime tempStartDate = resetForNewRound
        ? DateTime.now()
        : (parsedStartDate ?? DateTime.now());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(resetForNewRound ? "Нов рунд" : "Редакция на рунд"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Начална дата",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: tempStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            tempStartDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formatDisplayDate(tempStartDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Продължителност: $tempDuration дни",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: tempDuration.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: tempDuration.toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempDuration = value.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Изискван процент: $tempPercent%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: tempPercent.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: tempPercent.toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempPercent = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Отказ"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      duration = tempDuration;
                      requiredPercent = tempPercent;
                      startDate = tempStartDate.toIso8601String();

                      if (resetForNewRound) {
                        isCompleted = false;
                        selectedReward = null;
                        rewards = [];
                        _currentRotation = 0;
                        rewardController.clear();
                      }
                    });

                    saveWheel();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(resetForNewRound ? "Създай" : "Запази"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDate = Provider.of<AppData>(context).tasksByDate;
    final progress = calculatePeriodProgress(tasksByDate);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startDate != null && parsedStartDate != null && endDate != null)
              GestureDetector(
                onTap: (!isCompleted && !_isSpinning)
                    ? () => showCreateOrEditRoundDialog()
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Период: ${formatDisplayDate(parsedStartDate!)} - ${formatDisplayDate(endDate!)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Продължителност: $duration дни"),
                      Text("Изискване: $requiredPercent%"),
                      Text("Прогрес: ${(progress * 100).toStringAsFixed(0)}%"),
                      if (selectedReward != null)
                        Text("Спечелена награда: $selectedReward"),
                      if (!isCompleted) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Натисни тук за редакция на рунда",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 42,
                  ),
                  GestureDetector(
                    onTap: canSpin(progress) ? () => spinWheel(progress) : null,
                    child: Opacity(
                      opacity: _isSpinning ? 0.95 : 1,
                      child: Transform.rotate(
                        angle: _currentRotation,
                        child: WheelWidget(rewards: rewards),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isSpinning)
                    const Text(
                      "Колелото се върти...",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    )
                  else if (!canSpin(progress))
                    const Text(
                      "За въртене трябват поне 2 награди и достатъчен процент.",
                      textAlign: TextAlign.center,
                    )
                  else
                    const Text(
                      "Натисни колелото или бутона „Завърти“",
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rewardController,
                    decoration: const InputDecoration(
                      labelText: "Нова награда",
                    ),
                    onSubmitted: (_) => addReward(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: addReward,
                  icon: const Icon(Icons.add_circle, size: 30),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Награди: ${rewards.length}/8 (минимум 2 за въртене)",
                style: const TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rewards.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value),
                  onDeleted: () => removeReward(entry.key),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (startDate == null)
              ElevatedButton(
                onPressed: () => showCreateOrEditRoundDialog(),
                child: const Text("Създай рунд"),
              )
            else if (!isCompleted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSpinning
                          ? null
                          : () => showCreateOrEditRoundDialog(),
                      child: const Text("Редактирай рунд"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          canSpin(progress) ? () => spinWheel(progress) : null,
                      child: const Text("Завърти"),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Рундът приключи",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedReward != null)
                    Text(
                      "Награда: $selectedReward",
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSpinning
                        ? null
                        : () => showCreateOrEditRoundDialog(
                              resetForNewRound: true,
                            ),
                    child: const Text("Нов рунд"),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}