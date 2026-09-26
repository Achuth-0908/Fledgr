import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// ---------------- ACCOUNTS ----------------
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get typeId => text()(); // cash | bank | savings
  RealColumn get openingBalance => real()();
  RealColumn get balance => real()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get archived =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// ---------------- TRANSACTIONS ----------------
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // income | expense | transfer
  RealColumn get amount => real()();
  TextColumn get title => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get fromAccountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('cleared'))();
  BoolColumn get isEcommerce =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-editable income and expense categories. Icons are persisted as their
/// Material icon code points so the database stays platform independent.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income | expense
  IntColumn get iconCodePoint => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get amount => real()();
  TextColumn get monthKey => text()(); // yyyy-MM
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // income | expense | transfer
  RealColumn get amount => real()();
  TextColumn get title => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get fromAccountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get tags => text().nullable()();
  BoolColumn get isEcommerce => boolean().withDefault(const Constant(false))();
  TextColumn get frequency => text()(); // weekly | monthly | yearly
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ---------------- DATABASE ----------------
@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    Categories,
    Budgets,
    Goals,
    GoalContributions,
    RecurringTransactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'finance_app',
            web: DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
            ),
          ),
        );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.merchant);
            await m.addColumn(transactions, transactions.tags);
            await m.addColumn(transactions, transactions.status);
            await m.createTable(categories);
            await m.createTable(budgets);
            await m.createTable(goals);
            await m.createTable(goalContributions);
            await m.createTable(recurringTransactions);
          }
        },
      );
}
