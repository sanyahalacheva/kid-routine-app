import 'package:flutter/material.dart';

class TaskIconOption {
  final String key;
  final IconData icon;
  final String label;

  const TaskIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class TaskIcons {
  static const List<TaskIconOption> all = [
    TaskIconOption(key: 'star', icon: Icons.star, label: 'Звезда'),
    TaskIconOption(key: 'book', icon: Icons.menu_book, label: 'Книга'),
    TaskIconOption(key: 'tooth', icon: Icons.clean_hands, label: 'Зъби'),
    TaskIconOption(key: 'bed', icon: Icons.bed, label: 'Лягане'),
    TaskIconOption(key: 'breakfast', icon: Icons.breakfast_dining, label: 'Закуска'),
    TaskIconOption(key: 'lunch', icon: Icons.lunch_dining, label: 'Хранене'),
    TaskIconOption(key: 'bath', icon: Icons.bathtub, label: 'Баня'),
    TaskIconOption(key: 'school', icon: Icons.school, label: 'Училище'),
    TaskIconOption(key: 'sports', icon: Icons.sports_soccer, label: 'Спорт'),
    TaskIconOption(key: 'brush', icon: Icons.brush, label: 'Подреждане'),
    TaskIconOption(key: 'checkroom', icon: Icons.checkroom, label: 'Дрехи'),
    TaskIconOption(key: 'toys', icon: Icons.toys, label: 'Играчки'),
    TaskIconOption(key: 'pets', icon: Icons.pets, label: 'Домашен любимец'),
    TaskIconOption(key: 'music', icon: Icons.music_note, label: 'Музика'),
    TaskIconOption(key: 'draw', icon: Icons.palette, label: 'Рисуване'),
    TaskIconOption(key: 'park', icon: Icons.park, label: 'Разходка'),
    TaskIconOption(key: 'home', icon: Icons.home, label: 'У дома'),
    TaskIconOption(key: 'tv', icon: Icons.tv, label: 'Телевизия'),
    TaskIconOption(key: 'favorite', icon: Icons.favorite, label: 'Любимо'),
    TaskIconOption(key: 'task', icon: Icons.task_alt, label: 'Задача'),
  ];

  static IconData getIcon(String key) {
    for (final item in all) {
      if (item.key == key) return item.icon;
    }
    return Icons.star;
  }

  static String getLabel(String key) {
    for (final item in all) {
      if (item.key == key) return item.label;
    }
    return 'Икона';
  }
}