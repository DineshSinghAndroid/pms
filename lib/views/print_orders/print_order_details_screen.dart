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
  final Map<int, double> _itemGstRates = {};
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
    _itemGstRates.clear();
    for (final item in _po.items) {
      final initialVal = (item.unitPrice != null && item.unitPrice! > 0)
          ? (item.unitPrice! % 1 == 0
              ? item.unitPrice!.toInt().toString()
              : item.unitPrice!.toString())
          : '';
      _unitPriceControllers[item.id] = TextEditingController(text: initialVal);
      _itemGstRates[item.id] = item.gstRate > 0
          ? item.gstRate
          : (_po.gstRate > 0 ? _po.gstRate : 0.0);
    }
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
      _role == 'super_admin' ||
      widget.userProfile?.isSuperAdmin == true ||
      _cleanPhone == '';

  bool get isManager => _role == 'manager';
  bool get isStoreIncharge =>
      _role == 'store incharge' ||
      _role == 'store_incharge' ||
      widget.userProfile?.role == 'Store Incharge';
  bool get isWingIncharge => widget.userProfile?.isWingIncharge ?? false;

  bool get canSeeVendorDetails =>
      isSuperAdmin || isManager || isStoreIncharge || isAssignedVendor;

  bool get canSeePricing =>
      isSuperAdmin || isManager || isAssignedVendor;

  bool get canUpdateDelivery =>
      isSuperAdmin || isManager || isStoreIncharge;

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
    double totalTax = 0.0;
    for (final item in _po.items) {
      final text = _unitPriceControllers[item.id]?.text.trim() ?? '';
      final price = double.tryParse(text) ?? 0.0;
      final itemSubtotal = price * item.quantity;
      final gstRate = _itemGstRates[item.id] ?? 0.0;
      totalTax += (itemSubtotal * gstRate) / 100.0;
    }
    return totalTax;
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

  String _getAttachmentUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = ApiService.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    if (cleanPath.startsWith('storage/')) {
      return '$base/$cleanPath';
    }
    return '$base/storage/$cleanPath';
  }

  bool _isImageFile(String? path) {
    if (path == null || path.isEmpty) return false;
    final clean = path.split('?').first.toLowerCase();
    return clean.endsWith('.png') ||
        clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.webp') ||
        clean.endsWith('.gif') ||
        clean.endsWith('.bmp') ||
        clean.endsWith('.svg');
  }

  void _showImagePreviewModal(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: PmsTheme.glassSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: PmsTheme.background,
                  border: Border(
                    bottom: BorderSide(color: PmsTheme.glassBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: PmsTheme.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      final total = loadingProgress.expectedTotalBytes;
                      final loaded = loadingProgress.cumulativeBytesLoaded;
                      return Container(
                        height: 220,
                        color: PmsTheme.background,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: PmsTheme.primary,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                total != null
                                    ? 'Loading proof (${(loaded / (1024 * 1024)).toStringAsFixed(1)} / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB)...'
                                    : 'Loading image...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PmsTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        color: PmsTheme.glassSurface,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFFDC2626),
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unable to render image directly.',
                                style: TextStyle(
                                  color: PmsTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _launchUrl(imageUrl),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Open in Browser / Downloader'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PmsTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: PmsTheme.background,
                  border: Border(
                    top: BorderSide(color: PmsTheme.glassBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(imageUrl),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text(
                          'Open / Download Full Quality Proof',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PmsTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      String trimmed = url.trim();
      if (trimmed.isEmpty) return;
      if (!trimmed.startsWith('http://') &&
          !trimmed.startsWith('https://') &&
          !trimmed.startsWith('tel:') &&
          !trimmed.startsWith('mailto:')) {
        trimmed = 'https://$trimmed';
      }
      final uri = Uri.parse(trimmed);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url $url: $e');
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
          setState(() => _isSubmitting = false);
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _po.poNumber,
                  style: const TextStyle(
                    color: PmsTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_po.wing?.name ?? 'Wing'} · ${_po.purchaseRequest?.prNumber ?? 'Direct PO'}',
                  style: const TextStyle(
                    color: PmsTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
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
                  _buildDeliveryLogsCard(),
                  const SizedBox(height: 14),
                  if (_po.printOrderRemarks != null &&
                      _po.printOrderRemarks!.isNotEmpty) ...[
                    _buildRemarksCard(),
                    const SizedBox(height: 14),
                  ],
                  _buildMasterDesignCard(),
                  const SizedBox(height: 14),
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

  void _openUpdateDeliveryDialog() async {
    final result = await showDialog(
      context: context,
      builder: (_) => UpdateDeliveryDialog(
        printOrders: [_po],
        preselectedOrder: _po,
        userProfile: widget.userProfile,
      ),
    );

    if (result == true && mounted) {
      _handleRefresh();
    }
  }

  Widget _buildDeliveryLogsCard() {
    final deliveries = _po.deliveries;
    if (deliveries.isEmpty) {
      if (!canUpdateDelivery) return const SizedBox.shrink();
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
                  'DELIVERY & CHALLAN RECEIPTS',
                  style: TextStyle(
                    color: PmsTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openUpdateDeliveryDialog,
                  icon: const Icon(Icons.add_task_rounded, size: 14),
                  label: const Text('Receive Items', style: TextStyle(fontSize: 11)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'No delivery challans recorded yet for this order.',
              style: TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'DELIVERY & CHALLAN RECEIPTS',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${deliveries.length} Challan${deliveries.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deliveries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, dIdx) {
              final d = deliveries[dIdx];
              final isPartial = d.status == 'partially_received';
              final statusColor = isPartial ? const Color(0xFFD97706) : const Color(0xFF059669);
              final statusLabel = isPartial ? 'Partially Received' : 'Fully Received';

              return Container(
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challan info + status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PmsTheme.glassSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: PmsTheme.textSecondary),
                              ),
                              child: Text(
                                d.deliveryNumber,
                                style: const TextStyle(
                                  color: PmsTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Challan: ${d.challanNumber}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items in this delivery
                    ...d.items.map((it) {
                      final hasProof = it.attachmentPath != null && it.attachmentPath!.isNotEmpty;
                      final proofUrl = hasProof ? _getAttachmentUrl(it.attachmentPath!) : '';
                      final isImage = hasProof && _isImageFile(it.attachmentPath);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasProof)
                              GestureDetector(
                                onTap: () {
                                  if (isImage) {
                                    _showImagePreviewModal(
                                      context,
                                      proofUrl,
                                      'Artwork Proof - ${it.productName}',
                                    );
                                  } else {
                                    _launchUrl(proofUrl);
                                  }
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: PmsTheme.glassBorder),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: isImage
                                      ? Image.network(
                                          proofUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_not_supported_rounded,
                                            size: 16,
                                            color: PmsTheme.textSecondary,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.insert_drive_file_rounded,
                                            size: 18,
                                            color: PmsTheme.primary,
                                          ),
                                        ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          it.productName,
                                          style: const TextStyle(
                                            color: PmsTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (canSeePricing && it.unitPrice != null && it.unitPrice! > 0)
                                        Text(
                                          '₹${it.unitPrice! % 1 == 0 ? it.unitPrice!.toInt() : it.unitPrice!.toStringAsFixed(2)}/pc',
                                          style: const TextStyle(
                                            color: PmsTheme.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (it.size != null && it.size!.isNotEmpty)
                                        Text(
                                          'Size: ${it.size}',
                                          style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 10),
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '+${it.receivedQuantity} pcs',
                                            style: const TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            ' (Total ${it.totalReceivedToDate}/${it.orderedQuantity})',
                                            style: const TextStyle(
                                              color: PmsTheme.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (canSeePricing && it.totalPrice != null && it.totalPrice! > 0)
                                        Text(
                                          'Total: ₹${it.totalPrice! % 1 == 0 ? it.totalPrice!.toInt() : it.totalPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: PmsTheme.textPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    if (d.remarks != null && d.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note: ${d.remarks}',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),
                    // Footer: Date and receiver
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d.deliveryDate ?? '',
                          style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 10),
                        ),
                        Text(
                          'Received by: ${d.receivedByUser?.name ?? "Admin"}',
                          style: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (canUpdateDelivery) ...[
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                onPressed: _openUpdateDeliveryDialog,
                icon: const Icon(Icons.add_task_rounded, size: 14),
                label: const Text('Receive Additional Items', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
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

  Widget _buildMasterDesignCard() {
    String? cloudLink;
    String? artworkFileUrl;

    if (_po.finalDesignUrl != null && _po.finalDesignUrl!.isNotEmpty) {
      if (_po.finalDesignUrl!.startsWith('http://') ||
          _po.finalDesignUrl!.startsWith('https://') ||
          _po.finalDesignType == 'link' ||
          _po.finalDesignType == 'both') {
        cloudLink = _po.finalDesignUrl;
      } else {
        artworkFileUrl = _getAttachmentUrl(_po.finalDesignUrl!);
      }
    }

    if (artworkFileUrl == null) {
      if (_po.purchaseRequest?.artworkFilePath != null &&
          _po.purchaseRequest!.artworkFilePath!.isNotEmpty) {
        artworkFileUrl =
            _getAttachmentUrl(_po.purchaseRequest!.artworkFilePath!);
      } else if (_po.items.isNotEmpty &&
          _po.items.first.attachmentPath != null &&
          _po.items.first.attachmentPath!.isNotEmpty) {
        artworkFileUrl =
            _getAttachmentUrl(_po.items.first.attachmentPath!);
      }
    }

    final artworkName = _po.finalDesignName ??
        _po.purchaseRequest?.artworkFileName ??
        'Master Artwork / Print Design';

    if ((cloudLink == null || cloudLink.isEmpty) &&
        (artworkFileUrl == null || artworkFileUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    final hasBoth = cloudLink != null &&
        cloudLink.isNotEmpty &&
        artworkFileUrl != null &&
        artworkFileUrl.isNotEmpty;
    final isImg =
        artworkFileUrl != null && _isImageFile(artworkFileUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.primary.withValues(alpha: 0.3)),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.brush_rounded,
                    color: PmsTheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'MASTER PRINT\nDESIGN & ATTACHMENTS',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: hasBoth
                      ? const Color(0xFF059669).withValues(alpha: 0.15)
                      : (cloudLink != null
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                          : const Color(0xFF059669).withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasBoth
                      ? 'Link + File Attached'
                      : (cloudLink != null ? 'Cloud Link' : 'Artwork File'),
                  style: TextStyle(
                    color: hasBoth
                        ? const Color(0xFF059669)
                        : (cloudLink != null
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF059669)),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Artwork File Preview & Download (if present)
          if (artworkFileUrl != null && artworkFileUrl.isNotEmpty) ...[
            if (isImg) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      color: PmsTheme.background,
                      child: Image.network(
                        artworkFileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showImagePreviewModal(
                            context,
                            artworkFileUrl!,
                            artworkName,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    artworkName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'View Proof',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(artworkFileUrl!),
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text(
                      'Download Artwork File',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PmsTheme.primary,
                      side: const BorderSide(color: PmsTheme.glassBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 2. Cloud / Web Design Link (if present)
          if (cloudLink != null && cloudLink.isNotEmpty) ...[
            if (artworkFileUrl != null && artworkFileUrl.isNotEmpty)
              const Divider(color: PmsTheme.glassBorder, height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.cloud_outlined,
                          color: Color(0xFF4F46E5),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud Design / Drive Link',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'High-res vector / source design file',
                              style: TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl(cloudLink!),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Text(
                        cloudLink,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(cloudLink!),
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                      ),
                      label: const Text(
                        'Open Cloud Design Link',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: PmsTheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PRODUCTS & PRINT ATTACHMENTS',
                    style: TextStyle(
                      color: PmsTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_po.items.length} Product${_po.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: PmsTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  const Divider(color: PmsTheme.glassBorder, height: 20),
              itemBuilder: (context, idx) {
                final it = _po.items[idx];
                final attachPath = (it.attachmentPath != null && it.attachmentPath!.isNotEmpty)
                    ? it.attachmentPath!
                    : (_po.purchaseRequest?.artworkFilePath ?? '');
                final hasSpecificAttachment = it.attachmentPath != null && it.attachmentPath!.isNotEmpty;
                final fullAttachUrl = attachPath.isNotEmpty ? _getAttachmentUrl(attachPath) : null;
                final isImg = fullAttachUrl != null && _isImageFile(attachPath);
                final attachName = it.attachmentName ??
                    (hasSpecificAttachment
                        ? '${it.productName} Proof'
                        : (_po.purchaseRequest?.artworkFileName ?? '${it.productName} Artwork'));

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PmsTheme.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PmsTheme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: [Idx] Product Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: PmsTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: PmsTheme.primary,
                                  fontSize: 11,
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
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
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
                                    if (it.size != null && it.size!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PmsTheme.glassSurface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: PmsTheme.glassBorder,
                                          ),
                                        ),
                                        child: Text(
                                          'Size: ${it.size}',
                                          style: const TextStyle(
                                            color: PmsTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                      const SizedBox(height: 10),

                      // Separate Print Attachment Box for this item
                      if (fullAttachUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: PmsTheme.glassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isImg
                                  ? PmsTheme.primary.withValues(alpha: 0.35)
                                  : PmsTheme.glassBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Image Thumbnail with Zoom Overlay or Document Icon
                              if (isImg)
                                InkWell(
                                  onTap: () => _showImagePreviewModal(
                                    context,
                                    fullAttachUrl,
                                    attachName,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.black12,
                                          child: Image.network(
                                            fullAttachUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                              Icons.broken_image_outlined,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: PmsTheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.insert_drive_file_rounded,
                                    color: PmsTheme.primary,
                                    size: 24,
                                  ),
                                ),
                              const SizedBox(width: 10),

                              // Attachment info & actions
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasSpecificAttachment
                                                ? const Color(0xFF059669)
                                                      .withValues(alpha: 0.15)
                                                : const Color(0xFF4F46E5)
                                                      .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            hasSpecificAttachment
                                                ? 'Item Proof'
                                                : 'PR Artwork',
                                            style: TextStyle(
                                              color: hasSpecificAttachment
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFF4F46E5),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            attachName,
                                            style: const TextStyle(
                                              color: PmsTheme.textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (isImg) ...[
                                          InkWell(
                                            onTap: () =>
                                                _showImagePreviewModal(
                                              context,
                                              fullAttachUrl,
                                              attachName,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: PmsTheme.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: PmsTheme.primary
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.visibility_rounded,
                                                    size: 12,
                                                    color: PmsTheme.primary,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Preview',
                                                    style: TextStyle(
                                                      color: PmsTheme.primary,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        InkWell(
                                          onTap: () =>
                                              _launchUrl(fullAttachUrl),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: PmsTheme.background,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: PmsTheme.glassBorder,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isImg
                                                      ? Icons.download_rounded
                                                      : Icons.open_in_new_rounded,
                                                  size: 12,
                                                  color: PmsTheme.textPrimary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isImg ? 'Download' : 'Open Link',
                                                  style: const TextStyle(
                                                    color:
                                                        PmsTheme.textPrimary,
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.glassSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: PmsTheme.textSecondary,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'No proof attached for this item.',
                                style: TextStyle(
                                  color: PmsTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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

          const SizedBox(height: 12),

          // Items Unit Price Inputs with Separate Product Attachment Previews & Separate Item GST
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _po.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final it = _po.items[idx];
              final controller = _unitPriceControllers[it.id];
              final enteredPrice =
                  double.tryParse(controller?.text.trim() ?? '') ?? 0.0;
              final itemSubtotal = enteredPrice * it.quantity;
              final itemGstRate = _itemGstRates[it.id] ?? 0.0;
              final itemGstAmount = (itemSubtotal * itemGstRate) / 100.0;
              final itemGrandTotal = itemSubtotal + itemGstAmount;

              final attachPath = (it.attachmentPath != null && it.attachmentPath!.isNotEmpty)
                  ? it.attachmentPath!
                  : (_po.purchaseRequest?.artworkFilePath ?? '');
              final fullAttachUrl = attachPath.isNotEmpty ? _getAttachmentUrl(attachPath) : null;
              final isImg = fullAttachUrl != null && _isImageFile(attachPath);
              final attachName = it.attachmentName ??
                  (it.attachmentPath != null ? '${it.productName} Proof' : 'PR Artwork');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PmsTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name, Attachment Thumbnail, and Metadata
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail if available
                        if (fullAttachUrl != null && isImg) ...[
                          InkWell(
                            onTap: () => _showImagePreviewModal(
                              context,
                              fullAttachUrl,
                              attachName,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.black12,
                                    child: Image.network(
                                      fullAttachUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.broken_image_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
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
                              const SizedBox(height: 2),
                              Text(
                                'Required Qty: ${it.quantity}${it.size != null && it.size!.isNotEmpty ? " • Size: ${it.size}" : ""}',
                                style: const TextStyle(
                                  color: PmsTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              if (fullAttachUrl != null && isImg)
                                InkWell(
                                  onTap: () => _showImagePreviewModal(
                                    context,
                                    fullAttachUrl,
                                    attachName,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      '🔍 Tap image to inspect print design',
                                      style: TextStyle(
                                        color: PmsTheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: PmsTheme.glassBorder, height: 1),
                    const SizedBox(height: 10),

                    // Unit Price Input
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Rate / Unit (₹)',
                        labelStyle: const TextStyle(fontSize: 11),
                        prefixText: '₹ ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: PmsTheme.glassSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: PmsTheme.glassBorder,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Separate Item GST Rate Selector
                    Row(
                      children: [
                        const Text(
                          'Item GST:',
                          style: TextStyle(
                            color: PmsTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                                final isSelected = itemGstRate == rate;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      rate == 0 ? '0% (Exempt)' : '${rate.toInt()}%',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : PmsTheme.textPrimary,
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: PmsTheme.primary,
                                    backgroundColor: PmsTheme.glassSurface,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _itemGstRates[it.id] = rate;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Item Calculated Breakdown Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: PmsTheme.glassSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Subtotal: ₹${itemSubtotal.toStringAsFixed(2)} + GST (${itemGstRate.toInt()}%): ₹${itemGstAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          Text(
                            '₹${itemGrandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                    const Text(
                      'Total GST (Itemized):',
                      style: TextStyle(
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
      final itemGst = _itemGstRates[item.id] ?? 0.0;
      itemsPayload.add({
        'id': item.id,
        'unit_price': price,
        'gst_rate': itemGst,
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Price Quotation'),
        content: SingleChildScrollView(
          child: Column(
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
                    ..._po.items.map((item) {
                      final price = double.tryParse(_unitPriceControllers[item.id]?.text.trim() ?? '') ?? 0.0;
                      final itemSub = price * item.quantity;
                      final itemGst = _itemGstRates[item.id] ?? 0.0;
                      final itemTax = (itemSub * itemGst) / 100.0;
                      final itemTot = itemSub + itemTax;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} (${item.quantity} pcs @ ₹${price.toStringAsFixed(2)} + ${itemGst.toInt()}% GST)',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            Text(
                              '₹${itemTot.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Subtotal:', style: TextStyle(fontSize: 12)),
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
                        const Text(
                          'Total GST:',
                          style: TextStyle(fontSize: 12),
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
                      gstRate: _calculatedSubtotal > 0
                          ? ((_calculatedGstAmount / _calculatedSubtotal) * 100)
                          : 0.0,
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
                    final itemSub = it.totalPrice ?? (unitP * it.quantity);
                    final itemGstRate = it.gstRate;
                    final itemGstAmt = it.gstAmount ?? ((itemSub * itemGstRate) / 100.0);
                    final itemLineTotal = itemSub + itemGstAmt;
                    final attachPath = (it.attachmentPath != null && it.attachmentPath!.isNotEmpty)
                        ? it.attachmentPath!
                        : (_po.purchaseRequest?.artworkFilePath ?? '');
                    final fullAttachUrl = attachPath.isNotEmpty ? _getAttachmentUrl(attachPath) : null;
                    final isImg = fullAttachUrl != null && _isImageFile(attachPath);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (fullAttachUrl != null && isImg) ...[
                            InkWell(
                              onTap: () => _showImagePreviewModal(
                                context,
                                fullAttachUrl,
                                it.attachmentName ?? '${it.productName} Proof',
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  color: Colors.black12,
                                  child: Image.network(
                                    fullAttachUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.image_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        it.productName,
                                        style: const TextStyle(
                                          color: PmsTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (it.size != null && it.size!.isNotEmpty) ...[
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Text(
                                          it.size!,
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      'Rate: ₹${unitP.toStringAsFixed(2)} × ${it.quantity} = ₹${itemSub.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: itemGstRate > 0
                                            ? const Color(0xFFFEF3C7)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: itemGstRate > 0
                                              ? const Color(0xFFFCD34D)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Text(
                                        itemGstRate > 0
                                            ? 'GST ${itemGstRate.toInt()}% (+₹${itemGstAmt.toStringAsFixed(2)})'
                                            : 'GST 0% (Exempt)',
                                        style: TextStyle(
                                          color: itemGstRate > 0
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF64748B),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${itemLineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: PmsTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 14),
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
                        'Total GST (${_po.gstRate.toStringAsFixed(0)}% avg):',
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
                  const Divider(height: 14),
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

            // Previous Quotation Revision History (if multiple quotes submitted)
            _buildQuotationRevisionHistory(),
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

  Widget _buildQuotationRevisionHistory() {
    final quoteActivities = _po.activities
        .where((a) => a.action == 'quote_submitted')
        .toList();

    if (quoteActivities.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.history_rounded,
            color: Color(0xFF4F46E5),
            size: 20,
          ),
          title: Text(
            'Quotation Revision History (${quoteActivities.length} Submissions)',
            style: const TextStyle(
              color: PmsTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          subtitle: const Text(
            'Tap to compare separate product rates across revisions',
            style: TextStyle(
              color: PmsTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          children: [
            ...quoteActivities.asMap().entries.map((entry) {
              final idx = entry.key;
              final act = entry.value;
              final isLatest = idx == quoteActivities.length - 1;
              final dateStr = act.createdAt != null
                  ? '${act.createdAt!.toLocal().day}/${act.createdAt!.toLocal().month}/${act.createdAt!.toLocal().year} ${act.createdAt!.toLocal().hour % 12 == 0 ? 12 : act.createdAt!.toLocal().hour % 12}:${act.createdAt!.toLocal().minute.toString().padLeft(2, '0')} ${act.createdAt!.toLocal().hour >= 12 ? 'PM' : 'AM'}'
                  : '';

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLatest ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLatest
                        ? const Color(0xFFC7D2FE)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isLatest
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF64748B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Round #${idx + 1} ${isLatest ? '(Latest / Active)' : '(Previous)'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _sanitizeActivityRemarks(act.remarks ?? act.action),
                      style: const TextStyle(
                        color: PmsTheme.textPrimary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sanitizeActivityRemarks(act.remarks ?? act.action),
                            style: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          ...() {
                            final remarksText = act.remarks ?? '';
                            final urlRegex = RegExp(r'https?://[^\s<>"]+');
                            final matches = urlRegex.allMatches(remarksText);
                            final hasDirectAttach = act.attachmentPath !=
                                    null &&
                                act.attachmentPath!.isNotEmpty &&
                                !remarksText.contains(act.attachmentPath!);

                            if (matches.isEmpty && !hasDirectAttach) {
                              return <Widget>[];
                            }

                            return [
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ...matches.map((m) {
                                    final matchedUrl = m.group(0)!;
                                    return InkWell(
                                      onTap: () => _launchUrl(matchedUrl),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF4F46E5)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.open_in_new_rounded,
                                              size: 11,
                                              color: Color(0xFF4F46E5),
                                            ),
                                            const SizedBox(width: 4),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 180,
                                              ),
                                              child: Text(
                                                matchedUrl,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4F46E5),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (hasDirectAttach)
                                    InkWell(
                                      onTap: () {
                                        final p = act.attachmentPath!;
                                        if (p.startsWith('http://') ||
                                            p.startsWith('https://')) {
                                          _launchUrl(p);
                                        } else {
                                          final u = _getAttachmentUrl(p);
                                          if (_isImageFile(p)) {
                                            _showImagePreviewModal(
                                              context,
                                              u,
                                              act.attachmentName ??
                                                  'Activity Proof',
                                            );
                                          } else {
                                            _launchUrl(u);
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF059669)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.attach_file_rounded,
                                              size: 11,
                                              color: Color(0xFF059669),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              act.attachmentName ??
                                                  'View Attachment',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ];
                          }(),
                        ],
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
