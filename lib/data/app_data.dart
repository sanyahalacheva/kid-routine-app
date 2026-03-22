import 'package:flutter/material.dart';
import '../models/task.dart';

class AppData extends ChangeNotifier {
  Map<String, List<Task>> tasksByDate = {};

  void setTasks(Map<String, List<Task>> data) {
    tasksByDate = data;
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }
}