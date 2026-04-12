import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart' as loc;

import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../services/auth_service.dart';

// ============================================
// SIGN UP SCREEN
// ============================================
class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onLogin;

  const SignUpScreen({super.key, required this.onSignUpSuccess, required this.onLogin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final _authService = AuthService();

  Future<void> _handleSignUp() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final result = await _authService.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        widget.onSignUpSuccess();
      } else {
        setState(() => _error = result.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              height: MediaQuery.of(context).size.height * 0.28,
              bottomRadius: 28,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                      ),
                      Text('Campus Navigator',
                          style: AppTextStyles.headingBold(18, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Account', style: AppTextStyles.headingBold(24)),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: AppTextStyles.bodyMedium(13, color: AppColors.destructive)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(_nameController, 'Full Name', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildField(_emailController, 'your.name@lau.edu', Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                    const SizedBox(height: 12),
                    _buildField(_confirmController, 'Confirm Password', Icons.shield_outlined, obscure: true),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                        : AccentButton(label: 'Sign Up', onPressed: _handleSignUp),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: widget.onLogin,
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                            children: [
                              TextSpan(text: 'Sign In',
                                  style: AppTextStyles.bodySemiBold(14, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('By signing up, you agree to our Terms of Service.',
                          style: AppTextStyles.bodyRegular(10, color: AppColors.mutedForeground),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: AppDecorations.inputDecoration(
        hint: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.mutedForeground),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}

// ============================================
// FORGOT PASSWORD SCREEN
// ============================================
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Reset Password', style: AppTextStyles.headingBold(24)),
              const SizedBox(height: 8),
              Text(
                'Enter your LAU email and we\'ll send you a reset link.',
                style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_sent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppDecorations.inputDecoration(
                    hint: 'your.name@lau.edu.lb',
                    prefixIcon: const Icon(Icons.mail_outline, size: 18, color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Send Reset Link',
                  onPressed: () async {
                    await _authService.sendPasswordReset(_emailController.text);
                    setState(() => _sent = true);
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
                      const SizedBox(height: 8),
                      Text('Reset link sent!',
                          style: AppTextStyles.bodySemiBold(15, color: AppColors.success)),
                      Text('Check your inbox at ${_emailController.text}',
                          style: AppTextStyles.bodyRegular(13, color: AppColors.mutedForeground),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: widget.onBack,
                child: Text('Back to Sign In',
                    style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// ============================================
// VERIFY EMAIL SCREEN
// ============================================
class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onBack;
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.onVerified,
    required this.onBack,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  int _countdown = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_countdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown--);
    }
    if (mounted) setState(() => _canResend = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline, size: 48, color: Colors.white),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Check Your Inbox', style: AppTextStyles.headingBold(24)),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We sent a verification email to\n',
                  style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                  children: [
                    TextSpan(text: widget.email,
                        style: AppTextStyles.bodySemiBold(14, color: AppColors.primary)),
                    TextSpan(text: '. Tap it to activate your account.',
                        style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedPillButton(
                label: 'Resend Email',
                onPressed: _canResend ? () {
                  setState(() { _countdown = 45; _canResend = false; });
                  _startCountdown();
                } : () {},
                borderColor: _canResend ? AppColors.primary : AppColors.muted,
                textColor: _canResend ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(height: 12),
              if (!_canResend)
                Text(
                  'Resend in 0:${_countdown.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bodySemiBold(14, color: AppColors.accent),
                ),
              const SizedBox(height: 32),
              GradientButton(label: 'I\'ve verified — Continue', onPressed: widget.onVerified),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onBack,
                child: Text('Wrong email? Go back',
                    style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PERMISSIONS SCREEN
// Simplified to trigger native OS dialogs directly
// ============================================
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  final VoidCallback onSkip;

  const PermissionsScreen({
    super.key,
    required this.onPermissionsGranted,
    required this.onSkip,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      // 1. Request Location Permission (Native System Dialog)
      await Permission.locationWhenInUse.request();

      // 2. Request Bluetooth Permissions (Native System Dialogs)
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      // 3. Turn on Bluetooth Hardware (Native System Dialog on Android)
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          debugPrint('BT turnOn failed: $e');
        }
      }

      // 4. Trigger Native Location Service ON Dialog (GPS)
      // Using the 'location' package to trigger the specific system popup
      loc.Location location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        // This triggers the native OS "Turn on Location" dialog
        await location.requestService();
      }
    } catch (e) {
      debugPrint('Permission error: $e');
    }

    if (mounted) {
      setState(() => _isRequesting = false);
      // Proceed to the next screen
      widget.onPermissionsGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_audio_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 32),
              Text(
                'Enable Bluetooth & Location',
                style: AppTextStyles.headingBold(22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Campus Navigator needs these to find your location inside Nicol Hall.',
                style: AppTextStyles.bodyRegular(15, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isRequesting)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                AccentButton(
                  label: 'Grant Access',
                  onPressed: _requestPermissions,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => SystemNavigator.pop(), // Per user request: Exit app if skip
                child: Text('Exit App', style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// SYSTEM PERMISSION TRIGGERS
// ============================================
class PermissionDialogs {
  /// Directly triggers native OS prompts
  static Future<void> showPermissionDialogs(BuildContext context) async {
    // Request Location Permission
    await Permission.locationWhenInUse.request();
    
    // Request Bluetooth permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // Trigger Bluetooth Power ON
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('BT turnOn error: $e');
      }
    }

    // Trigger Native Location Service Dialog
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      await location.requestService();
    }
  }
}
