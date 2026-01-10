import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/data_service.dart';
import '../models/transaction.dart';

import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import '../widgets/category_pie_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool yearly = false;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    // -------- FILTERED TRANSACTIONS --------
    final filtered = data.transactions.where((t) {
      if (yearly) {
        return t.date.year == selectedYear;
      } else {
        return t.date.year == selectedYear &&
            t.date.month == selectedMonth;
      }
    }).toList();

    final income = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    final expense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final net = income - expense;

    final savings = filtered
      .where((t) {
        if (t.type != TransactionType.transfer) return false;
        if (t.toAccountId == null) return false;

        final matches = data.allAccounts.where(
          (a) => a.id == t.toAccountId,
        );

        if (matches.isEmpty) return false;

        return matches.first.type.id == "savings";
      })
      .fold(0.0, (sum, t) => sum + t.amount);

    // -------- CATEGORY TOTALS --------
    final Map<String, double> catTotals = {};
    for (final t in filtered.where((t) => t.type == TransactionType.expense)) {
      catTotals[t.categoryId!] =
          (catTotals[t.categoryId!] ?? 0) + t.amount;
    }

    final sortedCategories = catTotals.entries
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

    // -------- ACCOUNT TOTALS --------
    final Map<String, double> accountTotals = {};
    for (final t in filtered.where((t) => t.type == TransactionType.expense)) {
      if (t.accountId == null) continue;
      accountTotals[t.accountId!] =
          (accountTotals[t.accountId!] ?? 0) + t.amount;
    }

    // -------- ONLINE / OFFLINE --------
    final online = filtered
        .where((t) =>
            t.type == TransactionType.expense && t.isEcommerce == true)
        .fold(0.0, (s, t) => s + t.amount);

    final offline = filtered
        .where((t) =>
            t.type == TransactionType.expense && t.isEcommerce == false)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SectionTitle("Select Period"),
            // ---------------- FILTER BAR ----------------
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ---------- TOGGLE ----------
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text("Month"),
                          selected: !yearly,
                          onSelected: (_) => setState(() => yearly = false),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text("Year"),
                          selected: yearly,
                          onSelected: (_) => setState(() => yearly = true),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ---------- MONTH + YEAR ----------
                    Row(
                      children: [

                        // ---- MONTH (only in month mode) ----
                        if (!yearly)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Month",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                DropdownButton<int>(
                                  value: selectedMonth,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: List.generate(12, (i) {
                                    final m = i + 1;
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        DateFormat('MMMM').format(DateTime(0, m)),
                                      ),
                                    );
                                  }),
                                  onChanged: (v) =>
                                      setState(() => selectedMonth = v!),
                                ),
                              ],
                            ),
                          ),

                        if (!yearly) const SizedBox(width: 12),

                        // ---- YEAR ----
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Year",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),

                              DropdownButton<int>(
                                value: selectedYear,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: List.generate(20, (i) {
                                  final y = DateTime.now().year - 10 + i;
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  );
                                }),
                                onChanged: (v) =>
                                    setState(() => selectedYear = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- SUMMARY ----------------
            const SectionTitle("Summary"),
            _summaryRow("Income", income, colors),
            _summaryRow("Expense", expense, colors),
            _summaryRow("Net", net, colors),
            _summaryRow("Savings (Transfers)", savings, colors),

            const SizedBox(height: 24),

            // ---------------- SPENDING BY ACCOUNT ----------------
            const SectionTitle("Spending by Account"),

            if (accountTotals.isEmpty)
              const Text("No expenses recorded"),

            ...accountTotals.entries.map((e) {
              final acc =
                  data.allAccounts.firstWhere((a) => a.id == e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: ListTile(
                    leading: Icon(acc.icon),
                    title: Text(acc.name),
                    trailing: Text(
                      "₹${e.value.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ---------------- CATEGORY PIE ----------------
            const SectionTitle("Category-wise Spending"),

            if (catTotals.isEmpty)
              const Text("No expenses recorded"),

            if (catTotals.isNotEmpty)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CategoryPieChart(
                    data: catTotals,
                    catNames: {
                      for (var c in data.categories) c.id: c.name,
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 🔵🔵🔵 CATEGORY-WISE AMOUNT LIST (NEW SECTION) 🔵🔵🔵
            const SectionTitle("Category-wise Amount"),
            if (sortedCategories.isEmpty)
              const Text("No expenses recorded"),
            ...sortedCategories.map((e) {
              final cat = data.categories
                  .firstWhere((c) => c.id == e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: ListTile(
                    leading: Icon(cat.icon),
                    title: Text(cat.name),
                    trailing: Text(
                      "₹${e.value.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ---------------- ONLINE / OFFLINE PIE ----------------
            const SectionTitle("Online vs Offline Spending"),
            if (online==0 && offline==0)
              const Text("No expenses recorded"),
            if(online!=0 || offline!=0)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CategoryPieChart(
                    data: {
                      "Online": online,
                      "Offline": offline,
                    },
                    catNames: const {
                      "Online": "Online",
                      "Offline": "Offline",
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              "₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.inversePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
