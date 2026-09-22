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
import 'package:pms/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pms/theme/pms_theme.dart';
import 'package:pms/widgets/pms_ui.dart';

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

  String get _role => (widget.userProfile?.role ?? '').toLowerCase().trim();
  bool get isWingIncharge => widget.userProfile?.isWingIncharge ?? false;
  bool get isSuperAdmin =>
      widget.isSuperAdmin ||
      widget.userProfile?.isSuperAdmin == true ||
      _role == 'superadmin' ||
      _role == 'super admin' ||
      _role == 'super_admin';
  bool get isManager => _role == 'manager';
  bool get isStoreIncharge =>
      _role == 'store incharge' ||
      _role == 'store_incharge' ||
      widget.userProfile?.role == 'Store Incharge';
  bool get isAdmin => _role == 'admin';

  bool get canSeeVendorDetails => isSuperAdmin || isAdmin || isManager || isStoreIncharge;
  bool get canSeePricing => isSuperAdmin || isAdmin || isManager;
  bool get canUpdateDelivery => isSuperAdmin || isAdmin || isManager || isStoreIncharge;

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
      final vendorName = canSeeVendorDetails ? (d.printOrder?.vendor?.name ?? '') : '';
      final matchesQuery =
          q.isEmpty ||
          d.challanNumber.toLowerCase().contains(q) ||
          d.deliveryNumber.toLowerCase().contains(q) ||
          (d.remarks?.toLowerCase().contains(q) ?? false) ||
          (d.printOrder?.poNumber.toLowerCase().contains(q) ?? false) ||
          (vendorName.toLowerCase().contains(q)) ||
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
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  color: Colors.black.withValues(alpha: 0.85),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image preview',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _launchUrl(imageUrl),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open / Download'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
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

  void _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrintOrderBloc, PrintOrderState>(
      listener: (context, state) {
        if (state is DeliveryRecordedSuccess) {
          showPmsSnackBar(
            context,
            '✓ ${state.message}',
            kind: PmsSnackKind.success,
          );
        } else if (state is PrintOrderError) {
          showPmsSnackBar(
            context,
            state.message,
            kind: PmsSnackKind.error,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PmsPageHeader(
                    icon: Icons.local_shipping_rounded,
                    title: 'Delivery Logs',
                    subtitle: 'Challan receipts and partial deliveries',
                    action: canUpdateDelivery
                        ? FilledButton.icon(
                            onPressed: () => _openUpdateDeliveryDialog(),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Update Delivery'),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      color: PmsTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: canSeeVendorDetails
                          ? 'Search Challan #, Delivery #, PO #, or vendor...'
                          : 'Search Challan #, Delivery #, PO #, or product...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Delivery Logs'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'partially_received',
                          'Partially Received',
                          color: const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'completed',
                          'Fully Received',
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: PmsTheme.primary,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 40),
                          PmsEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Delivery Logs Found',
                            subtitle: canUpdateDelivery
                                ? 'Tap Update Delivery to receive products under a Challan.'
                                : 'No delivery receipts recorded yet.',
                            actionLabel: canUpdateDelivery ? 'Update Delivery' : null,
                            onAction: canUpdateDelivery
                                ? () => _openUpdateDeliveryDialog()
                                : null,
                          ),
                        ],
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
                            canSeeVendorDetails
                                ? (d.printOrder?.vendor?.name ?? 'Vendor')
                                : 'Printing Vendor',
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
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: d.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final it = d.items[idx];
                          final hasProof = it.attachmentPath != null && it.attachmentPath!.isNotEmpty;
                          final proofUrl = hasProof ? _getAttachmentUrl(it.attachmentPath!) : '';
                          final isImage = hasProof && _isImageFile(it.attachmentPath);

                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail / Proof Preview
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
                                      width: 44,
                                      height: 44,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: PmsTheme.glassBorder),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (isImage)
                                            Image.network(
                                              proofUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Icon(
                                                Icons.image_not_supported_rounded,
                                                size: 20,
                                                color: PmsTheme.textSecondary,
                                              ),
                                            )
                                          else
                                            const Center(
                                              child: Icon(
                                                Icons.insert_drive_file_rounded,
                                                size: 22,
                                                color: PmsTheme.primary,
                                              ),
                                            ),
                                          Positioned(
                                            bottom: 1,
                                            right: 1,
                                            child: Container(
                                              padding: const EdgeInsets.all(1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in_rounded,
                                                size: 9,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Product info + quantities + rates
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
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (canSeePricing && it.unitPrice != null && it.unitPrice! > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: PmsTheme.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '₹${it.unitPrice! % 1 == 0 ? it.unitPrice!.toInt() : it.unitPrice!.toStringAsFixed(2)}/pc',
                                                style: const TextStyle(
                                                  color: PmsTheme.primary,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (it.size != null && it.size!.isNotEmpty)
                                            Text(
                                              'Size: ${it.size}',
                                              style: const TextStyle(
                                                color: PmsTheme.textSecondary,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '+${it.receivedQuantity} pcs',
                                                style: const TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                              Text(
                                                ' (Total ${it.totalReceivedToDate}/${it.orderedQuantity})',
                                                style: const TextStyle(
                                                  color: PmsTheme.textSecondary,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (canSeePricing && it.totalPrice != null && it.totalPrice! > 0)
                                            Text(
                                              'Line Total: ₹${it.totalPrice! % 1 == 0 ? it.totalPrice!.toInt() : it.totalPrice!.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: PmsTheme.textPrimary,
                                                fontSize: 10.5,
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
                        },
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
