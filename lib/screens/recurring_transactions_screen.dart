import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final items = data.recurringTransactions.toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Bills & recurring income')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.dueRecurring.isNotEmpty) ...[
            const SectionTitle('Due now'),
            ...data.dueRecurring.map((item) => _RecurringTile(item: item, due: true)),
            const SizedBox(height: 16),
          ],
          const SectionTitle('All schedules'),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Schedule salary, rent, bills, or subscriptions.')),
            ),
          ...items.map((item) => _RecurringTile(item: item)),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  static Future<void> _showEditor(BuildContext context) async {
    final data = context.read<DataService>();
    final title = TextEditingController();
    final amount = TextEditingController();
    var type = TransactionType.expense;
    String? accountId;
    String? categoryId;
    var frequency = RecurrenceFrequency.monthly;
    var dueDate = DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) {
          final matchingCategories = data.categories.where(
            (category) => category.type == (type == TransactionType.expense ? 'expense' : 'income'),
          );
          return AlertDialog(
            title: const Text('New recurring item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TransactionType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: TransactionType.expense, child: Text('Expense / bill')),
                      DropdownMenuItem(value: TransactionType.income, child: Text('Income / salary')),
                    ],
                    onChanged: (value) => setState(() {
                      type = value!;
                      categoryId = null;
                    }),
                  ),
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                  ),
                  DropdownButtonFormField<String>(
                    value: accountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: data.accounts
                        .map((account) => DropdownMenuItem(value: account.id, child: Text(account.name)))
                        .toList(),
                    onChanged: (value) => setState(() => accountId = value),
                  ),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: matchingCategories
                        .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                        .toList(),
                    onChanged: (value) => setState(() => categoryId = value),
                  ),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Repeats'),
                    items: RecurrenceFrequency.values
                        .map((value) => DropdownMenuItem(value: value, child: Text(value.name)))
                        .toList(),
                    onChanged: (value) => setState(() => frequency = value!),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('First due date'),
                    subtitle: Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final value = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (value != null) setState(() => dueDate = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    await data.addRecurringTransaction(
                      type: type,
                      amount: double.tryParse(amount.text) ?? 0,
                      title: title.text,
                      accountId: accountId,
                      categoryId: categoryId,
                      frequency: frequency,
                      nextDueDate: dueDate,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } on FinanceValidationException catch (error) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                },
                child: const Text('Schedule'),
              ),
            ],
          );
        },
      ),
    );
    title.dispose();
    amount.dispose();
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransaction item;
  final bool due;
  const _RecurringTile({required this.item, this.due = false});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final category = data.categoryById(item.categoryId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: ListTile(
          enabled: item.isActive,
          leading: Icon(item.type == TransactionType.income ? Icons.south : Icons.north),
          title: Text(item.title),
          subtitle: Text(
            '${category?.name ?? 'Transfer'} · ${item.frequency.name} · next ${item.nextDueDate.day}/${item.nextDueDate.month}/${item.nextDueDate.year}',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'record') {
                try {
                  await data.recordRecurringTransaction(item.id);
                } on FinanceValidationException catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                }
              } else if (action == 'toggle') {
                await data.setRecurringActive(item.id, !item.isActive);
              } else {
                await data.deleteRecurringTransaction(item.id);
              }
            },
            itemBuilder: (_) => [
              if (due) const PopupMenuItem(value: 'record', child: Text('Record now')),
              PopupMenuItem(value: 'toggle', child: Text(item.isActive ? 'Pause' : 'Resume')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}
