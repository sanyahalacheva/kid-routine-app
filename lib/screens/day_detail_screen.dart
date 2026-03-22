import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/task.dart';
import '../data/app_data.dart';
import '../services/parent_pin_service.dart';
import '../utils/task_icons.dart';

class DayDetailScreen extends StatefulWidget {
  final String dateKey;

  const DayDetailScreen({
    super.key,
    required this.dateKey,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late List<Task> tasks;
  bool _parentUnlocked = false;

  @override
  void initState() {
    super.initState();
    final data = Provider.of<AppData>(context, listen: false);
    tasks = List<Task>.from(data.tasksByDate[widget.dateKey] ?? []);
  }

  List<Task> get sortedTasks {
    final sorted = List<Task>.from(tasks);

    sorted.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      if (a.isCompleted) return 1;
      return -1;
    });

    return sorted;
  }

  double get completionPercentage {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
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

  Future<void> saveDayTasks() async {
    final data = Provider.of<AppData>(context, listen: false);

    final updatedMap = Map<String, List<Task>>.from(data.tasksByDate);
    updatedMap[widget.dateKey] = tasks;

    data.setTasks(updatedMap);

    final prefs = await SharedPreferences.getInstance();

    final Map<String, List<String>> encodedMap = {};

    updatedMap.forEach((date, taskList) {
      encodedMap[date] = taskList
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
  }

  Future<void> toggleTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    await saveDayTasks();
  }

  Future<void> deleteTask(Task task) async {
    final granted = await ensureParentAccess();
    if (!granted) return;

    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });

    await saveDayTasks();
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

                    await saveDayTasks();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ден: ${widget.dateKey}"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                      "Изпълнение",
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
              const SizedBox(height: 16),
              ...sortedTasks.map((task) {
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
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.black,
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
      ),
    );
  }
}