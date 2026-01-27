import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _pinKey = 'user_pin';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  // Auto-lock configuration
  bool _isAuthenticated = false;
  DateTime? _lastActivityTime;
  int _autoLockTimeoutSeconds = 60; // Default 1 minute

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    final String? enabled = await _storage.read(key: _biometricsEnabledKey);
    return enabled == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your expenses',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (didAuthenticate) {
        setAuthenticated(true);
      }
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final String? pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<bool> verifyPin(String pin) async {
    final String? storedPin = await _storage.read(key: _pinKey);
    if (storedPin == pin) {
      setAuthenticated(true);
      return true;
    }
    return false;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
  }

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    if (value) {
      updateActivity();
    }
  }

  void updateActivity() {
    _lastActivityTime = DateTime.now();
  }

  bool shouldLock() {
    if (!_isAuthenticated) return false;
    if (_lastActivityTime == null) return false;

    final difference = DateTime.now().difference(_lastActivityTime!);
    if (difference.inSeconds >= _autoLockTimeoutSeconds) {
      setAuthenticated(false);
      return true;
    }
    return false;
  }

  void setAutoLockTimeout(int seconds) {
    _autoLockTimeoutSeconds = seconds;
  }
}
