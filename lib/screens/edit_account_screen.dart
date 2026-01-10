import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/account_category.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class EditAccountScreen extends StatefulWidget {
  final Account account;

  const EditAccountScreen({super.key, required this.account});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late AccountCategory selectedCategory;

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.account.name);

    // existing account category
    selectedCategory = widget.account.type;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final data = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Edit Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // -------- NAME --------
              const SectionTitle("Account Name"),
              AppCard(
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Account name",
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Required" : null,
                ),
              ),

              const SizedBox(height: 20),

              // -------- TYPE --------
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

              const SizedBox(height: 24),

              // -------- SAVE BUTTON --------
              AppCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      "Save Changes",
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Provider.of<DataService>(context, listen: false).editAccount(
      id: widget.account.id,
      name: nameCtrl.text.trim(),
      type: selectedCategory,
    );

    Navigator.pop(context);
  }
}
