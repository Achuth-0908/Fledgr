import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import '../models/account_category.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();

  late AccountCategory selectedCategory;

  @override
  void initState() {
    super.initState();

    final data = Provider.of<DataService>(context, listen: false);

    selectedCategory = data.accountCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = Provider.of<DataService>(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Add Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              const SectionTitle("Account Name"),
              AppCard(
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),
              ),

              const SizedBox(height: 20),

              const SectionTitle("Account Type"),
              AppCard(
                child: DropdownButtonFormField<AccountCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: data.accountCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
              ),

              const SizedBox(height: 20),

              const SectionTitle("Opening Balance"),
              AppCard(
                child: TextFormField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: "₹ ",
                  ),
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    return parsed == null || !parsed.isFinite
                        ? 'Enter a valid amount'
                        : null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              AppCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      "Save Account",
                      style: TextStyle(
                        color: colors.inversePrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await Provider.of<DataService>(context, listen: false).addAccount(
        name: nameCtrl.text.trim(),
        type: selectedCategory,
        icon: selectedCategory.icon,
        openingBalance: double.tryParse(balanceCtrl.text) ?? 0,
      );
      if (mounted) Navigator.pop(context);
    } on FinanceValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
