import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String type;   // "income" or "expense"
  final IconData icon; // <-- Material Icon

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });
}
