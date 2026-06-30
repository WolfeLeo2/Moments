import 'package:moments/core/services/app_logger.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _log = AppLogger('AuthService');

class AuthService {
  final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;

  AuthService(this._supabase) {
    // Initialize Google Sign In
    // For iOS: clientId is automatically read from Info.plist (GIDClientID)
    // For Android: need to provide serverClientId (web client ID)
    if (Platform.isIOS) {
      // iOS: No serverClientId needed, reads from Info.plist
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    } else {
      // Android: Use web client ID as serverClientId
      final webClientId = dotenv.env['SUPABASE_GOOGLE_WEB_CLIENT_ID'];
      _googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user's profile image URL
  String? get currentUserPhotoUrl => currentUser?.userMetadata?['avatar_url'];

  /// Get current user's display name
  String? get currentUserDisplayName => currentUser?.userMetadata?['full_name'];

  /// Get current user's email
  String? get currentUserEmail => currentUser?.email;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In was cancelled');
      }

      // Get Google Auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('No ID Token found from Google Sign In');
      }

      // Sign in to Supabase with Google credentials
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Create/update user profile
      if (response.user != null) {
        await _createOrUpdateProfile(response.user!);
      }

      return response;
    } catch (e) {
      _log.e('Error signing in with Google', error: e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createOrUpdateProfile(response.user!);
      }

      return response;
    } catch (e) {
      _log.e('Error signing in with email', error: e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Delete FCM token row before sign-out to prevent cross-account
      // notification delivery (C9). Best-effort — sign-out proceeds even on failure.
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _supabase
              .from('user_devices')
              .delete()
              .eq('fcm_token', token);
          await FirebaseMessaging.instance.deleteToken();
        }
      } catch (e) {
        _log.w('Failed to delete FCM token on sign-out', error: e);
      }

      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _supabase.auth.signOut();
    } catch (e) {
      _log.e('Error signing out', error: e);
      rethrow;
    }
  }

  /// Create or update user profile in profiles table
  Future<void> _createOrUpdateProfile(User user) async {
    try {
      // First check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select('invite_code')
          .eq('id', user.id)
          .maybeSingle();

      final profileData = {
        'id': user.id,
        'username': user.email?.split('@').first ?? 'user',
        'display_name':
            user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email,
        'avatar_url':
            user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only generate invite_code if profile doesn't exist or doesn't have one
      if (existingProfile == null || existingProfile['invite_code'] == null) {
        // Call the database function to generate invite code
        final result = await _supabase.rpc('generate_invite_code');
        profileData['invite_code'] = result as String;
      }

      await _supabase.from('profiles').upsert(profileData);
      _log.i('Profile created/updated for user: ${user.email}');
    } catch (e) {
      _log.w('Error creating/updating profile', error: e);
      // Don't rethrow - profile creation failure shouldn't block authentication
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      _log.e('Error resetting password', error: e);
      rethrow;
    }
  }
}
