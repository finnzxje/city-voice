import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Form state ─────────────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCitizenOtpMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _resetForm();
    }
  }

  void _resetForm() {
    _passwordController.clear();
    _otpController.clear();
    _isCitizenOtpMode = false;
    context.read<AuthViewModel>()
      ..clearMessages()
      ..resetOtpState();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Submit handler ─────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authVm = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final otp = _otpController.text.trim();
    final isCitizen = _tabController.index == 0;

    bool success = false;

    if (isCitizen) {
      if (_isCitizenOtpMode) {
        // OTP login flow
        if (!authVm.otpSent) {
          await authVm.requestLoginOtp(email: email);
          return; // Wait for OTP input
        } else {
          success = await authVm.verifyLoginOtp(email: email, otp: otp);
        }
      } else {
        // Password login
        success =
            await authVm.loginWithPassword(email: email, password: password);
        // Check for 403 (unverified account)
        if (!success && authVm.errorMessage != null && mounted) {
          final error = authVm.errorMessage!;
          if (error.toLowerCase().contains('xác thực') ||
              error.toLowerCase().contains('verify') ||
              error.toLowerCase().contains('active')) {
            context.push('/verify-email?email=${Uri.encodeComponent(email)}');
            return;
          }
        }
      }
    } else {
      // Staff login
      success = await authVm.staffLogin(email: email, password: password);
    }

    if (success && mounted) {
      context.go(authVm.user?.homeRoute ?? UserRole.citizen.homeRoute);
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
                // ── Logo / Branding ──────────────────────────────────────
                _buildLogo(theme),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Tabs ───────────────────────────────────────────
                      _buildTabs(theme),

                      // ── Form body ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        child: _buildForm(theme),
                      ),
                    ],
                  ),
                ),

                // ── Register Link (citizen only) ─────────────────────────
                _buildRegisterLink(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLogo(ThemeData theme) {
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
            Icons.location_city_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chào mừng trở lại',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng nhập vào CityVoice',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? AppColors.border,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 2.5,
        labelStyle: theme.textTheme.titleSmall,
        tabs: const [
          Tab(text: 'Cư dân'),
          Tab(text: 'Cán bộ'),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Error / Success messages ─────────────────────────────
              if (authVm.errorMessage != null) ...[
                _buildMessageBanner(
                  message: authVm.errorMessage!,
                  icon: Icons.error_outline_rounded,
                  bgColor: AppColors.statusRejectedBg,
                  fgColor: AppColors.error,
                ),
                const SizedBox(height: 16),
              ],
              if (authVm.successMessage != null) ...[
                _buildMessageBanner(
                  message: authVm.successMessage!,
                  icon: Icons.check_circle_outline_rounded,
                  bgColor: AppColors.statusResolvedBg,
                  fgColor: AppColors.success,
                ),
                const SizedBox(height: 16),
              ],

              // ── Email field ──────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !authVm.otpSent,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Password field (password modes) ──────────────────────
              if (!_isCitizenOtpMode || _tabController.index == 1) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // ── OTP field (OTP mode, after sent) ─────────────────────
              if (_isCitizenOtpMode && authVm.otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mã OTP',
                    hintText: '------',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) {
                      return 'Vui lòng nhập mã OTP 6 số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // ── Toggle Password / OTP (citizen only) ─────────────────
              if (_tabController.index == 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCitizenOtpMode = !_isCitizenOtpMode;
                      });
                      authVm
                        ..clearMessages()
                        ..resetOtpState();
                      _otpController.clear();
                      _passwordController.clear();
                    },
                    child: Text(
                      _isCitizenOtpMode
                          ? 'Đăng nhập bằng mật khẩu'
                          : 'Đăng nhập nhanh bằng OTP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // ── Submit button ────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: authVm.isLoading ? null : _handleSubmit,
                  child: authVm.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_submitLabel),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _submitLabel {
    if (_tabController.index == 0 && _isCitizenOtpMode) {
      final authVm = context.read<AuthViewModel>();
      return authVm.otpSent ? 'Xác nhận OTP' : 'Gửi mã OTP';
    }
    return 'Đăng nhập';
  }

  Widget _buildRegisterLink(ThemeData theme) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index != 0) return const SizedBox(height: 16);
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chưa có tài khoản? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  'Đăng ký ngay',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBanner({
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
        border: Border(
          left: BorderSide(color: fgColor, width: 3.5),
        ),
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
