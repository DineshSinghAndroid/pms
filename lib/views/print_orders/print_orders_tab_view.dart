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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF3B82F6); // Blue
      case 'in_production':
        return const Color(0xFF6366F1); // Indigo
      case 'dispatched':
        return const Color(0xFFA855F7); // Purple
      case 'partially_received':
        return const Color(0xFFF59E0B); // Amber
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'cancelled':
        return const Color(0xFFE11D48); // Rose
      case 'pending_vendor':
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'in_production':
        return 'In Production';
      case 'dispatched':
        return 'Dispatched';
      case 'partially_received':
        return 'Partially Received';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending_vendor':
      default:
        return 'Pending Vendor';
    }
  }

  List<PrintOrderModel> _filterOrders(List<PrintOrderModel> orders) {
    return orders.where((po) {
      final matchesStatus = _selectedStatusFilter == 'all' ||
          po.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
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
          color: const Color(0xFF0B1120),
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
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by PO #, vendor, wing, or product...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
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
                    _buildFilterChip('pending_vendor', 'Pending Vendor', color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildFilterChip('accepted', 'Accepted', color: const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _buildFilterChip('in_production', 'In Production', color: const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    _buildFilterChip('dispatched', 'Dispatched', color: const Color(0xFFA855F7)),
                    const SizedBox(width: 8),
                    _buildFilterChip('partially_received', 'Partially Received', color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildFilterChip('completed', 'Completed', color: const Color(0xFF10B981)),
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
            color: const Color(0xFF6366F1),
            child: BlocBuilder<PrintOrderBloc, PrintOrderState>(
              builder: (context, state) {
                if (state is PrintOrderLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  );
                } else if (state is PrintOrderError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                          const SizedBox(height: 10),
                          Text(
                            state.message,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _loadPrintOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
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
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.print_disabled_rounded, color: Colors.white38, size: 30),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Print Orders Found',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Approved PRs dispatched to vendors will appear here.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      return _buildPOCard(filtered[idx]);
                    },
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
    final activeColor = color ?? const Color(0xFF6366F1);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.white60,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = key);
      },
      selectedColor: activeColor,
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(
        color: isSelected ? activeColor : const Color(0xFF334155),
      ),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status color strip
              Container(
                width: 4,
                color: statusColor,
              ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF475569)),
                                ),
                                child: Text(
                                  po.poNumber,
                                  style: const TextStyle(
                                    color: Color(0xFF2DD4BF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              if (po.purchaseRequest != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    po.purchaseRequest!.prNumber,
                                    style: const TextStyle(
                                      color: Color(0xFFFB7185),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF818CF8)),
                          const SizedBox(width: 6),
                          Text(
                            po.vendor?.name ?? 'Assigned Vendor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (po.vendor?.mobile1 != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(+91 ${po.vendor!.mobile1})',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Products summary
                      Text(
                        po.items.map((i) {
                          final qtyStr = i.receivedQuantity > 0 ? '${i.receivedQuantity}/${i.quantity}' : '${i.quantity}';
                          return '${i.productName} (Qty: $qtyStr${i.size != null ? ', ${i.size}' : ''})';
                        }).join(' · '),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                              const Icon(Icons.apartment_rounded, size: 12, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                po.wing?.name ?? 'General Wing',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                po.expectedDeliveryDate ?? 'ASAP',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
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
