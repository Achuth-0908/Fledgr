import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();

  static const _pinKey = "APP_PIN";
  static const _lockEnabledKey = "LOCK_ENABLED";
  static const _biometricEnabledKey = "BIOMETRIC_ENABLED";

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await setLockEnabled(true);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  static Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(
        key: _lockEnabledKey,
        value: enabled ? "true" : "false");
  }

  static Future<bool> isLockEnabled() async {
    final v = await _storage.read(key: _lockEnabledKey);
    return v == "true";
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await setLockEnabled(false);
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == enteredPin;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? "true" : "false",
    );
  }

  static Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _biometricEnabledKey);
    return v == "true";
  }
}