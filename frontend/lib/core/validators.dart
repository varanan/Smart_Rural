class Validators {
  static String? requiredField(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? license(String? v) {
    if (requiredField(v, fieldName: 'License number') != null) {
      return 'License number is required';
    }
    final value = v!.toUpperCase().trim();
    final reg = RegExp(r'^[A-Z0-9-]{6,20}$');
    if (!reg.hasMatch(value)) {
      return 'Enter a valid license number';
    }
    return null;
  }

  static String? nicSriLanka(String? v) {
    if (requiredField(v, fieldName: 'NIC') != null) {
      return 'NIC is required';
    }
    final value = v!.toUpperCase().trim();
    final reg = RegExp(r'^(\d{9}[VvXx]|\d{12})$');
    if (!reg.hasMatch(value)) {
      return 'Enter a valid NIC (e.g., 199012345678 or 123456789V)';
    }
    return null;
  }

  static String? busNumber(String? v) {
    if (requiredField(v, fieldName: 'Bus number') != null) {
      return 'Bus number is required';
    }
    final value = v!.toUpperCase().trim();
    final reg = RegExp(r'^[A-Z0-9-\/]{2,15}$');
    if (!reg.hasMatch(value)) {
      return 'Enter a valid bus number';
    }
    return null;
  }

  static String? vehicleNumber(String? v) {
    if (requiredField(v, fieldName: 'Vehicle number') != null) {
      return 'Vehicle number is required';
    }
    final value = v!.toUpperCase().trim();
    final reg = RegExp(r'^[A-Z0-9-\/]{2,15}$');
    if (!reg.hasMatch(value)) {
      return 'Enter a valid vehicle number';
    }
    return null;
  }
}
