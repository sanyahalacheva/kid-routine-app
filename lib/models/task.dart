class Task {
  String id;
  String title;
  bool isCompleted;
  String iconKey;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.iconKey = 'star',
  });
}