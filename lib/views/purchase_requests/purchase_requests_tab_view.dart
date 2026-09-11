import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_state.dart';
import '../../bloc/purchase_request/purchase_request_bloc.dart';
import '../../bloc/purchase_request/purchase_request_event.dart';
import '../../bloc/purchase_request/purchase_request_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';
import '../../models/product_type_model.dart';
import '../../models/purchase_request_model.dart';
import '../../models/user_model.dart';
import '../../models/wing_model.dart';
import 'pr_details_screen.dart';

class PurchaseRequestsTabView extends StatefulWidget {
  final bool isSuperAdmin;
  final UserModel? currentUser;

  const PurchaseRequestsTabView({
    super.key,
    this.isSuperAdmin = true,
    this.currentUser,
  });

  @override
  State<PurchaseRequestsTabView> createState() =>
      _PurchaseRequestsTabViewState();
}

class _PurchaseRequestsTabViewState extends State<PurchaseRequestsTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;
  String _currentScope = 'active';

  bool get isSuperAdmin =>
      widget.isSuperAdmin ||
      widget.currentUser?.role.toLowerCase() == 'superadmin' ||
      widget.currentUser?.role.toLowerCase() == 'super admin' ||
      widget.currentUser?.phone == '7414055310';
  bool get isManager =>
      widget.currentUser?.role.toLowerCase() == 'manager';
  bool get isAdminOrManager => isSuperAdmin || isManager;
  bool get isDesigner => widget.currentUser?.role == 'Designer';

  bool _isImage(String? path) {
    if (path == null || path.isEmpty) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void initState() {
    super.initState();
    _fetchPRs();
  }

  @override
  void didUpdateWidget(covariant PurchaseRequestsTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      _fetchPRs();
    }
  }

  void _fetchPRs() {
    if (widget.currentUser != null && widget.currentUser!.role == 'Designer') {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(
          designerId: widget.currentUser!.id,
          phone: widget.currentUser!.phone,
        ),
      );
    } else if (widget.currentUser != null &&
        widget.currentUser!.isWingIncharge) {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(
          phone: widget.currentUser!.phone,
        ),
      );
    } else {
      context.read<PurchaseRequestBloc>().add(
        const FetchPurchaseRequestsEvent(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= CREATE PURCHASE REQUEST MODAL =================
  void _showCreatePRForm(BuildContext context) {
    final ptState = context.read<ProductTypeBloc>().state;
    final wingState = context.read<WingBloc>().state;

    final allProductTypes = ptState is ProductTypeLoaded
        ? ptState.productTypes
        : <ProductTypeModel>[];
    final allWings = wingState is WingLoaded ? wingState.wings : <WingModel>[];

    List<WingModel> availableWings = allWings;
    if (widget.currentUser?.isWingIncharge == true) {
      final assignedIds = widget.currentUser!.assignedWings.map((w) => w.id).toSet();
      if (assignedIds.isNotEmpty) {
        availableWings = allWings.where((w) => assignedIds.contains(w.id)).toList();
      }
      if (availableWings.isEmpty && widget.currentUser!.assignedWings.isNotEmpty) {
        availableWings = widget.currentUser!.assignedWings;
      }
    }

    if (allProductTypes.isEmpty || availableWings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.currentUser?.isWingIncharge == true
                ? 'No assigned wings found for your Wing Incharge account. Please contact Super Admin.'
                : 'Please ensure Product Types and Wings are loaded.',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Dynamic item list state
    List<Map<String, dynamic>> itemsList = [];
    int? selectedWingId = availableWings.isNotEmpty ? availableWings.first.id : null;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    final timeCtrl = TextEditingController(text: '04:00 PM');
    final remarksCtrl = TextEditingController();
    ProductTypeModel? chosenPickerProduct;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              color: Color(0xFFDC2626),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create Purchase Request (PR)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: PRODUCT PICKER & SEARCH
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Select Product to Add (Search from 614 Master Items) *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ProductTypeModel>(
                                isExpanded: true,
                                dropdownColor: Color(0xFFFFFFFF),
                                value: chosenPickerProduct,
                                hint: const Text(
                                  'Search & Select Product',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                                items: allProductTypes.map((pt) {
                                  return DropdownMenuItem<ProductTypeModel>(
                                    value: pt,
                                    child: Text(
                                      '[${pt.productCode ?? '000000'}] ${pt.name} (${pt.category?.name ?? ''})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() {
                                    chosenPickerProduct = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: chosenPickerProduct == null
                                ? null
                                : () {
                                    setModalState(() {
                                      itemsList.add({
                                        'product_type_id':
                                            chosenPickerProduct!.id,
                                        'product_name':
                                            chosenPickerProduct!.name,
                                        'product_code':
                                            chosenPickerProduct!.productCode ??
                                            '000000',
                                        'quantity_ctrl': TextEditingController(
                                          text: '1',
                                        ),
                                        'size_ctrl': TextEditingController(),
                                        'attachment_ctrl':
                                            TextEditingController(),
                                        'pickedBytes': null,
                                        'pickedName': null,
                                        'pickedSize': null,
                                      });
                                      chosenPickerProduct = null;
                                    });
                                  },
                            icon: const Icon(Icons.add_box_rounded, size: 16),
                            label: const Text('Add Product Box'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDC2626),
                              foregroundColor: Color(0xFFFFFFFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SECTION 2: LIST OF ITEMS WITH SPECS
                    Text(
                      '2. Selected Products & Specifications (${itemsList.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (itemsList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFE2E8F0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No products added yet. Select a product above and tap "Add Product Box".',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // Render dynamic item boxes
                    ...itemsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      child: Text(
                                        item['product_code'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item['product_name']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFB91C1C),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      itemsList.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Quantity
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Quantity *',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller:
                                            item['quantity_ctrl']
                                                as TextEditingController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Color(0xFFFFFFFF),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Size
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Size / Dimensions',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller:
                                            item['size_ctrl']
                                                as TextEditingController,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 10x4 ft, A4',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                          filled: true,
                                          fillColor: Color(0xFFFFFFFF),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Sample Attachment Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sample Attachment (Camera / Any File / Reference)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Dual Action Buttons: Camera & Upload Any File
                                Row(
                                  children: [
                                    // Option 1: Camera Photo
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          try {
                                            final picker = ImagePicker();
                                            final photo = await picker.pickImage(
                                              source: ImageSource.camera,
                                              imageQuality: 90,
                                            );
                                            if (photo != null) {
                                              final bytes = await photo.readAsBytes();
                                              setModalState(() {
                                                item['pickedBytes'] = bytes;
                                                item['pickedName'] = photo.name;
                                                item['pickedSize'] = bytes.length;
                                                (item['attachment_ctrl'] as TextEditingController).text = photo.name;
                                              });
                                            }
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('Error opening camera: $e'),
                                                backgroundColor: const Color(0xFFDC2626),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.camera_alt_rounded, size: 14),
                                        label: const Text(
                                          'Camera',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF2563EB),
                                          side: const BorderSide(color: Color(0xFF2563EB)),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Option 2: Upload Any File
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          try {
                                            final file = await FilePicker.pickFile(type: FileType.any);
                                            if (file != null) {
                                              final bytes = await file.readAsBytes();
                                              final size = await file.length();
                                              setModalState(() {
                                                item['pickedBytes'] = bytes;
                                                item['pickedName'] = file.name;
                                                item['pickedSize'] = size;
                                                (item['attachment_ctrl'] as TextEditingController).text = file.name;
                                              });
                                            }
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('Error selecting file: $e'),
                                                backgroundColor: const Color(0xFFDC2626),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.upload_file_rounded, size: 14),
                                        label: const Text(
                                          'Upload File',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF059669),
                                          side: const BorderSide(color: Color(0xFF059669)),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Preview Tile if a file/photo is selected
                                if (item['pickedBytes'] != null && item['pickedName'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Thumbnail / File Icon
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: _isImage(item['pickedName'] as String?)
                                              ? Image.memory(
                                                  item['pickedBytes'] as Uint8List,
                                                  width: 38,
                                                  height: 38,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 38,
                                                  height: 38,
                                                  color: const Color(0xFFE2E8F0),
                                                  child: Icon(
                                                    (item['pickedName'] as String).toLowerCase().endsWith('.pdf')
                                                        ? Icons.picture_as_pdf_rounded
                                                        : Icons.insert_drive_file_rounded,
                                                    color: (item['pickedName'] as String).toLowerCase().endsWith('.pdf')
                                                        ? const Color(0xFFDC2626)
                                                        : const Color(0xFF2563EB),
                                                    size: 22,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Filename & Size
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['pickedName'] as String,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (item['pickedSize'] != null)
                                                Text(
                                                  _formatFileSize(item['pickedSize'] as int),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Remove Attachment Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Color(0xFFDC2626),
                                            size: 18,
                                          ),
                                          tooltip: 'Remove Attachment',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setModalState(() {
                                              item['pickedBytes'] = null;
                                              item['pickedName'] = null;
                                              item['pickedSize'] = null;
                                              (item['attachment_ctrl'] as TextEditingController).clear();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 6),
                                // Text Field for custom reference / note
                                TextField(
                                  controller:
                                      item['attachment_ctrl']
                                          as TextEditingController,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.note_alt_outlined,
                                      color: Color(0xFF64748B),
                                      size: 15,
                                    ),
                                    hintText:
                                        'Or enter sample link / note (optional)',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFFFFFF),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // SECTION 3: ORDER LEVEL DETAILS (WING, DELIVERY & REMARKS)
                    const Text(
                      '3. Target Wing & Delivery Schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Wing Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedWingId,
                          isExpanded: true,
                          dropdownColor: Color(0xFFFFFFFF),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                          items: availableWings.map((w) {
                            return DropdownMenuItem<int>(
                              value: w.id,
                              child: Text(w.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedWingId = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Delivery Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Color(0xFFB91C1C),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Delivery Time',
                              hintStyle: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Remarks
                    TextField(
                      controller: remarksCtrl,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Remarks & finishing instructions...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: itemsList.isEmpty || selectedWingId == null
                          ? null
                          : () {
                              final formattedItems = itemsList.map((it) {
                                final qtyStr =
                                    (it['quantity_ctrl']
                                            as TextEditingController)
                                        .text
                                        .trim();
                                final sizeStr =
                                    (it['size_ctrl'] as TextEditingController)
                                        .text
                                        .trim();
                                final attStr =
                                    (it['attachment_ctrl']
                                            as TextEditingController)
                                        .text
                                        .trim();
                                final Uint8List? bytes = it['pickedBytes'] as Uint8List?;
                                final String? pickedName = it['pickedName'] as String?;

                                return {
                                  'product_type_id': it['product_type_id'],
                                  'product_name': it['product_name'],
                                  'quantity': int.tryParse(qtyStr) ?? 1,
                                  'size': sizeStr.isNotEmpty ? sizeStr : null,
                                  'attachment_path': attStr.isNotEmpty
                                      ? attStr
                                      : null,
                                  'attachment_name': pickedName ??
                                      (attStr.isNotEmpty ? attStr : null),
                                  'attachment_base64': bytes != null
                                      ? base64Encode(bytes)
                                      : null,
                                };
                              }).toList();

                              final dateFormatted =
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                              final payload = {
                                'wing_id': selectedWingId,
                                'expected_delivery_date': dateFormatted,
                                'expected_delivery_time': timeCtrl.text.trim(),
                                'remarks': remarksCtrl.text.trim(),
                                'items': formattedItems,
                                'created_by_user_id': widget.currentUser?.id,
                                'phone': widget.currentUser?.phone,
                              };

                              context.read<PurchaseRequestBloc>().add(
                                CreatePurchaseRequestEvent(payload),
                              );
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✓ Purchase Request created successfully!',
                                  ),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDC2626),
                        foregroundColor: Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Purchase Request (PR)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= ASSIGN DESIGNER MODAL =================
  void _showAssignDesignerDialog(
    BuildContext context,
    PurchaseRequestModel pr,
  ) {
    final userState = context.read<UserBloc>().state;
    final allUsers = userState is UserLoaded ? userState.users : <UserModel>[];
    final designers = allUsers
        .where((u) => u.role == 'Designer' && u.isActive)
        .toList();

    if (designers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Designer users found. Please create a user with role "Designer" first.',
          ),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    int chosenDesignerId = designers.first.id;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assign PR ${pr.prNumber}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an active Designer for Wing "${pr.wing?.name ?? 'General'}":',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: chosenDesignerId,
                        isExpanded: true,
                        dropdownColor: Color(0xFFFFFFFF),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                        items: designers.map((d) {
                          return DropdownMenuItem<int>(
                            value: d.id,
                            child: Text('${d.name} (${d.phone})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => chosenDesignerId = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<PurchaseRequestBloc>().add(
                      AssignDesignerEvent(
                        prId: pr.id,
                        designerId: chosenDesignerId,
                      ),
                    );
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ PR ${pr.prNumber} assigned to Designer!',
                        ),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD97706),
                    foregroundColor: Color(0xFFFFFFFF),
                  ),
                  child: const Text('Confirm Assignment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.currentUser?.role == 'Designer'
                        ? Icons.brush_rounded
                        : Icons.assignment_outlined,
                    color: widget.currentUser?.role == 'Designer'
                        ? Color(0xFFD97706)
                        : Color(0xFFB91C1C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.currentUser?.role == 'Designer'
                        ? 'My Assigned PRs'
                        : 'Purchase Requests (PR)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (widget.isSuperAdmin ||
                  widget.currentUser?.role.toLowerCase() == 'manager' ||
                  widget.currentUser?.isWingIncharge == true)
                ElevatedButton.icon(
                  onPressed: () => _showCreatePRForm(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Create PR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDC2626),
                    foregroundColor: Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          if (widget.currentUser?.role == 'Designer') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFFF7ED).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Color(0xFFD97706).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Designer: ${widget.currentUser?.name ?? 'Designer'} · Showing printing requests assigned to you',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Scope Navigation (Active Requests vs Shifted to Print / Post)
          BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
            builder: (context, state) {
              final allReqs = state is PurchaseRequestLoaded
                  ? state.requests
                  : <PurchaseRequestModel>[];
              final roleFilteredReqs = allReqs.where((pr) {
                if (widget.currentUser?.role == 'Designer' &&
                    widget.currentUser?.id != null) {
                  return pr.assignedDesignerId == widget.currentUser!.id;
                }
                return true;
              }).toList();

              final activeCount = roleFilteredReqs
                  .where(
                    (pr) =>
                        pr.status != 'sent_to_print' && pr.status != 'posted',
                  )
                  .length;
              final poCount = roleFilteredReqs
                  .where((pr) => pr.status == 'sent_to_print')
                  .length;
              final postCount = roleFilteredReqs
                  .where((pr) => pr.status == 'posted' || pr.isPosted)
                  .length;
              final totalCount = roleFilteredReqs.length;

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildScopeTab(
                        title: 'Active Design Requests',
                        count: activeCount,
                        scopeKey: 'active',
                        activeColor: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'Shifted to Print Orders',
                        count: poCount,
                        scopeKey: 'sent_to_print',
                        activeColor: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'Shifted to Post Orders',
                        count: postCount,
                        scopeKey: 'posted',
                        activeColor: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'All PR History',
                        count: totalCount,
                        scopeKey: 'all',
                        activeColor: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) =>
                setState(() => _searchQuery = val.trim().toLowerCase()),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search PR #, product, wing, or designer...',
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
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
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFDC2626),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusChip('All Statuses', null, Color(0xFF64748B)),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'Assigned',
                  'assigned_to_designer',
                  Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'In Progress',
                  'in_progress',
                  Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'Under Review',
                  'submitted_for_approval',
                  Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'Revision Needed',
                  'rejected_revision_needed',
                  Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                _buildStatusChip('Approved', 'approved', Color(0xFF059669)),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'Sent to Print',
                  'sent_to_print',
                  Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildStatusChip('Posted', 'posted', Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildStatusChip('Completed', 'completed', Color(0xFF059669)),
                if (widget.isSuperAdmin ||
                    widget.currentUser?.role.toLowerCase() == 'manager' ||
                    widget.currentUser?.role == 'Wing Incharge' ||
                    widget.currentUser?.isWingIncharge == true) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    'Pending Assignment',
                    'pending_assignment',
                    Color(0xFFD97706),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PR Cards List
          BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
            builder: (context, state) {
              if (state is PurchaseRequestLoading) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFDC2626),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              if (state is PurchaseRequestLoaded) {
                final list = state.requests.where((pr) {
                  // Role isolation: If logged in as Designer, ensure only PRs assigned to this designer are shown
                  if (widget.currentUser?.role == 'Designer' &&
                      widget.currentUser?.id != null) {
                    if (pr.assignedDesignerId != widget.currentUser!.id) {
                      return false;
                    }
                  }

                  final matchesQ =
                      _searchQuery.isEmpty ||
                      pr.prNumber.toLowerCase().contains(_searchQuery) ||
                      (pr.wing?.name.toLowerCase().contains(_searchQuery) ??
                          false) ||
                      (pr.assignedDesigner?.name.toLowerCase().contains(
                            _searchQuery,
                          ) ??
                          false) ||
                      pr.items.any(
                        (it) =>
                            it.productName.toLowerCase().contains(_searchQuery),
                      );

                  final matchesStatus =
                      _selectedStatus == null || pr.status == _selectedStatus;

                  // Scope filtering
                  bool matchesScope = true;
                  if (_selectedStatus == null) {
                    if (_currentScope == 'active') {
                      matchesScope =
                          (pr.status != 'sent_to_print' &&
                          pr.status != 'posted');
                    } else if (_currentScope == 'sent_to_print') {
                      matchesScope = (pr.status == 'sent_to_print');
                    } else if (_currentScope == 'posted') {
                      matchesScope = (pr.status == 'posted' || pr.isPosted);
                    }
                  }

                  return matchesQ && matchesStatus && matchesScope;
                }).toList();

                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No purchase requests match the selected filters.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pr = list[index];
                    return _buildPRCard(context, pr);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab({
    required String title,
    required int count,
    required String scopeKey,
    required Color activeColor,
  }) {
    final isSelected = _currentScope == scopeKey;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _currentScope = scopeKey;
          _selectedStatus = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFF0F172A).withValues(alpha: 0.25)
                    : Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? statusVal, Color activeColor) {
    final isSelected = _selectedStatus == statusVal;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Color(0xFF0F172A) : Color(0xFF64748B),
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Color(0xFFFFFFFF),
      side: BorderSide(color: isSelected ? activeColor : Color(0xFFE2E8F0)),
      onSelected: (selected) {
        setState(() => _selectedStatus = statusVal);
      },
    );
  }

  Widget _buildPRCard(BuildContext context, PurchaseRequestModel pr) {
    // Status visual theme configuration
    Color primaryColor = Color(0xFFD97706);
    Color cardBorderColor = Color(0xFFE2E8F0);
    Color cardBgTint = Color(0xFFFFFFFF);

    if (pr.status == 'assigned_to_designer') {
      primaryColor = Color(0xFF2563EB); // Blue
      cardBorderColor = Color(0xFF2563EB).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFEFF6FF).withValues(alpha: 0.12);
    } else if (pr.status == 'in_progress') {
      primaryColor = Color(0xFF2563EB); // Indigo
      cardBorderColor = Color(0xFF2563EB).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFEFF6FF).withValues(alpha: 0.12);
    } else if (pr.status == 'submitted_for_approval') {
      primaryColor = Color(0xFF2563EB); // Purple
      cardBorderColor = Color(0xFF2563EB).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFF5F3FF).withValues(alpha: 0.12);
    } else if (pr.status == 'rejected_revision_needed') {
      primaryColor = Color(0xFFDC2626); // Rose / Red
      cardBorderColor = Color(0xFFDC2626).withValues(alpha: 0.5);
      cardBgTint = Color(0xFFFEF2F2).withValues(alpha: 0.16);
    } else if (pr.status == 'approved') {
      primaryColor = Color(0xFF059669); // Teal
      cardBorderColor = Color(0xFF059669).withValues(alpha: 0.4);
      cardBgTint = Color(0xFF059669).withValues(alpha: 0.12);
    } else if (pr.status == 'sent_to_print') {
      primaryColor = Color(0xFF2563EB); // Blue
      cardBorderColor = Color(0xFF2563EB).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFEFF6FF).withValues(alpha: 0.12);
    } else if (pr.status == 'posted') {
      primaryColor = Color(0xFF2563EB); // Purple
      cardBorderColor = Color(0xFF2563EB).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFF5F3FF).withValues(alpha: 0.12);
    } else if (pr.status == 'completed') {
      primaryColor = Color(0xFF059669); // Emerald
      cardBorderColor = Color(0xFF059669).withValues(alpha: 0.4);
      cardBgTint = Color(0xFFECFDF5).withValues(alpha: 0.12);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PRDetailsScreen(
                prId: pr.id,
                isSuperAdmin: widget.isSuperAdmin,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
          ),
          child: Stack(
            children: [
              // Subtle colored background tint
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBgTint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              // Left Status Color Accent Strip (4px wide)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  left: 18,
                  right: 16,
                  top: 14,
                  bottom: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PR Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 12,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                pr.prNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            pr.wing?.name ?? 'General Wing',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Items summary or Locked Indicator for Designers
                    if (!isAdminOrManager &&
                        isDesigner &&
                        pr.status == 'assigned_to_designer') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Task specifications locked · Tap to open & Start Work',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pr.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_right_rounded,
                                  color: primaryColor,
                                  size: 16,
                                ),
                                Expanded(
                                  child: Text(
                                    '${it.productName} (Qty: ${it.quantity}${it.size != null ? ', ${it.size}' : ''})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Revision Alert Snippet if revision requested
                    if (pr.status == 'rejected_revision_needed' &&
                        pr.adminReviewRemarks != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF2F2).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFDC2626).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Revision Note: ${pr.adminReviewRemarks!}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Delivery info & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              color: Color(0xFF64748B),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pr.expectedDeliveryDate ?? 'No date set',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (pr.items.any(
                                  (it) =>
                                      it.attachmentPath != null &&
                                      it.attachmentPath!.isNotEmpty,
                                ) ||
                                (pr.artworkFilePath != null &&
                                    pr.artworkFilePath!.isNotEmpty)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F3FF)
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Color(0xFF2563EB)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.attach_file_rounded,
                                      size: 10,
                                      color: Color(0xFF475569),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Media',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        _buildStatusBadge(pr.status, pr),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Assigned Designer & Quick View Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pr.assignedDesigner != null
                                    ? Icons.brush_rounded
                                    : Icons.person_off_outlined,
                                color: pr.assignedDesigner != null
                                    ? primaryColor
                                    : Color(0xFFD97706),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pr.assignedDesigner != null
                                    ? 'Designer: \n${pr.assignedDesigner!.name}'
                                    : 'Unassigned',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: pr.assignedDesigner != null
                                      ? Color(0xFF0F172A)
                                      : Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (widget.isSuperAdmin ||
                                  widget.currentUser?.role.toLowerCase() == 'manager' ||
                                  widget.currentUser?.role == 'Digital Studio Incharge')
                                OutlinedButton(
                                  onPressed: () =>
                                      _showAssignDesignerDialog(context, pr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Color(0xFFD97706),
                                    side: const BorderSide(
                                      color: Color(0xFFD97706),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    minimumSize: const Size(0, 24),
                                    textStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    pr.assignedDesigner != null
                                        ? 'Re-assign'
                                        : 'Assign',
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: primaryColor,
                                size: 17,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, PurchaseRequestModel pr) {
    Color bg = Color(0xFFFFF7ED).withValues(alpha: 0.4);
    Color border = Color(0xFFD97706);
    Color text = Color(0xFFD97706);
    IconData icon = Icons.hourglass_empty_rounded;
    String label = 'Pending';

    if (status == 'assigned_to_designer') {
      bg = Color(0xFFEFF6FF).withValues(alpha: 0.4);
      border = Color(0xFF2563EB);
      text = Color(0xFF2563EB);
      icon = Icons.assignment_ind_rounded;
      label = 'Assigned';
    } else if (status == 'in_progress') {
      bg = Color(0xFFEFF6FF).withValues(alpha: 0.4);
      border = Color(0xFF2563EB);
      text = Color(0xFF2563EB);
      icon = Icons.draw_rounded;
      label = 'In Progress';
    } else if (status == 'submitted_for_approval') {
      bg = Color(0xFFF5F3FF).withValues(alpha: 0.4);
      border = Color(0xFF2563EB);
      text = Color(0xFF475569);
      icon = Icons.hourglass_top_rounded;
      label = 'Under Review';
    } else if (status == 'rejected_revision_needed') {
      bg = Color(0xFFFEF2F2).withValues(alpha: 0.5);
      border = Color(0xFFDC2626);
      text = Color(0xFFB91C1C);
      icon = Icons.replay_rounded;
      label = 'Revision (#${pr.revisionCount})';
    } else if (status == 'approved') {
      bg = Color(0xFF059669).withValues(alpha: 0.35);
      border = Color(0xFF059669);
      text = Color(0xFF059669);
      icon = Icons.check_circle_rounded;
      label = 'Approved';
    } else if (status == 'sent_to_print') {
      bg = Color(0xFFEFF6FF).withValues(alpha: 0.4);
      border = Color(0xFF2563EB);
      text = Color(0xFF2563EB);
      icon = Icons.print_rounded;
      label = 'Sent to Print';
    } else if (status == 'posted') {
      bg = Color(0xFFF5F3FF).withValues(alpha: 0.4);
      border = Color(0xFF2563EB);
      text = Color(0xFF475569);
      icon = Icons.campaign_rounded;
      label = 'Posted ✓';
    } else if (status == 'completed') {
      bg = Color(0xFFECFDF5).withValues(alpha: 0.4);
      border = Color(0xFF059669);
      text = Color(0xFF059669);
      icon = Icons.task_alt_rounded;
      label = 'Completed ✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
