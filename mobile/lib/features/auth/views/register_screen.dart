import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authVm = context.read<AuthViewModel>();
    final email = _emailController.text.trim();

    final success = await authVm.register(
      email: email,
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (success && mounted) {
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Branding ─────────────────────────────────────────────
                _buildHeader(theme),
                const SizedBox(height: 32),

                // ── Form Card ────────────────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
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

                            // ── Full Name ────────────────────────────────
                            TextFormField(
                              controller: _fullNameController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên',
                                hintText: 'Nguyễn Văn A',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập họ và tên';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ── Phone ────────────────────────────────────
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                hintText: '0901234567',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ── Email ────────────────────────────────────
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'example@email.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(v.trim())) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // ── Password ─────────────────────────────────
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (v.trim().length < 8) {
                                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // ── Submit ───────────────────────────────────
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    authVm.isLoading ? null : _handleSubmit,
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
                                          Text('Tạo tài khoản'),
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

                // ── Login link ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bạn đã có tài khoản? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Đăng nhập tại đây',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text('Tham gia CityVoice', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Cùng góp phần làm TP.HCM tốt đẹp hơn',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
