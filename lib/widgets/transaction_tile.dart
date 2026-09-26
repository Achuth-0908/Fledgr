import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/data_service.dart';
import '../screens/edit_transaction_screen.dart';
import 'app_card.dart';

class TransactionTile extends StatefulWidget {
  final FinanceTransaction tx;

  const TransactionTile({super.key, required this.tx});

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final colors = Theme.of(context).colorScheme;
    final data = Provider.of<DataService>(context, listen: false);

    String title = tx.title;
    String category = "";
    String account = "";
    IconData catIcon = Icons.category;

    String amountText = "";
    Color amountColor = colors.inversePrimary;

    // ---------- TYPE ----------
    switch (tx.type) {
      case TransactionType.expense:
        final cat = data.categoryById(tx.categoryId);
        final acc = data.accountById(tx.accountId);
        category = cat?.name ?? 'Archived category';
        account = acc?.name ?? 'Archived account';
        catIcon = cat?.icon ?? Icons.category;
        amountText = "- ₹${tx.amount.toStringAsFixed(2)}";
        amountColor = Colors.redAccent;
        break;

      case TransactionType.income:
        final cat = data.categoryById(tx.categoryId);
        final acc = data.accountById(tx.accountId);
        category = cat?.name ?? 'Archived category';
        account = acc?.name ?? 'Archived account';
        catIcon = cat?.icon ?? Icons.category;
        amountText = "+ ₹${tx.amount.toStringAsFixed(2)}";
        amountColor = const Color(0xFF43A047);
        break;

      case TransactionType.transfer:
        final from = data.accountById(tx.fromAccountId);
        final to = data.accountById(tx.toAccountId);
        category = "Transfer";
        account = "${from?.name ?? 'Archived account'} → ${to?.name ?? 'Archived account'}";
        catIcon = Icons.swap_horiz;
        amountText = "₹${tx.amount.toStringAsFixed(2)}";
        break;
    }

    final dateStr = "${tx.date.day}/${tx.date.month}/${tx.date.year}";

    return GestureDetector(
      onLongPressStart: (details) async {
        final colors = Theme.of(context).colorScheme;

        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: const [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Edit"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        );

        if (!mounted) return;

        if (selected == "edit") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTransactionScreen(tx: tx),
            ),
          );
        }

        if (selected == "delete") {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Delete Transaction?"),
              content:
                  const Text("This will update account balances accordingly."),
              actions: [
                TextButton(
                  child: Text("Cancel",
                      style: TextStyle(color: colors.secondary)),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: Text("Delete",
                      style: TextStyle(color: colors.secondary)),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final deletedTx = tx;
            data.deleteTransaction(tx.id);

            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: const Text("Transaction deleted"),
                duration: const Duration(seconds: 3),
                persist: false,
                action: SnackBarAction(
                  label: "Undo",
                  textColor: colors.secondary,
                  onPressed: () => data.restoreTransaction(deletedTx),
                ),
              ),
            );
          }
        }
      },

      child: AppCard(
        child: Column(
          children: [

            // ---------- MAIN TILE ----------
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              dense: true,

              // ---------- LEADING ICON ----------
              leading: Icon(
                tx.type == TransactionType.expense
                    ? Icons.arrow_upward
                    : tx.type == TransactionType.income
                        ? Icons.arrow_downward
                        : Icons.swap_horiz,
                color: amountColor,
                size: 22,
              ),

              // ---------- TITLE + ECOM BADGE ----------
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      (title.isEmpty ? category : title),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (tx.isEcommerce) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.public,
                      size: 15,
                    ),
                  ],
                  if (tx.status == TransactionStatus.pending) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.schedule, size: 15),
                  ],
                ],
              ),

              // ---------- SUBTITLE ----------
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        catIcon,
                        size: 16,
                        color: colors.inversePrimary.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "$category • $account",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.inversePrimary.withOpacity(0.6),
                    ),
                  )
                ],
              ),

              // ---------- AMOUNT + EXPAND ----------
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),

                  if (tx.note != null && tx.note!.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => expanded = !expanded),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------- NOTE ----------
            if (expanded && tx.note != null && tx.note!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tx.note!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
