import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/auth_view_model.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.verifyEmail(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (success && mounted) {
      context.go('/login');
    }
  }

  Future<void> _handleResend() async {
    final authVm = context.read<AuthViewModel>();
    await authVm.resendVerification(email: widget.email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Guard: if no email, redirect back to register.
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/register');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ─────────────────────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.statusResolvedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Xác minh email của bạn',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Chúng tôi vừa gửi một mã 6 số đến\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Card ─────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerTheme.color ?? AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Consumer<AuthViewModel>(
                    builder: (context, authVm, _) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Messages ─────────────────────────────────
                            if (authVm.errorMessage != null) ...[
                              _buildBanner(
                                message: authVm.errorMessage!,
                                icon: Icons.error_outline_rounded,
                                bgColor: AppColors.statusRejectedBg,
                                fgColor: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (authVm.successMessage != null &&
                                authVm.errorMessage == null) ...[
                              _buildBanner(
                                message: authVm.successMessage!,
                                icon: Icons.check_circle_outline_rounded,
                                bgColor: AppColors.statusResolvedBg,
                                fgColor: AppColors.success,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── OTP Input ────────────────────────────────
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: '------',
                                counterText: '',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length != 6) {
                                  return 'Vui lòng nhập mã OTP 6 số';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Verify Button ───────────────────────────
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    authVm.isLoading ? null : _handleVerify,
                                child: authVm.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Xác minh Email'),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Resend section ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Consumer<AuthViewModel>(
                    builder: (context, authVm, _) {
                      return Column(
                        children: [
                          Text(
                            'Bạn chưa nhận được mã?',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: authVm.isLoading ? null : _handleResend,
                            icon: authVm.isLoading
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Gửi lại mã xác minh'),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ── Back to login ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Quay lại trang đăng nhập',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner({
    required String message,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: fgColor, width: 3.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
