import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../bloc/print_order/print_order_bloc.dart';
import '../../bloc/print_order/print_order_state.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_state.dart';
import '../../bloc/purchase_request/purchase_request_bloc.dart';
import '../../bloc/purchase_request/purchase_request_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';
import '../../models/user_model.dart';

enum NavMenu {
  dashboard,
  vendors,
  purchaseRequests,
  printOrders,
  deliveryLogs,
  postOrders,
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
  final UserModel? userProfile;
  final bool isSuperAdmin;
  final bool isDesigner;

  const SideMenuDrawer({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
    required this.user,
    this.userProfile,
    required this.isSuperAdmin,
    this.isDesigner = false,
  });

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  bool _isPrintManagementExpanded = true;
  bool _isUserManagementExpanded = true;

  @override
  Widget build(BuildContext context) {
    final userPhone = widget.userProfile?.phone ?? widget.user.phoneNumber ?? '+91 7414055310';
    final roleName = widget.userProfile?.role ??
        (widget.isSuperAdmin ? 'Super Admin' : (widget.isDesigner ? 'Designer' : 'Printing Vendor'));
    final displayName = widget.userProfile?.name ?? roleName;

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
                      gradient: LinearGradient(
                        colors: widget.isDesigner
                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                            : [const Color(0xFF2563EB), const Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDesigner ? const Color(0xFFF59E0B) : const Color(0xFF2563EB))
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.isDesigner ? 'D' : 'P',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isDesigner ? 'PMS Designer' : 'PMS Admin',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
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
                  if (widget.isSuperAdmin || widget.isDesigner) ...[
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
                      // 1. Vendors (Admin only)
                      if (widget.isSuperAdmin)
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
                      // 2. Purchase Request (PR) - AVAILABLE TO BOTH ADMIN AND DESIGNER
                      BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                        builder: (context, state) {
                          final count =
                              state is PurchaseRequestLoaded ? state.requests.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.purchaseRequests,
                            icon: Icons.assignment_outlined,
                            label: widget.isDesigner ? 'Assigned PRs' : 'Purchase Request (PR)',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 2.5 Print Orders (PO) - AVAILABLE TO ADMIN, DESIGNER & VENDOR
                      BlocBuilder<PrintOrderBloc, PrintOrderState>(
                        builder: (context, state) {
                          final count =
                              state is PrintOrderLoaded ? state.printOrders.length : 0;
                          return _buildMenuItem(
                            menu: NavMenu.printOrders,
                            icon: Icons.print_outlined,
                            label: widget.isDesigner ? 'Print Orders' : 'Print Orders (PO)',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 2.6 Delivery Logs - AVAILABLE TO ADMIN
                      if (widget.isSuperAdmin)
                        BlocBuilder<PrintOrderBloc, PrintOrderState>(
                          builder: (context, state) {
                            final count = state is DeliveryLogsLoaded
                                ? state.deliveries.length
                                : 0;
                            return _buildMenuItem(
                              menu: NavMenu.deliveryLogs,
                              icon: Icons.inventory_2_outlined,
                              label: 'Delivery Logs',
                              badgeCount: count > 0 ? count : null,
                            );
                          },
                        ),
                      // 2.7 Post Orders - AVAILABLE TO ADMIN & DESIGNER
                      BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                        builder: (context, state) {
                          final count = state is PurchaseRequestLoaded
                              ? state.requests.where((r) => r.status == 'posted' || r.isPosted).length
                              : 0;
                          return _buildMenuItem(
                            menu: NavMenu.postOrders,
                            icon: Icons.campaign_outlined,
                            label: 'Post Orders',
                            badgeCount: count,
                          );
                        },
                      ),
                      // 3. Categories (Admin only)
                      if (widget.isSuperAdmin)
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
                      // 4. Product Types (Admin only)
                      if (widget.isSuperAdmin)
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
                      // 5. Wings Management (Admin only)
                      if (widget.isSuperAdmin)
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
                  ],

                  // --- SECTION 3: USER MANAGEMENT (Admin only) ---
                  if (widget.isSuperAdmin) ...[
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
                      color: widget.isDesigner
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                          : const Color(0xFF2563EB).withValues(alpha: 0.2),
                      border: Border.all(
                        color: widget.isDesigner
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : const Color(0xFF2563EB).withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isDesigner ? const Color(0xFFFCD34D) : const Color(0xFF60A5FA),
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
                          displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$roleName · $userPhone',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
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
            color: isSelected
                ? (widget.isDesigner ? const Color(0xFFD97706) : const Color(0xFF2563EB))
                : Colors.transparent,
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
                        ? (widget.isDesigner ? const Color(0xFFB45309) : const Color(0xFF1E40AF))
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
