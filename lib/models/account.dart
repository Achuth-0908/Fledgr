import 'package:flutter/material.dart';
import '../models/account_category.dart';

class Account {
  final String id;
  final String name;
  final AccountCategory type; 
  final double openingBalance;
  final DateTime createdAt;
  final bool archived;
  final IconData icon;

  double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.openingBalance,
    required this.createdAt,
    this.archived = false,   // <-- DEFAULT ALWAYS
    this.icon = Icons.account_balance_wallet,
  });

  Account copyWith({
    String? name,
    AccountCategory? type,
    double? balance,
    bool? archived,
    IconData? icon,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      openingBalance: openingBalance,
      createdAt: createdAt,
      archived: archived ?? this.archived,
      icon: icon ?? this.icon,
    );
  }
}
