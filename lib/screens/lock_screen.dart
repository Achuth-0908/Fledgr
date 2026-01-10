import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/security_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String? error;
  final auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    debugPrint("🔐 Checking if biometric is enabled...");

    final biometricEnabled = await SecurityService.isBiometricEnabled();
    debugPrint("➡ biometricEnabled = $biometricEnabled");

    if (!biometricEnabled) {
      debugPrint("❌ Biometrics disabled in settings");
      return;
    }

    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      debugPrint("➡ canAuthenticate = $canAuthenticate");

      if (!canAuthenticate) {
        debugPrint("❌ Device cannot authenticate");
        return;
      }

      debugPrint("👉 Asking user to authenticate...");

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock Finance Tracker',
      );

      debugPrint("✔ didAuthenticate = $didAuthenticate");

      if (didAuthenticate && mounted) {
        debugPrint("🎉 Opening home screen");
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        debugPrint("⚠ Authentication cancelled / failed");
      }
    } catch (e) {
      debugPrint("🔥 Biometrics error: $e");
    }
  }

  Future<void> _submit() async {
    final pin = await SecurityService.getPin();

    if (_pinController.text == pin) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } else {
      setState(() => error = "Incorrect PIN");
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------- App name -------
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo image
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        colors.inversePrimary,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    // App name
                    Text(
                      "Fledgr",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: colors.inversePrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ------- Icon inside card -------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 44,
                    color: colors.inversePrimary,
                  ),
                ),

                const SizedBox(height: 28),

                // ------- Instruction -------
                Text(
                  "Enter your 4-digit PIN",
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.inversePrimary.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 20),

                // ------- PIN field card -------
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autofocus: true,
                    cursorColor: colors.inversePrimary,
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.inversePrimary,
                    ),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    onChanged: (value) {
                      if (error != null) {
                        setState(() => error = null);
                      }
                      if (value.length == 4) _submit();
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // ------- ERROR BELOW FIELD -------
                if (error != null)
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: 18),

                // ------- Biometrics -------
                FutureBuilder<bool>(
                  future: SecurityService.isBiometricEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return TextButton.icon(
                        onPressed: _tryBiometric,
                        icon: Icon(
                          Icons.fingerprint,
                          color: colors.inversePrimary,
                        ),
                        label: Text(
                          "Use biometrics",
                          style: TextStyle(
                            color: colors.inversePrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
