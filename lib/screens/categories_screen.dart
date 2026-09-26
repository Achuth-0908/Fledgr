import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final income = data.categories.where((item) => item.type == 'income').toList();
    final expenses = data.categories.where((item) => item.type == 'expense').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Income categories'),
          ...income.map((item) => _CategoryTile(category: item)),
          const SizedBox(height: 20),
          const SectionTitle('Expense categories'),
          ...expenses.map((item) => _CategoryTile(category: item)),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  static Future<void> _showEditor(BuildContext context, {Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'expense';
    var icon = category?.icon ?? Icons.category;
    const icons = [
      Icons.category,
      Icons.restaurant,
      Icons.shopping_bag,
      Icons.home,
      Icons.directions_car,
      Icons.local_hospital,
      Icons.school,
      Icons.movie,
      Icons.work,
      Icons.savings,
      Icons.attach_money,
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'New category' : 'Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (category == null)
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (value) => setState(() => type = value!),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  children: icons
                      .map(
                        (candidate) => IconButton(
                          tooltip: 'Choose icon',
                          isSelected: candidate.codePoint == icon.codePoint,
                          onPressed: () => setState(() => icon = candidate),
                          icon: Icon(candidate),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final data = dialogContext.read<DataService>();
                  if (category == null) {
                    await data.addCategory(name: nameController.text, type: type, icon: icon);
                  } else {
                    await data.editCategory(id: category.id, name: nameController.text, icon: icon);
                  }
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
    nameController.dispose();
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: ListTile(
            leading: Icon(category.icon),
            title: Text(category.name),
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  await CategoriesScreen._showEditor(context, category: category);
                } else {
                  await context.read<DataService>().archiveCategory(category.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'archive', child: Text('Archive')),
              ],
            ),
          ),
        ),
      );
}
