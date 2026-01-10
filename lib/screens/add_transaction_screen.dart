import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../models/transaction.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType selectedType = TransactionType.expense;
  double amount = 0;
  String? accountId;
  String? toAccountId;
  String? categoryId;
  String title = "";
  String? note;
  DateTime selectedDate = DateTime.now();
  bool isEcommerce = false;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();


  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Add Transaction"),
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
                      context,
                      label: "Expense",
                      icon: Icons.arrow_upward,
                      type: TransactionType.expense,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTypeCard(
                      context,
                      label: "Income",
                      icon: Icons.arrow_downward,
                      type: TransactionType.income,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTypeCard(
                      context,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.inversePrimary,
                  ),
                  decoration: const InputDecoration(
                    prefixText: "₹ ",
                    hintText: "0.00",
                    border: InputBorder.none,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter amount" : null,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0,
                ),
              ),

              const SizedBox(height: 20),

              // ACCOUNT / FROM ACCOUNT
              SectionTitle(
                selectedType == TransactionType.transfer
                    ? "From Account"
                    : "Account",
              ),
              AppCard(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  hint: const Text("Select account"),
                  value: accountId,
                  items: data.accounts.map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(
                            a.icon,
                            size: 22,
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary,
                          ),
                          const SizedBox(width: 10),
                          Text(a.name),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              a.type.name,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                  onChanged: (v) => setState(() => accountId = v),
                  validator: (v) => v == null ? "Select account" : null,
                ),
              ),

              const SizedBox(height: 20),

              // TO ACCOUNT (Transfer only)
              if (selectedType == TransactionType.transfer) ...[
                const SectionTitle("To Account"),
                AppCard(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    hint: const Text("Select destination"),
                    value: toAccountId,
                    items: data.accounts
                        .where((a) => a.id != accountId)
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Row(
                              children: [
                                Icon(
                                  a.icon,
                                  size: 22,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                                const SizedBox(width: 10),
                                Text(a.name),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    a.type.name,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => toAccountId = v),
                    validator: (v) =>
                        v == null ? "Select destination" : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CATEGORY (not for transfer)
              if (selectedType != TransactionType.transfer) ...[
                const SectionTitle("Category"),
                AppCard(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    hint: const Text("Select category"),
                    value: categoryId,
                    items: data.categories
                        .where((c) =>
                            c.type ==
                            (selectedType == TransactionType.expense
                                ? "expense"
                                : "income"))
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(
                                  c.icon,
                                  size: 22,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                                const SizedBox(width: 10),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                    validator: (v) => v == null ? "Select category" : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              AppCard(
                child: SwitchListTile(
                  title: const Text("Online Purchase"),
                  value: isEcommerce,
                  onChanged: (v) => setState(() => isEcommerce = v),
                  activeThumbColor:
                      Theme.of(context).colorScheme.inversePrimary,
                  tileColor: Colors.transparent,
                ),
              ),

              // DATE
              const SectionTitle("Date"),
              AppCard(
                child: ListTile(
                  title: Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: TextStyle(
                      color: colors.inversePrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today,
                      color: colors.inversePrimary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // NOTE
              const SectionTitle("Note (Optional)"),
              AppCard(
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: "Add a note...",
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                  onChanged: (v) => note = v,
                ),
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON
              AppCard(
                child: InkWell(
                  onTap: _saveTransaction,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      "Save Transaction",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.inversePrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required TransactionType type,
    required ColorScheme colors,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => setState(() {
        selectedType = type;
        if (type != TransactionType.transfer) toAccountId = null;
        if (type == TransactionType.transfer) categoryId = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.inversePrimary : colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : colors.inversePrimary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? colors.primary : colors.inversePrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========= SHOW ERROR POPUP =========
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Insufficient Balance"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ========= SAVE TRANSACTION =========
  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final data = Provider.of<DataService>(context, listen: false);

    // ================= EXPENSE CHECK =================
    if (selectedType == TransactionType.expense) {
      final acc = data.allAccounts.firstWhere((a) => a.id == accountId);

      if (acc.balance < amount) {
        _showError(
            "This account has only ₹${acc.balance.toStringAsFixed(2)} available.");
        return;
      }

      data.addExpense(
        amount: amount,
        accountId: accountId!,
        categoryId: categoryId!,
        title: title,
        isEcommerce: isEcommerce,
        note: note,
        date: selectedDate,
      );
    }

    // ================= INCOME =================
    else if (selectedType == TransactionType.income) {
      data.addIncome(
        amount: amount,
        accountId: accountId!,
        categoryId: categoryId!,
        title: title,
        isEcommerce: isEcommerce,
        note: note,
        date: selectedDate,
      );
    }

    // ================= TRANSFER CHECK =================
    else {
      final from = data.allAccounts.firstWhere((a) => a.id == accountId);

      if (from.balance < amount) {
        _showError(
            "Source account has only ₹${from.balance.toStringAsFixed(2)} available.");
        return;
      }

      data.addTransfer(
        amount: amount,
        fromAccountId: accountId!,
        toAccountId: toAccountId!,
        title: title,
        isEcommerce: isEcommerce,
        note: note,
        date: selectedDate,
      );
    }

    Navigator.pop(context);
  }
}
