class Validators {
  // Define constant patterns at class level
  static const String _emailPattern = r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
  static const String _phonePattern = r'^\+?[\d\s-]{10,15}$';
  static const String _numericPattern = r'^\d+$';


  /// Validates an email address
  static String? validateEmail(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter your email';
      }

      final emailRegex = RegExp(_emailPattern);
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }

      return null;
    } catch (e) {
      return 'Invalid email format';
    }
  }

  /// Validates a password with minimum requirements
  static String? validatePassword(String? value, {int minLength = 6}) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }

      if (value.length < minLength) {
        return 'Password must be at least $minLength characters';
      }

      return null;
    } catch (e) {
      return 'Invalid password format';
    }
  }

  /// Validates a required field with custom field name
  static String? validateRequired(String? value, String fieldName) {
    try {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    } catch (e) {
      return '$fieldName is invalid';
    }
  }

  /// Validates a phone number with optional country code
  static String? validatePhone(String? value) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter your phone number';
      }

      final phoneRegex = RegExp(_phonePattern);
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Please enter a valid phone number';
      }

      return null;
    } catch (e) {
      return 'Invalid phone number format';
    }
  }

  /// Validates a numeric value with optional min and max
  static String? validateNumeric(
    String? value,
    String fieldName, {
    double? min,
    double? max,
  }) {
    try {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }

      final number = double.tryParse(value.trim());
      if (number == null) {
        return '$fieldName must be a number';
      }

      if (min != null && number < min) {
        return '$fieldName must be at least ${min.toString()}';
      }

      if (max != null && number > max) {
        return '$fieldName must not exceed ${max.toString()}';
      }

      return null;
    } catch (e) {
      return 'Invalid number format';
    }
  }

  /// Validates a reset token with configurable length
  static String? validateResetToken(String? value, {int length = 6}) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter the reset code';
      }

      final cleanValue = value.trim();
      if (!RegExp(_numericPattern).hasMatch(cleanValue)) {
        return 'Reset code must contain only numbers';
      }

      if (cleanValue.length != length) {
        return 'Reset code must be exactly $length digits';
      }

      return null;
    } catch (e) {
      return 'Invalid reset code format';
    }
  }

  /// Validates a PIN or OTP code with configurable length
  static String? validatePin(String? value, {int length = 4}) {
    try {
      if (value == null || value.isEmpty) {
        return 'Please enter the code';
      }

      final cleanValue = value.trim();
      if (cleanValue.length != length) {
        return 'Code must be exactly $length digits';
      }

      if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
        return 'Code must contain only numbers';
      }

      return null;
    } catch (e) {
      return 'Invalid code format';
    }
  }
}