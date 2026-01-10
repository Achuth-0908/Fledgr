import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../models/account.dart' as app_models;
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/account_category.dart';
import '../db/app_database.dart' as db;

class DataService with ChangeNotifier {
  final uuid = const Uuid();
  db.AppDatabase _db;


  DataService(this._db) {
    _loadData();
  }

  // expose db safely
  db.AppDatabase get database => _db;

  void attachDb(db.AppDatabase newDb) {
    _db.close();
    _db = newDb;
  }

  final accountCategories = [
    AccountCategory(
      id: "cash",
      name: "Cash",
      icon: Icons.money,
    ),
    AccountCategory(
      id: "bank",
      name: "Bank",
      icon: Icons.account_balance,
    ),
    AccountCategory(
      id: "savings",
      name: "Savings",
      icon: Icons.savings,
    ),
  ];

  // ----------------- ACCOUNTS -----------------
  final List<app_models.Account> _accounts = [];

  List<app_models.Account> get allAccounts => _accounts;

  List<app_models.Account> get accounts =>
      _accounts.where((a) => (a.archived == false)).toList();

  // ----------------- CATEGORIES -----------------
  final List<Category> _categories = [
    // ================= INCOME =================
    Category(
      id: "c1",
      name: "Salary",
      type: "income",
      icon: Icons.work,
    ),
    Category(
      id: "c2",
      name: "Bonus / Other Income",
      type: "income",
      icon: Icons.attach_money,
    ),
    Category(
      id: "c3",
      name: "Interest",
      type: "income",
      icon: Icons.savings,
    ),

    // ================= EXPENSES =================
    Category(
      id: "c4",
      name: "Food",
      type: "expense",
      icon: Icons.restaurant,
    ),
    Category(
      id: "c5",
      name: "Groceries",
      type: "expense",
      icon: Icons.local_grocery_store,
    ),
    Category(
      id: "c6",
      name: "Shopping",
      type: "expense",
      icon: Icons.shopping_bag,
    ),
    Category(
      id: "c7",
      name: "Travel",
      type: "expense",
      icon: Icons.flight_takeoff,
    ),
    Category(
      id: "c8",
      name: "Entertainment",
      type: "expense",
      icon: Icons.movie,
    ),
    Category(
      id: "c9",
      name: "Subscriptions",
      type: "expense",
      icon: Icons.subscriptions,
    ),
    Category(
      id: "c10",
      name: "Rent",
      type: "expense",
      icon: Icons.home,
    ),
    Category(
      id: "c11",
      name: "Bills & Utilities",
      type: "expense",
      icon: Icons.lightbulb,
    ),
    Category(
      id: "c12",
      name: "Medical",
      type: "expense",
      icon: Icons.medical_services,
    ),
    Category(
      id: "c13",
      name: "Fitness",
      type: "expense",
      icon: Icons.fitness_center,
    ),
    Category(
      id: "c14",
      name: "Education",
      type: "expense",
      icon: Icons.school,
    ),
    Category(
      id: "c15",
      name: "Miscellaneous",
      type: "expense",
      icon: Icons.category,
    ),
  ];

  List<Category> get categories => _categories;

  // ----------------- TRANSACTIONS -----------------
  final List<FinanceTransaction> _transactions = [];

  /// newest first list
  List<FinanceTransaction> get transactions =>
      _transactions.reversed.toList();

  /// last 5 newest transactions
  List<FinanceTransaction> get recentFive =>
      _transactions.reversed.take(5).toList();

  // ----------------- DATA LOADING -----------------
  Future<void> _loadData() async {
    await _loadAccounts();
    await _loadTransactions();
    notifyListeners();
  }

  Future<void> _loadAccounts() async {
    final accountRows = await _db.select(_db.accounts).get();
    _accounts.clear();
    
    for (final row in accountRows) {
      final accountType = accountCategories.firstWhere(
        (ac) => ac.id == row.typeId,
        orElse: () => accountCategories.first,
      );
      
      // Convert Drift's Account to your app's Account model
      _accounts.add(app_models.Account(
        id: row.id,
        name: row.name,
        type: accountType,
        icon: accountType.icon,
        balance: row.balance,
        openingBalance: row.openingBalance,
        createdAt: row.createdAt,
        archived: row.archived,
      ));
    }
  }

  Future<void> _loadTransactions() async {
    final txRows = await _db.select(_db.transactions).get();
    _transactions.clear();
    
    for (final row in txRows) {
      TransactionType type;
      switch (row.type) {
        case 'income':
          type = TransactionType.income;
          break;
        case 'expense':
          type = TransactionType.expense;
          break;
        case 'transfer':
          type = TransactionType.transfer;
          break;
        default:
          type = TransactionType.expense;
      }
      
      _transactions.add(FinanceTransaction(
        id: row.id,
        type: type,
        amount: row.amount,
        title: row.title,
        accountId: row.accountId,
        fromAccountId: row.fromAccountId,
        toAccountId: row.toAccountId,
        categoryId: row.categoryId,
        note: row.note,
        isEcommerce: row.isEcommerce,
        date: row.date,
      ));
    }
  }

  // ----------------- TOTALS -----------------

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalNetWorth => _accounts.fold(0, (sum, a) => sum + a.balance);

  double get totalSavings {
    final savingsIds =
        _accounts.where((a) => a.type.id == "savings").map((a) => a.id).toList();

    return _transactions
        .where((t) =>
            t.type == TransactionType.transfer &&
            t.toAccountId != null &&
            savingsIds.contains(t.toAccountId))
        .fold(0, (sum, t) => sum + t.amount);
  }

  // ----------------- ACCOUNT MANAGEMENT -----------------

  Future<void> addAccount({
    required String name,
    required AccountCategory type,
    required double openingBalance,
    required IconData icon,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.accounts).insert(
          db.AccountsCompanion.insert(
            id: id,
            name: name,
            typeId: type.id,
            openingBalance: openingBalance,
            balance: openingBalance,
            createdAt: now,
          ),
        );

    final acc = app_models.Account(
      id: id,
      name: name,
      type: type,
      icon: icon,
      balance: openingBalance,
      openingBalance: openingBalance,
      createdAt: now,
    );

    _accounts.add(acc);
    notifyListeners();
  }

  Future<void> editAccount({
    required String id,
    required String name,
    required AccountCategory type,
  }) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;

    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      db.AccountsCompanion(
        name: drift.Value(name),
        typeId: drift.Value(type.id),
      ),
    );

    _accounts[index] = _accounts[index].copyWith(
      name: name,
      type: type,
    );

    notifyListeners();
  }

  Future<bool> archiveAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index == -1) return false;

    if (_accounts[index].balance != 0) return false;

    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      const db.AccountsCompanion(
        archived: drift.Value(true),
      ),
    );

    _accounts[index] = _accounts[index].copyWith(
      archived: true,
    );

    notifyListeners();
    return true;
  }

  // ----------------- GROUPED VIEW -----------------
  /// Month -> Date -> List<FinanceTransaction>
  Map<String, Map<String, List<FinanceTransaction>>> get groupedTransactions {
    final Map<String, Map<String, List<FinanceTransaction>>> result = {};

    for (final tx in _transactions) {
      final monthKey = DateFormat('MMMM yyyy').format(tx.date);
      final dateKey = DateFormat('dd MMM').format(tx.date);

      result.putIfAbsent(monthKey, () => {});
      result[monthKey]!.putIfAbsent(dateKey, () => []);
      result[monthKey]![dateKey]!.add(tx);
    }

    return result;
  }

  Future<void> _updateAccountBalance(String accountId, double newBalance) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(db.AccountsCompanion(balance: drift.Value(newBalance)));
  }

  void _applyTransaction(FinanceTransaction tx) {
    if (tx.type == TransactionType.expense) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      account.balance -= tx.amount;
    }

    if (tx.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      account.balance += tx.amount;
    }

    if (tx.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == tx.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == tx.toAccountId);
      from.balance -= tx.amount;
      to.balance += tx.amount;
    }
  }

  void _rollbackTransaction(FinanceTransaction tx) {
    if (tx.type == TransactionType.expense) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      account.balance += tx.amount;
    }

    if (tx.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      account.balance -= tx.amount;
    }

    if (tx.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == tx.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == tx.toAccountId);
      from.balance += tx.amount;
      to.balance -= tx.amount;
    }
  }

  // ---------- MONTH HELPERS ----------
  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  // ---------- INCOME & EXPENSE PER MONTH ----------
  Map<String, double> get monthlyIncome {
    final Map<String, double> result = {};
    for (final t in _transactions) {
      if (t.type != TransactionType.income) continue;
      final key = _monthKey(t.date);
      result[key] = (result[key] ?? 0) + t.amount;
    }
    return result;
  }

  Map<String, double> get monthlyExpense {
    final Map<String, double> result = {};
    for (final t in _transactions) {
      if (t.type != TransactionType.expense) continue;
      final key = _monthKey(t.date);
      result[key] = (result[key] ?? 0) + t.amount;
    }
    return result;
  }

  // ---------- SAVINGS PER MONTH ----------
  Map<String, double> get monthlySavings {
    final Map<String, double> result = {};

    final savingsIds =
        _accounts.where((a) => a.type.id == "savings").map((a) => a.id).toList();

    for (final t in _transactions) {
      if (t.type == TransactionType.transfer &&
          t.toAccountId != null &&
          savingsIds.contains(t.toAccountId)) {
        final key = _monthKey(t.date);
        result[key] = (result[key] ?? 0) + t.amount;
      }
    }
    return result;
  }

  // ---------- CATEGORY TOTALS (EXPENSE ONLY) ----------
  Map<String, double> expenseByCategoryForMonth(DateTime month) {
    final Map<String, double> result = {};
    final key = DateFormat('yyyy-MM').format(month);

    for (final t in _transactions) {
      if (t.type != TransactionType.expense) continue;
      if (_monthKey(t.date) != key) continue;

      final cat = t.categoryId!;
      result[cat] = (result[cat] ?? 0) + t.amount;
    }

    return result;
  }

  // ----------------- TRANSACTION ADDERS -----------------

  Future<void> addExpense({
    required double amount,
    required String accountId,
    required String categoryId,
    required String title,
    required bool isEcommerce,
    String? note,
    required DateTime date,
  }) async {
    final id = uuid.v4();

    await _db.into(_db.transactions).insert(
          db.TransactionsCompanion.insert(
            id: id,
            type: 'expense',
            amount: amount,
            title: title,
            accountId: drift.Value(accountId),
            categoryId: drift.Value(categoryId),
            note: drift.Value(note),
            isEcommerce: drift.Value(isEcommerce),
            date: date,
          ),
        );

    final account = _accounts.firstWhere((a) => a.id == accountId);
    account.balance -= amount;
    await _updateAccountBalance(accountId, account.balance);

    _transactions.add(
      FinanceTransaction(
        id: id,
        type: TransactionType.expense,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        title: title,
        note: note,
        date: date,
        isEcommerce: isEcommerce,
      ),
    );

    notifyListeners();
  }

  Future<void> addIncome({
    required double amount,
    required String accountId,
    required String categoryId,
    required String title,
    required bool isEcommerce,
    String? note,
    required DateTime date,
  }) async {
    final id = uuid.v4();

    await _db.into(_db.transactions).insert(
          db.TransactionsCompanion.insert(
            id: id,
            type: 'income',
            amount: amount,
            title: title,
            accountId: drift.Value(accountId),
            categoryId: drift.Value(categoryId),
            note: drift.Value(note),
            isEcommerce: drift.Value(isEcommerce),
            date: date,
          ),
        );

    final account = _accounts.firstWhere((a) => a.id == accountId);
    account.balance += amount;
    await _updateAccountBalance(accountId, account.balance);

    _transactions.add(
      FinanceTransaction(
        id: id,
        type: TransactionType.income,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        title: title,
        note: note,
        date: date,
        isEcommerce: isEcommerce,
      ),
    );

    notifyListeners();
  }

  Future<void> addTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required String title,
    required bool isEcommerce,
    String? note,
    required DateTime date,
  }) async {
    final id = uuid.v4();

    await _db.into(_db.transactions).insert(
          db.TransactionsCompanion.insert(
            id: id,
            type: 'transfer',
            amount: amount,
            title: title,
            fromAccountId: drift.Value(fromAccountId),
            toAccountId: drift.Value(toAccountId),
            note: drift.Value(note),
            isEcommerce: drift.Value(isEcommerce),
            date: date,
          ),
        );

    final from = _accounts.firstWhere((a) => a.id == fromAccountId);
    final to = _accounts.firstWhere((a) => a.id == toAccountId);

    from.balance -= amount;
    to.balance += amount;

    await _updateAccountBalance(fromAccountId, from.balance);
    await _updateAccountBalance(toAccountId, to.balance);

    _transactions.add(
      FinanceTransaction(
        id: id,
        type: TransactionType.transfer,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        title: title,
        note: note,
        date: date,
        isEcommerce: isEcommerce,
      ),
    );

    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);

    _rollbackTransaction(tx);

    // Update account balances in database
    if (tx.type == TransactionType.expense || tx.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      await _updateAccountBalance(tx.accountId!, account.balance);
    } else if (tx.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == tx.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == tx.toAccountId);
      await _updateAccountBalance(tx.fromAccountId!, from.balance);
      await _updateAccountBalance(tx.toAccountId!, to.balance);
    }

    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

    _transactions.removeWhere((t) => t.id == id);

    notifyListeners();
  }

  Future<void> editTransaction(String id, FinanceTransaction updated) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    final oldTx = _transactions[index];

    // rollback old transaction effects
    _rollbackTransaction(oldTx);

    // apply new transaction effects
    _applyTransaction(updated);

    // update in database
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      db.TransactionsCompanion(
        type: drift.Value(updated.type == TransactionType.income
            ? 'income'
            : updated.type == TransactionType.expense
                ? 'expense'
                : 'transfer'),
        amount: drift.Value(updated.amount),
        title: drift.Value(updated.title),
        accountId: drift.Value(updated.accountId),
        fromAccountId: drift.Value(updated.fromAccountId),
        toAccountId: drift.Value(updated.toAccountId),
        categoryId: drift.Value(updated.categoryId),
        note: drift.Value(updated.note),
        isEcommerce: drift.Value(updated.isEcommerce),
        date: drift.Value(updated.date),
      ),
    );

    // Update account balances in database
    if (oldTx.type == TransactionType.expense || oldTx.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == oldTx.accountId);
      await _updateAccountBalance(oldTx.accountId!, account.balance);
    } else if (oldTx.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == oldTx.toAccountId);
      await _updateAccountBalance(oldTx.fromAccountId!, from.balance);
      await _updateAccountBalance(oldTx.toAccountId!, to.balance);
    }

    if (updated.type == TransactionType.expense || updated.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == updated.accountId);
      await _updateAccountBalance(updated.accountId!, account.balance);
    } else if (updated.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == updated.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == updated.toAccountId);
      await _updateAccountBalance(updated.fromAccountId!, from.balance);
      await _updateAccountBalance(updated.toAccountId!, to.balance);
    }

    // replace in memory
    _transactions[index] = updated;

    notifyListeners();
  }

  Future<void> restoreTransaction(FinanceTransaction tx) async {
    await _db.into(_db.transactions).insert(
          db.TransactionsCompanion.insert(
            id: tx.id,
            type: tx.type == TransactionType.income
                ? 'income'
                : tx.type == TransactionType.expense
                    ? 'expense'
                    : 'transfer',
            amount: tx.amount,
            title: tx.title,
            accountId: drift.Value(tx.accountId),
            fromAccountId: drift.Value(tx.fromAccountId),
            toAccountId: drift.Value(tx.toAccountId),
            categoryId: drift.Value(tx.categoryId),
            note: drift.Value(tx.note),
            isEcommerce: drift.Value(tx.isEcommerce),
            date: tx.date,
          ),
        );

    _transactions.add(tx);
    _applyTransaction(tx);

    // Update account balances in database
    if (tx.type == TransactionType.expense || tx.type == TransactionType.income) {
      final account = _accounts.firstWhere((a) => a.id == tx.accountId);
      await _updateAccountBalance(tx.accountId!, account.balance);
    } else if (tx.type == TransactionType.transfer) {
      final from = _accounts.firstWhere((a) => a.id == tx.fromAccountId);
      final to = _accounts.firstWhere((a) => a.id == tx.toAccountId);
      await _updateAccountBalance(tx.fromAccountId!, from.balance);
      await _updateAccountBalance(tx.toAccountId!, to.balance);
    }

    notifyListeners();
  }

  Future<void> reload() async {
    _accounts.clear();
    _transactions.clear();
    await _loadData();
    notifyListeners();
  }

}