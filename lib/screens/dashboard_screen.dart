import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import '../widgets/transaction_tile.dart';
import '../theme/theme_provider.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,

      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SectionTitle("Overview"),

            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Net Worth"),
                  Text(
                    "₹${data.totalNetWorth.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.inversePrimary,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Income"),
                        const SizedBox(height: 8),
                        Text(
                          "₹${data.totalIncome.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Expenses"),
                        const SizedBox(height: 8),
                        Text(
                          "₹${data.totalExpense.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const SectionTitle("Recent Activity"),

            const SizedBox(height: 8),

            if (data.recentFive.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No transactions yet",
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.inversePrimary.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ...data.recentFive.map(
                (tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionTile(tx: tx),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
