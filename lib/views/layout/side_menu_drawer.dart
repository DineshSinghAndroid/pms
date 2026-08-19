import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';

enum NavMenu {
  dashboard,
  vendors,
  categories,
  productTypes,
  wings,
  users,
  settings,
}

class SideMenuDrawer extends StatefulWidget {
  final NavMenu selectedMenu;
  final Function(NavMenu) onMenuSelected;
  final User user;
  final bool isSuperAdmin;

  const SideMenuDrawer({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.user,
    required this.isSuperAdmin,
  });

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  bool _isPrintManagementExpanded = true;
  bool _isUserManagementExpanded = true;

  @override
  Widget build(BuildContext context) {
    final userPhone = widget.user.phoneNumber ?? '+91 7414055310';
    final roleName = widget.isSuperAdmin ? 'Super Admin' : 'Printing Vendor';

    return Container(
      width: 280,
      height: double.infinity,
      color: const Color(0xFF0F172A), // Slate 900
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= HEADER / BRANDING =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PMS Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'PRINCE EDUHUB',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= MENU ITEMS LIST =================
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                children: [
                  // --- SECTION 1: GENERAL ---
                  _buildSectionHeader('GENERAL'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    menu: NavMenu.dashboard,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                  ),

                  const SizedBox(height: 18),

                  // --- SECTION 2: PRINT MANAGEMENT (Expandable) ---
                  if (widget.isSuperAdmin) ...[
                    _buildExpandableHeading(
                      title: 'PRINT MANAGEMENT',
                      color: const Color(0xFF60A5FA),
                      isExpanded: _isPrintManagementExpanded,
                      onToggle: () {
                        setState(() {
                          _isPrintManagementExpanded =
                              !_isPrintManagementExpanded;
                        });
                      },
                    ),
                    if (_isPrintManagementExpanded) ...[
                      const SizedBox(height: 4),
                      // 1. Vendors
                      BlocBuilder<VendorBloc, VendorState>(
                        builder: (context, state) {
                          final count =
                              state is VendorLoaded ? state.vendors.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.vendors,
                            icon: Icons.storefront_outlined,
                            label: 'Vendors',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 2. Categories
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, state) {
                          final count =
                              state is CategoryLoaded ? state.categories.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.categories,
                            icon: Icons.category_outlined,
                            label: 'Categories',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 3. Product Types
                      BlocBuilder<ProductTypeBloc, ProductTypeState>(
                        builder: (context, state) {
                          final count =
                              state is ProductTypeLoaded ? state.productTypes.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.productTypes,
                            icon: Icons.layers_outlined,
                            label: 'Product Types',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 4. Wings Management
                      BlocBuilder<WingBloc, WingState>(
                        builder: (context, state) {
                          final count =
                              state is WingLoaded ? state.wings.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.wings,
                            icon: Icons.apartment_rounded,
                            label: 'Wings Management',
                            badgeCount: count,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 18),

                    // --- SECTION 3: USER MANAGEMENT (Expandable) ---
                    _buildExpandableHeading(
                      title: 'USER MANAGEMENT',
                      color: const Color(0xFFA78BFA),
                      isExpanded: _isUserManagementExpanded,
                      onToggle: () {
                        setState(() {
                          _isUserManagementExpanded =
                              !_isUserManagementExpanded;
                        });
                      },
                    ),
                    if (_isUserManagementExpanded) ...[
                      const SizedBox(height: 4),
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, state) {
                          final count =
                              state is UserLoaded ? state.users.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.users,
                            icon: Icons.people_outline_rounded,
                            label: 'Users & Roles',
                            badgeCount: count,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 18),
                  ],

                  // --- SECTION 4: SYSTEM ---
                  _buildSectionHeader('SYSTEM'),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    menu: NavMenu.settings,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                ],
              ),
            ),

            // ================= FOOTER / USER PROFILE =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1120),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        roleName.isNotEmpty ? roleName[0] : 'U',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userPhone,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFFDA4AF), size: 20),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildExpandableHeading({
    required String title,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required NavMenu menu,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = widget.selectedMenu == menu;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => widget.onMenuSelected(menu),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
