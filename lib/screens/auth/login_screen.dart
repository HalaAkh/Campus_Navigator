import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/common/widgets.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        widget.onLoginSuccess();
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
            // Gradient hero
            GradientHeader(
              height: MediaQuery.of(context).size.height * 0.38,
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
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.location_on,
                            size: 100,
                            color: Color(0xFF007A6E)),
                      ),
                      const SizedBox(height: 12),
                      Text('Welcome Back!',
                          style: AppTextStyles.headingBold(22, color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('Sign in to start navigation',
                          style: AppTextStyles.bodyRegular(13, color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Card
            Transform.translate(
              offset: const Offset(0, 0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.bodyMedium(13,
                                color: AppColors.destructive)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppDecorations.inputDecoration(
                        hint: 'your.name@lau.edu',
                        prefixIcon: const Icon(Icons.mail_outline, size: 18,
                            color: AppColors.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: AppDecorations.inputDecoration(
                        hint: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18,
                            color: AppColors.mutedForeground),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.mutedForeground,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign In button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : GradientButton(label: 'Sign In', onPressed: _handleLogin),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: AppTextStyles.bodyRegular(12,
                                  color: AppColors.mutedForeground)),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Create Account
                    OutlinedPillButton(
                      label: 'Create Account',
                      onPressed: widget.onSignUp,
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password
                    Center(
                      child: TextButton(
                        onPressed: widget.onForgotPassword,
                        child: Text('Forgot Password?',
                            style: AppTextStyles.bodySemiBold(14,
                                color: AppColors.accent)),
                      ),
                    ),

                    Center(
                      child: Text(
                        'Restricted to @lau.edu & @lau.edu.lb accounts only',
                        style: AppTextStyles.bodyRegular(11,
                            color: AppColors.mutedForeground),
                      ),
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
}
