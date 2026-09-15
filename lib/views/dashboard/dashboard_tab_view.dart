import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../bloc/payment/payment_bloc.dart';
import '../../bloc/payment/payment_event.dart';
import '../../bloc/payment/payment_state.dart';
import '../../bloc/print_order/print_order_bloc.dart';
import '../../bloc/print_order/print_order_event.dart';
import '../../bloc/print_order/print_order_state.dart';
import '../../bloc/purchase_request/purchase_request_bloc.dart';
import '../../bloc/purchase_request/purchase_request_event.dart';
import '../../bloc/purchase_request/purchase_request_state.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';
import '../layout/side_menu_drawer.dart';
import '../print_orders/print_order_details_screen.dart';
import '../purchase_requests/pr_details_screen.dart';

class DashboardTabView extends StatelessWidget {
  final bool isSuperAdmin;
  final bool isDesigner;
  final UserModel? userProfile;
  final String userPhone;
  final Function(NavMenu)? onNavigate;

  const DashboardTabView({
    super.key,
    required this.isSuperAdmin,
    this.isDesigner = false,
    this.userProfile,
    required this.userPhone,
    this.onNavigate,
  });

  bool get _isSuperAdmin {
    if (isSuperAdmin) return true;
    final r = userProfile?.role.toLowerCase().trim() ?? '';
    if (r == 'superadmin' || r == 'super admin' || r == 'super_admin') return true;
    return userProfile?.isSuperAdmin ?? false;
  }

  bool get _isManager =>
      userProfile?.role.toLowerCase().trim() == 'manager' ||
      userProfile?.role.toLowerCase().trim() == 'admin';
  bool get _isDesigner =>
      isDesigner ||
      userProfile?.role == 'Designer' ||
      userProfile?.role.toLowerCase() == 'designer';
  bool get _isDigitalStudioIncharge =>
      userProfile?.role == 'Digital Studio Incharge' ||
      userProfile?.role.toLowerCase() == 'digital_studio_incharge';
  bool get _isDigitalStudioEmployee =>
      userProfile?.isDigitalStudioEmployee ?? false;
  bool get _isStoreIncharge =>
      userProfile?.role == 'Store Incharge' ||
      userProfile?.role.toLowerCase() == 'store incharge' ||
      userProfile?.role.toLowerCase() == 'store_incharge';
  bool get _isWingIncharge => userProfile?.isWingIncharge ?? false;
  bool get _isVendor => userProfile?.role.toLowerCase() == 'vendor';

  String get _roleTitle {
    if (_isSuperAdmin) return 'Super Admin Portal';
    if (_isDigitalStudioIncharge) return 'Digital Studio Incharge Portal';
    if (_isDigitalStudioEmployee) return 'Digital Studio Crew Portal';
    if (_isStoreIncharge) return 'Store & Receiving Portal';
    if (_isWingIncharge) {
      if (userProfile != null && userProfile!.assignedWings.isNotEmpty) {
        final wingNames = userProfile!.assignedWings.map((w) => w.name).join(', ');
        return 'Wing Incharge · $wingNames';
      }
      return 'Wing Incharge Portal';
    }
    if (_isDesigner) {
      return 'Designer Portal · ${userProfile?.name ?? 'Designer'}';
    }
    if (_isManager) return 'Management Portal';
    if (_isVendor) return 'Printing Vendor Portal';
    return '${userProfile?.role ?? 'User'} Portal';
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final cleanPhone = (userProfile?.phone ?? userPhone)
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');

    if (_isDigitalStudioIncharge || _isDigitalStudioEmployee) {
      context.read<DigitalStudioBloc>().add(RefreshDigitalStudioEvent(phone: cleanPhone));
    }

    if (_isDesigner) {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(
          designerId: userProfile?.id,
          phone: cleanPhone,
        ),
      );
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
    } else if (_isWingIncharge) {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(phone: cleanPhone),
      );
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
    } else if (_isStoreIncharge) {
      context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
      context.read<PrintOrderBloc>().add(const FetchDeliveryLogsEvent());
    } else if (_isVendor) {
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
    } else {
      // Super Admin, Manager
      context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
      context.read<PaymentBloc>().add(const FetchPaymentsEvent());
      context.read<PaymentBloc>().add(const FetchEligiblePaymentItemsEvent());
      context.read<DigitalStudioBloc>().add(RefreshDigitalStudioEvent(phone: cleanPhone));
    }

    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final phone = userProfile?.phone ?? userPhone;

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: () => _handleRefresh(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Welcome Header Banner
            _buildHeaderBanner(phone),

            const SizedBox(height: 20),

            // 2. Role-Based Content Sections
            if (_isDesigner)
              _buildDesignerSection(context)
            else if (_isStoreIncharge)
              _buildStoreInchargeSection(context)
            else if (_isWingIncharge)
              _buildWingInchargeSection(context)
            else if (_isVendor)
              _buildVendorSection(context)
            else if (_isDigitalStudioIncharge)
              _buildStudioInchargeSection(context)
            else if (_isDigitalStudioEmployee)
              _buildStudioEmployeeSection(context)
            else
              // Super Admin, Manager
              _buildAdminAndManagementSection(context),
          ],
        ),
      ),
    );
  }

  // ================= 1. HEADER BANNER =================
  Widget _buildHeaderBanner(String phone) {
    Color badgeColor = const Color(0xFF2563EB); // Blue
    IconData badgeIcon = Icons.admin_panel_settings_rounded;

    if (_isDesigner) {
      badgeColor = const Color(0xFFD97706);
      badgeIcon = Icons.brush_rounded;
    } else if (_isStoreIncharge) {
      badgeColor = const Color(0xFF0891B2);
      badgeIcon = Icons.inventory_2_rounded;
    } else if (_isWingIncharge) {
      badgeColor = const Color(0xFF7C3AED);
      badgeIcon = Icons.apartment_rounded;
    } else if (_isVendor) {
      badgeColor = const Color(0xFF059669);
      badgeIcon = Icons.print_rounded;
    } else if (_isDigitalStudioIncharge) {
      badgeColor = const Color(0xFF2563EB);
      badgeIcon = Icons.palette_rounded;
    } else if (_isDigitalStudioEmployee) {
      badgeColor = const Color(0xFF8B5CF6);
      badgeIcon = Icons.videocam_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Logged in as $phone',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF059669), size: 8),
                SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. ADMIN & MANAGEMENT SECTION =================
  // Shows 5 Core Cards: 1. Purchase Request, 2. Print Orders, 3. Post Orders, 4. Delivery Logs, 5. Add Payment
  Widget _buildAdminAndManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Action Shortcuts Bar
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                label: '+ New PR',
                icon: Icons.add_circle_outline,
                color: const Color(0xFF2563EB),
                onTap: () => onNavigate?.call(NavMenu.purchaseRequests),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                label: 'Delivery Logs',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF0891B2),
                onTap: () => onNavigate?.call(NavMenu.deliveryLogs),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                label: 'Add Payment',
                icon: Icons.payments_outlined,
                color: const Color(0xFF059669),
                onTap: () => onNavigate?.call(NavMenu.payments),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Title
        const Row(
          children: [
            Icon(Icons.dashboard_customize_rounded,
                color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 8),
            Text(
              'Key Operations & Tracking',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: 1. Purchase Request & 2. Print Orders
        Row(
          children: [
            Expanded(
              child: BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                builder: (context, state) {
                  final count = state is PurchaseRequestLoaded
                      ? state.requests.length
                      : 0;
                  return _buildStatCard(
                    title: '1. Purchase Request',
                    count: '$count',
                    subtitle: 'Multi-Product Requisitions',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF2563EB),
                    onTap: () => onNavigate?.call(NavMenu.purchaseRequests),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
                builder: (context, state) {
                  final count = state.printOrdersList.length;
                  return _buildStatCard(
                    title: '2. Print Orders',
                    count: '$count',
                    subtitle: 'Dispatched to Presses',
                    icon: Icons.print_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () => onNavigate?.call(NavMenu.printOrders),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: 3. Post Orders & 4. Delivery Logs
        Row(
          children: [
            Expanded(
              child: BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                builder: (context, state) {
                  final count = state is PurchaseRequestLoaded
                      ? state.requests
                          .where((r) => r.status == 'posted' || r.isPosted)
                          .length
                      : 0;
                  return _buildStatCard(
                    title: '3. Post Orders',
                    count: '$count',
                    subtitle: 'Digital & Social Media',
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () => onNavigate?.call(NavMenu.postOrders),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
                builder: (context, state) {
                  final deliveryCount = state.deliveriesList.length;
                  return _buildStatCard(
                    title: '4. Delivery Logs',
                    count: '$deliveryCount',
                    subtitle: 'Store Incharge Challans',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0891B2),
                    onTap: () => onNavigate?.call(NavMenu.deliveryLogs),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: 5. Add Payment (Full Width Highlight Card)
        BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            int paidCount = 0;
            int eligibleCount = 0;
            if (state is PaymentLoaded) {
              paidCount = state.payments.length;
              eligibleCount = state.eligibleItems.length;
            }
            return _buildStatCard(
              title: '5. Add Payment',
              count: '$paidCount Paid',
              subtitle: eligibleCount > 0
                  ? '$eligibleCount order(s) pending vendor settlement'
                  : 'Vendor invoices & settlement records',
              icon: Icons.payments_outlined,
              color: const Color(0xFF059669),
              onTap: () => onNavigate?.call(NavMenu.payments),
            );
          },
        ),

        const SizedBox(height: 24),

        // Recent Purchase Requests Preview
        _buildRecentPRsList(context),
      ],
    );
  }

  // ================= 3. STORE INCHARGE SECTION =================
  Widget _buildStoreInchargeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Highlight Card: Print Orders Arriving
        BlocBuilder<PrintOrderBloc, PrintOrderState>(
          builder: (context, state) {
            final count = state.printOrdersList.length;
            return _buildStatCard(
              title: 'Print Orders (PO)',
              count: '$count',
              subtitle: 'Vendor Shipments & Material Receipts',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF0891B2),
              onTap: () => onNavigate?.call(NavMenu.printOrders),
            );
          },
        ),

        const SizedBox(height: 12),

        // Purchase Requests
        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
          builder: (context, state) {
            final count = state is PurchaseRequestLoaded
                ? state.requests.length
                : 0;
            return _buildStatCard(
              title: 'Purchase Requests',
              count: '$count',
              subtitle: 'Original Item Requisitions & Specs',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => onNavigate?.call(NavMenu.purchaseRequests),
            );
          },
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () => onNavigate?.call(NavMenu.printOrders),
          icon: const Icon(Icons.inventory_rounded),
          label: const Text(
            'Go to Print Orders to Record Delivery',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildRecentPRsList(context),
      ],
    );
  }

  // ================= 4. WING INCHARGE SECTION =================
  Widget _buildWingInchargeSection(BuildContext context) {
    final wingName = userProfile?.assignedWings.isNotEmpty == true
        ? userProfile!.assignedWings.map((w) => w.name).join(', ')
        : 'Your Wing';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
          builder: (context, state) {
            final count = state is PurchaseRequestLoaded
                ? state.requests.length
                : 0;
            return _buildStatCard(
              title: 'Purchase Requests',
              count: '$count',
              subtitle: 'Requisitions for $wingName',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => onNavigate?.call(NavMenu.purchaseRequests),
            );
          },
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () => onNavigate?.call(NavMenu.purchaseRequests),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text(
            '+ Create Purchase Request',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildRecentPRsList(context),
      ],
    );
  }

  // ================= 5. DESIGNER SECTION =================
  Widget _buildDesignerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.palette_outlined, color: Color(0xFFD97706), size: 18),
            SizedBox(width: 8),
            Text(
              'Your Design Assignments & Workflows',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5-Color Status Breakdown Grid
        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
          builder: (context, state) {
            int assignedCount = 0;
            int inProgressCount = 0;
            int underReviewCount = 0;
            int revisionCount = 0;
            int approvedCount = 0;

            if (state is PurchaseRequestLoaded) {
              final designerPRs = userProfile?.id != null
                  ? state.requests
                      .where((pr) => pr.assignedDesignerId == userProfile!.id)
                      .toList()
                  : state.requests;

              assignedCount = designerPRs
                  .where(
                    (pr) =>
                        pr.status == 'assigned_to_designer' ||
                        pr.status == 'pending_assignment',
                  )
                  .length;
              inProgressCount =
                  designerPRs.where((pr) => pr.status == 'in_progress').length;
              underReviewCount = designerPRs
                  .where((pr) => pr.status == 'submitted_for_approval')
                  .length;
              revisionCount = designerPRs
                  .where((pr) => pr.status == 'rejected_revision_needed')
                  .length;
              approvedCount =
                  designerPRs.where((pr) => pr.status == 'approved').length;
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatusStat(
                        title: 'Assigned (New)',
                        count: '$assignedCount',
                        icon: Icons.assignment_ind_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: () =>
                            onNavigate?.call(NavMenu.purchaseRequests),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatusStat(
                        title: 'In Progress',
                        count: '$inProgressCount',
                        icon: Icons.draw_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: () =>
                            onNavigate?.call(NavMenu.purchaseRequests),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatusStat(
                        title: 'Under Review',
                        count: '$underReviewCount',
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () =>
                            onNavigate?.call(NavMenu.purchaseRequests),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStatusStat(
                        title: 'Revision Needed',
                        count: '$revisionCount',
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFDC2626),
                        onTap: () =>
                            onNavigate?.call(NavMenu.purchaseRequests),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildMiniStatusStat(
                  title: 'Approved / Completed Artwork',
                  count: '$approvedCount',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => onNavigate?.call(NavMenu.purchaseRequests),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        // Operational Overview Cards for Designer
        Row(
          children: [
            Expanded(
              child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
                builder: (context, state) {
                  final count = state.printOrdersList.length;
                  return _buildStatCard(
                    title: 'Print Orders',
                    count: '$count',
                    subtitle: 'Press Production',
                    icon: Icons.print_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () => onNavigate?.call(NavMenu.printOrders),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
                builder: (context, state) {
                  final count = state is PurchaseRequestLoaded
                      ? state.requests
                          .where((r) => r.status == 'posted' || r.isPosted)
                          .length
                      : 0;
                  return _buildStatCard(
                    title: 'Post Orders',
                    count: '$count',
                    subtitle: 'Digital Publishing',
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () => onNavigate?.call(NavMenu.postOrders),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildRecentPRsList(context, designerOnly: true),
      ],
    );
  }

  // ================= 6. DIGITAL STUDIO INCHARGE SECTION =================
  Widget _buildStudioInchargeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                label: 'Post Orders (Digital Publishing)',
                icon: Icons.campaign_rounded,
                color: const Color(0xFFD97706),
                onTap: () => onNavigate?.call(NavMenu.postOrders),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
          builder: (context, state) {
            final count = state is PurchaseRequestLoaded
                ? state.requests
                    .where((r) => r.status == 'posted' || r.isPosted)
                    .length
                : 0;
            return _buildStatCard(
              title: 'Post Orders',
              count: '$count',
              subtitle: 'Digital & Social Media Publishing',
              icon: Icons.campaign_rounded,
              color: const Color(0xFFD97706),
              onTap: () => onNavigate?.call(NavMenu.postOrders),
            );
          },
        ),
      ],
    );
  }

  // ================= 6.5. DIGITAL STUDIO EMPLOYEE SECTION =================
  Widget _buildStudioEmployeeSection(BuildContext context) {
    return BlocBuilder<DigitalStudioBloc, DigitalStudioState>(
      builder: (context, state) {
        if (state is DigitalStudioLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            ),
          );
        }

        final myUserId = userProfile?.id;
        final myShoots = state is DigitalStudioLoaded
            ? state.crewRequests.where((r) {
                return r.allottedEmployees.any((e) => e.id == myUserId);
              }).toList()
            : <DigitalStudioCrewRequestModel>[];

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final isTodayBooked = myShoots.any((r) {
          final sDate = DateFormat('yyyy-MM-dd').format(r.reportingDateTime);
          return sDate == todayStr;
        });

        final totalAvailableAssets = state is DigitalStudioLoaded
            ? state.availableAssets.length
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duty Status Banner for Today
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTodayBooked ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTodayBooked ? const Color(0xFFA7F3D0) : const Color(0xFFDDD6FE),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isTodayBooked ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTodayBooked ? Icons.event_available_rounded : Icons.beach_access_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTodayBooked ? 'Today\'s Duty: You are Booked' : 'Today\'s Duty: You have Off / Available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTodayBooked ? const Color(0xFF065F46) : const Color(0xFF5B21B6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTodayBooked
                              ? 'You have scheduled shoot duty today. Please check reporting time.'
                              : 'No shoots scheduled for today. Available for upcoming event duties.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isTodayBooked ? const Color(0xFF047857) : const Color(0xFF6D28D9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Navigation Button
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    label: 'Open Studio Calendar & Duty Schedule',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF1E3A8A),
                    onTap: () => onNavigate?.call(NavMenu.digitalStudio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'My Shoots',
                    count: '${myShoots.length}',
                    subtitle: 'Allotted Events',
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFF1E3A8A),
                    onTap: () => onNavigate?.call(NavMenu.digitalStudio),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Studio Gear',
                    count: '$totalAvailableAssets',
                    subtitle: 'Available Assets',
                    icon: Icons.camera_alt_outlined,
                    color: const Color(0xFF059669),
                    onTap: () => onNavigate?.call(NavMenu.digitalStudio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assigned Events List Header
            const Row(
              children: [
                Icon(Icons.event_note_rounded, color: Color(0xFF1E3A8A), size: 18),
                SizedBox(width: 8),
                Text(
                  'Your Upcoming Assigned Shoots',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (myShoots.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 36, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text(
                        'No upcoming shoots currently assigned to you.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: myShoots.map((req) {
                  final sTime = DateFormat('dd MMM, hh:mm a').format(req.reportingDateTime);
                  final eTime = DateFormat('hh:mm a').format(req.eventEndTime);

                  return InkWell(
                    onTap: () => onNavigate?.call(NavMenu.digitalStudio),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.videocam_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        req.wing?.name ?? 'Wing',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6D28D9),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      req.requestNumber,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req.eventName,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reporting: $sTime - $eTime',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  // ================= 7. VENDOR SECTION =================
  Widget _buildVendorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
                builder: (context, state) {
                  final count = state.printOrdersList.length;
                  return _buildStatCard(
                    title: 'Print Orders',
                    count: '$count',
                    subtitle: 'Production Orders',
                    icon: Icons.print_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () => onNavigate?.call(NavMenu.printOrders),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) {
                  final count =
                      state is PaymentLoaded ? state.payments.length : 0;
                  return _buildStatCard(
                    title: 'Payment Records',
                    count: '$count',
                    subtitle: 'Settlements Received',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF059669),
                    onTap: () => onNavigate?.call(NavMenu.payments),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Row(
          children: [
            Icon(Icons.print_rounded, color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 8),
            Text(
              'Your Assigned Print Production Orders',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        BlocBuilder<PrintOrderBloc, PrintOrderState>(
          builder: (context, state) {
            if (state is PrintOrderLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              );
            }

            if (state is PrintOrderLoaded) {
              if (state.printOrders.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No Print Orders Assigned Yet',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: state.printOrders.map((po) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrintOrderDetailsScreen(
                            printOrder: po,
                            userProfile: userProfile,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.print_rounded,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  po.poNumber,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${po.items.length} item(s) · ${po.wing?.name ?? 'Wing'}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: po.status.toLowerCase() == 'completed'
                                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                                  : (po.status.toLowerCase() == 'partially_received'
                                      ? const Color(0xFFD97706).withValues(alpha: 0.12)
                                      : const Color(0xFF2563EB).withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              po.status.toLowerCase() == 'completed'
                                  ? 'Completed'
                                  : (po.status.toLowerCase() == 'partially_received'
                                      ? 'Partially Received'
                                      : 'In Printing'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: po.status.toLowerCase() == 'completed'
                                    ? const Color(0xFF059669)
                                    : (po.status.toLowerCase() == 'partially_received'
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Icon(icon, color: color, size: 18)),
                  ),
                  Row(
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusStat({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Icon(icon, color: color, size: 17)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPRsList(BuildContext context, {bool designerOnly = false}) {
    return BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
      builder: (context, state) {
        if (state is PurchaseRequestLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }

        if (state is PurchaseRequestLoaded) {
          var list = state.requests;
          if (designerOnly && userProfile?.id != null) {
            list = list
                .where((pr) => pr.assignedDesignerId == userProfile!.id)
                .toList();
          }

          if (list.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No recent purchase requests found.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          final recent = list.take(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Purchase Requests',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigate?.call(NavMenu.purchaseRequests),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recent.map((pr) {
                Color statusColor = const Color(0xFFD97706);
                String statusLabel = 'Pending';

                if (pr.status == 'assigned_to_designer') {
                  statusColor = const Color(0xFF2563EB);
                  statusLabel = 'Assigned';
                } else if (pr.status == 'in_progress') {
                  statusColor = const Color(0xFF2563EB);
                  statusLabel = 'In Progress';
                } else if (pr.status == 'submitted_for_approval') {
                  statusColor = const Color(0xFF7C3AED);
                  statusLabel = 'Under Review';
                } else if (pr.status == 'approved') {
                  statusColor = const Color(0xFF059669);
                  statusLabel = 'Approved';
                } else if (pr.status == 'sent_to_print') {
                  statusColor = const Color(0xFF2563EB);
                  statusLabel = 'In Print';
                } else if (pr.status == 'posted') {
                  statusColor = const Color(0xFFD97706);
                  statusLabel = 'Posted';
                } else if (pr.status == 'completed') {
                  statusColor = const Color(0xFF059669);
                  statusLabel = 'Completed';
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PRDetailsScreen(
                            prId: pr.id,
                            isSuperAdmin: _isSuperAdmin,
                            currentUser: userProfile,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pr.prNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pr.wing?.name ?? 'General Wing',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${pr.items.length} item(s) · ${pr.expectedDeliveryDate ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
