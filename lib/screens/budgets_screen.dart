import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final progress = data.budgetProgressForMonth(_month);
    final total = data.totalBudgetForMonth(_month);
    final spent = data.totalBudgetSpentForMonth(_month);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [IconButton(onPressed: _pickMonth, icon: const Icon(Icons.calendar_month))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(DateFormat('MMMM y').format(_month)),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Planned ${_money(total)}'),
                const SizedBox(height: 6),
                Text('Spent ${_money(spent)}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: total == 0 ? 0 : (spent / total).clamp(0, 1)),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'Add a category budget to get started.'
                      : spent > total
                          ? '${_money(spent - total)} over budget'
                          : '${_money(total - spent)} remaining',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Category budgets'),
          if (progress.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('No budgets for this month yet')),
            ),
          ...progress.map((item) => _BudgetTile(progress: item, month: _month)),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choose any date in the budget month',
    );
    if (selected != null) setState(() => _month = DateTime(selected.year, selected.month));
  }

  Future<void> _showBudgetEditor(BuildContext context, {Budget? budget}) async {
    final data = context.read<DataService>();
    final controller = TextEditingController(text: budget?.amount.toStringAsFixed(0) ?? '');
    String? categoryId = budget?.categoryId;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(budget == null ? 'Set a budget' : 'Edit budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Expense category'),
                items: data.categories
                    .where((category) => category.type == 'expense')
                    .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                    .toList(),
                onChanged: budget == null ? (value) => setState(() => categoryId = value) : null,
              ),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: '₹ '),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  if (categoryId == null) throw const FinanceValidationException('Choose an expense category.');
                  await data.saveBudget(
                    categoryId: categoryId!,
                    amount: double.tryParse(controller.text) ?? 0,
                    month: _month,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on FinanceValidationException catch (error) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetProgress progress;
  final DateTime month;
  const _BudgetTile({required this.progress, required this.month});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final category = data.categoryById(progress.budget.categoryId);
    final theme = Theme.of(context);
    final over = progress.isOverBudget;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: ListTile(
          leading: Icon(category?.icon ?? Icons.category),
          title: Text(category?.name ?? 'Archived category'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_money(progress.spent)} of ${_money(progress.budget.amount)}'),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: progress.percentage.clamp(0, 1),
                color: over ? theme.colorScheme.error : null,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'delete') {
                await data.deleteBudget(progress.budget.id);
              } else if (context.mounted) {
                await (context.findAncestorStateOfType<_BudgetsScreenState>())
                    ?._showBudgetEditor(context, budget: progress.budget);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) => '₹${value.toStringAsFixed(0)}';
