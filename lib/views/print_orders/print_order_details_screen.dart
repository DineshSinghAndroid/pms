import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/views/delivery_logs/update_delivery_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class PrintOrderDetailsScreen extends StatefulWidget {
  final PrintOrderModel printOrder;
  final UserModel? userProfile;

  const PrintOrderDetailsScreen({
    super.key,
    required this.printOrder,
    this.userProfile,
  });

  @override
  State<PrintOrderDetailsScreen> createState() => _PrintOrderDetailsScreenState();
}

class _PrintOrderDetailsScreenState extends State<PrintOrderDetailsScreen> {
  late PrintOrderModel _po;

  @override
  void initState() {
    super.initState();
    _po = widget.printOrder;
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
        return 'Vendor Accepted';
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUpdateStatusDialog(String newStatus, String actionTitle) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          actionTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update status for ${_po.poNumber} to '${_getStatusLabel(newStatus)}'?",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Optional remarks or note...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              final phone = widget.userProfile?.phone;
              context.read<PrintOrderBloc>().add(
                    UpdatePrintOrderStatusEvent(
                      printOrderId: _po.id,
                      status: newStatus,
                      remarks: remarksController.text.trim().isNotEmpty
                          ? remarksController.text.trim()
                          : null,
                      phone: phone,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrintOrderBloc, PrintOrderState>(
      listener: (context, state) {
        if (state is PrintOrderActionSuccess && state.printOrder.id == _po.id) {
          setState(() {
            _po = state.printOrder;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else if (state is PrintOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: Text(
            _po.poNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(_po.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor(_po.status)),
              ),
              child: Text(
                _getStatusLabel(_po.status),
                style: TextStyle(
                  color: _getStatusColor(_po.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Info Card
              _buildVendorCard(),
              const SizedBox(height: 14),

              // Target Wing & Delivery Target
              _buildDeliveryCard(),
              const SizedBox(height: 14),

              // Production Remarks (if present)
              if (_po.printOrderRemarks != null &&
                  _po.printOrderRemarks!.isNotEmpty) ...[
                _buildRemarksCard(),
                const SizedBox(height: 14),
              ],

              // Products List
              _buildProductsList(),
              const SizedBox(height: 14),

              // Activity Timeline
              _buildActivityTimeline(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActionBar(),
      ),
    );
  }

  Widget _buildVendorCard() {
    final v = _po.vendor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ASSIGNED PRINTING VENDOR',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (_po.purchaseRequest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Linked PR: ${_po.purchaseRequest!.prNumber}',
                    style: const TextStyle(
                      color: Color(0xFFFB7185),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.print_rounded, color: Color(0xFF818CF8), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v?.name ?? 'Assigned Vendor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (v?.mobile1 != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+91 ${v!.mobile1}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (v?.mobile1 != null)
                IconButton(
                  onPressed: () => _launchUrl('tel:+91${v!.mobile1}'),
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          if (v?.address != null && v!.address!.isNotEmpty) ...[
            const Divider(color: Color(0xFF334155), height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    v.address!,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY TARGET & SCHEDULE',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Wing / Branch',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      _po.wing?.name ?? 'General Wing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expected Delivery',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      '${_po.expectedDeliveryDate ?? 'ASAP'} (${_po.expectedDeliveryTime ?? 'Anytime'})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_po.requesterRemarks != null &&
              _po.requesterRemarks!.isNotEmpty) ...[
            const Divider(color: Color(0xFF334155), height: 20),
            const Text('Requester Remarks (Read-Only):',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              _po.requesterRemarks!,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF78350F).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 16),
              SizedBox(width: 6),
              Text(
                'PRINT PRODUCTION INSTRUCTIONS',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _po.printOrderRemarks!,
            style: const TextStyle(
              color: Color(0xFFFEF3C7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRINT ITEMS & PROOFS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_po.items.length} Products',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_po.items.isEmpty)
            const Text(
              'No items attached.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF334155), height: 16),
              itemBuilder: (context, idx) {
                final it = _po.items[idx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: it.receivedQuantity >= it.quantity
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : (it.receivedQuantity > 0
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                              : const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      it.receivedQuantity > 0
                                          ? 'Received: ${it.receivedQuantity} / ${it.quantity}'
                                          : 'Qty: ${it.quantity}',
                                      style: TextStyle(
                                        color: it.receivedQuantity >= it.quantity
                                            ? const Color(0xFF34D399)
                                            : (it.receivedQuantity > 0
                                                ? const Color(0xFFFBBF24)
                                                : const Color(0xFF93C5FD)),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (it.size != null && it.size!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Size: ${it.size}',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (it.attachmentPath != null &&
                        it.attachmentPath!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          final fullUrl = it.attachmentPath!.startsWith('http')
                              ? it.attachmentPath!
                              : 'http://192.168.1.146:8000/storage/${it.attachmentPath}';
                          _launchUrl(fullUrl);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.download_rounded,
                                  color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  it.attachmentName ?? 'Download Print Proof',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUCTION & DISPATCH AUDIT LOG',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (_po.activities.isEmpty)
            const Text(
              'No history recorded yet.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.activities.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF334155), height: 12),
              itemBuilder: (context, idx) {
                final act = _po.activities[idx];
                final dateStr = act.createdAt != null
                    ? '${act.createdAt!.day}/${act.createdAt!.month} ${act.createdAt!.hour.toString().padLeft(2, '0')}:${act.createdAt!.minute.toString().padLeft(2, '0')}'
                    : '';
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        act.remarks ?? act.action,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget? _buildBottomActionBar() {
    final role = (widget.userProfile?.role ?? '').toLowerCase();
    final isDesigner = role == 'designer';
    final cleanPhone = (widget.userProfile?.phone ?? '')
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');
    final vendorPhone1 = (_po.vendor?.mobile1 ?? '')
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');
    final vendorPhone2 = (_po.vendor?.mobile2 ?? '')
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');
    final isAssignedVendor = role == 'vendor' ||
        (cleanPhone.isNotEmpty &&
            (cleanPhone == vendorPhone1 || cleanPhone == vendorPhone2));
    final isSuperAdmin = role == 'superadmin' ||
        role == 'super admin' ||
        cleanPhone == '7414055310';

    // 1. Designers must NEVER see or execute vendor order lifecycle actions
    if (isDesigner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF38BDF8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dispatched to ${_po.vendor?.name ?? "Vendor"}. Waiting for vendor production & delivery.',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Only the assigned Vendor or Superadmin can change print order statuses
    if (!isAssignedVendor && !isSuperAdmin) {
      return null;
    }

    final currentStatus = _po.status.toLowerCase();

    // 3. When order is Dispatched or Partially Received:
    // VENDORS CANNOT mark as completed or received.
    // ADMINS get the "Record / Update Delivery" button.
    if (currentStatus == 'dispatched' || currentStatus == 'partially_received') {
      if (!isSuperAdmin) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Color(0xFF334155))),
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: currentStatus == 'partially_received'
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                      : const Color(0xFFA855F7).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    currentStatus == 'partially_received'
                        ? Icons.pending_actions_rounded
                        : Icons.local_shipping_outlined,
                    color: currentStatus == 'partially_received'
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFC084FC),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentStatus == 'partially_received'
                          ? 'Order is Partially Received by Admin. Remaining products are pending delivery verification.'
                          : 'Material marked as Dispatched. Waiting for Admin / Store to verify delivery & record receipts.',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Superadmin: Provide "Record / Update Delivery" button
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Color(0xFF334155))),
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: () async {
                final res = await showDialog(
                  context: context,
                  builder: (_) => UpdateDeliveryDialog(
                    printOrders: [_po],
                    preselectedOrder: _po,
                    userProfile: widget.userProfile,
                  ),
                );
                if (res == true && mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text(
                'Record / Update Delivery (Challan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      }
    }

    String? nextStatus;
    String? btnLabel;
    Color btnColor = const Color(0xFF6366F1);
    IconData btnIcon = Icons.check_circle_outline;

    switch (currentStatus) {
      case 'pending_vendor':
        nextStatus = 'accepted';
        btnLabel = 'Accept Print Order';
        btnColor = const Color(0xFF3B82F6);
        btnIcon = Icons.thumb_up_alt_outlined;
        break;
      case 'accepted':
        nextStatus = 'in_production';
        btnLabel = 'Start Production / Printing';
        btnColor = const Color(0xFF6366F1);
        btnIcon = Icons.precision_manufacturing_outlined;
        break;
      case 'in_production':
        nextStatus = 'dispatched';
        btnLabel = 'Dispatch Printed Material';
        btnColor = const Color(0xFFA855F7);
        btnIcon = Icons.local_shipping_outlined;
        break;
      default:
        return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _showUpdateStatusDialog(nextStatus!, btnLabel!),
          icon: Icon(btnIcon, size: 18),
          label: Text(
            btnLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
