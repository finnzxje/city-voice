import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../viewmodels/admin_view_model.dart';

/// Admin screen for managing user roles.
///
/// Displays a list of all users with role dropdowns.
/// Changing a role shows a confirmation dialog before calling the API.
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.select<AuthViewModel, String?>(
      (authVm) => authVm.user?.id,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          if (vm.usersState == ViewState.loading && vm.users.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.usersState == ViewState.error && vm.users.isEmpty) {
            return _buildErrorState(theme, vm);
          }

          final users = vm.filteredUsers;

          return Column(
            children: [
              // ── Search & Filter Header ──────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: vm.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        const Text(
                          'Vai trò:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: vm.roleFilter,
                                isExpanded: true,
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Tất cả vai trò'),
                                  ),
                                  ...vm.availableRoles
                                      .map((role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(_roleLabel(role)),
                                          )),
                                ],
                                onChanged: vm.setRoleFilter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── User List ───────────────────────────────────────────────────
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search_rounded,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy người dùng nào',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: vm.loadUsers,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 72,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final initials = user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: _avatarColor(user.role),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!user.isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.textHint
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Đã vô hiệu',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textHint,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: DropdownButton<String>(
                                value: vm.availableRoles.contains(user.role)
                                    ? user.role
                                    : null,
                                underline: const SizedBox.shrink(),
                                borderRadius: BorderRadius.circular(12),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _roleColor(user.role),
                                ),
                                items: vm.availableRoles.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(
                                      _roleLabel(role),
                                      style: TextStyle(
                                        color: _roleColor(role),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: user.id == currentUserId
                                    ? null
                                    : (newRole) {
                                        if (newRole == null ||
                                            newRole == user.role) {
                                          return;
                                        }
                                        _showConfirmDialog(
                                          context,
                                          vm,
                                          user.id,
                                          user.fullName,
                                          user.role,
                                          newRole,
                                        );
                                      },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    AdminViewModel vm,
    String userId,
    String fullName,
    String currentRole,
    String newRole,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận đổi quyền'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn đổi quyền của '),
              TextSpan(
                text: fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' từ '),
              TextSpan(
                text: _roleLabel(currentRole),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _roleColor(currentRole),
                ),
              ),
              const TextSpan(text: ' thành '),
              TextSpan(
                text: _roleLabel(newRole),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _roleColor(newRole),
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.updateUserRole(userId, newRole).then((success) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã cập nhật quyền thành công'
                        : vm.actionError ?? 'Đã xảy ra lỗi'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, AdminViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            vm.usersError ?? 'Đã xảy ra lỗi',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => vm.loadUsers(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String role) {
    return switch (UserRole.fromValue(role)) {
      UserRole.admin => const Color(0xFFD32F2F),
      UserRole.manager => const Color(0xFF7B1FA2),
      UserRole.staff => const Color(0xFF1565C0),
      UserRole.citizen => AppColors.primary,
    };
  }

  Color _roleColor(String role) {
    return switch (UserRole.fromValue(role)) {
      UserRole.admin => const Color(0xFFD32F2F),
      UserRole.manager => const Color(0xFF7B1FA2),
      UserRole.staff => const Color(0xFF1565C0),
      UserRole.citizen => AppColors.primary,
    };
  }

  String _roleLabel(String role) {
    return UserRole.fromValue(role).managementLabel;
  }
}
