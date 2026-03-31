import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_category.dart';
import '../models/upsert_category_request.dart';
import '../viewmodels/admin_view_model.dart';

class AdminCategoryListScreen extends StatefulWidget {
  const AdminCategoryListScreen({super.key});

  @override
  State<AdminCategoryListScreen> createState() =>
      _AdminCategoryListScreenState();
}

class _AdminCategoryListScreenState extends State<AdminCategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Danh mục sự cố'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm danh mục',
            onPressed: () => _showCategoryForm(context, null),
          ),
        ],
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          if (vm.categoriesState == ViewState.loading &&
              vm.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.categoriesState == ViewState.error && vm.categories.isEmpty) {
            return _buildErrorState(theme, vm);
          }

          if (vm.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64,
                      color: AppColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có danh mục nào',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.loadCategories,
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vm.categories.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final cat = vm.categories[index];
                return _CategoryListTile(
                  category: cat,
                  onTap: () => _showCategoryForm(context, cat),
                  onToggle: (_) => _handleToggleCategory(context, vm, cat),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCategoryForm(BuildContext context, AdminCategory? existing) {
    final vm = context.read<AdminViewModel>();
    vm.clearActionError();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: _CategoryFormSheet(existing: existing),
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
            vm.categoriesError ?? 'Đã xảy ra lỗi',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => vm.loadCategories(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleCategory(
    BuildContext context,
    AdminViewModel vm,
    AdminCategory category,
  ) async {
    final success = await vm.toggleCategoryActive(category);
    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.actionError ?? 'Không thể cập nhật trạng thái'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Category List Tile ──────────────────────────────────────────────────────

class _CategoryListTile extends StatelessWidget {
  final AdminCategory category;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _CategoryListTile({
    required this.category,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = category.active;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _iconForKey(category.iconKey),
          color: isActive ? AppColors.primary : AppColors.textHint,
          size: 22,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.textPrimary : AppColors.textHint,
          decoration: isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Text(
        category.slug,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: isActive,
        onChanged: (v) => onToggle(v),
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  /// Maps common iconKey strings to Material icons.
  IconData _iconForKey(String? key) {
    return switch (key) {
      'road' => Icons.add_road_rounded,
      'light' => Icons.lightbulb_outline_rounded,
      'tree' => Icons.park_outlined,
      'water' => Icons.water_drop_outlined,
      'trash' => Icons.delete_outline_rounded,
      'building' => Icons.apartment_rounded,
      'bridge' => Icons.architecture_rounded,
      'sign' => Icons.signpost_outlined,
      'electric' => Icons.electric_bolt_outlined,
      'sidewalk' => Icons.directions_walk_rounded,
      'drain' => Icons.waves_rounded,
      'noise' => Icons.volume_up_outlined,
      'fire' => Icons.local_fire_department_outlined,
      'other' => Icons.more_horiz_rounded,
      _ => Icons.category_outlined,
    };
  }
}

// ─── Category Create/Edit Bottom Sheet ──────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final AdminCategory? existing;

  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _iconKeyCtrl;
  late bool _active;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _slugCtrl = TextEditingController(text: widget.existing?.slug ?? '');
    _iconKeyCtrl = TextEditingController(text: widget.existing?.iconKey ?? '');
    _active = widget.existing?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _iconKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _isEditing ? 'Chỉnh sửa danh mục' : 'Tạo danh mục mới',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục *',
                    hintText: 'Ví dụ: Ổ gà / Mặt đường hư hỏng',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên danh mục';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Slug field
                Consumer<AdminViewModel>(
                  builder: (context, vm, _) {
                    final slugError = vm.actionError != null &&
                            vm.actionError!.contains('Slug')
                        ? vm.actionError
                        : null;

                    return TextFormField(
                      controller: _slugCtrl,
                      decoration: InputDecoration(
                        labelText: 'Slug *',
                        hintText: 'hu-hong-duong-bo',
                        helperText:
                            'Ký tự thường, không dấu, dùng dấu gạch ngang',
                        helperMaxLines: 2,
                        errorText: slugError,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập slug';
                        }
                        if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                          return 'Slug chỉ chứa ký tự thường, số và dấu gạch ngang';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // IconKey field
                TextFormField(
                  controller: _iconKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon Key',
                    hintText: 'road, light, tree, water, trash...',
                    helperText: 'Từ khóa cho icon (xem danh sách hỗ trợ)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Active toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Hiển thị cho người dùng',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit button
                Consumer<AdminViewModel>(
                  builder: (context, vm, _) {
                    final isLoading = vm.actionState == ViewState.loading;

                    return FilledButton(
                      onPressed: isLoading ? null : () => _submit(vm),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Cập nhật' : 'Tạo mới',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AdminViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    vm.clearActionError();

    final request = UpsertCategoryRequest(
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim(),
      iconKey:
          _iconKeyCtrl.text.trim().isEmpty ? null : _iconKeyCtrl.text.trim(),
      active: _active,
    );

    bool success;
    if (_isEditing) {
      success = await vm.updateCategory(widget.existing!.id, request);
    } else {
      success = await vm.createCategory(request);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Đã cập nhật danh mục' : 'Đã tạo danh mục mới',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // On error (e.g. 409): stay open — actionError is shown via Consumer.
  }
}
