import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Blind matching service for phone number discovery.
///
/// Numbers are normalized to their last 9 digits (strips country codes),
/// then SHA-256 hashed. Only hashes are ever sent to Supabase —
/// raw numbers never leave the device.
class PhoneHashService {
  const PhoneHashService._();

  /// Normalize a phone number to its last 9 digits (digits only).
  ///
  /// This strips country codes so that +254712345678, 0712345678,
  /// and 254712345678 all produce the same canonical form: `712345678`.
  static String normalize(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length <= 9) return digitsOnly;
    return digitsOnly.substring(digitsOnly.length - 9);
  }

  /// SHA-256 hash a single normalized phone number.
  static String hashNumber(String phoneNumber) {
    final normalized = normalize(phoneNumber);
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  /// Hash a batch of phone numbers (e.g. from contacts).
  /// Returns unique hashes only.
  static List<String> hashBatch(List<String> phoneNumbers) {
    final hashes = <String>{};
    for (final number in phoneNumbers) {
      final normalized = normalize(number);
      if (normalized.length >= 7) {
        hashes.add(hashNumber(number));
      }
    }
    return hashes.toList();
  }
}
