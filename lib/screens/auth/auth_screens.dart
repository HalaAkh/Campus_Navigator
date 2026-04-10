import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:provider/provider.dart';
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
                      const Icon(Icons.location_on, size: 48, color: Colors.white),
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
                    Text('Create Account ✨', style: AppTextStyles.headingBold(24)),
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
                    _buildField(_emailController, 'your.name@lau.edu.lb', Icons.mail_outline,
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
// Requests real Bluetooth + Location from device
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
  bool _btGranted = false;
  bool _locGranted = false;
  bool _isRequesting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // Check if already granted
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    final bt = await Permission.bluetoothScan.status;
    final loc = await Permission.locationWhenInUse.status;
    if (mounted) {
      setState(() {
        _btGranted = bt.isGranted;
        _locGranted = loc.isGranted;
      });
      // Auto-proceed if both already granted
      if (_btGranted && _locGranted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) widget.onPermissionsGranted();
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() { _isRequesting = true; _statusMessage = null; });

    try {
      // Step 1: Request Location first (required for BLE on Android)
      final locStatus = await Permission.locationWhenInUse.request();
      if (mounted) setState(() => _locGranted = locStatus.isGranted);

      // Step 2: Request Bluetooth permissions
      final btScan = await Permission.bluetoothScan.request();
      final btConnect = await Permission.bluetoothConnect.request();
      if (mounted) setState(() => _btGranted = btScan.isGranted && btConnect.isGranted);

      // Step 3: Check and enable Bluetooth hardware
      if (_btGranted) {
        try {
          // Check current Bluetooth state
          final btState = await FlutterBluePlus.adapterState.first;

          if (btState != BluetoothAdapterState.on) {
            // Bluetooth is off, try to turn it on
            try {
              await FlutterBluePlus.turnOn();
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) setState(() => _statusMessage = '✓ Bluetooth enabled');
            } catch (e) {
              // Fallback: Show message to enable manually
              if (mounted) {
                setState(() => _statusMessage = 'Please enable Bluetooth in Settings. We cannot do it automatically on your device.');
              }
            }
          } else {
            if (mounted) setState(() => _statusMessage = '✓ Bluetooth is already enabled');
          }
        } catch (e) {
          debugPrint('BT state check failed: $e');
        }
      }

      // Step 4: Check location service
      if (_locGranted) {
        try {
          final isLocationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
          if (!isLocationServiceEnabled) {
            if (mounted) {
              setState(() => _statusMessage = '⚠️ Location service is off. Enabling from Settings...');
            }
            // Try to open location settings
            await openAppSettings();
          } else {
            if (mounted) setState(() => _statusMessage = '✓ Location is enabled');
          }
        } catch (e) {
          debugPrint('Location check failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }

    setState(() => _isRequesting = false);

    // Check final status and retry or proceed
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      final btState = await FlutterBluePlus.adapterState.first;
      final btEnabled = btState == BluetoothAdapterState.on;
      final locEnabled = await Permission.locationWhenInUse.status.then((s) => s.isGranted);

      setState(() {
        _btGranted = _btGranted && btEnabled;
        _locGranted = _locGranted && locEnabled;
      });

      // Check final status
      if (_btGranted && _locGranted && btEnabled && locEnabled) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) widget.onPermissionsGranted();
      } else {
        // Show what's still missing
        if (mounted) {
          final missing = [];
          if (!btEnabled) missing.add('Bluetooth');
          if (!locEnabled) missing.add('Location');
          setState(() => _statusMessage =
            '❌ ${missing.join(' & ')} still disabled. Please manually enable in phone Settings.');
        }
      }
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final bothGranted = _btGranted && _locGranted;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Icon
                Container(
                width: 88, height: 88,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_searching, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),

              Text('Enable Access', style: AppTextStyles.headingBold(26)),
              const SizedBox(height: 8),
              Text(
                'We need to enable Bluetooth and Location to detect beacons and find your position inside Nicol Hall. Tap "Enable Permissions" below.',
                style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Why Location? explanation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Android requires Location permission to scan for Bluetooth beacons. Your location is NOT shared or stored.',
                        style: AppTextStyles.bodyRegular(12, color: AppColors.foreground),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Permission rows
              _PermissionRow(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                desc: 'Detect MOKO BLE beacons nearby',
                granted: _btGranted,
              ),
              const SizedBox(height: 10),
              _PermissionRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                desc: 'Required by Android for BLE scanning',
                granted: _locGranted,
              ),
              const SizedBox(height: 28),

              // Status message
              if (_statusMessage != null) ...[
      Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_statusMessage!,
          style: AppTextStyles.bodyRegular(12, color: AppColors.destructive),
          textAlign: TextAlign.center),
    ),
    const SizedBox(height: 12),
    // Open settings button
    OutlinedPillButton(
    label: 'Open Phone Settings',
    onPressed: _openSettings,
    borderColor: AppColors.primary,
    textColor: AppColors.primary,
    ),
    const SizedBox(height: 12),
    ],

    // Main button
    if (_isRequesting)
    const CircularProgressIndicator(color: AppColors.primary)
    else if (bothGranted)
    GradientButton(
    label: '✓ All Set — Continue',
    onPressed: widget.onPermissionsGranted,
    )
    else
    AccentButton(
    label: 'Enable Permissions',
    onPressed: _requestPermissions,
    ),

    const SizedBox(height: 12),
    TextButton(
    onPressed: widget.onSkip,
    child: Text(
    'Skip for now (navigation won\'t work)',
    style: AppTextStyles.bodyMedium(13, color: AppColors.mutedForeground),
    ),
    ),
    ],
    ),
    ),
    ));
    }
}


class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool granted;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.desc,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: granted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20,
                color: granted ? AppColors.success : AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySemiBold(14)),
                Text(desc, style: AppTextStyles.bodyRegular(11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: granted
                ? Container(
              key: const ValueKey('granted'),
              width: 28, height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            )
                : Container(
              key: const ValueKey('pending'),
              width: 28, height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.muted, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// MANDATORY PERMISSIONS SCREEN
// Shows on app startup - user MUST enable or app closes
// ============================================
class MandatoryPermissionsScreen extends StatefulWidget {
  final VoidCallback onPermissionsEnabled;

  const MandatoryPermissionsScreen({
    super.key,
    required this.onPermissionsEnabled,
  });

  @override
  State<MandatoryPermissionsScreen> createState() => _MandatoryPermissionsScreenState();
}

class _MandatoryPermissionsScreenState extends State<MandatoryPermissionsScreen> {
  bool _btGranted = false;
  bool _locGranted = false;
  bool _isRequesting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    final bt = await Permission.bluetoothScan.status;
    final loc = await Permission.locationWhenInUse.status;
    if (mounted) {
      setState(() {
        _btGranted = bt.isGranted;
        _locGranted = loc.isGranted;
      });
      // Auto-proceed if both already granted
      if (_btGranted && _locGranted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _verifyAndProceed();
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() { _isRequesting = true; _statusMessage = null; });

    try {
      // Step 1: Request Location first (required for BLE on Android)
      final locStatus = await Permission.locationWhenInUse.request();
      if (mounted) setState(() => _locGranted = locStatus.isGranted);

      // Step 2: Request Bluetooth permissions
      final btScan = await Permission.bluetoothScan.request();
      final btConnect = await Permission.bluetoothConnect.request();
      if (mounted) setState(() => _btGranted = btScan.isGranted && btConnect.isGranted);

      // Step 3: Check and enable Bluetooth hardware
      if (_btGranted) {
        try {
          final btState = await FlutterBluePlus.adapterState.first;
          if (btState != BluetoothAdapterState.on) {
            try {
              await FlutterBluePlus.turnOn();
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) setState(() => _statusMessage = '✓ Bluetooth enabled');
            } catch (e) {
              if (mounted) {
                setState(() => _statusMessage = '⚠️ Please manually enable Bluetooth in Settings');
              }
            }
          } else {
            if (mounted) setState(() => _statusMessage = '✓ Bluetooth is enabled');
          }
        } catch (e) {
          debugPrint('BT state check failed: $e');
        }
      }

      // Step 4: Verify location service
      if (_locGranted) {
        try {
          final isLocationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
          if (!isLocationServiceEnabled) {
            if (mounted) {
              setState(() => _statusMessage = '⚠️ Please enable Location in Settings');
            }
            await openAppSettings();
          } else {
            if (mounted) setState(() => _statusMessage = '✓ Location is enabled');
          }
        } catch (e) {
          debugPrint('Location check failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }

    setState(() => _isRequesting = false);

    // Verify everything is actually enabled
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      await _verifyAndProceed();
    }
  }

  Future<void> _verifyAndProceed() async {
    try {
      final btState = await FlutterBluePlus.adapterState.first;
      final btEnabled = btState == BluetoothAdapterState.on;
      final locEnabled = await Permission.locationWhenInUse.status.then((s) => s.isGranted);

      setState(() {
        _btGranted = btEnabled;
        _locGranted = locEnabled;
      });

      if (btEnabled && locEnabled) {
        // Everything enabled - proceed to app
        widget.onPermissionsEnabled();
      } else {
        // Missing something
        final missing = [];
        if (!btEnabled) missing.add('Bluetooth');
        if (!locEnabled) missing.add('Location');
        setState(() => _statusMessage =
          '❌ ${missing.join(' & ')} NOT enabled. Please enable in Settings to use the app.');
      }
    } catch (e) {
      debugPrint('Verification failed: $e');
      setState(() => _statusMessage = '⚠️ Permission check failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bothGranted = _btGranted && _locGranted;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header icon
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_searching, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Title
              Text('Enable Bluetooth & Location', style: AppTextStyles.headingBold(26)),
              const SizedBox(height: 8),
              Text(
                'Campus Navigator requires Bluetooth and Location to work. These are REQUIRED to use this app.',
                style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Location is needed for Bluetooth beacon scanning only. Your location data is NOT shared.',
                        style: AppTextStyles.bodyRegular(12, color: AppColors.foreground),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Permission status rows
              _PermissionRow(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                desc: 'Required for indoor navigation',
                granted: _btGranted,
              ),
              const SizedBox(height: 10),
              _PermissionRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                desc: 'Required for beacon detection',
                granted: _locGranted,
              ),
              const SizedBox(height: 28),

              // Status message
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage!.contains('✓')
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: AppTextStyles.bodyRegular(
                      12,
                      color: _statusMessage!.contains('✓') ? AppColors.success : AppColors.destructive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Main button
              if (_isRequesting)
                const CircularProgressIndicator(color: AppColors.primary)
              else if (bothGranted)
                GradientButton(
                  label: '✓ Permissions Enabled — Enter App',
                  onPressed: widget.onPermissionsEnabled,
                )
              else
                AccentButton(
                  label: 'Enable Permissions',
                  onPressed: _requestPermissions,
                ),

              const SizedBox(height: 24),

              // Warning about closing the app
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⚠️ Bluetooth and Location are REQUIRED. If you do not enable them, the app will not function.',
                  style: AppTextStyles.bodyRegular(11, color: AppColors.destructive),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

