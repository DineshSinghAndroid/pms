import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pms/theme/pms_theme.dart';

class UpdateDeliveryDialog extends StatefulWidget {
  final List<PrintOrderModel> printOrders;
  final PrintOrderModel? preselectedOrder;
  final UserModel? userProfile;

  const UpdateDeliveryDialog({
    super.key,
    required this.printOrders,
    this.preselectedOrder,
    this.userProfile,
  });

  @override
  State<UpdateDeliveryDialog> createState() => _UpdateDeliveryDialogState();
}

class _UpdateDeliveryDialogState extends State<UpdateDeliveryDialog> {
  PrintOrderModel? _selectedPO;
  final TextEditingController _searchPOController = TextEditingController();
  final TextEditingController _challanController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();

  // Map of PrintOrderItem id -> TextEditingController for received quantity
  final Map<int, TextEditingController> _itemControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.preselectedOrder != null) {
      _selectPO(widget.preselectedOrder!);
    }
  }

  @override
  void dispose() {
    _searchPOController.dispose();
    _challanController.dispose();
    _remarksController.dispose();
    for (var c in _itemControllers.values) {
      c.dispose();
    }
    super.dispose();
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

  void _selectPO(PrintOrderModel po) {
    setState(() {
      _selectedPO = po;
      _itemControllers.clear();
      for (var it in po.items) {
        final remaining = (it.quantity - it.receivedQuantity);
        _itemControllers[it.id] = TextEditingController(
          text: remaining > 0 ? '$remaining' : '',
        );
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<PrintOrderModel> get _filteredPOs {
    final q = _searchPOController.text.toLowerCase().trim();
    final activeList = widget.printOrders
        .where((p) => !p.isCancelled && !p.isFullyReceived)
        .toList();
    if (q.isEmpty) return activeList;
    return activeList.where((p) {
      return p.poNumber.toLowerCase().contains(q) ||
          (p.vendor?.name.toLowerCase().contains(q) ?? false) ||
          (p.wing?.name.toLowerCase().contains(q) ?? false) ||
          p.items.any((it) => it.productName.toLowerCase().contains(q));
    }).toList();
  }

  void _submitDelivery() {
    if (_selectedPO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Print Order first.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final challan = _challanController.text.trim();
    if (challan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan Number is required.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final itemsPayload = <Map<String, dynamic>>[];
    int totalNewQty = 0;

    for (var it in _selectedPO!.items) {
      final ctrl = _itemControllers[it.id];
      final qty = int.tryParse(ctrl?.text.trim() ?? '') ?? 0;
      itemsPayload.add({'id': it.id, 'received_quantity': qty});
      totalNewQty += qty;
    }

    if (totalNewQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 1 received item quantity.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final phone = widget.userProfile?.phone;
    final dateStr =
        '${_deliveryDate.year.toString().padLeft(4, '0')}-${_deliveryDate.month.toString().padLeft(2, '0')}-${_deliveryDate.day.toString().padLeft(2, '0')}';

    context.read<PrintOrderBloc>().add(
      RecordDeliveryEvent(
        printOrderId: _selectedPO!.id,
        challanNumber: challan,
        deliveryDate: dateStr,
        remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
        phone: phone,
        items: itemsPayload,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PmsTheme.glassSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: PmsTheme.glassBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(0xFF059669).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFF059669)),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Delivery & Receive PO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Log product shipment quantities & Challan number',
                          style: TextStyle(
                            fontSize: 11,
                            color: PmsTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PmsTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: PO Selector
                    const Text(
                      '1. SELECT PRINT ORDER (PO) *',
                      style: TextStyle(
                        color: PmsTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_selectedPO == null) ...[
                      // Search PO
                      TextField(
                        controller: _searchPOController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by PO #, vendor, or wing...',
                          hintStyle: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: PmsTheme.textSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: PmsTheme.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: PmsTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: PmsTheme.glassBorder),
                        ),
                        child: _filteredPOs.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    _searchPOController.text.trim().isNotEmpty
                                        ? 'No matching Print Orders found.'
                                        : (widget.printOrders.any((p) => p.isFullyReceived)
                                            ? 'All Print Orders are fully received!'
                                            : 'No Print Orders available to receive.'),
                                    style: const TextStyle(
                                      color: PmsTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredPOs.length,
                                separatorBuilder: (_, _) => const Divider(
                                  color: PmsTheme.glassSurface,
                                  height: 1,
                                ),
                                itemBuilder: (context, idx) {
                                  final po = _filteredPOs[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${po.poNumber} · ${po.vendor?.name ?? "Vendor"}',
                                      style: const TextStyle(
                                        color: PmsTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${po.wing?.name ?? "Wing"} · ${po.items.length} Products · Status: ${po.status}',
                                      style: const TextStyle(
                                        color: PmsTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: PmsTheme.primary,
                                      size: 18,
                                    ),
                                    onTap: () => _selectPO(po),
                                  );
                                },
                              ),
                      ),
                    ] else ...[
                      // Selected PO Summary Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: PmsTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PmsTheme.primary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PmsTheme.glassSurface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: PmsTheme.textSecondary,
                                          ),
                                        ),
                                        child: Text(
                                          _selectedPO!.poNumber,
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedPO!.vendor?.name ?? 'Vendor',
                                          style: const TextStyle(
                                            color: PmsTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _selectedPO = null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 28),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Change PO',
                                    style: TextStyle(
                                      color: PmsTheme.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Target Wing: ${_selectedPO!.wing?.name ?? "General Wing"} · Delivery: ${_selectedPO!.expectedDeliveryDate ?? "ASAP"}',
                              style: const TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (_selectedPO!.printOrderRemarks != null &&
                                _selectedPO!.printOrderRemarks!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Order Note: ${_selectedPO!.printOrderRemarks}',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (_selectedPO != null) ...[
                      const SizedBox(height: 20),

                      // Step 2: Items & Received Quantities
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '2. PRODUCTS & QUANTITIES RECEIVED *',
                            style: TextStyle(
                              color: PmsTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: PmsTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_selectedPO!.items.length} Product${_selectedPO!.items.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: PmsTheme.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedPO!.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final it = _selectedPO!.items[idx];
                          final ctrl = _itemControllers[it.id];
                          final remaining = (it.quantity - it.receivedQuantity);
                          final isComplete = remaining <= 0;

                          final hasAttachment = it.attachmentPath != null &&
                              it.attachmentPath!.isNotEmpty;
                          final fullUrl = hasAttachment
                              ? (it.attachmentPath!.startsWith('http')
                                  ? it.attachmentPath!
                                  : '${ApiService.baseUrl}/storage/${it.attachmentPath}')
                              : null;
                          final isImage = hasAttachment && _isImageFile(it.attachmentPath);

                          final unitPriceStr = it.unitPrice != null
                              ? '₹${it.unitPrice!.toStringAsFixed(2)} / pc'
                              : null;
                          final lineTotal = it.totalPrice ??
                              (it.unitPrice != null ? (it.unitPrice! * it.quantity) : null);
                          final lineTotalStr = lineTotal != null
                              ? '₹${lineTotal.toStringAsFixed(2)}'
                              : null;

                          return Container(
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? const Color(0xFFF0FDF4)
                                  : PmsTheme.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isComplete
                                    ? const Color(0xFF86EFAC)
                                    : PmsTheme.glassBorder,
                                width: isComplete ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Header with Image Proof & Name
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product / Proof Thumbnail
                                      if (fullUrl != null) ...[
                                        InkWell(
                                          onTap: () {
                                            if (isImage) {
                                              _showImagePreviewModal(
                                                context,
                                                fullUrl,
                                                '#${idx + 1}. ${it.productName} Proof',
                                              );
                                            } else {
                                              _launchUrl(fullUrl);
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: 58,
                                                  height: 58,
                                                  decoration: BoxDecoration(
                                                    color: PmsTheme.glassSurface,
                                                    border: Border.all(
                                                      color: PmsTheme.primary
                                                          .withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: isImage
                                                      ? Image.network(
                                                          fullUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, _, _) =>
                                                              const Icon(
                                                            Icons.image_not_supported_outlined,
                                                            size: 24,
                                                            color: PmsTheme.textSecondary,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.attach_file_rounded,
                                                          size: 26,
                                                          color: PmsTheme.primary,
                                                        ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black87,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Icon(
                                                    isImage
                                                        ? Icons.zoom_in_rounded
                                                        : Icons.open_in_new_rounded,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],

                                      // Product Name, Size & Rate
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '#${idx + 1}. ${it.productName}',
                                                    style: const TextStyle(
                                                      color: PmsTheme.textPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isComplete)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFDCFCE7),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      '✓ 100% Recv',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF166534),
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Size: ${it.size ?? "Standard"}',
                                              style: const TextStyle(
                                                color: PmsTheme.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Rate & Line Total Chips
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
                                                      color: const Color(0xFFEFF6FF),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: const Color(0xFFBFDBFE),
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
                                                      color: const Color(0xFFECFDF5),
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: const Color(0xFFA7F3D0),
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
                                ),

                                const Divider(
                                  color: PmsTheme.glassSurface,
                                  height: 1,
                                ),

                                // Quantity Details & Receipt Input
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Ordered: ${it.quantity}  ·  Recv so \nfar: ${it.receivedQuantity}  ·  Remaining: ${remaining > 0 ? remaining : 0}',
                                            style: const TextStyle(
                                              color: PmsTheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (remaining > 0)
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  ctrl?.text = '$remaining';
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF059669)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF059669),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Recv Balance ($remaining)',
                                                  style: const TextStyle(
                                                    color: Color(0xFF059669),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Receiving in this Challan:',
                                            style: TextStyle(
                                              color: PmsTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 80,
                                                height: 36,
                                                child: TextField(
                                                  controller: ctrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: PmsTheme.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: '0',
                                                    filled: true,
                                                    fillColor:
                                                        const Color(0xFFFFFFFF),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 8,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                      borderSide:
                                                          const BorderSide(
                                                        color: PmsTheme
                                                            .glassBorder,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                      borderSide:
                                                          const BorderSide(
                                                        color: PmsTheme
                                                            .glassBorder,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '/ ${it.quantity} pcs',
                                                style: const TextStyle(
                                                  color:
                                                      PmsTheme.textSecondary,
                                                  fontSize: 11.5,
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
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Step 3: Challan Number & Remarks
                      const Text(
                        '3. DELIVERY DETAILS',
                        style: TextStyle(
                          color: PmsTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Challan Number *
                      TextField(
                        controller: _challanController,
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Challan Number *',
                          labelStyle: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'e.g. CH-2026-9812',
                          hintStyle: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: PmsTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delivery Date Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deliveryDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _deliveryDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PmsTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery Date',
                                    style: TextStyle(
                                      color: PmsTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                                    style: const TextStyle(
                                      color: PmsTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: PmsTheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remark / Delivery Note
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Remark / Delivery Note',
                          labelStyle: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 12,
                          ),
                          hintText: 'e.g. Received partial 200 copies in good condition at gate...',
                          hintStyle: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: PmsTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: PmsTheme.glassBorder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: PmsTheme.textSecondary),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submitDelivery,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Save & Record Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF059669),
                      foregroundColor: Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
