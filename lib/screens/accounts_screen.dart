import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import 'edit_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,

      appBar: AppBar(
        title: const Text("Accounts"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SectionTitle("Your Accounts"),

            ...data.accounts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onLongPressStart: (details) async {
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
                          value: "archive",
                          child: Row(
                            children: [
                              Icon(Icons.archive, size: 18),
                              SizedBox(width: 8),
                              Text("Archive"),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (selected == "edit") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditAccountScreen(account: a),
                        ),
                      );
                    }

                    if (selected == "archive") {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Archive Account?"),
                          content: const Text(
                            "The balance must be ₹0 before archiving.\n"
                            "You can restore the account later.",
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: colors.secondary),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              child: Text(
                                "Archive",
                                style: TextStyle(color: colors.secondary),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final ok = await data.archiveAccount(a.id);

                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Account balance must be 0 to archive",
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account archived"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },

                  child: AppCard(
                    child: ListTile(
                      leading: Icon(a.type.icon),
                      title: Text(a.name),
                      subtitle: Text(a.type.name),
                      trailing: Text("₹${a.balance.toStringAsFixed(2)}"),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
