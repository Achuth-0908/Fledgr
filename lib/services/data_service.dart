import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart' as db;
import '../models/account.dart' as app_models;
import '../models/account_category.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';

class FinanceValidationException implements Exception {
  final String message;
  const FinanceValidationException(this.message);

  @override
  String toString() => message;
}

/// The application's local-only finance store. Drift writes to the device's
/// private app directory; this service never sends financial data to a server.
class DataService with ChangeNotifier {
  final uuid = const Uuid();
  db.AppDatabase _db;
  bool _isLoading = true;

  DataService(this._db) {
    _loadData();
  }

  db.AppDatabase get database => _db;
  bool get isLoading => _isLoading;

  void attachDb(db.AppDatabase newDb) {
    _db.close();
    _db = newDb;
  }

  final accountCategories = const [
    AccountCategory(id: 'cash', name: 'Cash', icon: Icons.money),
    AccountCategory(id: 'bank', name: 'Bank', icon: Icons.account_balance),
    AccountCategory(id: 'savings', name: 'Savings', icon: Icons.savings),
    AccountCategory(id: 'wallet', name: 'Wallet / UPI', icon: Icons.account_balance_wallet),
    AccountCategory(id: 'credit', name: 'Credit Card', icon: Icons.credit_card),
    AccountCategory(id: 'loan', name: 'Loan / Liability', icon: Icons.request_quote),
    AccountCategory(id: 'investment', name: 'Investment', icon: Icons.trending_up),
  ];

  static final List<Category> _defaultCategories = [
    Category(id: 'c1', name: 'Salary', type: 'income', icon: Icons.work),
    Category(id: 'c2', name: 'Bonus / Other Income', type: 'income', icon: Icons.attach_money),
    Category(id: 'c3', name: 'Interest', type: 'income', icon: Icons.savings),
    Category(id: 'c4', name: 'Food', type: 'expense', icon: Icons.restaurant),
    Category(id: 'c5', name: 'Groceries', type: 'expense', icon: Icons.local_grocery_store),
    Category(id: 'c6', name: 'Shopping', type: 'expense', icon: Icons.shopping_bag),
    Category(id: 'c7', name: 'Travel', type: 'expense', icon: Icons.flight_takeoff),
    Category(id: 'c8', name: 'Entertainment', type: 'expense', icon: Icons.movie),
    Category(id: 'c9', name: 'Subscriptions', type: 'expense', icon: Icons.subscriptions),
    Category(id: 'c10', name: 'Rent', type: 'expense', icon: Icons.home),
    Category(id: 'c11', name: 'Bills & Utilities', type: 'expense', icon: Icons.lightbulb),
    Category(id: 'c12', name: 'Medical', type: 'expense', icon: Icons.medical_services),
    Category(id: 'c13', name: 'Fitness', type: 'expense', icon: Icons.fitness_center),
    Category(id: 'c14', name: 'Education', type: 'expense', icon: Icons.school),
    Category(id: 'c15', name: 'Miscellaneous', type: 'expense', icon: Icons.category),
  ];

  final List<app_models.Account> _accounts = [];
  final List<Category> _categories = [];
  final List<FinanceTransaction> _transactions = [];
  final List<Budget> _budgets = [];
  final List<Goal> _goals = [];
  final List<RecurringTransaction> _recurringTransactions = [];

  List<app_models.Account> get allAccounts => List.unmodifiable(_accounts);
  List<app_models.Account> get accounts =>
      List.unmodifiable(_accounts.where((account) => !account.archived));
  List<Category> get allCategories => List.unmodifiable(_categories);
  List<Category> get categories =>
      List.unmodifiable(_categories.where((category) => !category.archived));
  List<FinanceTransaction> get transactions {
    final result = List<FinanceTransaction>.from(_transactions);
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<FinanceTransaction> get recentFive => transactions.take(5).toList();
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<RecurringTransaction> get recurringTransactions =>
      List.unmodifiable(_recurringTransactions);

  List<RecurringTransaction> get dueRecurring {
    final today = _startOfDay(DateTime.now());
    return _recurringTransactions
        .where((item) => item.isActive && !item.nextDueDate.isAfter(today))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  app_models.Account? accountById(String? id) {
    if (id == null) return null;
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    await _loadAccounts();
    await _loadCategories();
    await _loadTransactions();
    await _loadBudgets();
    await _loadGoals();
    await _loadRecurringTransactions();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAccounts() async {
    final rows = await _db.select(_db.accounts).get();
    _accounts
      ..clear()
      ..addAll(rows.map((row) {
        final type = accountCategories.firstWhere(
          (item) => item.id == row.typeId,
          orElse: () => accountCategories.first,
        );
        return app_models.Account(
          id: row.id,
          name: row.name,
          type: type,
          icon: type.icon,
          balance: row.balance,
          openingBalance: row.openingBalance,
          createdAt: row.createdAt,
          archived: row.archived,
        );
      }));
  }

  Future<void> _loadCategories() async {
    var rows = await _db.select(_db.categories).get();
    if (rows.isEmpty) {
      final now = DateTime.now();
      await _db.batch((batch) {
        batch.insertAll(
          _db.categories,
          _defaultCategories
              .map(
                (category) => db.CategoriesCompanion.insert(
                  id: category.id,
                  name: category.name,
                  type: category.type,
                  iconCodePoint: category.icon.codePoint,
                  createdAt: now,
                ),
              )
              .toList(),
        );
      });
      rows = await _db.select(_db.categories).get();
    }
    _categories
      ..clear()
      ..addAll(rows.map(_categoryFromRow));
  }

  Category _categoryFromRow(db.Category row) => Category(
        id: row.id,
        name: row.name,
        type: row.type,
        icon: IconData(row.iconCodePoint, fontFamily: 'MaterialIcons'),
        archived: row.archived,
      );

  Future<void> _loadTransactions() async {
    final rows = await _db.select(_db.transactions).get();
    _transactions
      ..clear()
      ..addAll(rows.map(_transactionFromRow));
  }

  FinanceTransaction _transactionFromRow(db.Transaction row) => FinanceTransaction(
        id: row.id,
        type: _transactionTypeFromString(row.type),
        amount: row.amount,
        title: row.title,
        accountId: row.accountId,
        fromAccountId: row.fromAccountId,
        toAccountId: row.toAccountId,
        categoryId: row.categoryId,
        note: row.note,
        merchant: row.merchant,
        tags: _tagsFromString(row.tags),
        status: _statusFromString(row.status),
        isEcommerce: row.isEcommerce,
        date: row.date,
      );

  Future<void> _loadBudgets() async {
    final rows = await _db.select(_db.budgets).get();
    _budgets
      ..clear()
      ..addAll(rows.map(
        (row) => Budget(
          id: row.id,
          categoryId: row.categoryId,
          amount: row.amount,
          monthKey: row.monthKey,
          createdAt: row.createdAt,
        ),
      ));
  }

  Future<void> _loadGoals() async {
    final rows = await _db.select(_db.goals).get();
    _goals
      ..clear()
      ..addAll(rows.map(
        (row) => Goal(
          id: row.id,
          name: row.name,
          targetAmount: row.targetAmount,
          savedAmount: row.savedAmount,
          targetDate: row.targetDate,
          completed: row.completed,
          createdAt: row.createdAt,
        ),
      ));
  }

  Future<void> _loadRecurringTransactions() async {
    final rows = await _db.select(_db.recurringTransactions).get();
    _recurringTransactions
      ..clear()
      ..addAll(rows.map(
        (row) => RecurringTransaction(
          id: row.id,
          type: _transactionTypeFromString(row.type),
          amount: row.amount,
          title: row.title,
          accountId: row.accountId,
          fromAccountId: row.fromAccountId,
          toAccountId: row.toAccountId,
          categoryId: row.categoryId,
          note: row.note,
          merchant: row.merchant,
          tags: _tagsFromString(row.tags),
          isEcommerce: row.isEcommerce,
          frequency: _frequencyFromString(row.frequency),
          nextDueDate: row.nextDueDate,
          isActive: row.isActive,
          createdAt: row.createdAt,
        ),
      ));
  }

  // ---------- Dashboard totals ----------
  bool _countsInReports(FinanceTransaction transaction) =>
      transaction.status == TransactionStatus.cleared;

  double get totalIncome => _transactions
      .where((item) => item.type == TransactionType.income && _countsInReports(item))
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((item) => item.type == TransactionType.expense && _countsInReports(item))
      .fold(0, (sum, item) => sum + item.amount);

  double get totalNetWorth =>
      _accounts.where((account) => !account.archived).fold(0, (sum, item) => sum + item.balance);

  double get currentMonthIncome => _amountForMonth(TransactionType.income, DateTime.now());
  double get currentMonthExpense => _amountForMonth(TransactionType.expense, DateTime.now());
  double get currentMonthCashFlow => currentMonthIncome - currentMonthExpense;

  double _amountForMonth(TransactionType type, DateTime date) => _transactions
      .where(
        (item) =>
            item.type == type &&
            _countsInReports(item) &&
            _monthKey(item.date) == _monthKey(date),
      )
      .fold(0, (sum, item) => sum + item.amount);

  double get totalSavings {
    final savingsIds = _accounts
        .where((account) => account.type.id == 'savings')
        .map((account) => account.id)
        .toSet();
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.transfer &&
              _countsInReports(item) &&
              savingsIds.contains(item.toAccountId),
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  String monthKeyFor(DateTime date) => _monthKey(date);
  String _monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);
  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<String, double> get monthlyIncome => _monthlyTotals(TransactionType.income);
  Map<String, double> get monthlyExpense => _monthlyTotals(TransactionType.expense);

  Map<String, double> _monthlyTotals(TransactionType type) {
    final totals = <String, double>{};
    for (final item in _transactions) {
      if (item.type != type || !_countsInReports(item)) continue;
      final key = _monthKey(item.date);
      totals[key] = (totals[key] ?? 0) + item.amount;
    }
    return totals;
  }

  Map<String, double> get monthlySavings {
    final result = <String, double>{};
    final savingsIds = _accounts
        .where((account) => account.type.id == 'savings')
        .map((account) => account.id)
        .toSet();
    for (final item in _transactions) {
      if (item.type != TransactionType.transfer ||
          !_countsInReports(item) ||
          !savingsIds.contains(item.toAccountId)) {
        continue;
      }
      final key = _monthKey(item.date);
      result[key] = (result[key] ?? 0) + item.amount;
    }
    return result;
  }

  Map<String, double> expenseByCategoryForMonth(DateTime month) {
    final result = <String, double>{};
    for (final item in _transactions) {
      if (item.type != TransactionType.expense ||
          !_countsInReports(item) ||
          item.categoryId == null ||
          _monthKey(item.date) != _monthKey(month)) {
        continue;
      }
      result[item.categoryId!] = (result[item.categoryId!] ?? 0) + item.amount;
    }
    return result;
  }

  // ---------- Accounts ----------
  Future<void> addAccount({
    required String name,
    required AccountCategory type,
    required double openingBalance,
    required IconData icon,
  }) async {
    _validateName(name, 'Account name');
    _validateAmount(openingBalance, allowNegative: type.id == 'credit' || type.id == 'loan');
    final id = uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.accounts).insert(
          db.AccountsCompanion.insert(
            id: id,
            name: name.trim(),
            typeId: type.id,
            openingBalance: openingBalance,
            balance: openingBalance,
            createdAt: now,
          ),
        );
    _accounts.add(app_models.Account(
      id: id,
      name: name.trim(),
      type: type,
      icon: icon,
      balance: openingBalance,
      openingBalance: openingBalance,
      createdAt: now,
    ));
    notifyListeners();
  }

  Future<void> editAccount({
    required String id,
    required String name,
    required AccountCategory type,
  }) async {
    _validateName(name, 'Account name');
    final index = _accounts.indexWhere((account) => account.id == id);
    if (index < 0) throw const FinanceValidationException('Account was not found.');
    await (_db.update(_db.accounts)..where((account) => account.id.equals(id))).write(
      db.AccountsCompanion(name: drift.Value(name.trim()), typeId: drift.Value(type.id)),
    );
    _accounts[index] = _accounts[index].copyWith(name: name.trim(), type: type);
    notifyListeners();
  }

  Future<bool> archiveAccount(String id) async {
    final index = _accounts.indexWhere((account) => account.id == id);
    if (index < 0 || _accounts[index].balance != 0) return false;
    await (_db.update(_db.accounts)..where((account) => account.id.equals(id))).write(
      const db.AccountsCompanion(archived: drift.Value(true)),
    );
    _accounts[index] = _accounts[index].copyWith(archived: true);
    notifyListeners();
    return true;
  }

  // ---------- Categories ----------
  Future<void> addCategory({
    required String name,
    required String type,
    required IconData icon,
  }) async {
    _validateName(name, 'Category name');
    if (type != 'income' && type != 'expense') {
      throw const FinanceValidationException('Choose income or expense for the category.');
    }
    final exists = _categories.any(
      (item) => item.type == type && item.name.toLowerCase() == name.trim().toLowerCase(),
    );
    if (exists) throw const FinanceValidationException('A category with that name already exists.');
    final id = uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.categories).insert(db.CategoriesCompanion.insert(
          id: id,
          name: name.trim(),
          type: type,
          iconCodePoint: icon.codePoint,
          createdAt: now,
        ));
    _categories.add(Category(id: id, name: name.trim(), type: type, icon: icon));
    notifyListeners();
  }

  Future<void> editCategory({
    required String id,
    required String name,
    required IconData icon,
  }) async {
    _validateName(name, 'Category name');
    final index = _categories.indexWhere((item) => item.id == id);
    if (index < 0) throw const FinanceValidationException('Category was not found.');
    final category = _categories[index];
    await (_db.update(_db.categories)..where((row) => row.id.equals(id))).write(
      db.CategoriesCompanion(name: drift.Value(name.trim()), iconCodePoint: drift.Value(icon.codePoint)),
    );
    _categories[index] = Category(
      id: category.id,
      name: name.trim(),
      type: category.type,
      icon: icon,
      archived: category.archived,
    );
    notifyListeners();
  }

  Future<void> archiveCategory(String id) async {
    final index = _categories.indexWhere((item) => item.id == id);
    if (index < 0) return;
    await (_db.update(_db.categories)..where((row) => row.id.equals(id))).write(
      const db.CategoriesCompanion(archived: drift.Value(true)),
    );
    final category = _categories[index];
    _categories[index] = Category(
      id: category.id,
      name: category.name,
      type: category.type,
      icon: category.icon,
      archived: true,
    );
    notifyListeners();
  }

  // ---------- Budgets ----------
  List<BudgetProgress> budgetProgressForMonth(DateTime month) {
    final key = _monthKey(month);
    final expenses = expenseByCategoryForMonth(month);
    final results = _budgets
        .where((budget) => budget.monthKey == key)
        .map((budget) => BudgetProgress(budget: budget, spent: expenses[budget.categoryId] ?? 0))
        .toList();
    results.sort((a, b) => b.percentage.compareTo(a.percentage));
    return results;
  }

  double totalBudgetForMonth(DateTime month) => _budgets
      .where((item) => item.monthKey == _monthKey(month))
      .fold(0, (sum, item) => sum + item.amount);

  double totalBudgetSpentForMonth(DateTime month) =>
      budgetProgressForMonth(month).fold(0, (sum, item) => sum + item.spent);

  Future<void> saveBudget({
    required String categoryId,
    required double amount,
    required DateTime month,
  }) async {
    _validateAmount(amount);
    final category = categoryById(categoryId);
    if (category == null || category.type != 'expense') {
      throw const FinanceValidationException('Choose an expense category.');
    }
    final key = _monthKey(month);
    final index = _budgets.indexWhere(
      (item) => item.categoryId == categoryId && item.monthKey == key,
    );
    if (index >= 0) {
      final old = _budgets[index];
      await (_db.update(_db.budgets)..where((row) => row.id.equals(old.id))).write(
        db.BudgetsCompanion(amount: drift.Value(amount)),
      );
      _budgets[index] = Budget(
        id: old.id,
        categoryId: old.categoryId,
        amount: amount,
        monthKey: old.monthKey,
        createdAt: old.createdAt,
      );
    } else {
      final budget = Budget(
        id: uuid.v4(),
        categoryId: categoryId,
        amount: amount,
        monthKey: key,
        createdAt: DateTime.now(),
      );
      await _db.into(_db.budgets).insert(db.BudgetsCompanion.insert(
            id: budget.id,
            categoryId: budget.categoryId,
            amount: budget.amount,
            monthKey: budget.monthKey,
            createdAt: budget.createdAt,
          ));
      _budgets.add(budget);
    }
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgets)..where((row) => row.id.equals(id))).go();
    _budgets.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // ---------- Goals ----------
  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    _validateName(name, 'Goal name');
    _validateAmount(targetAmount);
    final goal = Goal(
      id: uuid.v4(),
      name: name.trim(),
      targetAmount: targetAmount,
      savedAmount: 0,
      targetDate: targetDate,
      completed: false,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.goals).insert(db.GoalsCompanion.insert(
          id: goal.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          targetDate: drift.Value(goal.targetDate),
          createdAt: goal.createdAt,
        ));
    _goals.add(goal);
    notifyListeners();
  }

  Future<void> contributeToGoal({
    required String goalId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    _validateAmount(amount);
    final index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index < 0) throw const FinanceValidationException('Goal was not found.');
    final oldGoal = _goals[index];
    final newSaved = oldGoal.savedAmount + amount;
    final completed = newSaved >= oldGoal.targetAmount;
    final contributionDate = date ?? DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.goalContributions).insert(db.GoalContributionsCompanion.insert(
            id: uuid.v4(),
            goalId: goalId,
            amount: amount,
            note: drift.Value(_nullableTrim(note)),
            date: contributionDate,
          ));
      await (_db.update(_db.goals)..where((row) => row.id.equals(goalId))).write(
        db.GoalsCompanion(
          savedAmount: drift.Value(newSaved),
          completed: drift.Value(completed),
        ),
      );
    });
    _goals[index] = Goal(
      id: oldGoal.id,
      name: oldGoal.name,
      targetAmount: oldGoal.targetAmount,
      savedAmount: newSaved,
      targetDate: oldGoal.targetDate,
      completed: completed,
      createdAt: oldGoal.createdAt,
    );
    notifyListeners();
  }

  Future<void> archiveGoal(String id) async {
    await (_db.update(_db.goals)..where((row) => row.id.equals(id))).write(
      const db.GoalsCompanion(completed: drift.Value(true)),
    );
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index >= 0) {
      final goal = _goals[index];
      _goals[index] = Goal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        savedAmount: goal.savedAmount,
        targetDate: goal.targetDate,
        completed: true,
        createdAt: goal.createdAt,
      );
      notifyListeners();
    }
  }

  // ---------- Recurring transactions ----------
  Future<void> addRecurringTransaction({
    required TransactionType type,
    required double amount,
    required String title,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
    String? note,
    String? merchant,
    List<String> tags = const [],
    bool isEcommerce = false,
    required RecurrenceFrequency frequency,
    required DateTime nextDueDate,
  }) async {
    _validateTransactionInput(
      type: type,
      amount: amount,
      title: title,
      accountId: accountId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
    );
    final recurring = RecurringTransaction(
      id: uuid.v4(),
      type: type,
      amount: amount,
      title: title.trim(),
      accountId: accountId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: _nullableTrim(note),
      merchant: _nullableTrim(merchant),
      tags: _normaliseTags(tags),
      isEcommerce: isEcommerce,
      frequency: frequency,
      nextDueDate: _startOfDay(nextDueDate),
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.recurringTransactions).insert(_recurringCompanion(recurring));
    _recurringTransactions.add(recurring);
    notifyListeners();
  }

  Future<void> recordRecurringTransaction(String id) async {
    final index = _recurringTransactions.indexWhere((item) => item.id == id);
    if (index < 0) throw const FinanceValidationException('Scheduled transaction was not found.');
    final item = _recurringTransactions[index];
    if (!item.isActive) throw const FinanceValidationException('This schedule is paused.');
    final occurrenceDate = item.nextDueDate;
    if (item.type == TransactionType.expense) {
      await addExpense(
        amount: item.amount,
        accountId: item.accountId!,
        categoryId: item.categoryId!,
        title: item.title,
        note: item.note,
        merchant: item.merchant,
        tags: item.tags,
        isEcommerce: item.isEcommerce,
        date: occurrenceDate,
      );
    } else if (item.type == TransactionType.income) {
      await addIncome(
        amount: item.amount,
        accountId: item.accountId!,
        categoryId: item.categoryId!,
        title: item.title,
        note: item.note,
        merchant: item.merchant,
        tags: item.tags,
        isEcommerce: item.isEcommerce,
        date: occurrenceDate,
      );
    } else {
      await addTransfer(
        amount: item.amount,
        fromAccountId: item.fromAccountId!,
        toAccountId: item.toAccountId!,
        title: item.title,
        note: item.note,
        merchant: item.merchant,
        tags: item.tags,
        isEcommerce: item.isEcommerce,
        date: occurrenceDate,
      );
    }
    final updated = RecurringTransaction(
      id: item.id,
      type: item.type,
      amount: item.amount,
      title: item.title,
      accountId: item.accountId,
      fromAccountId: item.fromAccountId,
      toAccountId: item.toAccountId,
      categoryId: item.categoryId,
      note: item.note,
      merchant: item.merchant,
      tags: item.tags,
      isEcommerce: item.isEcommerce,
      frequency: item.frequency,
      nextDueDate: _advanceDate(item.nextDueDate, item.frequency),
      isActive: item.isActive,
      createdAt: item.createdAt,
    );
    await (_db.update(_db.recurringTransactions)..where((row) => row.id.equals(id))).write(
      db.RecurringTransactionsCompanion(nextDueDate: drift.Value(updated.nextDueDate)),
    );
    _recurringTransactions[index] = updated;
    notifyListeners();
  }

  Future<void> setRecurringActive(String id, bool active) async {
    final index = _recurringTransactions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    await (_db.update(_db.recurringTransactions)..where((row) => row.id.equals(id))).write(
      db.RecurringTransactionsCompanion(isActive: drift.Value(active)),
    );
    final item = _recurringTransactions[index];
    _recurringTransactions[index] = RecurringTransaction(
      id: item.id,
      type: item.type,
      amount: item.amount,
      title: item.title,
      accountId: item.accountId,
      fromAccountId: item.fromAccountId,
      toAccountId: item.toAccountId,
      categoryId: item.categoryId,
      note: item.note,
      merchant: item.merchant,
      tags: item.tags,
      isEcommerce: item.isEcommerce,
      frequency: item.frequency,
      nextDueDate: item.nextDueDate,
      isActive: active,
      createdAt: item.createdAt,
    );
    notifyListeners();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await (_db.delete(_db.recurringTransactions)..where((row) => row.id.equals(id))).go();
    _recurringTransactions.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // ---------- Ledger ----------
  Future<void> addExpense({
    required double amount,
    required String accountId,
    required String categoryId,
    required String title,
    required bool isEcommerce,
    String? note,
    String? merchant,
    List<String> tags = const [],
    TransactionStatus status = TransactionStatus.cleared,
    required DateTime date,
  }) => _addTransaction(FinanceTransaction(
        id: uuid.v4(),
        type: TransactionType.expense,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        title: title.trim(),
        note: _nullableTrim(note),
        merchant: _nullableTrim(merchant),
        tags: _normaliseTags(tags),
        status: status,
        date: date,
        isEcommerce: isEcommerce,
      ));

  Future<void> addIncome({
    required double amount,
    required String accountId,
    required String categoryId,
    required String title,
    required bool isEcommerce,
    String? note,
    String? merchant,
    List<String> tags = const [],
    TransactionStatus status = TransactionStatus.cleared,
    required DateTime date,
  }) => _addTransaction(FinanceTransaction(
        id: uuid.v4(),
        type: TransactionType.income,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        title: title.trim(),
        note: _nullableTrim(note),
        merchant: _nullableTrim(merchant),
        tags: _normaliseTags(tags),
        status: status,
        date: date,
        isEcommerce: isEcommerce,
      ));

  Future<void> addTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required String title,
    required bool isEcommerce,
    String? note,
    String? merchant,
    List<String> tags = const [],
    TransactionStatus status = TransactionStatus.cleared,
    required DateTime date,
  }) => _addTransaction(FinanceTransaction(
        id: uuid.v4(),
        type: TransactionType.transfer,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        title: title.trim(),
        note: _nullableTrim(note),
        merchant: _nullableTrim(merchant),
        tags: _normaliseTags(tags),
        status: status,
        date: date,
        isEcommerce: isEcommerce,
      ));

  Future<void> _addTransaction(FinanceTransaction transaction) async {
    _validateTransaction(transaction);
    _ensureSufficientBalance(transaction);
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(_transactionCompanion(transaction));
      if (_affectsBalance(transaction)) await _writeBalanceChanges(transaction, applying: true);
    });
    if (_affectsBalance(transaction)) _applyTransaction(transaction);
    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> editTransaction(String id, FinanceTransaction updated) async {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index < 0) throw const FinanceValidationException('Transaction was not found.');
    final old = _transactions[index];
    final persisted = FinanceTransaction(
      id: id,
      type: updated.type,
      amount: updated.amount,
      title: updated.title.trim(),
      accountId: updated.accountId,
      fromAccountId: updated.fromAccountId,
      toAccountId: updated.toAccountId,
      categoryId: updated.categoryId,
      note: _nullableTrim(updated.note),
      merchant: _nullableTrim(updated.merchant),
      tags: _normaliseTags(updated.tags),
      status: updated.status,
      date: updated.date,
      isEcommerce: updated.isEcommerce,
    );
    _validateTransaction(persisted);
    _ensureSufficientBalance(persisted, replacing: old);
    await _db.transaction(() async {
      if (_affectsBalance(old)) await _writeBalanceChanges(old, applying: false);
      if (_affectsBalance(persisted)) await _writeBalanceChanges(persisted, applying: true);
      await (_db.update(_db.transactions)..where((row) => row.id.equals(id))).write(
        _transactionCompanion(persisted),
      );
    });
    if (_affectsBalance(old)) _rollbackTransaction(old);
    if (_affectsBalance(persisted)) _applyTransaction(persisted);
    _transactions[index] = persisted;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final transaction = _transactions[index];
    await _db.transaction(() async {
      if (_affectsBalance(transaction)) await _writeBalanceChanges(transaction, applying: false);
      await (_db.delete(_db.transactions)..where((row) => row.id.equals(id))).go();
    });
    if (_affectsBalance(transaction)) _rollbackTransaction(transaction);
    _transactions.removeAt(index);
    notifyListeners();
  }

  Future<void> restoreTransaction(FinanceTransaction transaction) async {
    _validateTransaction(transaction);
    _ensureSufficientBalance(transaction);
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(_transactionCompanion(transaction));
      if (_affectsBalance(transaction)) await _writeBalanceChanges(transaction, applying: true);
    });
    if (_affectsBalance(transaction)) _applyTransaction(transaction);
    _transactions.add(transaction);
    notifyListeners();
  }

  bool _affectsBalance(FinanceTransaction transaction) =>
      transaction.status == TransactionStatus.cleared;

  Future<void> _writeBalanceChanges(FinanceTransaction transaction, {required bool applying}) async {
    final multiplier = applying ? 1 : -1;
    if (transaction.type == TransactionType.expense) {
      await _changeStoredBalance(transaction.accountId!, -transaction.amount * multiplier);
    } else if (transaction.type == TransactionType.income) {
      await _changeStoredBalance(transaction.accountId!, transaction.amount * multiplier);
    } else {
      await _changeStoredBalance(transaction.fromAccountId!, -transaction.amount * multiplier);
      await _changeStoredBalance(transaction.toAccountId!, transaction.amount * multiplier);
    }
  }

  Future<void> _changeStoredBalance(String accountId, double change) async {
    final account = accountById(accountId);
    if (account == null) throw const FinanceValidationException('Account was not found.');
    await (_db.update(_db.accounts)..where((row) => row.id.equals(accountId))).write(
      db.AccountsCompanion(balance: drift.Value(account.balance + change)),
    );
  }

  void _applyTransaction(FinanceTransaction transaction) {
    if (transaction.type == TransactionType.expense) {
      accountById(transaction.accountId)!.balance -= transaction.amount;
    } else if (transaction.type == TransactionType.income) {
      accountById(transaction.accountId)!.balance += transaction.amount;
    } else {
      accountById(transaction.fromAccountId)!.balance -= transaction.amount;
      accountById(transaction.toAccountId)!.balance += transaction.amount;
    }
  }

  void _rollbackTransaction(FinanceTransaction transaction) {
    if (transaction.type == TransactionType.expense) {
      accountById(transaction.accountId)!.balance += transaction.amount;
    } else if (transaction.type == TransactionType.income) {
      accountById(transaction.accountId)!.balance -= transaction.amount;
    } else {
      accountById(transaction.fromAccountId)!.balance += transaction.amount;
      accountById(transaction.toAccountId)!.balance -= transaction.amount;
    }
  }

  void _ensureSufficientBalance(FinanceTransaction transaction, {FinanceTransaction? replacing}) {
    if (!_affectsBalance(transaction)) return;
    final simulated = <String, double>{
      for (final account in _accounts) account.id: account.balance,
    };
    if (replacing != null && _affectsBalance(replacing)) {
      _applyToBalanceMap(simulated, replacing, applying: false);
    }
    _applyToBalanceMap(simulated, transaction, applying: true);
    for (final entry in simulated.entries) {
      final account = accountById(entry.key)!;
      if (entry.value < 0 && account.type.id != 'credit' && account.type.id != 'loan') {
        throw FinanceValidationException('${account.name} does not have enough available balance.');
      }
    }
  }

  void _applyToBalanceMap(
    Map<String, double> balances,
    FinanceTransaction transaction, {
    required bool applying,
  }) {
    final factor = applying ? 1 : -1;
    if (transaction.type == TransactionType.expense) {
      balances[transaction.accountId!] = balances[transaction.accountId!]! - transaction.amount * factor;
    } else if (transaction.type == TransactionType.income) {
      balances[transaction.accountId!] = balances[transaction.accountId!]! + transaction.amount * factor;
    } else {
      balances[transaction.fromAccountId!] = balances[transaction.fromAccountId!]! - transaction.amount * factor;
      balances[transaction.toAccountId!] = balances[transaction.toAccountId!]! + transaction.amount * factor;
    }
  }

  db.TransactionsCompanion _transactionCompanion(FinanceTransaction item) =>
      db.TransactionsCompanion(
        id: drift.Value(item.id),
        type: drift.Value(_transactionTypeToString(item.type)),
        amount: drift.Value(item.amount),
        title: drift.Value(item.title),
        accountId: drift.Value(item.accountId),
        fromAccountId: drift.Value(item.fromAccountId),
        toAccountId: drift.Value(item.toAccountId),
        categoryId: drift.Value(item.categoryId),
        note: drift.Value(item.note),
        merchant: drift.Value(item.merchant),
        tags: drift.Value(_tagsToString(item.tags)),
        status: drift.Value(_statusToString(item.status)),
        isEcommerce: drift.Value(item.isEcommerce),
        date: drift.Value(item.date),
      );

  db.RecurringTransactionsCompanion _recurringCompanion(RecurringTransaction item) =>
      db.RecurringTransactionsCompanion.insert(
        id: item.id,
        type: _transactionTypeToString(item.type),
        amount: item.amount,
        title: item.title,
        accountId: drift.Value(item.accountId),
        fromAccountId: drift.Value(item.fromAccountId),
        toAccountId: drift.Value(item.toAccountId),
        categoryId: drift.Value(item.categoryId),
        note: drift.Value(item.note),
        merchant: drift.Value(item.merchant),
        tags: drift.Value(_tagsToString(item.tags)),
        isEcommerce: drift.Value(item.isEcommerce),
        frequency: _frequencyToString(item.frequency),
        nextDueDate: item.nextDueDate,
        isActive: drift.Value(item.isActive),
        createdAt: item.createdAt,
      );

  void _validateTransaction(FinanceTransaction transaction) => _validateTransactionInput(
        type: transaction.type,
        amount: transaction.amount,
        title: transaction.title,
        accountId: transaction.accountId,
        fromAccountId: transaction.fromAccountId,
        toAccountId: transaction.toAccountId,
        categoryId: transaction.categoryId,
      );

  void _validateTransactionInput({
    required TransactionType type,
    required double amount,
    required String title,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
  }) {
    _validateAmount(amount);
    _validateName(title, 'Title');
    if (type == TransactionType.transfer) {
      if (accountById(fromAccountId) == null || accountById(toAccountId) == null) {
        throw const FinanceValidationException('Choose both transfer accounts.');
      }
      if (fromAccountId == toAccountId) {
        throw const FinanceValidationException('Choose two different accounts for a transfer.');
      }
    } else {
      if (accountById(accountId) == null) {
        throw const FinanceValidationException('Choose an account.');
      }
      final category = categoryById(categoryId);
      final expectedType = type == TransactionType.expense ? 'expense' : 'income';
      if (category == null || category.type != expectedType) {
        throw const FinanceValidationException('Choose a matching category.');
      }
    }
  }

  void _validateAmount(double value, {bool allowNegative = false}) {
    if (!value.isFinite || (!allowNegative && value <= 0)) {
      throw const FinanceValidationException('Enter an amount greater than zero.');
    }
  }

  void _validateName(String value, String label) {
    if (value.trim().isEmpty) throw FinanceValidationException('$label is required.');
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> _normaliseTags(List<String> tags) => tags
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
  List<String> _tagsFromString(String? value) => value == null || value.isEmpty
      ? const []
      : _normaliseTags(value.split(','));
  String? _tagsToString(List<String> tags) {
    final normalised = _normaliseTags(tags);
    return normalised.isEmpty ? null : normalised.join(',');
  }

  TransactionType _transactionTypeFromString(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  String _transactionTypeToString(TransactionType type) => type.name;
  TransactionStatus _statusFromString(String value) =>
      value == 'pending' ? TransactionStatus.pending : TransactionStatus.cleared;
  String _statusToString(TransactionStatus status) => status.name;
  RecurrenceFrequency _frequencyFromString(String value) =>
      RecurrenceFrequency.values.firstWhere(
        (item) => item.name == value,
        orElse: () => RecurrenceFrequency.monthly,
      );
  String _frequencyToString(RecurrenceFrequency frequency) => frequency.name;

  DateTime _advanceDate(DateTime date, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurrenceFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }

  Future<void> reload() async => _loadData();
}
