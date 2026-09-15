import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_delivery_model.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/views/delivery_logs/update_delivery_dialog.dart';
import 'package:pms/views/print_orders/print_order_details_screen.dart';
import 'package:pms/theme/pms_theme.dart';

class DeliveryLogsTabView extends StatefulWidget {
  final UserModel? userProfile;
  final bool isSuperAdmin;

  const DeliveryLogsTabView({
    super.key,
    this.userProfile,
    required this.isSuperAdmin,
  });

  @override
  State<DeliveryLogsTabView> createState() => _DeliveryLogsTabViewState();
}

class _DeliveryLogsTabViewState extends State<DeliveryLogsTabView> {
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<PrintOrderDeliveryModel> _cachedDeliveries = [];
  List<PrintOrderModel> _cachedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final phone = widget.userProfile?.phone;
    context.read<PrintOrderBloc>().add(const FetchDeliveryLogsEvent());
    context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: phone));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PrintOrderDeliveryModel> _filterLogs(
    List<PrintOrderDeliveryModel> logs,
  ) {
    return logs.where((d) {
      final matchesStatus =
          _selectedStatusFilter == 'all' ||
          d.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery =
          q.isEmpty ||
          d.challanNumber.toLowerCase().contains(q) ||
          d.deliveryNumber.toLowerCase().contains(q) ||
          (d.remarks?.toLowerCase().contains(q) ?? false) ||
          (d.printOrder?.poNumber.toLowerCase().contains(q) ?? false) ||
          (d.printOrder?.vendor?.name.toLowerCase().contains(q) ?? false) ||
          d.items.any((it) => it.productName.toLowerCase().contains(q));

      return matchesStatus && matchesQuery;
    }).toList();
  }

  void _openUpdateDeliveryDialog([PrintOrderModel? preselectedOrder]) async {
    final result = await showDialog(
      context: context,
      builder: (_) => UpdateDeliveryDialog(
        printOrders: _cachedOrders,
        preselectedOrder: preselectedOrder,
        userProfile: widget.userProfile,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrintOrderBloc, PrintOrderState>(
      listener: (context, state) {
        if (state is DeliveryRecordedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${state.message}'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        } else if (state is PrintOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DeliveryLogsLoaded) {
          _cachedDeliveries = state.deliveries;
        } else if (state is PrintOrderLoaded) {
          _cachedOrders = state.printOrders;
        }

        final filtered = _filterLogs(_cachedDeliveries);

        return Column(
          children: [
            // Top Bar with Action Button & Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFF0B1120),
              child: Column(
                children: [
                  // Button on Top: + Update Delivery
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openUpdateDeliveryDialog(),
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: const Text(
                            '+ Update Delivery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF059669),
                            foregroundColor: Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      color: PmsTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search Challan #, Delivery #, PO #, or vendor...',
                      hintStyle: const TextStyle(
                        color: PmsTheme.textSecondary,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
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
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: PmsTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: PmsTheme.glassBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Delivery Logs'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'partially_received',
                          'Partially Received',
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'completed',
                          'Fully Received',
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: Color(0xFF059669),
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: PmsTheme.glassSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: PmsTheme.textSecondary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Delivery Logs Found',
                              style: TextStyle(
                                color: PmsTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Click "+ Update Delivery" to receive products under a Challan.',
                              style: TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          return _buildDeliveryCard(filtered[idx]);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedStatusFilter == key;
    final activeColor = color ?? Color(0xFF059669);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? activeColor : PmsTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = key);
      },
      selectedColor: activeColor.withValues(alpha: 0.16),
      backgroundColor: PmsTheme.glassSurface,
      side: BorderSide(color: isSelected ? activeColor : PmsTheme.glassBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
    );
  }

  Widget _buildDeliveryCard(PrintOrderDeliveryModel d) {
    final isPartial = d.status == 'partially_received';
    final statusColor = isPartial ? Color(0xFFD97706) : Color(0xFF059669);
    final statusLabel = isPartial ? 'Partially Received' : 'Fully Received';

    return Container(
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPartial
              ? Color(0xFFD97706).withValues(alpha: 0.5)
              : Color(0xFF059669).withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color strip
            Container(width: 5, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Challan Number + Status Chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: PmsTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: PmsTheme.textSecondary),
                                ),
                                child: Text(
                                  d.deliveryNumber,
                                  style: const TextStyle(
                                    color: PmsTheme.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: PmsTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF059669)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 12,
                                      color: Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Challan: ${d.challanNumber}',
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
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

                    // Row 2: Linked PO + Vendor Name
                    Row(
                      children: [
                        if (d.printOrder != null) ...[
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PrintOrderDetailsScreen(
                                    printOrder: d.printOrder!,
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: PmsTheme.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.print_rounded,
                                    color: PmsTheme.primary,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    d.printOrder!.poNumber,
                                    style: const TextStyle(
                                      color: PmsTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            d.printOrder?.vendor?.name ?? 'Vendor',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PmsTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items Breakdown
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: d.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    it.productName,
                                    style: const TextStyle(
                                      color: PmsTheme.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${it.receivedQuantity} ',
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '(Total ${it.totalReceivedToDate}/${it.orderedQuantity})',
                                  style: const TextStyle(
                                    color: PmsTheme.textSecondary,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (d.remarks != null && d.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: ${d.remarks}',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Footer: Date & Received By
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Wing: ${d.printOrder?.wing?.name ?? "General"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${d.deliveryDate ?? ""} · By: ${d.receivedByUser?.name ?? "Admin"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}
