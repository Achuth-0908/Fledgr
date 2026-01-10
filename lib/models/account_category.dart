import 'package:flutter/material.dart';

class AccountCategory {
  final String id;       // e.g. "cash"
  final String name;     // e.g. "Cash"
  final IconData icon;

  const AccountCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}
