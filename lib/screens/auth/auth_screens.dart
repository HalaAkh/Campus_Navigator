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

// SIGN UP SCREEN
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
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;
  final _authService = AuthService();

  // Password rule validation
  bool _isPasswordComplex(String password) {
    // Regex for: At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
    final regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Validation Order: Name -> Email -> Password -> Confirm
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (!_authService.isValidLauEmail(email)) {
      setState(() => _error = 'Please enter a valid LAU email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter a password.');
      return;
    }
    if (!_isPasswordComplex(password)) {
      setState(() => _error = 'Password must be at least 8 characters long and include an uppercase letter, a lowercase letter, a number, and a special character (!@#\$&*~).');
      return;
    }
    if (confirm.isEmpty) {
      setState(() => _error = 'Please confirm your password.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    final result = await _authService.signUp(name, email, password);
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
      backgroundColor: AppColors.card,
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
                      const SizedBox(height: 40),
                      Image.asset(
                        'assets/images/pin.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                      ),
                      const SizedBox(height: 12),
                      Text('Create Account',
                          style: AppTextStyles.headingBold(22, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('Join Campus Navigator - LAU Edition',
                          style: AppTextStyles.bodyRegular(13, color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withOpacity(0.1),
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
                  _buildField(_passwordController, 'Password', Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 12),
                  _buildField(_confirmController, 'Confirm Password', Icons.shield_outlined, isConfirm: true),
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
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {bool isPassword = false, bool isConfirm = false, TextInputType? keyboardType}) {

    final isVisible = isPassword ? _showPassword : (isConfirm ? _showConfirm : false);
    final obscure = (isPassword || isConfirm) && !isVisible;

    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium(15),
      decoration: AppDecorations.inputDecoration(
        hint: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.mutedForeground),
        suffixIcon: (isPassword || isConfirm)
            ? IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.mutedForeground,
          ),
          onPressed: () => setState(() {
            if (isPassword) _showPassword = !_showPassword;
            if (isConfirm) _showConfirm = !_showConfirm;
          }),
        )
            : null,
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

// FORGOT PASSWORD SCREEN
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _isLoading = false;
  String? _error;
  final _authService = AuthService();

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (!_authService.isValidLauEmail(email)) {
      setState(() => _error = 'Please enter a valid LAU email address.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    final result = await _authService.sendPasswordReset(email);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        setState(() => _sent = true);
      } else {
        setState(() => _error = result.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                ),
              ),
              const SizedBox(height: 60),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Reset Password', style: AppTextStyles.headingBold(24)),
              const SizedBox(height: 8),
              Text(
                'Enter your LAU email and we\'ll send you a reset link.',
                style: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: AppTextStyles.bodyMedium(13, color: AppColors.destructive)),
                ),
                const SizedBox(height: 16),
              ],
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
                _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : GradientButton(
                      label: 'Send Reset Link',
                      onPressed: _handleReset,
                    ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
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
              const SizedBox(height: 60),
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

// VERIFY EMAIL SCREEN
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
  Timer? _verificationTimer;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Check verification status every 3 seconds automatically
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    await _authService.reloadUser();
    if (_authService.isEmailVerified) {
      _verificationTimer?.cancel();
      if (mounted) {
        await _authService.saveUserToFirestore();
        widget.onVerified();
      }
    }
  }

  void _startCountdown() async {
    while (_countdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown--);
    }
    if (mounted) setState(() => _canResend = true);
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
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
                onPressed: _canResend ? () async {
                  await _authService.resendVerificationEmail();
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
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
              const SizedBox(height: 16),
              Text('Waiting for verification...',
                  style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground)),
              const SizedBox(height: 60),
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

// PERMISSIONS SCREEN
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
      // Request Location Permission
      PermissionStatus locStatus = await Permission.locationWhenInUse.request();
      if (locStatus != PermissionStatus.granted) {
        exit(0);
        return;
      }
      // Request precise/fine location
      PermissionStatus preciseStatus = await Permission.location.request();
      if (preciseStatus != PermissionStatus.granted) {
        exit(0);
        return;
      }

      // 2. Request Bluetooth Permissions (Native System Dialogs)
      Map<Permission, PermissionStatus> btStatuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      // IF DENIED -> EXIT
      if (btStatuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          btStatuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        exit(0);
      }

      // 3. Turn on Bluetooth Hardware (Native System Dialog on Android)
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
          // Small delay to allow the adapter state to update
          await Future.delayed(const Duration(milliseconds: 500));

          // IF USER CANCELS THE "TURN ON" DIALOG -> EXIT
          if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
            exit(0);
          }
        } catch (e) {
          // If the OS prevents turning on BT programmatically
          exit(0);
        }
      }

      // 4. Trigger Native Location Service ON Dialog (GPS)
      loc.Location location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          exit(0);
        }
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
                'Access Required',
                style: AppTextStyles.headingBold(22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This app uses your location and Bluetooth to navigate you accurately inside Nicol Hall. Navigation is not possible without these permissions.',
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
                onPressed: () => exit(0),
                child: Text('Exit App', style: AppTextStyles.bodyMedium(14, color: AppColors.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SYSTEM PERMISSION TRIGGERS
class PermissionDialogs {
  static Future<void> showPermissionDialogs(BuildContext context) async {
    // Request Location Permission
    PermissionStatus locStatus = await Permission.locationWhenInUse.request();
    if (locStatus != PermissionStatus.granted) {
      exit(0);
      return;
    }
    // Request precise/fine location (triggers Precise/Approximate dialog on Android 12+)
    PermissionStatus preciseStatus = await Permission.location.request();
    if (preciseStatus != PermissionStatus.granted) {
      exit(0);
      return;
    }

    // Request Bluetooth permissions
    Map<Permission, PermissionStatus> btStatuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    ].request();

    // EXIT IF BLUETOOTH PERMISSION DENIED
    if (btStatuses[Permission.bluetoothScan] != PermissionStatus.granted ||
    btStatuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
    exit(0);
    }

    if (Platform.isAndroid) {
    try {
    await FlutterBluePlus.turnOn();
    // Wait briefly for hardware state change
    await Future.delayed(const Duration(milliseconds: 500));

    // EXIT IF BLUETOOTH HARDWARE NOT TURNED ON
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
    exit(0);
    }
    } catch (e) {
    exit(0);
    }
    }
    // Trigger Native Location Service Dialog
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        exit(0);
      }
    }
  }
}
