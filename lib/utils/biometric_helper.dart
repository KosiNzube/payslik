import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      print('🔍 DEBUG: Checking biometric availability');
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      print(
          '🔍 DEBUG: canCheck = $canCheck, isDeviceSupported = $isDeviceSupported');

      if (!canCheck || !isDeviceSupported) {
        print('🔍 DEBUG: Device does not support biometrics');
        return false;
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      print('🔍 DEBUG: Available biometrics = $availableBiometrics');

      print('🔍 DEBUG: Starting biometric authentication');
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      print('🔍 DEBUG: Authentication result = $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('🔍 DEBUG: BiometricHelper error = $e');
      return false;
    }
  }
}