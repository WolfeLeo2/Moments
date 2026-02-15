import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('ChatEncryptionService');

/// AES-256-CBC encryption for chat messages.
///
/// Uses a master key from env + conversation ID as salt to derive
/// a per-conversation encryption key. Only text content is encrypted —
/// media URLs and metadata are left in the clear.
///
/// Encrypted messages are stored as base64-encoded ciphertext in Supabase.
/// The IV is prepended to the ciphertext so decryption is self-contained.
class ChatEncryptionService {
  ChatEncryptionService._();

  static final ChatEncryptionService _instance = ChatEncryptionService._();
  static ChatEncryptionService get instance => _instance;

  /// Prefix added to encrypted messages so we can distinguish them
  /// from legacy plaintext messages during migration.
  static const String _encPrefix = 'enc:';

  /// Derive a 256-bit key from the master secret + conversation salt.
  Key _deriveKey(String conversationId) {
    final masterSecret =
        dotenv.env['CHAT_ENCRYPTION_KEY'] ?? 'moments-default-key-change-me';
    final combined = '$masterSecret:$conversationId';
    final hash = sha256.convert(utf8.encode(combined));
    return Key.fromBase64(base64.encode(hash.bytes));
  }

  /// Encrypt plaintext content for a given conversation.
  /// Returns a string formatted as `enc:<base64(iv + ciphertext)>`.
  String encrypt(String plaintext, String conversationId) {
    try {
      final key = _deriveKey(conversationId);
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV + ciphertext for self-contained decryption
      final combined = iv.bytes + encrypted.bytes;
      return '$_encPrefix${base64.encode(combined)}';
    } catch (e) {
      _log.e('Encryption failed, sending plaintext', error: e);
      return plaintext; // Graceful fallback
    }
  }

  /// Decrypt a message. Handles both encrypted (`enc:...`) and
  /// legacy plaintext messages transparently.
  String decrypt(String ciphertext, String conversationId) {
    if (!ciphertext.startsWith(_encPrefix)) {
      // Legacy plaintext message — return as-is
      return ciphertext;
    }

    try {
      final payload = ciphertext.substring(_encPrefix.length);
      final combined = base64.decode(payload);

      // First 16 bytes = IV, rest = ciphertext
      final iv = IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);

      final key = _deriveKey(conversationId);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(Encrypted(encryptedBytes), iv: iv);
    } catch (e) {
      _log.e('Decryption failed, returning raw content', error: e);
      return ciphertext; // Show raw if decryption fails
    }
  }

  /// Check if a message is encrypted.
  static bool isEncrypted(String content) => content.startsWith(_encPrefix);
}
