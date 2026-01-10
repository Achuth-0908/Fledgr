enum TransactionType { expense, income, transfer }

class FinanceTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String title;          // NEW
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;
  final DateTime date;
  final bool isEcommerce;

  FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,      // NEW
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    required this.date,
    this.isEcommerce = false,
  });
}
