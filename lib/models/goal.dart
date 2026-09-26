class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final bool completed;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
    required this.completed,
    required this.createdAt,
  });

  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);
  double get progress => targetAmount == 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
}
