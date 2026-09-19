import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/models/vendor_model.dart';
import 'package:pms/repositories/print_order_repository.dart';
import 'package:pms/repositories/vendor_repository.dart';
import 'package:pms/services/api_service.dart';
import 'package:pms/theme/pms_theme.dart';
import 'package:pms/views/delivery_logs/update_delivery_dialog.dart';
import 'package:pms/widgets/app_gradient_background.dart';
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
  final Map<int, TextEditingController> _unitPriceControllers = {};
  double _selectedGstRate = 0.0;
  final TextEditingController _quoteRemarksController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _po = widget.printOrder;
    _initQuoteForm();
  }

  void _initQuoteForm() {
    _unitPriceControllers.clear();
    for (final item in _po.items) {
      final initialVal = (item.unitPrice != null && item.unitPrice! > 0)
          ? (item.unitPrice! % 1 == 0
              ? item.unitPrice!.toInt().toString()
              : item.unitPrice!.toString())
          : '';
      _unitPriceControllers[item.id] = TextEditingController(text: initialVal);
    }
    _selectedGstRate = _po.gstRate;
    _quoteRemarksController.text = _po.quoteRemarks ?? '';
  }

  @override
  void dispose() {
    for (final c in _unitPriceControllers.values) {
      c.dispose();
    }
    _quoteRemarksController.dispose();
    super.dispose();
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
      _cleanPhone == '';

  bool get isManager => _role == 'manager';

  bool get canSeeVendorDetails =>
      isSuperAdmin || isManager || isAssignedVendor;

  bool get canSeePricing =>
      isSuperAdmin || isManager || isAssignedVendor;

  double get _calculatedSubtotal {
    double sub = 0.0;
    for (final item in _po.items) {
      final text = _unitPriceControllers[item.id]?.text.trim() ?? '';
      final price = double.tryParse(text) ?? 0.0;
      sub += price * item.quantity;
    }
    return sub;
  }

  double get _calculatedGstAmount {
    return (_calculatedSubtotal * _selectedGstRate) / 100.0;
  }

  double get _calculatedGrandTotal {
    return _calculatedSubtotal + _calculatedGstAmount;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'partially_received':
        return const Color(0xFFD97706);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'in_production':
      case 'in_printing':
      case 'pending_vendor':
      case 'accepted':
      case 'dispatched':
      default:
        return PmsTheme.primary;
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

  Color _getQuotationStatusColor(String? qStatus) {
    switch (qStatus?.toLowerCase()) {
      case 'quote_approved':
        return const Color(0xFF059669);
      case 'quote_submitted':
        return const Color(0xFF2563EB);
      case 'revision_requested':
        return const Color(0xFFD97706);
      case 'pending_quote':
      default:
        return const Color(0xFF9333EA);
    }
  }

  String _getQuotationStatusLabel(String? qStatus) {
    switch (qStatus?.toLowerCase()) {
      case 'quote_approved':
        return 'Quote Approved';
      case 'quote_submitted':
        return 'Quote Submitted';
      case 'revision_requested':
        return 'Revision Requested';
      case 'pending_quote':
      default:
        return 'Pending Quote';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final updated = await PrintOrderRepository().getPrintOrderDetails(_po.id);
      if (mounted) {
        setState(() {
          _po = updated;
          _initQuoteForm();
        });
      }
    } catch (_) {}

    if (mounted) {
      if (_cleanPhone.isNotEmpty) {
        context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: _cleanPhone));
      } else {
        context.read<PrintOrderBloc>().add(const FetchPrintOrders());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrintOrderBloc, PrintOrderState>(
      listener: (context, state) {
        if (state is PrintOrderActionSuccess && state.printOrder.id == _po.id) {
          setState(() {
            _po = state.printOrder;
            _initQuoteForm();
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else if (state is PrintOrderError) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      },
      child: AppGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: PmsTheme.glassSurface,
            elevation: 0,
            title: Text(
              _po.poNumber,
              style: const TextStyle(
                color: PmsTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            iconTheme: const IconThemeData(color: PmsTheme.textPrimary),
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
          body: RefreshIndicator(
            color: PmsTheme.primary,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVendorCard(),
                  const SizedBox(height: 14),
                  _buildDeliveryCard(),
                  const SizedBox(height: 14),
                  if (_po.printOrderRemarks != null &&
                      _po.printOrderRemarks!.isNotEmpty) ...[
                    _buildRemarksCard(),
                    const SizedBox(height: 14),
                  ],
                  _buildProductsList(),
                  const SizedBox(height: 14),
                  if (canSeePricing) ...[
                    if (isAssignedVendor &&
                        (_po.isPendingQuote || _po.isRevisionRequested))
                      _buildVendorQuotationForm()
                    else
                      _buildQuotationReviewCard(),
                    const SizedBox(height: 14),
                  ],
                  _buildActivityTimeline(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(),
        ),
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
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
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
                  color: PmsTheme.primary,
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
                    color: PmsTheme.background,
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
                  color: PmsTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PmsTheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.print_rounded,
                  color: PmsTheme.primary,
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
                        color: PmsTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (vendorMobile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        vendorMobile,
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
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
                    backgroundColor: const Color(0xFF059669).withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          if (vendorAddress != null && vendorAddress.isNotEmpty) ...[
            const Divider(color: PmsTheme.glassBorder, height: 20),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: PmsTheme.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vendorAddress,
                    style: const TextStyle(
                      color: PmsTheme.textSecondary,
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
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY TARGET & SCHEDULE',
            style: TextStyle(
              color: PmsTheme.textSecondary,
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
                      style: TextStyle(color: PmsTheme.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _po.wing?.name ?? 'General Wing',
                      style: const TextStyle(
                        color: PmsTheme.textPrimary,
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
                      style: TextStyle(color: PmsTheme.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_po.expectedDeliveryDate ?? "ASAP"} (${_po.expectedDeliveryTime ?? "Anytime"})',
                      style: const TextStyle(
                        color: PmsTheme.textPrimary,
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
            const Divider(color: PmsTheme.glassBorder, height: 20),
            const Text(
              'Requester Remarks (Read-Only):',
              style: TextStyle(color: PmsTheme.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              _po.requesterRemarks!,
              style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 11),
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
        color: const Color(0xFFFFF7ED).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
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
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
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
                  color: PmsTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_po.items.length} Products',
                  style: const TextStyle(
                    color: PmsTheme.textSecondary,
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
              style: TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: PmsTheme.glassBorder, height: 16),
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
                            color: PmsTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: PmsTheme.primary,
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
                                  color: PmsTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: it.receivedQuantity >= it.quantity
                                          ? const Color(0xFF059669)
                                                .withValues(alpha: 0.15)
                                          : (it.receivedQuantity > 0
                                                ? const Color(0xFFD97706)
                                                      .withValues(alpha: 0.15)
                                                : PmsTheme.primary
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
                                            ? const Color(0xFF059669)
                                            : (it.receivedQuantity > 0
                                                  ? const Color(0xFFD97706)
                                                  : PmsTheme.primary),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (it.size != null &&
                                      it.size!.isNotEmpty)
                                    Text(
                                      'Size: ${it.size}',
                                      style: const TextStyle(
                                        color: PmsTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (canSeePricing && it.unitPrice != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFF059669)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '₹${it.unitPrice}/pc = ₹${(it.totalPrice ?? (it.unitPrice! * it.quantity)).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
                            color: PmsTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PmsTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                color: PmsTheme.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  it.attachmentName ?? 'Download Print Proof',
                                  style: const TextStyle(
                                    color: PmsTheme.primary,
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

  // ==========================================
  // VENDOR QUOTATION FORM
  // ==========================================
  Widget _buildVendorQuotationForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _po.isRevisionRequested
              ? const Color(0xFFD97706)
              : PmsTheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.request_quote_rounded,
                    color: _po.isRevisionRequested
                        ? const Color(0xFFD97706)
                        : PmsTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _po.isRevisionRequested
                        ? 'REVISE PRICE QUOTATION'
                        : 'SUBMIT PRICE QUOTATION',
                    style: TextStyle(
                      color: _po.isRevisionRequested
                          ? const Color(0xFFD97706)
                          : PmsTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getQuotationStatusColor(_po.quotationStatus)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getQuotationStatusLabel(_po.quotationStatus),
                  style: TextStyle(
                    color: _getQuotationStatusColor(_po.quotationStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Revision Alert Banner
          if (_po.isRevisionRequested &&
              _po.quoteRemarks != null &&
              _po.quoteRemarks!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Requested Quotation Revision:',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _po.quoteRemarks!,
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Text(
            'Enter your per-piece / per-print unit price for each item. The system will auto-calculate line item totals and grand total.',
            style: TextStyle(color: PmsTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Items Unit Price Inputs
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _po.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final it = _po.items[idx];
              final controller = _unitPriceControllers[it.id];
              final enteredPrice =
                  double.tryParse(controller?.text.trim() ?? '') ?? 0.0;
              final lineTotal = enteredPrice * it.quantity;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PmsTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.productName,
                            style: const TextStyle(
                              color: PmsTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${it.quantity} ${it.size != null && it.size!.isNotEmpty ? "• Size: ${it.size}" : ""}',
                            style: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Rate / pc',
                          labelStyle: const TextStyle(fontSize: 11),
                          prefixText: '₹ ',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Item Total',
                            style: TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            '₹${lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // GST Rate Selector
          const Text(
            'GST Rate (%)',
            style: TextStyle(
              color: PmsTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
              final isSelected = _selectedGstRate == rate;
              return ChoiceChip(
                label: Text(
                  rate == 0 ? '0% (Exempt)' : '${rate.toInt()}%',
                  style: TextStyle(
                    color: isSelected ? Colors.white : PmsTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: PmsTheme.primary,
                backgroundColor: PmsTheme.background,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedGstRate = rate;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Real-time Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PmsTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PmsTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Items Subtotal:',
                      style: TextStyle(
                        color: PmsTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${_calculatedSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: PmsTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST (${_selectedGstRate.toInt()}%):',
                      style: const TextStyle(
                        color: PmsTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${_calculatedGstAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: PmsTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total (Payable):',
                      style: TextStyle(
                        color: PmsTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₹${_calculatedGrandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quotation Remarks
          TextField(
            controller: _quoteRemarksController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Vendor Quote Remarks / Delivery Timeline Notes',
              hintText: 'e.g., Rates valid for 15 days, 2 days turnaround time...',
              hintStyle: const TextStyle(fontSize: 11),
              labelStyle: const TextStyle(fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmAndSubmitQuotation,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _po.isRevisionRequested
                    ? 'Submit Revised Quotation to Admin'
                    : 'Submit Price Quotation to Admin',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndSubmitQuotation() {
    final List<Map<String, dynamic>> itemsPayload = [];
    for (final item in _po.items) {
      final text = _unitPriceControllers[item.id]?.text.trim() ?? '';
      final price = double.tryParse(text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a valid rate per unit for "${item.productName}"',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
      itemsPayload.add({
        'id': item.id,
        'unit_price': price,
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Price Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to submit this quotation to Admin for approval?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                      Text(
                        '₹${_calculatedSubtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST (${_selectedGstRate.toInt()}%):',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '₹${_calculatedGstAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_calculatedGrandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSubmitting = true;
              });
              context.read<PrintOrderBloc>().add(
                    SubmitQuotationEvent(
                      printOrderId: _po.id,
                      items: itemsPayload,
                      gstRate: _selectedGstRate,
                      quoteRemarks: _quoteRemarksController.text.trim(),
                      phone: _cleanPhone,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUOTATION REVIEW & DETAILS CARD
  // ==========================================
  Widget _buildQuotationReviewCard() {
    final hasQuoteFigures =
        _po.grandTotalAmount != null && _po.grandTotalAmount! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getQuotationStatusColor(_po.quotationStatus)
              .withValues(alpha: 0.5),
        ),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: _getQuotationStatusColor(_po.quotationStatus),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VENDOR PRICE QUOTATION',
                    style: TextStyle(
                      color: PmsTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getQuotationStatusColor(_po.quotationStatus)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getQuotationStatusColor(_po.quotationStatus),
                  ),
                ),
                child: Text(
                  _getQuotationStatusLabel(_po.quotationStatus),
                  style: TextStyle(
                    color: _getQuotationStatusColor(_po.quotationStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasQuoteFigures) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8B4FE)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quotation is pending. The assigned vendor has not yet submitted their price quotation for this order.',
                      style: TextStyle(
                        color: Color(0xFF6B21A8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Quotation Price Breakdown Table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PmsTheme.glassBorder),
              ),
              child: Column(
                children: [
                  ..._po.items.map((it) {
                    final unitP = it.unitPrice ?? 0.0;
                    final totalP = it.totalPrice ?? (unitP * it.quantity);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${it.productName} (${it.quantity} @ ₹$unitP/pc)',
                              style: const TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '₹${totalP.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: PmsTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${(_po.subtotalAmount ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST (${_po.gstRate.toStringAsFixed(0)}%):',
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${(_po.gstAmount ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total Amount:',
                        style: TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹${(_po.grandTotalAmount ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_po.quoteRemarks != null && _po.quoteRemarks!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: PmsTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Vendor Note: ${_po.quoteRemarks}',
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Admin Decision Action Buttons
          if (isSuperAdmin || isManager) ...[
            const SizedBox(height: 14),
            if (_po.isQuoteSubmitted) ...[
              // Approve Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmApproveQuotation(),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'Approve Quotation (₹${(_po.grandTotalAmount ?? 0.0).toStringAsFixed(2)}) & Start Print',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary Decision Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRevisionDialog(),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      label: const Text(
                        'Request Revision',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD97706)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReassignDialog(),
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                      label: const Text(
                        'Send to Other',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_po.isPendingQuote || _po.isRevisionRequested) ...[
              // Option to reassign if vendor not responding
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReassignDialog(),
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: Color(0xFF4F46E5),
                  ),
                  label: const Text(
                    'Reassign to Another Vendor for Quotation',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _confirmApproveQuotation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Vendor Quotation?'),
        content: Text(
          'Are you sure you want to approve the quotation of ₹${(_po.grandTotalAmount ?? 0.0).toStringAsFixed(2)} for ${_po.vendor?.name ?? "this vendor"}?\n\nThe order status will move to In Printing and the vendor will be notified to begin production.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PrintOrderBloc>().add(
                    ApproveQuotationEvent(
                      printOrderId: _po.id,
                      phone: _cleanPhone,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Start Print'),
          ),
        ],
      ),
    );
  }

  void _showRevisionDialog() {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Quotation Revision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify what changes the vendor needs to make (e.g. rate reduction, delivery timeline adjustment):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: remarksCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Price is too high, please reduce to ₹0.40/print...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = remarksCtrl.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter revision remarks for the vendor'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              context.read<PrintOrderBloc>().add(
                    RequestQuotationRevisionEvent(
                      printOrderId: _po.id,
                      remarks: text,
                      phone: _cleanPhone,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog() {
    int? selectedVendorId;
    final remarksCtrl = TextEditingController();
    List<VendorModel> vendors = [];
    bool isLoadingVendors = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoadingVendors && vendors.isEmpty) {
            VendorRepository().getVendors().then((list) {
              if (ctx.mounted) {
                setDialogState(() {
                  vendors = list.where((v) => v.id != _po.vendorId).toList();
                  isLoadingVendors = false;
                  if (vendors.isNotEmpty) {
                    selectedVendorId = vendors.first.id;
                  }
                });
              }
            }).catchError((_) {
              if (ctx.mounted) {
                setDialogState(() {
                  isLoadingVendors = false;
                });
              }
            });
          }

          return AlertDialog(
            title: const Text('Send to Another Vendor'),
            content: isLoadingVendors
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a new vendor to request a fresh price quotation. Previous quotation figures will be reset.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      if (vendors.isEmpty)
                        const Text(
                          'No other active vendors available.',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                          ),
                        )
                      else ...[
                        const Text(
                          'Select Vendor:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          initialValue: selectedVendorId,
                          items: vendors.map((v) {
                            return DropdownMenuItem<int>(
                              value: v.id,
                              child: Text(
                                '${v.name} (${v.mobile1})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedVendorId = val;
                            });
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: remarksCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reassignment Remarks (Optional)',
                            labelStyle: const TextStyle(fontSize: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (!isLoadingVendors && vendors.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    if (selectedVendorId == null) return;
                    Navigator.pop(ctx);
                    context.read<PrintOrderBloc>().add(
                          ReassignVendorEvent(
                            printOrderId: _po.id,
                            vendorId: selectedVendorId!,
                            remarks: remarksCtrl.text.trim(),
                            phone: _cleanPhone,
                          ),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reassign & Request Quote'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUCTION & DISPATCH AUDIT LOG',
            style: TextStyle(
              color: PmsTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (_po.activities.isEmpty)
            const Text(
              'No history recorded yet.',
              style: TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _po.activities.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: PmsTheme.glassBorder, height: 12),
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
                    const Icon(Icons.circle, size: 8, color: PmsTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sanitizeActivityRemarks(act.remarks ?? act.action),
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
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
      RegExp(r'''Vendor\s*['"][^'"]+['"]''', caseSensitive: false),
      "Vendor 'XXXX'",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"dispatched to Vendor\s+[^\s,;]+(?:\s+[^\s,;]+)*\s+by", caseSensitive: false),
      "dispatched to Vendor 'XXXX' by",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+Vendor\s+[^,;\r\n]+\s+was cancelled", caseSensitive: false),
      "to Printing Vendor was cancelled",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+[^,;\r\n]+\s+was cancelled", caseSensitive: false),
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
          color: PmsTheme.glassSurface,
          border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
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

    // 2. If quote approved and user can record delivery (Superadmin, Manager, Store Incharge)
    if (_po.isQuoteApproved && canRecordDelivery) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: PmsTheme.glassSurface,
          border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
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

    // 3. For Vendor: Status awareness banner
    if (isAssignedVendor) {
      String bannerText;
      Color bannerBg;
      Color bannerBorder;
      Color bannerTextCol;
      IconData bannerIcon;

      if (_po.isQuoteApproved) {
        bannerText = 'Quotation Approved! Please print and deliver to campus.';
        bannerBg = const Color(0xFFECFDF5);
        bannerBorder = const Color(0xFFA7F3D0);
        bannerTextCol = const Color(0xFF065F46);
        bannerIcon = Icons.check_circle_outline_rounded;
      } else if (_po.isQuoteSubmitted) {
        bannerText = 'Quotation Submitted! Awaiting Admin / Manager approval.';
        bannerBg = const Color(0xFFEFF6FF);
        bannerBorder = const Color(0xFFBFDBFE);
        bannerTextCol = const Color(0xFF1E40AF);
        bannerIcon = Icons.hourglass_top_rounded;
      } else if (_po.isRevisionRequested) {
        bannerText = 'Quotation Revision Requested. Please submit revised prices above.';
        bannerBg = const Color(0xFFFEF3C7);
        bannerBorder = const Color(0xFFFCD34D);
        bannerTextCol = const Color(0xFF92400E);
        bannerIcon = Icons.warning_amber_rounded;
      } else {
        bannerText = 'Price Quotation Required. Please enter per-piece prices above and submit.';
        bannerBg = const Color(0xFFF5F3FF);
        bannerBorder = const Color(0xFFDDD6FE);
        bannerTextCol = const Color(0xFF6B21A8);
        bannerIcon = Icons.request_quote_outlined;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: PmsTheme.glassSurface,
          border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bannerBorder),
            ),
            child: Row(
              children: [
                Icon(
                  bannerIcon,
                  color: bannerTextCol,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      color: bannerTextCol,
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
