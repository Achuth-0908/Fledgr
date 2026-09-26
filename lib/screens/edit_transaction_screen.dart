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
  String? merchant;
  late List<String> tags;
  late TransactionStatus status;
  late DateTime date;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _merchantController = TextEditingController();
  final _tagsController = TextEditingController();

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

    accountId = tx.accountId ?? tx.fromAccountId;
    toAccountId = tx.toAccountId;
    categoryId = tx.categoryId;

    note = tx.note;
    _noteController.text = tx.note ?? "";
    merchant = tx.merchant;
    _merchantController.text = tx.merchant ?? "";
    tags = tx.tags;
    _tagsController.text = tx.tags.join(', ');
    status = tx.status;

    date = tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    _tagsController.dispose();
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

              const SectionTitle("Merchant / Payee (Optional)"),
              AppCard(
                child: TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "e.g. Swiggy, Employer",
                  ),
                  onChanged: (value) => merchant = value,
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
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    return parsed == null || !parsed.isFinite || parsed <= 0
                        ? "Enter an amount greater than zero"
                        : null;
                  },
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

              if (selectedType != TransactionType.transfer) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: SwitchListTile(
                    title: const Text("Pending transaction"),
                    subtitle: const Text("Does not affect your account balance yet"),
                    value: status == TransactionStatus.pending,
                    onChanged: (value) => setState(() {
                      status = value ? TransactionStatus.pending : TransactionStatus.cleared;
                    }),
                  ),
                ),
              ],

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

              const SizedBox(height: 20),
              const SectionTitle("Tags (Optional)"),
              AppCard(
                child: TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "work, essential, tax",
                  ),
                  onChanged: (value) => tags = value.split(','),
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
  Future<void> _saveChanges() async {
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
      merchant: merchant,
      tags: tags,
      status: selectedType == TransactionType.transfer
          ? TransactionStatus.cleared
          : status,
      date: date,
    );

    try {
      await data.editTransaction(widget.tx.id, updated);
      if (mounted) Navigator.pop(context);
    } on FinanceValidationException catch (error) {
      if (mounted) _showError(error.message);
    }
  }
}
