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
import '../../bloc/payment/payment_bloc.dart';
import '../../bloc/payment/payment_state.dart';
import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../bloc/news_tracking/news_tracking_bloc.dart';
import '../../bloc/news_tracking/news_tracking_state.dart';
import '../../models/user_model.dart';
import '../../widgets/app_logo.dart';
import '../legal/delete_account_dialog.dart';

enum NavMenu {
  dashboard,
  vendors,
  purchaseRequests,
  printOrders,
  deliveryLogs,
  payments,
  postOrders,
  digitalStudio,
  newsTracking,
  categories,
  productTypes,
  wings,
  users,
  settings,
  privacyPolicy,
  termsAndConditions,
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

  bool get isDigitalStudioIncharge =>
      widget.userProfile?.role == 'Digital Studio Incharge' ||
      widget.userProfile?.role.toLowerCase() == 'digital_studio_incharge';

  bool get isDigitalStudioEmployee =>
      widget.userProfile?.isDigitalStudioEmployee ?? false;

  bool get isWingIncharge =>
      widget.userProfile?.isWingIncharge ?? false;
  bool get isStoreIncharge =>
      widget.userProfile?.role == 'Store Incharge' ||
      widget.userProfile?.role.toLowerCase() == 'store incharge' ||
      widget.userProfile?.role.toLowerCase() == 'store_incharge';
  bool get isManager => widget.userProfile?.role.toLowerCase() == 'manager';

  @override
  Widget build(BuildContext context) {
    final userPhone =
        widget.userProfile?.phone ??
        widget.user.phoneNumber ??
        '+91 7414055310';
    final roleName =
        widget.userProfile?.role ??
        (widget.isSuperAdmin
            ? 'Super Admin'
            : (widget.isDesigner ? 'Designer' : 'Printing Vendor'));
    final displayName = widget.userProfile?.name ?? roleName;

    return Container(
      width: 280,
      height: double.infinity,
      color: Color(0xFFF8FAFC), // Slate 900
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= HEADER / BRANDING =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFFFFFFF))),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 40, showShadow: false),
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
                          color: Color(0xFF0F172A),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
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
                  if (!isDigitalStudioEmployee &&
                      (widget.isSuperAdmin ||
                          widget.isDesigner ||
                          isDigitalStudioIncharge ||
                          isWingIncharge ||
                          isStoreIncharge ||
                          isManager)) ...[
                    _buildExpandableHeading(
                      title: 'PRINT MANAGEMENT',
                      color: Color(0xFF2563EB),
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
                      // 1. Vendors (Admin & Manager)
                      if (widget.isSuperAdmin || isManager)
                        BlocBuilder<VendorBloc, VendorState>(
                          builder: (context, state) {
                            final count = state is VendorLoaded
                                ? state.vendors.length
                                : 0;
                            return _buildMenuItem(
                              menu: NavMenu.vendors,
                              icon: Icons.storefront_outlined,
                              label: 'Vendors',
                              badgeCount: count,
                            );
                          },
                        ),
                      // 2. Purchase Request (PR) - Excluded for Digital Studio Incharge & Employees
                      if (!isDigitalStudioIncharge && !isDigitalStudioEmployee)
                        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                          builder: (context, state) {
                            final count = state is PurchaseRequestLoaded
                                ? state.requests.length
                                : 0;
                            return _buildMenuItem(
                              menu: NavMenu.purchaseRequests,
                              icon: Icons.assignment_outlined,
                              label: widget.isDesigner
                                  ? 'Assigned PRs'
                                  : 'Purchase Request (PR)',
                              badgeCount: count,
                            );
                          },
                        ),
                      // 2.5 Print Orders (PO) - Excluded for Digital Studio Incharge & Employees
                      if (!isDigitalStudioIncharge &&
                          !isDigitalStudioEmployee &&
                          (widget.isSuperAdmin ||
                              widget.isDesigner ||
                              isStoreIncharge ||
                              isManager ||
                              isWingIncharge ||
                              widget.userProfile?.role.toLowerCase() ==
                                  'vendor'))
                        BlocBuilder<PrintOrderBloc, PrintOrderState>(
                          builder: (context, state) {
                            final count = state.printOrdersList.length;
                            return _buildMenuItem(
                              menu: NavMenu.printOrders,
                              icon: Icons.print_outlined,
                              label: widget.isDesigner
                                  ? 'Print Orders'
                                  : 'Print Orders (PO)',
                              badgeCount: count,
                            );
                          },
                        ),
                      // 2.6 Delivery Logs - AVAILABLE TO ADMIN, MANAGER & STORE INCHARGE
                      if (widget.isSuperAdmin || isManager || isStoreIncharge)
                        BlocBuilder<PrintOrderBloc, PrintOrderState>(
                          builder: (context, state) {
                            final count = state.deliveriesList.length;
                            return _buildMenuItem(
                              menu: NavMenu.deliveryLogs,
                              icon: Icons.inventory_2_outlined,
                              label: 'Delivery Logs',
                              badgeCount: count > 0 ? count : null,
                            );
                          },
                        ),
                      // 2.7 Add Payment - AVAILABLE TO ADMIN & MANAGER ONLY
                      if (widget.isSuperAdmin || isManager)
                        BlocBuilder<PaymentBloc, PaymentState>(
                          builder: (context, state) {
                            final count = state is PaymentLoaded
                                ? state.payments.length
                                : 0;
                            return _buildMenuItem(
                              menu: NavMenu.payments,
                              icon: Icons.payments_outlined,
                              label: 'Add Payment',
                              badgeCount: count > 0 ? count : null,
                            );
                          },
                        ),
                      // 2.8 Post Orders - AVAILABLE TO ADMIN, STUDIO INCHARGE, DESIGNER & MANAGER
                      if (widget.isSuperAdmin ||
                          isDigitalStudioIncharge ||
                          widget.isDesigner ||
                          isManager)
                        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                          builder: (context, state) {
                            final count = state is PurchaseRequestLoaded
                                ? state.requests
                                    .where(
                                      (r) =>
                                          r.status == 'posted' || r.isPosted,
                                    )
                                    .length
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
                            final count = state is CategoryLoaded
                                ? state.categories.length
                                : 0;
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
                            final count = state is ProductTypeLoaded
                                ? state.productTypes.length
                                : 0;
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
                            final count = state is WingLoaded
                                ? state.wings.length
                                : 0;
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

                  // --- SECTION 3: DIGITAL STUDIO ---
                  if (widget.userProfile?.canViewStudioModule ??
                      (!widget.isDesigner &&
                          (widget.isSuperAdmin ||
                              isDigitalStudioIncharge ||
                              isWingIncharge ||
                              isManager))) ...[
                    _buildSectionHeader('DIGITAL STUDIO'),
                    const SizedBox(height: 4),
                    BlocBuilder<DigitalStudioBloc, DigitalStudioState>(
                      builder: (context, state) {
                        final count = state is DigitalStudioLoaded
                            ? state.crewRequests.where((r) => r.status == 'pending').length
                            : 0;
                        return _buildMenuItem(
                          menu: NavMenu.digitalStudio,
                          icon: Icons.videocam_outlined,
                          label: 'Digital Studio',
                          badgeCount: count > 0 ? count : null,
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // --- SECTION 3.5: NEWS TRACKING (Superadmin & Manager only) ---
                  if (!isDigitalStudioEmployee && (widget.isSuperAdmin || isManager)) ...[
                    _buildSectionHeader('NEWS TRACKING'),
                    const SizedBox(height: 4),
                    BlocBuilder<NewsTrackingBloc, NewsTrackingState>(
                      builder: (context, state) {
                        final count = state is NewsTrackingLoaded
                            ? state.totalEntries
                            : 0;
                        return _buildMenuItem(
                          menu: NavMenu.newsTracking,
                          icon: Icons.newspaper_rounded,
                          label: 'News Tracking',
                          badgeCount: count > 0 ? count : null,
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // --- SECTION 4: USER MANAGEMENT (Admin only) ---
                  if (!isDigitalStudioEmployee && widget.isSuperAdmin) ...[
                    _buildExpandableHeading(
                      title: 'USER MANAGEMENT',
                      color: Color(0xFF2563EB),
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
                          final count = state is UserLoaded
                              ? state.users.length
                              : 0;
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
                  _buildMenuItem(
                    menu: NavMenu.privacyPolicy,
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                  ),
                  _buildMenuItem(
                    menu: NavMenu.termsAndConditions,
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () => DeleteAccountDialog.show(
                        context,
                        user: widget.user,
                        userProfile: widget.userProfile,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.person_remove_outlined,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= FOOTER / USER PROFILE =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                 border: Border(top: BorderSide(color: Color(0xFFFFFFFF))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.isDesigner
                          ? Color(0xFFD97706).withValues(alpha: 0.2)
                          : Color(0xFF2563EB).withValues(alpha: 0.2),
                      border: Border.all(
                        color: widget.isDesigner
                            ? Color(0xFFD97706).withValues(alpha: 0.4)
                            : Color(0xFF2563EB).withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                     child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isDesigner
                              ? Color(0xFFD97706)
                              : Color(0xFF2563EB),
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
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$roleName · $userPhone',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFB91C1C),
                      size: 20,
                    ),
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
                ? (widget.isDesigner ? Color(0xFFD97706) : Color(0xFF2563EB))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Color(0xFF0F172A) : Color(0xFF475569),
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (widget.isDesigner
                              ? Color(0xFFB45309)
                              : Color(0xFFEFF6FF))
                        : Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
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
