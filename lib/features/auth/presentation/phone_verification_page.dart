import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Falling back to GoogleFonts if Theme doesn't have custom font, but user said use Theme.
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/phone_hash_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/sources/supabase_config.dart';

final _log = AppLogger('PhoneVerificationPage');

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _supabase = SupabaseConfig.client;

  bool _isLoading = false;
  String? _errorMessage;
  String _completePhoneNumber = '';
  bool _isValidPhone = false;

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        context.go(AppRouter.loginRoute);
      }
    } catch (e) {
      _log.e('Error signing out', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  Future<void> _savePhoneAndContinue() async {
    if (!_isValidPhone || _completePhoneNumber.isEmpty) {
      setState(() => _errorMessage = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Hashing logic from the original OTP page
      final phoneHash = PhoneHashService.hashNumber(_completePhoneNumber);

      // Directly update the profile with the phone number and hash
      // Skipping the actual SMS OTP verification step for now.
      await _supabase
          .from('profiles')
          .update({
            'phone_number': _completePhoneNumber,
            'phone_hash': phoneHash,
          })
          .eq('id', userId);

      _log.i('Phone number saved: $_completePhoneNumber (Hash: $phoneHash)');
      if (mounted) {
        AppRouter.goToMap(context);
      }
    } catch (e) {
      _log.e('Failed to save phone number', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save number. Please try again.';
      });
    }
  }

  void _skip() {
    AppRouter.goToMap(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        actions: [
          // Sign Out button (kept from new design)
          TextButton.icon(
            onPressed: _signOut,
            icon: Icon(Icons.logout, color: AppTheme.emergencyRed, size: 20),
            label: Text(
              'Sign Out',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.emergencyRed,
              ),
            ),
          ),
          // Skip button
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.phonelink_setup,
                    size: 64,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'Add Phone Number',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Help friends verify your contact. This will make it easier for them to find you on Moments.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Phone Input
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    initialCountryCode: 'KE',
                    disableLengthCheck: false,
                    showDropdownIcon: true,
                    dropdownIconPosition: IconPosition.trailing,
                    flagsButtonMargin: const EdgeInsets.only(left: 8),
                    style: textTheme.bodyLarge,
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                    },
                    onCountryChanged: (_) => _isValidPhone = false,
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        _isValidPhone = false;
                        return 'Enter your phone number';
                      }
                      _isValidPhone = true;
                      return null;
                    },
                    invalidNumberMessage: 'Invalid phone number',
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _savePhoneAndContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Number',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
