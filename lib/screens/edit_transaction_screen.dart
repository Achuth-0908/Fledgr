import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class EditTransactionScreen extends StatefulWidget {
  final FinanceTransaction tx;

  const EditTransactionScreen({super.key, required this.tx});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TransactionType selectedType;
  late double amount;
  late String title;
  bool isEcommerce = false;

  String? accountId;
  String? toAccountId;
  String? categoryId;
  String? note;
  late DateTime date;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final tx = widget.tx;

    selectedType = tx.type;
    amount = tx.amount;
    _amountController.text = tx.amount.toString();

    title = tx.title;
    _titleController.text = tx.title;

    isEcommerce = tx.isEcommerce;

    accountId = tx.accountId;
    toAccountId = tx.toAccountId;
    categoryId = tx.categoryId;

    note = tx.note;
    _noteController.text = tx.note ?? "";

    date = tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Edit Transaction"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // TYPE SELECTOR
              const SectionTitle("Transaction Type"),

              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      label: "Expense",
                      icon: Icons.arrow_upward,
                      type: TransactionType.expense,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTypeCard(
                      label: "Income",
                      icon: Icons.arrow_downward,
                      type: TransactionType.income,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTypeCard(
                      label: "Transfer",
                      icon: Icons.swap_horiz,
                      type: TransactionType.transfer,
                      colors: colors,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TITLE
              const SectionTitle("Title"),
              AppCard(
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter a title" : null,
                  onChanged: (v) => title = v,
                ),
              ),

              const SizedBox(height: 20),

              // AMOUNT
              const SectionTitle("Amount"),
              AppCard(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: "₹ ",
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter amount" : null,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0,
                ),
              ),

              const SizedBox(height: 20),

              // ACCOUNT
              SectionTitle(
                selectedType == TransactionType.transfer
                    ? "From Account"
                    : "Account",
              ),
              AppCard(
                child: DropdownButtonFormField<String>(
                  value: accountId,
                  hint: const Text("Select account"),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: data.accounts
                      .map((a) =>
                          DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (v) => setState(() => accountId = v),
                  validator: (v) =>
                      v == null ? "Select account" : null,
                ),
              ),

              const SizedBox(height: 20),

              // TO ACCOUNT
              if (selectedType == TransactionType.transfer) ...[
                const SectionTitle("To Account"),
                AppCard(
                  child: DropdownButtonFormField<String>(
                    value: toAccountId,
                    hint: const Text("Select destination"),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: data.accounts
                        .where((a) => a.id != accountId)
                        .map((a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)))
                        .toList(),
                    onChanged: (v) => setState(() => toAccountId = v),
                    validator: (v) =>
                        v == null ? "Select destination" : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CATEGORY
              if (selectedType != TransactionType.transfer) ...[
                const SectionTitle("Category"),
                AppCard(
                  child: DropdownButtonFormField<String>(
                    value: categoryId,
                    hint: const Text("Select category"),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: data.categories
                        .where((c) =>
                            c.type ==
                            (selectedType == TransactionType.expense
                                ? "expense"
                                : "income"))
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(c.icon,
                                      size: 22,
                                      color: colors.inversePrimary),
                                  const SizedBox(width: 10),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                    validator: (v) =>
                        v == null ? "Select category" : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // E-COMMERCE
              AppCard(
                child: SwitchListTile(
                  title: const Text("Online Purchase"),
                  value: isEcommerce,
                  onChanged: (v) => setState(() => isEcommerce = v),
                  activeThumbColor: Theme.of(context).colorScheme.inversePrimary,
                  tileColor: Colors.transparent,
                ),
              ),

              // DATE
              const SectionTitle("Date"),
              AppCard(
                child: ListTile(
                  title: Text(
                      "${date.day}/${date.month}/${date.year}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // NOTE
              const SectionTitle("Note (Optional)"),
              AppCard(
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Add a note...",
                  ),
                  onChanged: (v) => note = v,
                ),
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON
              AppCard(
                child: InkWell(
                  onTap: _saveChanges,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  // TYPE CARD
  Widget _buildTypeCard({
    required String label,
    required IconData icon,
    required TransactionType type,
    required ColorScheme colors,
  }) {
    final selected = selectedType == type;

    return GestureDetector(
      onTap: () => setState(() {
        selectedType = type;
        if (type != TransactionType.transfer) toAccountId = null;
        if (type == TransactionType.transfer) categoryId = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colors.inversePrimary : colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? colors.primary : colors.inversePrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: selected ? colors.primary : colors.inversePrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Insufficient Balance"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // SAVE
  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final data = Provider.of<DataService>(context, listen: false);

    final oldTx = widget.tx;

    // ============ EXPENSE CHECK ============
    if (selectedType == TransactionType.expense) {
      final acc = data.allAccounts.firstWhere((a) => a.id == accountId);

      final available = acc.balance + oldTx.amount;

      if (available < amount) {
        _showError(
            "This account has only ₹${available.toStringAsFixed(2)} available.");
        return;
      }
    }

    // ============ TRANSFER CHECK ============
    if (selectedType == TransactionType.transfer) {
      final from = data.allAccounts.firstWhere((a) => a.id == accountId);

      final oldTransferAmount =
          oldTx.type == TransactionType.transfer ? oldTx.amount : 0;

      final available = from.balance + oldTransferAmount;

      if (available < amount) {
        _showError(
            "Source account has only ₹${available.toStringAsFixed(2)} available.");
        return;
      }
    }

    final updated = FinanceTransaction(
      id: widget.tx.id,
      type: selectedType,
      amount: amount,
      title: title,
      isEcommerce: isEcommerce,
      accountId: accountId,
      toAccountId: toAccountId,
      fromAccountId:
          selectedType == TransactionType.transfer ? accountId : null,
      categoryId: categoryId,
      note: note,
      date: date,
    );

    data.editTransaction(widget.tx.id, updated);

    Navigator.pop(context);
  }
}
