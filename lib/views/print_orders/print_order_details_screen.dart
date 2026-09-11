import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/services/api_service.dart';
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
  State<PrintOrderDetailsScreen> createState() =>
      _PrintOrderDetailsScreenState();
}

class _PrintOrderDetailsScreenState extends State<PrintOrderDetailsScreen> {
  late PrintOrderModel _po;

  @override
  void initState() {
    super.initState();
    _po = widget.printOrder;
  }

  String get _role => (widget.userProfile?.role ?? '').toLowerCase();
  String get _cleanPhone => (widget.userProfile?.phone ?? '')
      .replaceAll(RegExp(r'^\+?91'), '')
      .replaceAll(RegExp(r'\D'), '');

  bool get isAssignedVendor {
    final vendorPhone1 = (_po.vendor?.mobile1 ?? '')
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');
    final vendorPhone2 = (_po.vendor?.mobile2 ?? '')
        .replaceAll(RegExp(r'^\+?91'), '')
        .replaceAll(RegExp(r'\D'), '');
    return _role == 'vendor' ||
        (_cleanPhone.isNotEmpty &&
            (_cleanPhone == vendorPhone1 || _cleanPhone == vendorPhone2));
  }

  bool get isSuperAdmin =>
      _role == 'superadmin' ||
      _role == 'super admin' ||
      _cleanPhone == '7414055310';

  bool get isManager => _role == 'manager';

  bool get canSeeVendorDetails =>
      isSuperAdmin || isManager || isAssignedVendor;

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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          title: Text(
            _po.poNumber,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
    final vendorName = canSeeVendorDetails
        ? (v?.name ?? 'Assigned Vendor')
        : 'XXXX (Printing Vendor)';
    final vendorMobile = canSeeVendorDetails
        ? (v?.mobile1 != null ? '+91 ${v!.mobile1}' : null)
        : '+91 XXXXX XXXXX';
    final vendorAddress = canSeeVendorDetails ? v?.address : 'XXXX';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
                  color: Color(0xFF2563EB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (_po.purchaseRequest != null)
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
                    'Linked PR: ${_po.purchaseRequest!.prNumber}',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
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
                  color: Color(0xFF2563EB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFF2563EB).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.print_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (vendorMobile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        vendorMobile,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canSeeVendorDetails && v?.mobile1 != null)
                IconButton(
                  onPressed: () => _launchUrl('tel:+91${v!.mobile1}'),
                  icon: const Icon(
                    Icons.phone_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xFF059669).withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          if (vendorAddress != null && vendorAddress.isNotEmpty) ...[
            const Divider(color: Color(0xFFE2E8F0), height: 20),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF64748B),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vendorAddress,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
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
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY TARGET & SCHEDULE',
            style: TextStyle(
              color: Color(0xFF64748B),
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
                    const Text(
                      'Target Wing / Branch',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _po.wing?.name ?? 'General Wing',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
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
                    const Text(
                      'Expected Delivery',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_po.expectedDeliveryDate ?? 'ASAP'} (${_po.expectedDeliveryTime ?? 'Anytime'})',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
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
            const Divider(color: Color(0xFFE2E8F0), height: 20),
            const Text(
              'Requester Remarks (Read-Only):',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              _po.requesterRemarks!,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
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
        color: Color(0xFFFFF7ED).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFD97706).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFD97706),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'PRINT PRODUCTION INSTRUCTIONS',
                style: TextStyle(
                  color: Color(0xFFD97706),
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
              color: Color(0xFF92400E),
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
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
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
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_po.items.length} Products',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_po.items.isEmpty)
            const Text(
              'No items attached.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
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
                            color: Color(0xFF2563EB).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
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
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: it.receivedQuantity >= it.quantity
                                          ? Color(0xFF059669)
                                                .withValues(alpha: 0.15)
                                          : (it.receivedQuantity > 0
                                                ? Color(0xFFD97706)
                                                      .withValues(alpha: 0.15)
                                                : Color(0xFF2563EB)
                                                      .withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      it.receivedQuantity > 0
                                          ? 'Received: ${it.receivedQuantity} / ${it.quantity}'
                                          : 'Qty: ${it.quantity}',
                                      style: TextStyle(
                                        color:
                                            it.receivedQuantity >= it.quantity
                                            ? Color(0xFF059669)
                                            : (it.receivedQuantity > 0
                                                  ? Color(0xFFD97706)
                                                  : Color(0xFF2563EB)),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (it.size != null &&
                                      it.size!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Size: ${it.size}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
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
                              : '${ApiService.baseUrl}/storage/${it.attachmentPath}';
                          _launchUrl(fullUrl);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                color: Color(0xFF2563EB),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  it.attachmentName ?? 'Download Print Proof',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
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
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUCTION & DISPATCH AUDIT LOG',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (_po.activities.isEmpty)
            const Text(
              'No history recorded yet.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.activities.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFFE2E8F0), height: 12),
              itemBuilder: (context, idx) {
                final act = _po.activities[idx];
                final String dateStr;
                if (act.createdAt != null) {
                  final dt = act.createdAt!.toLocal();
                  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
                  final min = dt.minute.toString().padLeft(2, '0');
                  dateStr = '${dt.day}/${dt.month} $hour:$min $ampm';
                } else {
                  dateStr = '';
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sanitizeActivityRemarks(act.remarks ?? act.action),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
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

  String _sanitizeActivityRemarks(String remarks) {
    if (canSeeVendorDetails) return remarks;

    String sanitized = remarks;
    if (_po.vendor?.name != null && _po.vendor!.name.isNotEmpty) {
      final trimmed = _po.vendor!.name.trim();
      if (trimmed.isNotEmpty && trimmed != 'XXXX' && !trimmed.contains('XXXX')) {
        sanitized = sanitized.replaceAll(
          RegExp(RegExp.escape(trimmed), caseSensitive: false),
          'XXXX',
        );
      }
    }

    sanitized = sanitized.replaceAll(
      RegExp(r"Vendor\s*['\x22][^'\x22]+['\x22]", caseSensitive: false),
      "Vendor 'XXXX'",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"dispatched to Vendor\s+[^\s,;]+(?:\s+[^\s,;]+)*\s+by", caseSensitive: false),
      "dispatched to Vendor 'XXXX' by",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+Vendor\s+[^,;\n\r]+\s+was cancelled", caseSensitive: false),
      "to Printing Vendor was cancelled",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+[^,;\n\r]+\s+was cancelled", caseSensitive: false),
      "to Printing Vendor was cancelled",
    );

    return sanitized;
  }

  Widget? _buildBottomActionBar() {
    final isStoreIncharge = _role == 'store incharge';
    final canRecordDelivery = isSuperAdmin || isManager || isStoreIncharge;
    final currentStatus = _po.status.toLowerCase();

    // 1. If completed, show completed badge
    if (currentStatus == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order Fully Received & Completed at Campus.',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Can record delivery (Superadmin, Manager, Store Incharge)
    if (canRecordDelivery) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
              'Record Delivery Receipt (Challan)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // 3. For Vendor: Show info banner
    if (isAssignedVendor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.print_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order is assigned for printing. Please print & deliver to campus.',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return null;
  }
}
