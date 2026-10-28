import 'package:flutter/services.dart';
import '../constants/app_errors.dart';

class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppErrors.nameRequired;
    }
    if (value.trim().length < 2) {
      return AppErrors.nameMinLength;
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppErrors.mobileRequired;
    }
    final trimmed = value.trim();
    final regex = RegExp(r'^[0-9]{10}$');
    if (!regex.hasMatch(trimmed)) {
      return AppErrors.mobileExactDigits;
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(trimmed)) {
      return AppErrors.emailInvalid;
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

class WordLimitFormatter extends TextInputFormatter {
  final int maxWords;

  const WordLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.trim().isEmpty) return newValue;
    final words = newValue.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= maxWords) {
      return newValue;
    }
    return oldValue;
  }
}
