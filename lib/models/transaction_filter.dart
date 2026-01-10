import '../models/transaction.dart';
import 'package:flutter/material.dart';


class TransactionFilter {
  DateTimeRange? dateRange;
  String? accountId;
  String? categoryId;
  TransactionType? type;
  String search = "";

  TransactionFilter({
    this.dateRange,
    this.accountId,
    this.categoryId,
    this.type,
    this.search = "",
  });

  void clear() {
    dateRange = null;
    accountId = null;
    categoryId = null;
    type = null;
    search = "";
  }

  bool get isActive =>
      dateRange != null ||
      accountId != null ||
      categoryId != null ||
      type != null ||
      search.isNotEmpty;
}
