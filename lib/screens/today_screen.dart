import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../data/app_data.dart';
import '../services/parent_pin_service.dart';
import '../models/task.dart';
import '../utils/task_icons.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  Map<String, List<Task>> tasksByDate = {};
  final TextEditingController _controller = TextEditingController();

  bool _parentUnlocked = false;
  String _selectedIconKey = 'star';

  String get todayKey {
    final now = DateTime.now();
    return "${now.day}-${now.month}-${now.year}";
  }

  List<Task> get todayTasks {
    final tasks = List<Task>.from(tasksByDate[todayKey] ?? []);

    tasks.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      if (a.isCompleted) return 1;
      return -1;
    });

    return tasks;
  }

  double get completionPercentage {
    if (todayTasks.isEmpty) return 0;
    final completed = todayTasks.where((t) => t.isCompleted).length;
    return completed / todayTasks.length;
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> ensureParentAccess() async {
    if (_parentUnlocked) return true;

    final granted = await ParentPinService.requestPinIfNeeded(context);

    if (granted) {
      setState(() {
        _parentUnlocked = true;
      });

      Future.delayed(const Duration(seconds: 30), () {
        if (!mounted) return;
        setState(() {
          _parentUnlocked = false;
        });
      });
    }

    return granted;
  }

  Future<void> showIconPicker({
    required String initialIconKey,
    required Function(String selectedKey) onSelected,
  }) async {
    String tempSelected = initialIconKey;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Избери икона'),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: TaskIcons.all.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final item = TaskIcons.all[index];
                    final isSelected = item.key == tempSelected;

                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSelected = item.key;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.indigo
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.indigo : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Отказ'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelected(tempSelected);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Избери'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> addTask(String title) async {
    setState(() {
      tasksByDate.putIfAbsent(todayKey, () => []);
      tasksByDate[todayKey]!.add(
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          iconKey: _selectedIconKey,
        ),
      );
      _selectedIconKey = 'star';
    });

    await saveTasks();
  }

  Future<void> toggleTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    await saveTasks();
  }

  Future<void> deleteTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    setState(() {
      tasksByDate[todayKey]?.removeWhere((t) => t.id == task.id);
    });

    await saveTasks();
  }

  Future<void> editTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    final controller = TextEditingController(text: task.title);
    String tempIconKey = task.iconKey;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Редакция на задача'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Ново име на задачата',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Икона:'),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(TaskIcons.getIcon(tempIconKey)),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () async {
                            await showIconPicker(
                              initialIconKey: tempIconKey,
                              onSelected: (selectedKey) {
                                setDialogState(() {
                                  tempIconKey = selectedKey;
                                });
                              },
                            );
                          },
                          child: const Text('Смени'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Отказ'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newTitle = controller.text.trim();
                    if (newTitle.isEmpty) return;

                    setState(() {
                      task.title = newTitle;
                      task.iconKey = tempIconKey;
                    });

                    await saveTasks();
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Запази'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> confirmDeleteTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Изтриване'),
          content: const Text(
            'Сигурни ли сте, че искате да изтриете тази задача?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Отказ'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await deleteTask(task);
              },
              child: const Text('Изтрий'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, List<String>> encodedMap = {};

    tasksByDate.forEach((date, tasks) {
      encodedMap[date] = tasks
          .map(
            (t) => jsonEncode({
              'id': t.id,
              'title': t.title,
              'isCompleted': t.isCompleted,
              'iconKey': t.iconKey,
            }),
          )
          .toList();
    });

    await prefs.setString('tasksByDate', jsonEncode(encodedMap));

    if (!mounted) return;
    Provider.of<AppData>(context, listen: false).setTasks(tasksByDate);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasksByDate');

    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;

      final loadedTasks = decoded.map((date, list) {
        final tasksList = list as List;
        return MapEntry(
          date,
          tasksList.map((e) {
            final map = jsonDecode(e);
            return Task(
              id: map['id'],
              title: map['title'],
              isCompleted: map['isCompleted'],
              iconKey: map['iconKey'] ?? 'star',
            );
          }).toList(),
        );
      });

      if (!mounted) return;

      setState(() {
        tasksByDate = loadedTasks;
      });

      Provider.of<AppData>(context, listen: false).setTasks(tasksByDate);
    } else {
      if (!mounted) return;
      Provider.of<AppData>(context, listen: false).setTasks({});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Днес",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(completionPercentage * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: completionPercentage,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await showIconPicker(
                            initialIconKey: _selectedIconKey,
                            onSelected: (selectedKey) {
                              setState(() {
                                _selectedIconKey = selectedKey;
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            TaskIcons.getIcon(_selectedIconKey),
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Нова задача",
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) async {
                            if (value.trim().isNotEmpty) {
                              await addTask(value.trim());
                              _controller.clear();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (_controller.text.trim().isNotEmpty) {
                            await addTask(_controller.text.trim());
                            _controller.clear();
                          }
                        },
                        icon: const Icon(
                          Icons.add_circle,
                          size: 30,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      TaskIcons.getLabel(_selectedIconKey),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...todayTasks.map((task) {
              return Opacity(
                opacity: task.isCompleted ? 0.6 : 1,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) async {
                          await toggleTask(task);
                        },
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          TaskIcons.getIcon(task.iconKey),
                          size: 20,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await editTask(task);
                          },
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color:
                                  task.isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await confirmDeleteTask(task);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}