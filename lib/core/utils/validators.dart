class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
    r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
    r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
    r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
    r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
    r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
    r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])',
  );
  // static final RegExp _alphabetRegex = RegExp(r'[a-zA-Z]');
  // static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharactersRegex = RegExp(
    r'[!@#$%^&*(),.?":{}|<>]',
  );

  static final RegExp _isAsciiPrintableRegex = RegExp(r'^[\x20-\x7E]+$');

  /// A form field is required with given label
  static String? require(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) {
      return "$label is required.";
    }
    return null;
  }

  /// Require and format validator for name
  static String? name(String? value, {String label = "Name"}) {
    String invalidError = "Invalid $label.";

    if (value == null || value.trim().isEmpty) {
      return "$label is required.";
    } else if (value.length < 3) {
      return invalidError;
    } else if (_specialCharactersRegex.hasMatch(value)) {
      /// If value contains number
      return invalidError;
    }

    return null;
  }

  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return "Email address is required.";
    if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  static String? username(String? value) => require(value, label: "Username");

  static String? password(String? value) => require(value, label: "Password");

  static String? passwordPolicy(String? value) {
    if (value?.isNotEmpty != true) {
      return "Password is required.";
    } else if (value!.length <= 6) {
      return "Password must be more than 6 characters.";
    } else if (!_isAsciiPrintableRegex.hasMatch(value)) {
      return "Invalid password.";
    }
    return null;
  }

  static String? token(String? value) => require(value, label: "Token");

  static String? confirmPassword(String? value) =>
      require(value, label: "Confirm password");

  static String? currentPassword(String? value) =>
      require(value, label: "Current password");

  static String? newPassword(String? value) =>
      require(value, label: "New password");

  /// Validate integer and avoid zero from integer if needed
  static String? integer(
    String? value, {
    required String label,
    int? minAmount,
    int? maxAmount,
  }) {
    if (value == null || value.isEmpty) {
      return "$label is required.";
    } else if (double.tryParse(value) == null) {
      return "Invalid ${label.toLowerCase()}.";
    } else if (minAmount != null && minAmount > double.parse(value)) {
      return "$label must be at least $minAmount.";
    } else if (maxAmount != null && maxAmount < double.parse(value)) {
      /// If value exceeded maximum count
      return "$label can be at most $maxAmount.";
    }
    return null;
  }

  static String? age(String? value) =>
      Validators.integer(value, label: "Age", minAmount: 1, maxAmount: 120);
}
