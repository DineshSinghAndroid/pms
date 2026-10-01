import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_event.dart';
import '../../bloc/wing/wing_state.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/category/category_state.dart';
import '../../models/user_model.dart';
import '../../models/wing_model.dart';
import '../../models/category_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';

class UsersTabView extends StatefulWidget {
  final bool isSuperAdmin;
  final String? userPhone;

  const UsersTabView({super.key, this.isSuperAdmin = true, this.userPhone});

  @override
  State<UsersTabView> createState() => _UsersTabViewState();
}

class _UsersTabViewState extends State<UsersTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<UserBloc>().state;
      if (state is! UserLoaded || state.users.isEmpty) {
        debugPrint('👥 [UsersTabView] Auto-fetching users for phone: ${widget.userPhone}');
        context.read<UserBloc>().add(FetchUsersEvent(phone: widget.userPhone));
      }
      final catState = context.read<CategoryBloc>().state;
      if (catState is! CategoryLoaded || catState.categories.isEmpty) {
        context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
      }
      final wingState = context.read<WingBloc>().state;
      if (wingState is! WingLoaded || wingState.wings.isEmpty) {
        context.read<WingBloc>().add(const RefreshWingsEvent());
      }
    });
  }

  final List<String> _roles = [
    'All',
    'Superadmin',
    'manager',
    'vendor',
    'Digital Studio Incharge',
    'Digital Store Incharge',
    'Digital Studio Employee',
    'Designer',
    'Store Incharge',
    'Wing Incharge',
  ];

  final List<String> _assignableRoles = [
    'Superadmin',
    'manager',
    'vendor',
    'Digital Studio Incharge',
    'Digital Store Incharge',
    'Digital Studio Employee',
    'Designer',
    'Store Incharge',
    'Wing Incharge',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserForm(BuildContext context, {UserModel? user}) {
    final wingState = context.read<WingBloc>().state;
    if (wingState is! WingLoaded || wingState.wings.isEmpty) {
      context.read<WingBloc>().add(const RefreshWingsEvent());
    }
    List<int> selectedWingIds = user?.assignedWings.map((w) => w.id).toList() ?? [];

    final catState = context.read<CategoryBloc>().state;
    if (catState is! CategoryLoaded || catState.categories.isEmpty) {
      context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
    }
    List<int> selectedCategoryIds = user?.assignedCategories.map((c) => c.id).toList() ?? [];

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final initialRole = user?.role ?? 'manager';
    String selectedRole = _assignableRoles.firstWhere(
      (r) => r.toLowerCase() == initialRole.toLowerCase(),
      orElse: () => _assignableRoles.firstWhere(
        (r) => r == initialRole,
        orElse: () => 'manager',
      ),
    );
    bool isActive = user?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return GestureDetector(
              onTap: () => FocusScope.of(ctx).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PmsSheetHeader(
                      title: user != null
                          ? 'Edit System User'
                          : 'Add New System User',
                      subtitle: user != null
                          ? 'Update profile, role and access'
                          : 'Invite a teammate with OTP login',
                      onClose: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 8),

                    // Full Name
                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Full Name *',
                      hint: 'e.g. Ramesh Kumar',
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    _buildTextField(
                      controller: phoneCtrl,
                      label: 'Phone Number (Login OTP) *',
                      hint: '1234567890',
                      keyboardType: TextInputType.phone,
                      prefix: '+91 ',
                    ),
                    const SizedBox(height: 12),

                    // Email Address
                    _buildTextField(
                      controller: emailCtrl,
                      label: 'Email Address',
                      hint: 'user@princeeduhub.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Role Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Role *',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PmsTheme.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _assignableRoles.firstWhere(
                                (r) => r.toLowerCase() == selectedRole.toLowerCase(),
                                orElse: () => _assignableRoles.first,
                              ),
                              isExpanded: true,
                              dropdownColor: const Color(0xFFFFFFFF),
                              style: const TextStyle(
                                fontSize: 13,
                                color: PmsTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              items: _assignableRoles.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedRole = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (selectedRole == 'Wing Incharge') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Assigned Wing(s) *',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF134E4A),
                                  ),
                                ),
                                Text(
                                  'Select 1 or more',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PmsTheme.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<WingBloc, WingState>(
                              builder: (wCtx, wState) {
                                if (wState is WingLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: PmsTheme.teal),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Loading wings...', style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
                                      ],
                                    ),
                                  );
                                }
                                final wings = wState is WingLoaded ? wState.wings : <WingModel>[];
                                if (wings.isEmpty) {
                                  return Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'No wings loaded. Please refresh wings.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: PmsTheme.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.read<WingBloc>().add(const RefreshWingsEvent()),
                                        child: const Text('Retry', style: TextStyle(fontSize: 11, color: PmsTheme.teal, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                }
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: wings.map((w) {
                                    final isSelected = selectedWingIds.contains(w.id);
                                    return FilterChip(
                                      label: Text(
                                        w.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : PmsTheme.textPrimary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: PmsTheme.teal,
                                      backgroundColor: PmsTheme.glassSurface,
                                      checkmarkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isSelected ? PmsTheme.teal : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setModalState(() {
                                          if (selected) {
                                            selectedWingIds.add(w.id);
                                          } else {
                                            selectedWingIds.remove(w.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Assigned Category(ies) *',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                Text(
                                  'Multi-select allowed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Select categories this Wing Incharge can view and choose products from during PR creation.',
                              style: TextStyle(
                                fontSize: 10,
                                color: PmsTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<CategoryBloc, CategoryState>(
                              builder: (cCtx, cState) {
                                if (cState is CategoryLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Loading categories...', style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
                                      ],
                                    ),
                                  );
                                }
                                final categories = cState is CategoryLoaded ? cState.categories : <CategoryModel>[];
                                if (categories.isEmpty) {
                                  return Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'No categories available.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: PmsTheme.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.read<CategoryBloc>().add(const RefreshCategoriesEvent()),
                                        child: const Text('Retry', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                }
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: categories.map((c) {
                                    final isSelected = selectedCategoryIds.contains(c.id);
                                    return FilterChip(
                                      label: Text(
                                        c.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.white : PmsTheme.textPrimary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF16A34A),
                                      backgroundColor: PmsTheme.glassSurface,
                                      checkmarkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setModalState(() {
                                          if (selected) {
                                            selectedCategoryIds.add(c.id);
                                          } else {
                                            selectedCategoryIds.remove(c.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Account Active Checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            activeColor: PmsTheme.primary,
                            onChanged: (val) {
                              setModalState(() {
                                isActive = val ?? true;
                              });
                            },
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PmsTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'User can log into the PMS application',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PmsTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final email = emailCtrl.text.trim();

                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill Full Name and Phone Number',
                              ),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }

                        if (selectedRole == 'Wing Incharge' && selectedWingIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one assigned wing for the Wing Incharge.',
                              ),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }

                        final payload = <String, dynamic>{
                          'name': name,
                          'phone': phone,
                          'email': email.isNotEmpty ? email : null,
                          'role': selectedRole,
                          'is_active': isActive,
                        };

                        if (selectedRole == 'Wing Incharge') {
                          payload['wing_ids'] = selectedWingIds;
                          payload['category_ids'] = selectedCategoryIds;
                        }

                        if (user != null) {
                          context.read<UserBloc>().add(
                            UpdateUserEvent(userId: user.id, payload: payload, phone: widget.userPhone),
                          );
                        } else {
                          context.read<UserBloc>().add(
                            CreateUserEvent(payload, phone: widget.userPhone),
                          );
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              user != null
                                  ? '✓ User updated!'
                                  : '✓ User created!',
                            ),
                            backgroundColor: Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PmsTheme.primary,
                        foregroundColor: Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        user != null ? 'Save Changes' : 'Create User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    if (user.phone == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the primary Superadmin account.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete User',
            style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete user "${user.name}"?',
            style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: PmsTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<UserBloc>().add(DeleteUserEvent(user.id, phone: widget.userPhone));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ User deleted'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC2626),
                foregroundColor: Color(0xFFFFFFFF),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: PmsTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
            prefixText: prefix,
            prefixStyle: const TextStyle(
              color: PmsTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: PmsTheme.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: PmsTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.trim().toLowerCase()) {
      case 'superadmin':
      case 'super admin':
      case 'super_admin':
      case 'admin':
        return PmsTheme.primary; // Purple
      case 'vendor':
        return const Color(0xFF059669); // Emerald
      case 'manager':
        return const Color(0xFF2563EB); // Blue
      case 'digital studio incharge':
      case 'digital_studio_incharge':
        return PmsTheme.teal; // Teal
      case 'digital store incharge':
      case 'digital_store_incharge':
      case 'digital store inchrage':
        return const Color(0xFF0D9488); // Cyan/Teal
      case 'digital studio employee':
      case 'digital_studio_employee':
      case 'cameraman':
      case 'video editor':
      case 'drone operator':
      case 'photographer':
        return const Color(0xFF0284C7); // Sky / Cyan Blue
      case 'designer':
        return const Color(0xFFD97706); // Amber
      case 'store incharge':
      case 'store_incharge':
        return const Color(0xFF6366F1); // Indigo
      case 'wing incharge':
      case 'wing_incharge':
      case 'counsellor':
      case 'counselor':
        return const Color(0xFFEA580C); // Orange
      default:
        return PmsTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: PmsTheme.primary,
      onRefresh: () async {
        context.read<UserBloc>().add(RefreshUsersEvent(phone: widget.userPhone));
        await context.read<UserBloc>().stream.firstWhere(
              (state) => state is UserLoaded || state is UserError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          PmsPageHeader(
            icon: Icons.people_alt_rounded,
            title: 'Users & Roles',
            subtitle: 'Directory of system accounts and access',
            action: widget.isSuperAdmin
                ? FilledButton.icon(
                    onPressed: () => _showUserForm(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add User'),
                  )
                : null,
          ),

          const SizedBox(height: 18),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
            style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, phone or role...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          // Role Filter Chips Horizontal Scroll
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final role = _roles[index];
                return PmsFilterChip(
                  label: role,
                  selected: _selectedRoleFilter == role,
                  onSelected: (_) {
                    setState(() => _selectedRoleFilter = role);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // User Cards List
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoading) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }

              if (state is UserError) {
                return GlassCard(
                  backgroundColor: const Color(0xFFFEF2F2),
                  border: Border.all(
                    color: PmsTheme.error.withValues(alpha: 0.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Couldn’t load users',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.errorMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          context.read<UserBloc>().add(
                                FetchUsersEvent(phone: widget.userPhone),
                              );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PmsTheme.error,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is UserLoaded) {
                final users = state.users.where((u) {
                  final uRole = u.role.toLowerCase().trim();
                  final filterRole = _selectedRoleFilter.toLowerCase().trim();

                  final matchesQuery =
                      _searchQuery.isEmpty ||
                      u.name.toLowerCase().contains(_searchQuery) ||
                      u.phone.toLowerCase().contains(_searchQuery) ||
                      (u.email?.toLowerCase().contains(_searchQuery) ??
                          false) ||
                      uRole.contains(_searchQuery);

                  bool matchesRole = filterRole == 'all' || uRole == filterRole;

                  if (!matchesRole) {
                    if (filterRole == 'digital studio employee') {
                      matchesRole = uRole == 'digital studio employee' ||
                          uRole == 'digital_studio_employee' ||
                          uRole == 'cameraman' ||
                          uRole == 'video editor' ||
                          uRole == 'drone operator' ||
                          uRole == 'photographer';
                    } else if (filterRole == 'digital store incharge') {
                      matchesRole = uRole == 'digital store incharge' ||
                          uRole == 'digital_store_incharge' ||
                          uRole == 'digital store inchrage';
                    } else if (filterRole == 'wing incharge') {
                      matchesRole = uRole == 'wing incharge' ||
                          uRole == 'wing_incharge' ||
                          uRole == 'counsellor' ||
                          uRole == 'counselor';
                    } else if (filterRole == 'digital studio incharge') {
                      matchesRole = uRole == 'digital studio incharge' ||
                          uRole == 'digital_studio_incharge';
                    } else if (filterRole == 'store incharge') {
                      matchesRole = uRole == 'store incharge' ||
                          uRole == 'store_incharge';
                    } else if (filterRole == 'superadmin') {
                      matchesRole = uRole == 'superadmin' ||
                          uRole == 'super admin' ||
                          uRole == 'super_admin' ||
                          uRole == 'admin';
                    }
                  }

                  return matchesQuery && matchesRole;
                }).toList();

                if (users.isEmpty) {
                  return PmsEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No matching users',
                    subtitle:
                        'Try another search or role filter, or add a new user.',
                    actionLabel: widget.isSuperAdmin ? 'Add User' : null,
                    onAction: widget.isSuperAdmin
                        ? () => _showUserForm(context)
                        : null,
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(context, user);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final roleColor = _getRoleColor(user.role);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      roleColor,
                      roleColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID #${user.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PmsStatusChip(label: user.role, color: roleColor),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.phone_iphone_rounded,
                color: PmsTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '+91 ${user.phone}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.isSuperAdmin && !user.isSuperAdmin
                    ? () {
                        context.read<UserBloc>().add(
                              ToggleUserActiveEvent(
                                user.id,
                                phone: widget.userPhone,
                              ),
                            );
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: PmsStatusChip(
                  label: user.isActive ? 'Active' : 'Inactive',
                  color: user.isActive ? PmsTheme.success : PmsTheme.error,
                  icon: user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                ),
              ),
            ],
          ),

          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: PmsTheme.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PmsTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (user.assignedWings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.assignedWings.map((w) {
                return PmsStatusChip(
                  label: w.name,
                  color: PmsTheme.teal,
                  icon: Icons.apartment_rounded,
                );
              }).toList(),
            ),
          ],
          if (user.assignedCategories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.assignedCategories.map((c) {
                return PmsStatusChip(
                  label: c.name,
                  color: const Color(0xFF16A34A),
                  icon: Icons.category_rounded,
                );
              }).toList(),
            ),
          ],

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit user',
                  onPressed: () => _showUserForm(context, user: user),
                ),
                if (!user.isSuperAdmin) ...[
                  const SizedBox(width: 8),
                  PmsIconAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete user',
                    color: PmsTheme.error,
                    onPressed: () => _confirmDelete(context, user),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
