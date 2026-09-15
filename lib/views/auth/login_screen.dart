import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../repositories/user_repository.dart';
import '../../services/permission_service.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(
    text: '',
  );
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String _verificationId = '';
  int? _resendToken;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? PmsTheme.error : PmsTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInactiveDialog([String message = 'Your user account is marked inactive. Contact Super Admin.']) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: PmsTheme.error, size: 24),
            SizedBox(width: 8),
            Text(
              'Account Inactive',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: PmsTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: PmsTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Trigger Firebase Real SMS Phone Verification
  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit mobile number.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhoneNumber = '+91$rawPhone';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            final phone = userCredential.user?.phoneNumber ?? fullPhoneNumber;
            final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
            try {
              final repo = UserRepository();
              final profile = await repo.getProfile(cleanPhone);
              if (profile != null && !profile.isActive && !profile.isSuperAdmin) {
                await FirebaseAuth.instance.signOut();
                setState(() => _isLoading = false);
                _showInactiveDialog();
                return;
              }
            } on InactiveUserException catch (e) {
              await FirebaseAuth.instance.signOut();
              setState(() => _isLoading = false);
              _showInactiveDialog(e.message);
              return;
            }
          } catch (e) {
            debugPrint("Auto-sign in error: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar(e.message ?? 'Verification failed.', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isLoading = false;
          });
          _showSnackBar('Real SMS OTP sent to $fullPhoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to send OTP: $e', isError: true);
    }
  }

  /// Verify entered SMS OTP code
  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      _showSnackBar('Please enter the 6-digit SMS code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final phone = userCredential.user?.phoneNumber ?? '+91${_phoneController.text.trim()}';
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      // Verify active status before granting access
      try {
        final repo = UserRepository();
        final profile = await repo.getProfile(cleanPhone);
        if (profile != null && !profile.isActive && !profile.isSuperAdmin) {
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          _showInactiveDialog();
          return;
        }
      } on InactiveUserException catch (e) {
        await FirebaseAuth.instance.signOut();
        setState(() => _isLoading = false);
        _showInactiveDialog(e.message);
        return;
      } catch (e) {
        debugPrint('Profile pre-check note: $e');
      }

      _showSnackBar('Authentication successful! Checking permissions...');
      await PermissionService.requestAllPermissionsOneByOne();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'invalid-verification-code') {
        _showSnackBar(
          'Incorrect OTP entered. Please check SMS.',
          isError: true,
        );
      } else {
        _showSnackBar(e.message ?? 'Verification failed.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        // If in OTP state, return to mobile number entry
        if (_isOtpSent) {
          setState(() {
            _isOtpSent = false;
            _otpController.clear();
          });
          return;
        }

        // Double-tap to exit confirmation
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Press back again to exit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              backgroundColor: PmsTheme.textPrimary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppGradientBackground(
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  const Center(child: AppLogo(size: 96)),
                  const SizedBox(height: 20),
                  const Text(
                    'Prince Eduhub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PMS Admin · Real Mobile OTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: PmsTheme.textMuted),
                  ),
                  const SizedBox(height: 36),

                  // Login Card Container
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isOtpSent) ...[
                          // Phone Number Field
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PmsTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: PmsTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: PmsTheme.textMuted,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Welcome to Prince Group',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PmsTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          PmsGradientButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            loading: _isLoading,
                            label: 'Send Real SMS OTP',
                          ),
                        ] else ...[
                          // OTP Input Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SMS Sent To:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: PmsTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '+91 ${_phoneController.text.trim()}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: PmsTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PmsTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter 6-Digit Code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PmsTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              color: PmsTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              hintStyle: TextStyle(
                                color: PmsTheme.textMuted,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PmsTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          PmsGradientButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            loading: _isLoading,
                            label: 'Verify Real OTP & Login',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'PMS Admin • Prince Eduhub',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: PmsTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  ),
  );
}
}

