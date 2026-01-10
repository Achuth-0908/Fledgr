import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';
import 'services/data_service.dart';
import 'services/security_service.dart';
import 'db/app_database.dart' as db;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load saved theme first
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool("isDarkMode") ?? false;
  
  // Create the database instance
  final database = db.AppDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark:isDark)),
        ChangeNotifierProvider(create: (_) => DataService(database)),
      ],
      child: const FinanceApp(),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,

      // Lock Gate decides first screen
      home: const LockGate(),

      routes: {
        "/home": (_) => const HomeShell(),
      },
    );
  }
}

/// ---------------- LOCK GATE ----------------
/// Decides whether to show LockScreen or Home
class LockGate extends StatelessWidget {
  const LockGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SecurityService.isLockEnabled(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final enabled = snapshot.data ?? false;

        return enabled ? const LockScreen() : const HomeShell();
      },
    );
  }
}