import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';
import '../../models/user_model.dart';
import '../../models/wing_model.dart';
import '../../theme/pms_theme.dart';

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
    });
  }

  final List<String> _roles = [
    'All',
    'Superadmin',
    'vendor',
    'manager',
    'Digital Studio Incharge',
    'Designer',
    'Store Incharge',
    'Wing Incharge',
  ];

  final List<String> _assignableRoles = [
    'Superadmin',
    'vendor',
    'manager',
    'Digital Studio Incharge',
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
    final allWings = wingState is WingLoaded ? wingState.wings : <WingModel>[];
    List<int> selectedWingIds = user?.assignedWings.map((w) => w.id).toList() ?? [];

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    String selectedRole = user?.role ?? 'manager';
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user != null
                              ? 'Edit System User'
                              : 'Add New System User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: PmsTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                              value: _assignableRoles.contains(selectedRole)
                                  ? selectedRole
                                  : _assignableRoles.first,
                              isExpanded: true,
                              dropdownColor: Color(0xFFFFFFFF),
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
                            if (allWings.isEmpty)
                              const Text(
                                'No wings loaded. Please refresh wings.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PmsTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: allWings.map((w) {
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
        return PmsTheme.primary; // Purple
      case 'vendor':
        return Color(0xFF059669); // Emerald
      case 'manager':
        return PmsTheme.primary; // Blue
      case 'digital studio incharge':
        return PmsTheme.teal; // Teal
      case 'designer':
        return Color(0xFFD97706); // Amber
      case 'store incharge':
        return PmsTheme.primary; // Indigo
      case 'wing incharge':
        return Color(0xFFEA580C); // Orange
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
          // Section Header & Add Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: PmsTheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Users & Roles Directory',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (widget.isSuperAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showUserForm(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PmsTheme.primary,
                    foregroundColor: Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
            style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search users by name, phone or role...',
              hintStyle: const TextStyle(
                color: PmsTheme.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: PmsTheme.textSecondary,
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: PmsTheme.textSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PmsTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: PmsTheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Role Filter Chips Horizontal Scroll
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final role = _roles[index];
                final isSelected = _selectedRoleFilter == role;

                return ChoiceChip(
                  label: Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? PmsTheme.textPrimary : PmsTheme.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: PmsTheme.primary,
                  backgroundColor: PmsTheme.glassSurface,
                  side: BorderSide(
                    color: isSelected ? PmsTheme.primary : PmsTheme.glassBorder,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedRoleFilter = role;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // User Cards List
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoading) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: PmsTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              if (state is UserError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEF2F2).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFDC2626)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Failed to load users: ${state.errorMessage}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<UserBloc>().add(FetchUsersEvent(phone: widget.userPhone));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB91C1C),
                          foregroundColor: Color(0xFFFFFFFF),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is UserLoaded) {
                final users = state.users.where((u) {
                  final matchesQuery =
                      _searchQuery.isEmpty ||
                      u.name.toLowerCase().contains(_searchQuery) ||
                      u.phone.toLowerCase().contains(_searchQuery) ||
                      (u.email?.toLowerCase().contains(_searchQuery) ??
                          false) ||
                      u.role.toLowerCase().contains(_searchQuery);

                  final matchesRole =
                      _selectedRoleFilter == 'All' ||
                      u.role.toLowerCase() == _selectedRoleFilter.toLowerCase();

                  return matchesQuery && matchesRole;
                }).toList();

                if (users.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
                    ),
                    child: const Center(
                      child: Text(
                        'No matching users found.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: #${user.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      user.role,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: PmsTheme.glassBorder, height: 1),
          const SizedBox(height: 10),

          // Phone & Active toggle
          Row(
            children: [
              const Icon(
                Icons.phone_iphone_rounded,
                color: PmsTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '+91 ${user.phone}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PmsTheme.glassBorder,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.isSuperAdmin && !user.isSuperAdmin
                    ? () {
                        context.read<UserBloc>().add(
                          ToggleUserActiveEvent(user.id, phone: widget.userPhone),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Color(0xFFECFDF5).withValues(alpha: 0.4)
                        : Color(0xFFFEF2F2).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: user.isActive
                          ? Color(0xFF059669)
                          : Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: PmsTheme.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PmsTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (user.assignedWings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: user.assignedWings.map((w) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Text(
                    w.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PmsTheme.teal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Admin action buttons
          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showUserForm(context, user: user),
                  icon: const Icon(Icons.edit, size: 12),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PmsTheme.primary,
                    side: const BorderSide(color: PmsTheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (!user.isSuperAdmin) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, user),
                    icon: const Icon(Icons.delete_outline, size: 12),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFB91C1C),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
