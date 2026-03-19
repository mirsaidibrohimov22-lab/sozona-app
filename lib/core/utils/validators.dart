// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Input Validators
// ═══════════════════════════════════════════════════════════════

import 'package:my_first_app/core/constants/app_constants.dart';

/// Barcha input validatsiya funksiyalari.
///
/// Formalar va Security Rules uchun ishlatiladi.
/// Har bir funksiya: to'g'ri → true, noto'g'ri → false.
class Validators {
  Validators._();

  /// Email to'g'rimi?
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  /// Telefon raqam to'g'rimi? (+998... yoki +49...)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    return regex.hasMatch(phone.trim());
  }

  /// Ism to'g'rimi?
  static bool isValidName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final trimmed = name.trim();
    return trimmed.length >= AppConstants.minNameLength &&
        trimmed.length <= AppConstants.maxNameLength;
  }

  /// Parol kuchli mi?
  /// Kamida 8 belgi, 1 katta harf, 1 kichik harf, 1 raqam.
  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    if (password.length < AppConstants.minPasswordLength) return false;
    if (password.length > AppConstants.maxPasswordLength) return false;

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);

    return hasUpperCase && hasLowerCase && hasDigit;
  }

  /// OTP kodi to'g'rimi? (6 ta raqam)
  static bool isValidOtp(String? otp) {
    if (otp == null) return false;
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }

  /// Rol to'g'rimi?
  static bool isValidRole(String? role) {
    return role == 'student' || role == 'teacher';
  }

  /// O'rganish tili to'g'rimi?
  static bool isValidLanguage(String? language) {
    return language == 'en' || language == 'de';
  }

  /// UI tili to'g'rimi?
  static bool isValidUiLanguage(String? language) {
    return language == 'uz' || language == 'en';
  }

  /// CEFR daraja to'g'rimi?
  static bool isValidLevel(String? level) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
    return level != null && levels.contains(level);
  }

  /// Kunlik maqsad to'g'rimi?
  static bool isValidGoalMinutes(int? minutes) {
    const goals = [10, 20, 30];
    return minutes != null && goals.contains(minutes);
  }

  /// Content turi to'g'rimi?
  static bool isValidContentType(String? type) {
    const types = ['quiz', 'flashcard_set', 'listening', 'speaking'];
    return type != null && types.contains(type);
  }

  /// Join code to'g'rimi? (6 belgili alfanumerik)
  static bool isValidJoinCode(String? code) {
    if (code == null) return false;
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code.toUpperCase());
  }

  // ═══════════════════════════════════
  // FORM VALIDATOR XABARLARI
  // ═══════════════════════════════════
  // TextFormField.validator uchun — null qaytarsa to'g'ri, String qaytarsa xatolik.

  /// Email validatsiya (form uchun).
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email kiritish shart';
    if (!isValidEmail(value)) return 'Email formati noto\'g\'ri';
    return null;
  }

  /// Telefon validatsiya (form uchun).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon raqam kiritish shart';
    }
    if (!isValidPhone(value)) {
      return 'Telefon formati noto\'g\'ri (masalan: +998901234567)';
    }
    return null;
  }

  /// Ism validatsiya (form uchun).
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ism kiritish shart';
    if (!isValidName(value)) {
      return 'Ism ${AppConstants.minNameLength}-${AppConstants.maxNameLength} belgi bo\'lishi kerak';
    }
    return null;
  }

  /// Parol validatsiya (form uchun).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Parol kiritish shart';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Parol kamida ${AppConstants.minPasswordLength} belgi bo\'lishi kerak';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Kamida 1 ta katta harf kerak';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Kamida 1 ta kichik harf kerak';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Kamida 1 ta raqam kerak';
    return null;
  }

  /// OTP validatsiya (form uchun).
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'Kodni kiritish shart';
    if (!isValidOtp(value)) return 'Kod 6 ta raqamdan iborat bo\'lishi kerak';
    return null;
  }

  /// Join code validatsiya (form uchun).
  static String? validateJoinCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Kodni kiritish shart';
    if (!isValidJoinCode(value)) {
      return 'Kod 6 ta belgidan iborat bo\'lishi kerak';
    }
    return null;
  }
}
