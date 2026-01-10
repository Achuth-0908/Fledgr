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
  BoolColumn get isEcommerce =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ---------------- DATABASE ----------------
@DriftDatabase(
  tables: [Accounts, Transactions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'finance_app.db', // REQUIRED
          ),
        );

  @override
  int get schemaVersion => 1;
}
