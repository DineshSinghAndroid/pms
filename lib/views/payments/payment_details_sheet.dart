import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/payment/payment_bloc.dart';
import 'package:pms/bloc/payment/payment_event.dart';
import 'package:pms/bloc/payment/payment_state.dart';
import 'package:pms/models/payment_model.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/services/api_service.dart';
import 'package:pms/theme/pms_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentDetailsSheet extends StatefulWidget {
  final ProductPaymentModel payment;

  const PaymentDetailsSheet({super.key, required this.payment});

  @override
  State<PaymentDetailsSheet> createState() => _PaymentDetailsSheetState();
}

class _PaymentDetailsSheetState extends State<PaymentDetailsSheet> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(FetchPaymentDetailsEvent(widget.payment.id));
  }

  bool _isImageFile(String? path) {
    if (path == null || path.isEmpty) return false;
    final clean = path.toLowerCase().split('?').first;
    return clean.endsWith('.png') ||
        clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.webp') ||
        clean.endsWith('.gif') ||
        clean.endsWith('.bmp') ||
        clean.endsWith('.svg');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                      return Container(
                        height: 220,
                        color: PmsTheme.background,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: PmsTheme.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: PmsTheme.background,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image_rounded,
                              size: 40,
                              color: PmsTheme.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Unable to load preview image.',
                              style: TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: () => _launchUrl(imageUrl),
                              icon: const Icon(Icons.open_in_browser, size: 16),
                              label: const Text('Open External File'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: PmsTheme.background,
                  border: Border(
                    top: BorderSide(color: PmsTheme.glassBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _launchUrl(imageUrl),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Original'),
                      style: TextButton.styleFrom(
                        foregroundColor: PmsTheme.primary,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final payment = (state is PaymentLoaded &&
                state.selectedPaymentDetails != null &&
                state.selectedPaymentDetails!.id == widget.payment.id)
            ? state.selectedPaymentDetails!
            : widget.payment;

        final item = payment.printOrderItem;
        final po = payment.printOrder;
        final vendor = payment.vendor ?? po?.vendor;
        final wing = payment.wing ?? po?.wing;
        final lifecycle = payment.lifecycle;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: PmsTheme.glassSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: PmsTheme.primaryGradient,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: PmsTheme.glowShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        payment.paymentNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Record',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Lifecycle & invoice details',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Payment Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            label: 'INVOICE NUMBER',
                            value: payment.invoiceNumber,
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            label: 'PAID AMOUNT',
                            value: payment.amount != null
                                ? '₹${payment.amount!.toStringAsFixed(2)}'
                                : 'N/A',
                            valueColor: const Color(0xFF059669),
                            icon: Icons.currency_rupee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            label: 'PAYMENT DATE',
                            value: payment.paymentDate ?? 'N/A',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            label: 'METHOD',
                            value: payment.paymentMethod ?? 'Bank Transfer',
                            icon: Icons.payment_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product & PO Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Print Order #${payment.poNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: PmsTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '✓ 100% Received & Paid',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wing: ${wing?.name ?? 'General'} · Vendor: ${vendor?.name ?? 'Vendor'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: PmsTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'ORDERED PRODUCTS & PRICING BREAKDOWN:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: PmsTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (payment.items.isNotEmpty)
                            ...payment.items.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final it = entry.value;

                              final name = it is Map
                                  ? (it['product_name']?.toString() ?? 'Product')
                                  : (it is PrintOrderItemModel ? it.productName : 'Product');
                              final code = it is Map
                                  ? (it['product_code']?.toString() ?? '')
                                  : '';
                              final qty = it is Map
                                  ? (it['quantity'] is int ? it['quantity'] : int.tryParse('${it['quantity']}') ?? 1)
                                  : (it is PrintOrderItemModel ? it.quantity : 1);
                              final sz = it is Map
                                  ? (it['size']?.toString() ?? 'Standard')
                                  : (it is PrintOrderItemModel ? (it.size ?? 'Standard') : 'Standard');
                              final rec = it is Map
                                  ? (it['received_quantity'] is int ? it['received_quantity'] : int.tryParse('${it['received_quantity']}') ?? qty)
                                  : (it is PrintOrderItemModel ? it.receivedQuantity : qty);
                              final attPath = it is Map
                                  ? it['attachment_path']?.toString()
                                  : (it is PrintOrderItemModel ? it.attachmentPath : null);

                              final unitPrice = it is Map
                                  ? (it['unit_price'] != null ? double.tryParse('${it['unit_price']}') : null)
                                  : (it is PrintOrderItemModel ? it.unitPrice : null);
                              final totalPrice = it is Map
                                  ? (it['total_price'] != null ? double.tryParse('${it['total_price']}') : null)
                                  : (it is PrintOrderItemModel ? it.totalPrice : null);

                              final unitPriceStr = unitPrice != null
                                  ? '₹${unitPrice.toStringAsFixed(2)} / pc'
                                  : null;
                              final lineTotal = totalPrice ??
                                  (unitPrice != null ? (unitPrice * qty) : null);
                              final lineTotalStr = lineTotal != null
                                  ? '₹${lineTotal.toStringAsFixed(2)}'
                                  : null;

                              final hasAtt = attPath != null && attPath.isNotEmpty;
                              final fullUrl = hasAtt
                                  ? (attPath.startsWith('http')
                                      ? attPath
                                      : '${ApiService.baseUrl}/storage/$attPath')
                                  : null;
                              final isImage = hasAtt && _isImageFile(attPath);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: PmsTheme.glassSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Proof Thumbnail
                                    if (fullUrl != null) ...[
                                      InkWell(
                                        onTap: () {
                                          if (isImage) {
                                            _showImagePreviewModal(
                                              context,
                                              fullUrl,
                                              '#${idx + 1}. $name Proof',
                                            );
                                          } else {
                                            _launchUrl(fullUrl);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                color: Colors.white,
                                                child: isImage
                                                    ? Image.network(
                                                        fullUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, _, _) =>
                                                                const Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          size: 20,
                                                          color: PmsTheme
                                                              .textSecondary,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .attach_file_rounded,
                                                        size: 22,
                                                        color:
                                                            PmsTheme.primary,
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 1,
                                              right: 1,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Icon(
                                                  isImage
                                                      ? Icons.zoom_in_rounded
                                                      : Icons
                                                          .open_in_new_rounded,
                                                  size: 9,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '#${idx + 1}. $name${code.isNotEmpty ? ' ($code)' : ''}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color: PmsTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Recv: $rec/$qty',
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF166534),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Size: $sz · Ordered: $qty pcs',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: PmsTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (unitPriceStr != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEFF6FF),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFFBFDBFE),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Rate: $unitPriceStr',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1D4ED8),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              if (lineTotalStr != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFECFDF5),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFFA7F3D0),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Item Total: $lineTotalStr',
                                                    style: const TextStyle(
                                                      color: Color(0xFF065F46),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                              );
                            })
                          else if (item != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: PmsTheme.glassSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF059669), size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${item.productName} · ${item.quantity} pcs (${item.size ?? 'Standard'})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              payment.productsSummary.isNotEmpty
                                  ? payment.productsSummary
                                  : 'Products Delivered & Settled',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Day 1 Product Lifecycle Timeline
                    const Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'DAY 1 PRODUCT LIFECYCLE LOGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (lifecycle.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Loading lifecycle logs...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...lifecycle.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stage = entry.value;
                        final isLast = index == lifecycle.length - 1;

                        return _buildTimelineItem(stage, isLast: isLast);
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    Color? valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PmsTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: PmsTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: PmsTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? PmsTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(PaymentLifecycleStage stage, {required bool isLast}) {
    Color dotColor = PmsTheme.primary; // Indigo
    if (stage.stage == 'payment') {
      dotColor = const Color(0xFF059669); // Emerald
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Stage Details Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stage.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: PmsTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (stage.date != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            stage.date!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: PmsTheme.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _renderStageDetails(stage),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderStageDetails(PaymentLifecycleStage stage) {
    final d = stage.details;
    switch (stage.stage) {
      case 'purchase_request':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PR Number: ${d['pr_number'] ?? 'N/A'} · Wing: ${d['wing'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            Text('Requester: ${d['requester_name'] ?? 'Staff'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            if (d['remarks'] != null && d['remarks'] != '-')
              Text('Remarks: ${d['remarks']}',
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        );
      case 'artwork_design':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Designer: ${d['designer_name'] ?? 'Assigned Designer'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            Text('Approved By: ${d['approved_by'] ?? 'Admin'} (${d['approved_at'] ?? ''})',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            if (d['admin_review_remarks'] != null && d['admin_review_remarks'] != '-')
              Text('Review: ${d['admin_review_remarks']}',
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        );
      case 'print_order':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PO Number: ${d['po_number'] ?? 'N/A'} · Vendor: ${d['vendor_name'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            Text('Ordered Quantity: ${d['ordered_quantity'] ?? 1} · Size: ${d['size'] ?? 'Standard'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
          ],
        );
      case 'delivery':
        final batches = d['batches'] is List ? d['batches'] as List : [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Received ${d['total_received']} / ${d['total_ordered']} units',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 4),
            if (batches.isNotEmpty)
              ...batches.map(
                (b) => Text(
                  '• Challan ${b['challan_number']}: Received ${b['received_quantity']} Qty on ${b['delivery_date']} by ${b['receiver_name']}',
                  style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
                ),
              )
            else
              const Text('No batch logs', style: TextStyle(fontSize: 11)),
          ],
        );
      case 'payment':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #: ${d['invoice_number'] ?? 'N/A'} · Amount: ₹${d['amount'] ?? '0.00'}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669))),
            Text('Paid By: ${d['paid_by'] ?? 'Admin'} · Method: ${d['payment_method'] ?? 'Bank Transfer'}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
            if (d['remarks'] != null && d['remarks'] != '-')
              Text('Notes: ${d['remarks']}',
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
