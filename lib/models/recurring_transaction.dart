import 'transaction.dart';

enum RecurrenceFrequency { weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String title;
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;
  final String? merchant;
  final List<String> tags;
  final bool isEcommerce;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;

  const RecurringTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.merchant,
    this.tags = const [],
    required this.isEcommerce,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
    required this.createdAt,
  });
}
