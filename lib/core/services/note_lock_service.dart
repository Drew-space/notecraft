import 'package:local_auth/local_auth.dart';

class NoteLockService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device supports any authentication
  /// (biometrics, PIN, pattern, or password).
  static Future<bool> isDeviceSupported() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user with the system's default authentication.
  /// biometricOnly: false → falls back to PIN / pattern / password.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to unlock this note',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
