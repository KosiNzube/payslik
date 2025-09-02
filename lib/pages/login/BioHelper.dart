import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricHelper {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        print('Device does not support biometric authentication');
        return false;
      }

      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('No biometric authentication methods are enrolled');
        return false;
      }

      print('Available biometric types: $availableBiometrics');
      return true;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Authenticate using biometric authentication
  static Future<bool> authenticate() async {
    try {
      // First check if biometric authentication is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow fallback to PIN/Password if needed
          stickyAuth: true,     // Keep auth dialog until user interacts
          sensitiveTransaction: true, // For sensitive operations
        ),
      );

      print('Biometric authentication result: $didAuthenticate');
      return didAuthenticate;

    } on PlatformException catch (e) {
      print('Biometric authentication platform exception: ${e.code} - ${e.message}');

      // Handle specific error cases
      switch (e.code) {
        case auth_error.notAvailable:
          print('Biometric authentication not available on this device');
          break;
        case auth_error.notEnrolled:
          print('No biometric credentials are enrolled on this device');
          break;
        case auth_error.lockedOut:
          print('Biometric authentication is temporarily locked due to too many failed attempts');
          break;
        case auth_error.permanentlyLockedOut:
          print('Biometric authentication is permanently locked. User must use alternative authentication');
          break;
        case auth_error.passcodeNotSet:
          print('Device passcode/PIN is not set up');
          break;

        case 'UserCancel':
        case 'user_cancel':
          print('User cancelled biometric authentication');
          break;
        case 'TouchIDNotAvailable':
          print('Touch ID is not available on this device');
          break;
        case 'TouchIDNotEnrolled':
          print('Touch ID is not enrolled on this device');
          break;
        case 'FaceIDNotAvailable':
          print('Face ID is not available on this device');
          break;
        case 'FaceIDNotEnrolled':
          print('Face ID is not enrolled on this device');
          break;
        default:
          print('Unknown biometric authentication error: ${e.code} - ${e.message}');
      }
      return false;

    } catch (e) {
      print('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if device supports biometrics (without checking enrollment)
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Get a user-friendly message about biometric availability
  static Future<String> getBiometricStatusMessage() async {
    try {
      final bool deviceSupported = await isDeviceSupported();
      if (!deviceSupported) {
        return 'This device does not support biometric authentication';
      }

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return 'Biometric authentication is not available on this device';
      }

      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return 'No biometric credentials are enrolled. Please set up fingerprint or face recognition in your device settings';
      }

      // Build message based on available biometrics
      List<String> biometricNames = [];
      for (BiometricType type in availableBiometrics) {
        switch (type) {
          case BiometricType.fingerprint:
            biometricNames.add('Fingerprint');
            break;
          case BiometricType.face:
            biometricNames.add('Face ID');
            break;
          case BiometricType.iris:
            biometricNames.add('Iris');
            break;
          case BiometricType.strong:
            biometricNames.add('Strong Biometric');
            break;
          case BiometricType.weak:
            biometricNames.add('Weak Biometric');
            break;
        }
      }

      return 'Available biometric authentication: ${biometricNames.join(', ')}';

    } catch (e) {
      return 'Unable to determine biometric status: $e';
    }
  }
}