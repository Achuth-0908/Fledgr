class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final String monthKey;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.monthKey,
    required this.createdAt,
  });
}

class BudgetProgress {
  final Budget budget;
  final double spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get remaining => budget.amount - spent;
  double get percentage => budget.amount == 0 ? 0 : spent / budget.amount;
  bool get isOverBudget => spent > budget.amount;
}
