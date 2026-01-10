import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/theme_provider.dart';
import '../services/security_service.dart';

// >>> ADDED
import '../services/backup_service.dart';
import '../services/data_service.dart';
import '../db/app_database.dart' as db;

import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool lockEnabled = false;
  bool biometricEnabled = false;
  final pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    lockEnabled = await SecurityService.isLockEnabled();
    biometricEnabled = await SecurityService.isBiometricEnabled();
    setState(() {});
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: colors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle("Appearance"),
          AppCard(
            child: _SettingTile(
              icon: Icons.palette_outlined,
              title: "Dark Mode",
              subtitle: themeProvider.isDarkMode ? "Enabled" : "Disabled",
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: colors.inversePrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle("Security"),
          AppCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.lock_outline,
                  title: "Enable App Lock",
                  subtitle: lockEnabled 
                    ? "Your app is protected with a PIN" 
                    : "Protect your app with a PIN",
                  trailing: Switch(
                    value: lockEnabled,
                    onChanged: (v) async {
                      if (v) {
                        _showPinSetup();
                      } else {
                        _showVerifyPinToDisable();
                      }
                    },
                    activeColor: colors.inversePrimary,
                  ),
                ),
                if (lockEnabled) ...[
                  Divider(height: 1, color: colors.inversePrimary.withOpacity(0.2)),
                  _SettingTile(
                    icon: Icons.fingerprint,
                    title: "Biometric Authentication",
                    subtitle: biometricEnabled 
                      ? "Use fingerprint or face unlock"
                      : "Disabled",
                    trailing: Switch(
                      value: biometricEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final canCheckBiometrics = await auth.canCheckBiometrics;
                          final isDeviceSupported = await auth.isDeviceSupported();
                          
                          if (canCheckBiometrics && isDeviceSupported) {
                            await SecurityService.setBiometricEnabled(true);
                            setState(() => biometricEnabled = true);
                            
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Biometric authentication enabled"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Biometric authentication not available on this device"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          await SecurityService.setBiometricEnabled(false);
                          setState(() => biometricEnabled = false);
                          
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Biometric authentication disabled"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      activeColor: colors.inversePrimary,
                    ),
                  ),
                  Divider(height: 1, color: colors.inversePrimary.withOpacity(0.2)),
                  _SettingTile(
                    icon: Icons.edit_outlined,
                    title: "Change PIN",
                    subtitle: "Update your security PIN",
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colors.inversePrimary.withOpacity(0.6),
                    ),
                    onTap: () => _showVerifyCurrentPin(),
                  ),
                ],
              ],
            ),
          ),

          // >>> ADDED BELOW
          const SizedBox(height: 24),
          const SectionTitle("Backup & Restore"),
          AppCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.upload_file,
                  title: "Export Backup",
                  subtitle: "Save your data as a .db file",
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _exportBackup,
                ),

                Divider(height: 1, color: colors.inversePrimary.withOpacity(0.2)),

                _SettingTile(
                  icon: Icons.download,
                  title: "Import Backup",
                  subtitle: "Restore data from backup file",
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _importBackup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // >>> ADDED — BACKUP LOGIC

  Future<void> _exportBackup() async {
    try {
      await BackupService.exportBackup();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup exported successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
      );
    }
  }

  Future<void> _importBackup() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Restore Backup"),
        content: const Text("This will replace ALL current data and restart the app. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Restore"),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('User cancelled confirmation');
      return;
    }

    try {
      print('User confirmed, starting import...');
      
      // FIRST: Let user pick the file (DON'T close database yet!)
      final ok = await BackupService.importBackup();
      
      print('Import result: $ok');
      
      if (!ok) {
        print('Import failed or user cancelled file picker');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Import cancelled")),
        );
        return; // Don't restart if user cancelled
      }

      print('Import successful, closing database...');
      
      // SECOND: Now close the database (file has already been replaced)
      final dataService = Provider.of<DataService>(context, listen: false);
      await dataService.database.close();
      
      print('Database closed');

      // Success - show restart dialog
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup restored successfully!")),
      );
      
      _showRestartDialog();
      
    } catch (e, stackTrace) {
      print('Import error: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Restore failed: $e")),
      );
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Restart Required"),
        content: const Text("Please close and reopen the app to complete the restore."),
        actions: [
          TextButton(
            onPressed: () {
              // Force close the app
              exit(0);
            },
            child: const Text("Close App"),
          ),
        ],
      ),
    );
  }

  void _showVerifyPinToDisable() {
    pinController.clear();
    
    showDialog(
      context: context,
      builder: (_) {
        final colors = Theme.of(context).colorScheme;
        
        return AlertDialog(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: colors.inversePrimary),
              const SizedBox(width: 12),
              const Text("Verify PIN"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your PIN to disable app lock",
                style: TextStyle(
                  color: colors.inversePrimary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: colors.inversePrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "••••",
                  hintStyle: TextStyle(
                    color: colors.inversePrimary.withOpacity(0.3),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.inversePrimary, width: 2),
                  ),
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final enteredPin = pinController.text.trim();
                
                if (enteredPin.length != 4) {
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a 4-digit PIN"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final isCorrect = await SecurityService.verifyPin(enteredPin);
                
                if (isCorrect) {
                  await SecurityService.clearPin();
                  await SecurityService.setLockEnabled(false);
                  await SecurityService.setBiometricEnabled(false);
                  setState(() {
                    lockEnabled = false;
                    biometricEnabled = false;
                  });
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("App lock disabled"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect PIN. Please try again."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  pinController.clear();
                }
              },
              child: Text(
                "Disable",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVerifyCurrentPin() {
    pinController.clear();
    
    showDialog(
      context: context,
      builder: (_) {
        final colors = Theme.of(context).colorScheme;
        
        return AlertDialog(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: colors.inversePrimary),
              const SizedBox(width: 12),
              const Text("Verify Current PIN"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your current PIN to continue",
                style: TextStyle(
                  color: colors.inversePrimary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: colors.inversePrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "••••",
                  hintStyle: TextStyle(
                    color: colors.inversePrimary.withOpacity(0.3),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.inversePrimary, width: 2),
                  ),
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final enteredPin = pinController.text.trim();
                
                if (enteredPin.length != 4) {
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a 4-digit PIN"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final isCorrect = await SecurityService.verifyPin(enteredPin);
                
                if (isCorrect) {
                  Navigator.pop(context);
                  _showPinSetup(isChanging: true);
                } else {
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect PIN. Please try again."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  pinController.clear();
                }
              },
              child: Text(
                "Verify",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPinSetup({bool isChanging = false}) {
    pinController.clear();
    
    showDialog(
      context: context,
      builder: (_) {
        final colors = Theme.of(context).colorScheme;
        
        return AlertDialog(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: colors.inversePrimary),
              const SizedBox(width: 12),
              Text(isChanging ? "Change PIN" : "Set 4-digit PIN"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChanging 
                  ? "Enter your new 4-digit PIN"
                  : "Enter a 4-digit PIN to secure your app",
                style: TextStyle(
                  color: colors.inversePrimary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: colors.inversePrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "••••",
                  hintStyle: TextStyle(
                    color: colors.inversePrimary.withOpacity(0.3),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.inversePrimary, width: 2),
                  ),
                  counterText: "",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                
                if (pin.length != 4) {
                  Navigator.pop(context);
                  
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a 4-digit PIN"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                await SecurityService.setPin(pin);
                await SecurityService.setLockEnabled(true);
                setState(() => lockEnabled = true);
                Navigator.pop(context);

                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isChanging 
                        ? "PIN updated successfully" 
                        : "App lock enabled successfully",
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                "Save",
                style: TextStyle(color: colors.inversePrimary.withOpacity(0.3)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: colors.inversePrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.inversePrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}