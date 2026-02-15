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
  final _otpController = TextEditingController();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String _completePhoneNumber = '';
  bool _isValidPhone = false;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

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

  Future<void> _sendOtp() async {
    if (!_isValidPhone || _completePhoneNumber.isEmpty) {
      setState(() => _errorMessage = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.updateUser(
        UserAttributes(phone: _completePhoneNumber),
      );

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startCooldown();
      _log.i('OTP sent to $_completePhoneNumber');
    } catch (e) {
      // Supabase sends specific error messages
      _log.e('Failed to send OTP', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = _parseError(e);
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.verifyOTP(
        phone: _completePhoneNumber,
        token: code,
        type: OtpType.phoneChange,
      );

      await _savePhoneToProfile();

      _log.i('Phone verified: $_completePhoneNumber');
      if (mounted) {
        AppRouter.goToMap(context);
      }
    } catch (e) {
      _log.e('OTP verification failed', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = _parseError(e);
      });
    }
  }

  Future<void> _savePhoneToProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final phoneHash = PhoneHashService.hashNumber(_completePhoneNumber);
      await _supabase
          .from('profiles')
          .update({
            'phone_number': _completePhoneNumber,
            'phone_hash': phoneHash,
          })
          .eq('id', userId);
    } catch (e) {
      _log.w('Failed to save phone to profile', error: e);
    }
  }

  void _startCooldown() {
    _cooldownSeconds = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('rate_limit') || msg.contains('429')) {
      return 'Too many attempts. Please wait before trying again.';
    }
    if (msg.contains('invalid') || msg.contains('expired')) {
      return 'Invalid or expired code. Try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // User requested GoogleSansFlex via Theme.of(context).textTheme
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _signOut,
              icon: Icon(Icons.logout, color: AppTheme.emergencyRed, size: 20),
              label: Text(
                'Sign Out',
                style: textTheme.labelLarge?.copyWith(color: AppTheme.emergencyRed),
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
                  // Icon or Illustration could go here
                  Icon(
                    _otpSent
                        ? Icons.mark_email_read_outlined
                        : Icons.phonelink_lock,
                    size: 64,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    _otpSent ? 'Verify Code' : 'Verify Phone Number',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    _otpSent
                        ? 'We verified $_completePhoneNumber. Enter the 6-digit code sent to you.'
                        : 'We need to verify your phone number to secure your account. This cannot be skipped.',
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

                  if (!_otpSent) ...[
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

                    // Send Button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        // Using standard Material 3 button
                        onPressed: _isLoading ? null : _sendOtp,
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
                                'Send Verification Code',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // OTP Input
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '000000',
                        hintStyle: textTheme.headlineMedium?.copyWith(
                          color: Colors.black12,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _verifyOtp,
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
                                'Verify Code',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend & Change Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _cooldownSeconds > 0 ? null : _sendOtp,
                          child: Text(
                            _cooldownSeconds > 0
                                ? 'Resend (${_cooldownSeconds}s)'
                                : 'Resend Code',
                            style: textTheme.labelLarge?.copyWith(
                              color: _cooldownSeconds > 0
                                  ? AppTheme.textGray
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        Text('•', style: TextStyle(color: AppTheme.textGray)),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                    _errorMessage = null;
                                  });
                                },
                          child: Text(
                            'Change Number',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppTheme.textGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
