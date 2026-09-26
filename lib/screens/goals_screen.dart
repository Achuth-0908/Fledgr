import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<DataService>().goals.where((goal) => !goal.completed).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('What are you saving for?'),
          if (goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Create a goal such as an emergency fund or a trip.')),
            ),
          ...goals.map((goal) => _GoalTile(goal: goal)),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  static Future<void> _showGoalEditor(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    DateTime? targetDate;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('New savings goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Goal name')),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₹ '),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target date'),
                subtitle: Text(targetDate == null ? 'Optional' : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final value = await showDatePicker(
                    context: dialogContext,
                    initialDate: targetDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (value != null) setState(() => targetDate = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await dialogContext.read<DataService>().addGoal(
                    name: name.text,
                    targetAmount: double.tryParse(target.text) ?? 0,
                    targetDate: targetDate,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on FinanceValidationException catch (error) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    target.dispose();
  }
}

class _GoalTile extends StatelessWidget {
  final Goal goal;
  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(goal.name),
                subtitle: Text('₹${goal.savedAmount.toStringAsFixed(0)} of ₹${goal.targetAmount.toStringAsFixed(0)}'),
                trailing: Text('${(goal.progress * 100).toStringAsFixed(0)}%'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(value: goal.progress),
              ),
              ButtonBar(
                children: [
                  TextButton.icon(
                    onPressed: () => _showContribution(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add savings'),
                  ),
                  TextButton(
                    onPressed: () => context.read<DataService>().archiveGoal(goal.id),
                    child: const Text('Archive'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _showContribution(BuildContext context) async {
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await dialogContext.read<DataService>().contributeToGoal(
                  goalId: goal.id,
                  amount: double.tryParse(amount.text) ?? 0,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on FinanceValidationException catch (error) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    amount.dispose();
  }
}
