import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'add_transaction_screen.dart';
import 'add_account_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    AccountsScreen(),
    TransactionsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _pages[_selectedIndex],

      floatingActionButton: _buildFab(colors),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.primary,
        selectedItemColor: colors.inversePrimary,
        unselectedItemColor: colors.inversePrimary.withOpacity(0.5),
        elevation: 0,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: "Accounts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_rounded),
            label: "Transactions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Reports",
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(ColorScheme colors) {
    switch (_selectedIndex) {
      case 0: // HOME → Add Transaction
        return FloatingActionButton(
          heroTag: "fab_home",
          child: Icon(Icons.add, color: colors.inversePrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(),
              ),
            );
          },
        );

      case 1: // ACCOUNTS → Add Account
        return FloatingActionButton(
          heroTag: "fab_accounts",
          child: Icon(Icons.add, color: colors.inversePrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddAccountScreen(),
              ),
            );
          },
        );

      default:
        return null; // No FAB on other tabs
    }
  }
}
