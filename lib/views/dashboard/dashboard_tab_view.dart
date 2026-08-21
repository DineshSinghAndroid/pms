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

  @override
  Widget build(BuildContext context) {
    final displayName = userProfile?.name ?? (isSuperAdmin ? 'Super Admin' : (isDesigner ? 'Designer' : 'Vendor'));
    final phone = userProfile?.phone ?? userPhone;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSuperAdmin
                          ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                          : (isDesigner
                              ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                              : [const Color(0xFF0D9488), const Color(0xFF059669)]),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isSuperAdmin
                          ? Icons.admin_panel_settings_rounded
                          : (isDesigner ? Icons.brush_rounded : Icons.print_rounded),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuperAdmin
                            ? 'Super Admin Portal'
                            : (isDesigner ? 'Designer Portal · $displayName' : 'Printing Vendor Portal'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Logged in as $phone',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                      SizedBox(width: 5),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= DESIGNER WORKSPACE =================
          if (isDesigner) ...[
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 8),
                Text(
                  'Your Design Assignments & Status Breakdown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Designer PR 5-Color Status Grid
            BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
              builder: (context, state) {
                int assignedCount = 0;
                int inProgressCount = 0;
                int underReviewCount = 0;
                int revisionCount = 0;
                int approvedCount = 0;

                if (state is PurchaseRequestLoaded) {
                  final designerPRs = userProfile?.id != null
                      ? state.requests.where((pr) => pr.assignedDesignerId == userProfile!.id).toList()
                      : state.requests;

                  assignedCount = designerPRs.where((pr) => pr.status == 'assigned_to_designer' || pr.status == 'pending_assignment').length;
                  inProgressCount = designerPRs.where((pr) => pr.status == 'in_progress').length;
                  underReviewCount = designerPRs.where((pr) => pr.status == 'submitted_for_approval').length;
                  revisionCount = designerPRs.where((pr) => pr.status == 'rejected_revision_needed').length;
                  approvedCount = designerPRs.where((pr) => pr.status == 'approved').length;
                }

                return Column(
                  children: [
                    // Row 1: Assigned (Blue) & In Progress (Indigo)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatusStat(
                            title: 'Assigned (New)',
                            count: '$assignedCount',
                            icon: Icons.assignment_ind_rounded,
                            color: const Color(0xFF3B82F6),
                            onTap: () {
                              if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStatusStat(
                            title: 'In Progress',
                            count: '$inProgressCount',
                            icon: Icons.draw_rounded,
                            color: const Color(0xFF6366F1),
                            onTap: () {
                              if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Under Review (Purple) & Revision Needed (Rose)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatusStat(
                            title: 'Under Review',
                            count: '$underReviewCount',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFA855F7),
                            onTap: () {
                              if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniStatusStat(
                            title: 'Revision Needed',
                            count: '$revisionCount',
                            icon: Icons.replay_rounded,
                            color: const Color(0xFFE11D48),
                            onTap: () {
                              if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Approved / Completed (Emerald Green) Full Width
                    _buildMiniStatusStat(
                      title: 'Approved / Completed Artwork',
                      count: '$approvedCount',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Live List of Assigned PRs with Dedicated Status Colors
            BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
              builder: (context, state) {
                if (state is PurchaseRequestLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                }

                if (state is PurchaseRequestLoaded) {
                  final designerRequests = userProfile?.id != null
                      ? state.requests.where((pr) => pr.assignedDesignerId == userProfile!.id).toList()
                      : state.requests;

                  if (designerRequests.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.assignment_outlined, color: Color(0xFF64748B), size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No Purchase Requests Assigned Yet',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'When the Super Admin assigns a printing PR to your account, it will immediately show up here.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Assigned PRs:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 8),
                      ...designerRequests.map((pr) {
                        Color statusColor = const Color(0xFFF59E0B);
                        Color statusBg = const Color(0xFF78350F).withValues(alpha: 0.35);
                        Color statusBorder = const Color(0xFFF59E0B);
                        Color statusText = const Color(0xFFFCD34D);
                        String statusLabel = 'Pending';
                        IconData statusIcon = Icons.hourglass_empty_rounded;

                        if (pr.status == 'assigned_to_designer') {
                          statusColor = const Color(0xFF3B82F6);
                          statusBg = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFF3B82F6);
                          statusText = const Color(0xFF93C5FD);
                          statusLabel = 'Assigned';
                          statusIcon = Icons.assignment_ind_rounded;
                        } else if (pr.status == 'in_progress') {
                          statusColor = const Color(0xFF6366F1);
                          statusBg = const Color(0xFF312E81).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFF6366F1);
                          statusText = const Color(0xFFA5B4FC);
                          statusLabel = 'In Progress';
                          statusIcon = Icons.draw_rounded;
                        } else if (pr.status == 'submitted_for_approval') {
                          statusColor = const Color(0xFFA855F7);
                          statusBg = const Color(0xFF581C87).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFFA855F7);
                          statusText = const Color(0xFFD8B4FE);
                          statusLabel = 'Under Review';
                          statusIcon = Icons.hourglass_top_rounded;
                        } else if (pr.status == 'rejected_revision_needed') {
                          statusColor = const Color(0xFFE11D48);
                          statusBg = const Color(0xFF881337).withValues(alpha: 0.45);
                          statusBorder = const Color(0xFFFB7185);
                          statusText = const Color(0xFFFDA4AF);
                          statusLabel = 'Revision (#${pr.revisionCount})';
                          statusIcon = Icons.replay_rounded;
                        } else if (pr.status == 'approved') {
                          statusColor = const Color(0xFF14B8A6);
                          statusBg = const Color(0xFF0D9488).withValues(alpha: 0.3);
                          statusBorder = const Color(0xFF14B8A6);
                          statusText = const Color(0xFF5EEAD4);
                          statusLabel = 'Approved';
                          statusIcon = Icons.check_circle_rounded;
                        } else if (pr.status == 'sent_to_print') {
                          statusColor = const Color(0xFF3B82F6);
                          statusBg = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFF3B82F6);
                          statusText = const Color(0xFF93C5FD);
                          statusLabel = 'Sent to Print';
                          statusIcon = Icons.print_rounded;
                        } else if (pr.status == 'posted') {
                          statusColor = const Color(0xFF8B5CF6);
                          statusBg = const Color(0xFF581C87).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFFA855F7);
                          statusText = const Color(0xFFD8B4FE);
                          statusLabel = 'Posted ✓';
                          statusIcon = Icons.campaign_rounded;
                        } else if (pr.status == 'completed') {
                          statusColor = const Color(0xFF10B981);
                          statusBg = const Color(0xFF064E3B).withValues(alpha: 0.35);
                          statusBorder = const Color(0xFF10B981);
                          statusText = const Color(0xFF6EE7B7);
                          statusLabel = 'Completed ✓';
                          statusIcon = Icons.task_alt_rounded;
                        }

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PRDetailsScreen(
                                    prId: pr.id,
                                    isSuperAdmin: isSuperAdmin,
                                    currentUser: userProfile,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: statusBorder.withValues(alpha: 0.4)),
                              ),
                              child: Stack(
                                children: [
                                  // Left Status Accent Bar
                                  Positioned(
                                    left: 0,
                                    top: 10,
                                    bottom: 10,
                                    child: Container(
                                      width: 3.5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(left: 14, right: 12, top: 12, bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            pr.prNumber,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
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
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                '${pr.items.length} item(s) · Delivery: ${pr.expectedDeliveryDate ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: 11, color: statusText),
                                              const SizedBox(width: 3),
                                              Text(
                                                statusLabel,
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusText),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
            ),
          ],

          // ================= SUPER ADMIN MASTER METRICS GRID =================
          if (isSuperAdmin) ...[
            const Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: Color(0xFF60A5FA), size: 18),
                SizedBox(width: 8),
                Text(
                  'Print Management Overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 0: Purchase Requests (PR) Card (Prominent)
            BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
              builder: (context, state) {
                final count =
                    state is PurchaseRequestLoaded ? state.requests.length : 0;
                return _buildStatCard(
                  title: 'Purchase Requests (PR)',
                  count: '$count',
                  subtitle: 'Multi-Product Orders & Designer Assignments',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFFFB7185),
                  onTap: () {
                    if (onNavigate != null) onNavigate!(NavMenu.purchaseRequests);
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Row 1: Categories & Product Types
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      final count =
                          state is CategoryLoaded ? state.categories.length : 0;
                      return _buildStatCard(
                        title: 'Categories',
                        count: '$count',
                        subtitle: 'Education, Hospital...',
                        icon: Icons.category_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.categories);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<ProductTypeBloc, ProductTypeState>(
                    builder: (context, state) {
                      final count =
                          state is ProductTypeLoaded ? state.productTypes.length : 0;
                      return _buildStatCard(
                        title: 'Product Types',
                        count: '$count',
                        subtitle: '614 6-Digit Codes',
                        icon: Icons.layers_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.productTypes);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Wings & Vendors
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<WingBloc, WingState>(
                    builder: (context, state) {
                      final count =
                          state is WingLoaded ? state.wings.length : 0;
                      return _buildStatCard(
                        title: 'Wings Master',
                        count: '$count',
                        subtitle: '17 Campuses & Hospital',
                        icon: Icons.apartment_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.wings);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<VendorBloc, VendorState>(
                    builder: (context, state) {
                      final count =
                          state is VendorLoaded ? state.vendors.length : 0;
                      return _buildStatCard(
                        title: 'Printing Vendors',
                        count: '$count',
                        subtitle: '26 Authorized Presses',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFFA855F7),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.vendors);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Users & Print Orders
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      final count = state is UserLoaded ? state.users.length : 0;
                      return _buildStatCard(
                        title: 'Users & Roles',
                        count: '$count',
                        subtitle: 'Admins & Staff',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.users);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
                    builder: (context, state) {
                      final count =
                          state is PrintOrderLoaded ? state.printOrders.length : 0;
                      return _buildStatCard(
                        title: 'Print Orders (PO)',
                        count: '$count',
                        subtitle: 'Dispatched to Presses',
                        icon: Icons.print_rounded,
                        color: const Color(0xFF06B6D4),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.printOrders);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 4: Post Orders (Digital Publishing)
            BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
              builder: (context, state) {
                final count = state is PurchaseRequestLoaded
                    ? state.requests.where((r) => r.status == 'posted' || r.isPosted).length
                    : 0;
                return _buildStatCard(
                  title: 'Post Orders (Digital & Social)',
                  count: '$count',
                  subtitle: 'Approved & Forwarded for Post Publishing',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFA855F7),
                  onTap: () {
                    if (onNavigate != null) onNavigate!(NavMenu.postOrders);
                  },
                );
              },
            ),
          ],

          // ================= VENDOR WORKSPACE =================
          if (!isSuperAdmin && !isDesigner) ...[
            const Row(
              children: [
                Icon(Icons.print_rounded, color: Color(0xFF06B6D4), size: 18),
                SizedBox(width: 8),
                Text(
                  'Your Assigned Print Production Orders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vendor Print Orders Live List
            BlocBuilder<PrintOrderBloc, PrintOrderState>(
              builder: (context, state) {
                if (state is PrintOrderLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
                }

                if (state is PrintOrderLoaded) {
                  if (state.printOrders.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.print_disabled_rounded, color: Color(0xFF64748B), size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No Print Orders Assigned Yet',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'When the Super Admin or Designer dispatches an approved print order to your press, it will show up here.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: state.printOrders.map((po) {
                      Color statusColor = const Color(0xFFF59E0B);
                      String statusLabel = 'Pending';
                      if (po.status == 'accepted') {
                        statusColor = const Color(0xFF3B82F6);
                        statusLabel = 'Accepted';
                      } else if (po.status == 'in_production') {
                        statusColor = const Color(0xFF6366F1);
                        statusLabel = 'In Production';
                      } else if (po.status == 'dispatched') {
                        statusColor = const Color(0xFFA855F7);
                        statusLabel = 'Dispatched';
                      } else if (po.status == 'completed') {
                        statusColor = const Color(0xFF10B981);
                        statusLabel = 'Completed';
                      }

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
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                ),
                                child: Icon(Icons.print_rounded, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          po.poNumber,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${po.items.length} items · ${po.wing?.name ?? 'General Wing'} · Delivery: ${po.expectedDeliveryDate ?? 'ASAP'}',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
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
        ],
      ),
    );
  }

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
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
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
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 18),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: color.withValues(alpha: 0.7)),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                count,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
