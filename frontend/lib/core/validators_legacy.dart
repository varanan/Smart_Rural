class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? requiredField(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? license(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    return null;
  }

  static String? nicSriLanka(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIC is required';
    }
    final nicRegex = RegExp(r'^[0-9]{9}[VX]$|^[0-9]{12}$');
    if (!nicRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid Sri Lankan NIC';
    }
    return null;
  }

  static String? busNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bus number is required';
    }
    return null;
  }

  static String? vehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    return null;
  }
}
