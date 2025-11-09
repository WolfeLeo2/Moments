import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Initialize Google Sign In with web client ID
    final webClientId = dotenv.env['SUPABASE_GOOGLE_WEB_CLIENT_ID'];
    _googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile'],
    );
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
      print('❌ Error signing in with Google: $e');
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
      print('❌ Error signing in with email: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
      );

      if (response.user != null) {
        await _createOrUpdateProfile(response.user!);
      }

      return response;
    } catch (e) {
      print('❌ Error signing up with email: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  /// Create or update user profile in profiles table
  Future<void> _createOrUpdateProfile(User user) async {
    try {
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

      await _supabase.from('profiles').upsert(profileData);
      print('✅ Profile created/updated for user: ${user.email}');
    } catch (e) {
      print('❌ Error creating/updating profile: $e');
      // Don't rethrow - profile creation failure shouldn't block authentication
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }
}
