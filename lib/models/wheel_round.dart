class WheelRound {
  String startDate;
  int durationDays;
  int requiredPercent;
  List<String> rewards;
  bool isCompleted;
  String? selectedReward;

  WheelRound({
    required this.startDate,
    required this.durationDays,
    required this.requiredPercent,
    required this.rewards,
    this.isCompleted = false,
    this.selectedReward,
  });
}