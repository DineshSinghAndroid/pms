import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/views/print_orders/print_order_details_screen.dart';

class PrintOrdersTabView extends StatefulWidget {
  final UserModel? userProfile;
  final bool isSuperAdmin;
  final bool isDesigner;

  const PrintOrdersTabView({
    super.key,
    this.userProfile,
    required this.isSuperAdmin,
    this.isDesigner = false,
  });

  @override
  State<PrintOrdersTabView> createState() => _PrintOrdersTabViewState();
}

class _PrintOrdersTabViewState extends State<PrintOrdersTabView> {
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrintOrders();
  }

  void _loadPrintOrders() {
    final phone = widget.userProfile?.phone;
    context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: phone));
  }

  String get _role => (widget.userProfile?.role ?? '').toLowerCase();
  String get _cleanPhone => (widget.userProfile?.phone ?? '')
      .replaceAll(RegExp(r'^\+?91'), '')
      .replaceAll(RegExp(r'\D'), '');

  bool get isSuperAdmin =>
      widget.isSuperAdmin ||
      _role == 'superadmin' ||
      _role == 'super admin' ||
      _cleanPhone == '';

  bool get isManager => _role == 'manager';
  bool get isVendor => _role == 'vendor';

  bool get canSeeVendorDetails => isSuperAdmin || isManager || isVendor;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'partially_received':
        return const Color(0xFFD97706); // Amber
      case 'completed':
        return const Color(0xFF059669); // Emerald
      case 'cancelled':
        return const Color(0xFFDC2626); // Rose
      case 'in_production':
      case 'in_printing':
      case 'pending_vendor':
      case 'accepted':
      case 'dispatched':
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'partially_received':
        return 'Partially Received';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'in_production':
      case 'in_printing':
      case 'pending_vendor':
      case 'accepted':
      case 'dispatched':
      default:
        return 'In Printing';
    }
  }

  List<PrintOrderModel> _filterOrders(List<PrintOrderModel> orders) {
    return orders.where((po) {
      // Role isolation: Designers only see Print Orders they worked on or created
      if (widget.isDesigner || widget.userProfile?.role == 'Designer') {
        final currentUserId = widget.userProfile?.id;
        final currentUserPhone = widget.userProfile?.phone;
        final pr = po.purchaseRequest;
        final bool isMyOrder =
            (currentUserId != null && po.createdByUserId == currentUserId) ||
            (currentUserId != null && pr?.assignedDesignerId == currentUserId) ||
            (currentUserPhone != null &&
                pr?.assignedDesigner?.phone != null &&
                pr!.assignedDesigner!.phone == currentUserPhone) ||
            (currentUserId != null && pr?.workStartedByUserId == currentUserId) ||
            (currentUserPhone != null &&
                pr?.workStartedByUser?.phone != null &&
                pr!.workStartedByUser!.phone == currentUserPhone) ||
            (currentUserId != null && pr?.createdByUserId == currentUserId);
        if (!isMyOrder) return false;
      }

      // Role isolation: Wing Incharges only see Print Orders for PRs they created
      if (widget.userProfile?.role == 'Wing Incharge') {
        final currentUserId = widget.userProfile?.id;
        final currentUserPhone = widget.userProfile?.phone;
        final pr = po.purchaseRequest;
        final bool isMyWingOrder =
            (currentUserId != null && pr?.createdByUserId == currentUserId) ||
            (currentUserPhone != null &&
                pr?.createdByUser?.phone != null &&
                pr!.createdByUser!.phone == currentUserPhone) ||
            (currentUserId != null && po.createdByUserId == currentUserId);
        if (!isMyWingOrder) return false;
      }

      final s = po.status.toLowerCase();
      final bool matchesStatus;
      if (_selectedStatusFilter == 'all') {
        matchesStatus = true;
      } else if (_selectedStatusFilter == 'in_production') {
        matchesStatus = s == 'in_production' ||
            s == 'in_printing' ||
            s == 'pending_vendor' ||
            s == 'accepted' ||
            s == 'dispatched';
      } else {
        matchesStatus = s == _selectedStatusFilter.toLowerCase();
      }

      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery =
          q.isEmpty ||
          po.poNumber.toLowerCase().contains(q) ||
          (po.vendor?.name.toLowerCase().contains(q) ?? false) ||
          (po.wing?.name.toLowerCase().contains(q) ?? false) ||
          (po.purchaseRequest?.prNumber.toLowerCase().contains(q) ?? false) ||
          po.items.any((it) => it.productName.toLowerCase().contains(q));

      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Search & Status Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Color(0xFF0B1120),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by PO #, vendor, wing, or product...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF64748B),
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Orders'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'in_production',
                      'In Printing',
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'partially_received',
                      'Partially Received',
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'completed',
                      'Completed',
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadPrintOrders(),
            color: Color(0xFF2563EB),
            child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
              builder: (context, state) {
                if (state is PrintOrderLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                } else if (state is PrintOrderError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _loadPrintOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2563EB),
                              foregroundColor: Color(0xFFFFFFFF),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is PrintOrderLoaded) {
                  final filtered = _filterOrders(state.printOrders);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.print_disabled_rounded,
                              color: Color(0xFF64748B),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Print Orders Found',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (widget.isDesigner || widget.userProfile?.role == 'Designer')
                                ? 'Only print orders created from your designs will appear here.'
                                : 'Approved PRs dispatched to vendors will appear here.',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (widget.isDesigner || widget.userProfile?.role == 'Designer')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFFEFF6FF),
                          child: Row(
                            children: [
                              const Icon(Icons.palette_outlined, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Showing print orders designed by you (${widget.userProfile?.name ?? 'Designer'})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            return _buildPOCard(filtered[idx]);
                          },
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedStatusFilter == key;
    final activeColor = color ?? Color(0xFF2563EB);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = key);
      },
      selectedColor: activeColor,
      backgroundColor: Color(0xFFFFFFFF),
      side: BorderSide(color: isSelected ? activeColor : Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
    );
  }

  Widget _buildPOCard(PrintOrderModel po) {
    final statusColor = _getStatusColor(po.status);
    final statusLabel = _getStatusLabel(po.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrintOrderDetailsScreen(
              printOrder: po,
              userProfile: widget.userProfile,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status color strip
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: PO # + Status Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Color(0xFF475569)),
                                ),
                                child: Text(
                                  po.poNumber,
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              if (po.purchaseRequest != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    po.purchaseRequest!.prNumber,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Assigned Vendor
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            canSeeVendorDetails
                                ? (po.vendor?.name ?? 'Assigned Vendor')
                                : 'XXXX (Printing Vendor)',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (canSeeVendorDetails && po.vendor?.mobile1 != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(+91 ${po.vendor!.mobile1})',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Products summary
                      Text(
                        po.items
                            .map((i) {
                              final qtyStr = i.receivedQuantity > 0
                                  ? '${i.receivedQuantity}/${i.quantity}'
                                  : '${i.quantity}';
                              return '${i.productName} (Qty: $qtyStr${i.size != null ? ', ${i.size}' : ''})';
                            })
                            .join(' · '),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Bottom Wing & Delivery Target
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                po.wing?.name ?? 'General Wing',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                po.expectedDeliveryDate ?? 'ASAP',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
