import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../models/transaction.dart';
import '../models/transaction_filter.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/section_title.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionFilter filter = TransactionFilter();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    final all = data.transactions;

    final filtered = all.where((t) {
      if (filter.type != null && t.type != filter.type) return false;

      if (filter.accountId != null) {
        if (t.type == TransactionType.transfer) {
          if (t.fromAccountId != filter.accountId &&
              t.toAccountId != filter.accountId) return false;
        } else if (t.accountId != filter.accountId) return false;
      }

      if (filter.categoryId != null &&
          t.categoryId != filter.categoryId) return false;

      if (filter.dateRange != null &&
          (t.date.isBefore(filter.dateRange!.start) ||
              t.date.isAfter(filter.dateRange!.end))) return false;

      if (filter.search.isNotEmpty &&
          ![
            t.title,
            t.note ?? '',
            t.merchant ?? '',
            t.tags.join(' '),
          ].join(' ').toLowerCase().contains(filter.search.toLowerCase())) return false;

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Transactions"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (filter.isActive) _buildActiveFilters(colors),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("No transactions found"))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final tx = filtered[i];

                        final currentYear = tx.date.year;
                        final previousYear =
                            i == 0 ? null : filtered[i - 1].date.year;

                        final showYearHeader =
                            currentYear != previousYear;

                        final currentMonth =
                            "${tx.date.month}-${tx.date.year}";
                        final previousMonth =
                            i == 0
                                ? null
                                : "${filtered[i - 1].date.month}-${filtered[i - 1].date.year}";

                        final showMonthHeader =
                            currentMonth != previousMonth;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showYearHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 4),
                                child: Text(
                                  currentYear.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            if (showMonthHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 6, bottom: 4),
                                child: Text(
                                  "${_monthName(tx.date.month)} ${tx.date.year}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            TransactionTile(tx: tx),
                            SizedBox(height: 8,)
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- MONTH NAME ----------
  String _monthName(int m) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[m - 1];
  }

  // ---------- ACTIVE FILTER CHIPS ----------
  Widget _buildActiveFilters(ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (filter.dateRange != null)
          FilterChip(
            label: const Text("Date"),
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => filter.dateRange = null),
          ),
        if (filter.accountId != null)
          FilterChip(
            label: const Text("Account"),
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => filter.accountId = null),
          ),
        if (filter.categoryId != null)
          FilterChip(
            label: const Text("Category"),
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => filter.categoryId = null),
          ),
        if (filter.type != null)
          FilterChip(
            label: Text(filter.type!.name),
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => filter.type = null),
          ),
        if (filter.search.isNotEmpty)
          FilterChip(
            label: const Text("Search"),
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => filter.search = ""),
          ),
        TextButton(
          onPressed: () => setState(() => filter.clear()),
          child: const Text("Clear All"),
        )
      ],
    );
  }

  // ---------- FILTER UI ----------
  void _openFilters() {
    final data = Provider.of<DataService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          shrinkWrap: true,
          children: [
            const SectionTitle("Filter Transactions"),
            const SizedBox(height: 10),

            DropdownButtonFormField<TransactionType?>(
              value: filter.type,
              decoration: const InputDecoration(labelText: "Type"),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("All"),
                ),
                ...TransactionType.values.map(
                  (t) =>
                      DropdownMenuItem(value: t, child: Text(t.name)),
                )
              ],
              onChanged: (v) => setState(() => filter.type = v),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String?>(
              value: filter.accountId,
              decoration: const InputDecoration(labelText: "Account"),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("All"),
                ),
                ...data.allAccounts.map(
                  (a) =>
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                )
              ],
              onChanged: (v) => setState(() => filter.accountId = v),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String?>(
              value: filter.categoryId,
              decoration: const InputDecoration(labelText: "Category"),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("All"),
                ),
                ...data.categories.map(
                  (c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                )
              ],
              onChanged: (v) => setState(() => filter.categoryId = v),
            ),

            const SizedBox(height: 10),

            ListTile(
              title: const Text("Date Range"),
              subtitle: Text(
                filter.dateRange == null
                    ? "All time"
                    : "${filter.dateRange!.start.day}/${filter.dateRange!.start.month}"
                      " → "
                      "${filter.dateRange!.end.day}/${filter.dateRange!.end.month}",
              ),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => filter.dateRange = picked);
                }
              },
            ),

            const SizedBox(height: 10),

            TextField(
              decoration:
                  const InputDecoration(labelText: "Search title, payee, note, or tag"),
              onChanged: (v) => setState(() => filter.search = v),
            ),
          ],
        ),
      ),
    );
  }
}
