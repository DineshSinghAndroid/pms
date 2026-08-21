import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  State<PurchaseRequestsTabView> createState() => _PurchaseRequestsTabViewState();
}

class _PurchaseRequestsTabViewState extends State<PurchaseRequestsTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;
  String _currentScope = 'active';

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
    } else if (widget.isSuperAdmin) {
      context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
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

    final allProductTypes = ptState is ProductTypeLoaded ? ptState.productTypes : <ProductTypeModel>[];
    final allWings = wingState is WingLoaded ? wingState.wings : [];

    if (allProductTypes.isEmpty || allWings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure Product Types and Wings are loaded.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    // Dynamic item list state
    List<Map<String, dynamic>> itemsList = [];
    int? selectedWingId = allWings.isNotEmpty ? allWings.first.id : null;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    final timeCtrl = TextEditingController(text: '04:00 PM');
    final remarksCtrl = TextEditingController();
    ProductTypeModel? chosenPickerProduct;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
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
                            Icon(Icons.assignment_outlined, color: Color(0xFFFB7185), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Create Purchase Request (PR)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: PRODUCT PICKER & SEARCH
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Select Product to Add (Search from 614 Master Items) *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDA4AF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ProductTypeModel>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E293B),
                                value: chosenPickerProduct,
                                hint: const Text('Search & Select Product', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                items: allProductTypes.map((pt) {
                                  return DropdownMenuItem<ProductTypeModel>(
                                    value: pt,
                                    child: Text(
                                      '[${pt.productCode ?? '000000'}] ${pt.name} (${pt.category?.name ?? ''})',
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
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
                                        'product_type_id': chosenPickerProduct!.id,
                                        'product_name': chosenPickerProduct!.name,
                                        'product_code': chosenPickerProduct!.productCode ?? '000000',
                                        'quantity_ctrl': TextEditingController(text: '1'),
                                        'size_ctrl': TextEditingController(),
                                        'attachment_ctrl': TextEditingController(),
                                      });
                                      chosenPickerProduct = null;
                                    });
                                  },
                            icon: const Icon(Icons.add_box_rounded, size: 16),
                            label: const Text('Add Product Box'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SECTION 2: DYNAMIC PRODUCT BOXES
                    Text(
                      '2. Selected Products & Specifications (${itemsList.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    if (itemsList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155), style: BorderStyle.solid),
                        ),
                        child: const Center(
                          child: Text(
                            'No products added yet. Select a product above and tap "Add Product Box".',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF475569)),
                                      ),
                                      child: Text(
                                        item['product_code'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF34D399),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['product_name'],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFDA4AF), size: 18),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Quantity *', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: item['quantity_ctrl'] as TextEditingController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Size
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Size / Dimensions', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: item['size_ctrl'] as TextEditingController,
                                        style: const TextStyle(fontSize: 13, color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. 10x4 ft, A4',
                                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Sample Attachment field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sample Attachment (File / Image Name / Reference)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: item['attachment_ctrl'] as TextEditingController,
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.attach_file, color: Color(0xFFFDA4AF), size: 16),
                                    hintText: 'e.g. admission_banner_sample.png',
                                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    filled: true,
                                    fillColor: const Color(0xFF1E293B),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    // Wing Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedWingId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          items: allWings.map((w) {
                            return DropdownMenuItem<int>(
                              value: w.id,
                              child: Text('${w.name} (${w.code ?? 'Wing'})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedWingId = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Date & Time Picker
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFFDA4AF)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Delivery Time',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Remarks & finishing instructions...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: itemsList.isEmpty || selectedWingId == null
                          ? null
                          : () {
                              final formattedItems = itemsList.map((it) {
                                final qtyStr = (it['quantity_ctrl'] as TextEditingController).text.trim();
                                final sizeStr = (it['size_ctrl'] as TextEditingController).text.trim();
                                final attStr = (it['attachment_ctrl'] as TextEditingController).text.trim();
                                return {
                                  'product_type_id': it['product_type_id'],
                                  'product_name': it['product_name'],
                                  'quantity': int.tryParse(qtyStr) ?? 1,
                                  'size': sizeStr.isNotEmpty ? sizeStr : null,
                                  'attachment_path': attStr.isNotEmpty ? attStr : null,
                                  'attachment_name': attStr.isNotEmpty ? attStr : null,
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
                              };

                              context.read<PurchaseRequestBloc>().add(CreatePurchaseRequestEvent(payload));
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Purchase Request created successfully!'),
                                  backgroundColor: Color(0xFFE11D48),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Purchase Request (PR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
  void _showAssignDesignerDialog(BuildContext context, PurchaseRequestModel pr) {
    final userState = context.read<UserBloc>().state;
    final allUsers = userState is UserLoaded ? userState.users : <UserModel>[];
    final designers = allUsers.where((u) => u.role == 'Designer' && u.isActive).toList();

    if (designers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Designer users found. Please create a user with role "Designer" first.'),
          backgroundColor: Color(0xFFF59E0B),
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
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Icon(Icons.person_pin_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text('Assign PR ${pr.prNumber}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an active Designer for Wing "${pr.wing?.name ?? 'General'}":',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: chosenDesignerId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        items: designers.map((d) {
                          return DropdownMenuItem<int>(
                            value: d.id,
                            child: Text('${d.name} (${d.phone})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => chosenDesignerId = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<PurchaseRequestBloc>().add(
                          AssignDesignerEvent(prId: pr.id, designerId: chosenDesignerId),
                        );
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ PR ${pr.prNumber} assigned to Designer!'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
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
                    widget.currentUser?.role == 'Designer' ? Icons.brush_rounded : Icons.assignment_outlined,
                    color: widget.currentUser?.role == 'Designer' ? const Color(0xFFF59E0B) : const Color(0xFFFDA4AF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.currentUser?.role == 'Designer' ? 'My Assigned PRs' : 'Purchase Requests (PR)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              if (widget.isSuperAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showCreatePRForm(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Create PR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),

          if (widget.currentUser?.role == 'Designer') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF78350F).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFCD34D), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Designer: ${widget.currentUser?.name ?? 'Designer'} · Showing printing requests assigned to you',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFDE68A), fontWeight: FontWeight.w600),
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
              final allReqs = state is PurchaseRequestLoaded ? state.requests : <PurchaseRequestModel>[];
              final roleFilteredReqs = allReqs.where((pr) {
                if (widget.currentUser?.role == 'Designer' && widget.currentUser?.id != null) {
                  return pr.assignedDesignerId == widget.currentUser!.id;
                }
                return true;
              }).toList();

              final activeCount = roleFilteredReqs.where((pr) => pr.status != 'sent_to_print' && pr.status != 'posted').length;
              final poCount = roleFilteredReqs.where((pr) => pr.status == 'sent_to_print').length;
              final postCount = roleFilteredReqs.where((pr) => pr.status == 'posted' || pr.isPosted).length;
              final totalCount = roleFilteredReqs.length;

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildScopeTab(
                        title: 'Active Design Requests',
                        count: activeCount,
                        scopeKey: 'active',
                        activeColor: const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'Shifted to Print Orders',
                        count: poCount,
                        scopeKey: 'sent_to_print',
                        activeColor: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'Shifted to Post Orders',
                        count: postCount,
                        scopeKey: 'posted',
                        activeColor: const Color(0xFFA855F7),
                      ),
                      const SizedBox(width: 4),
                      _buildScopeTab(
                        title: 'All PR History',
                        count: totalCount,
                        scopeKey: 'all',
                        activeColor: const Color(0xFF64748B),
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
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search PR #, product, wing, or designer...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
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
                _buildStatusChip('All Statuses', null, const Color(0xFF64748B)),
                const SizedBox(width: 8),
                _buildStatusChip('Assigned', 'assigned_to_designer', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatusChip('In Progress', 'in_progress', const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildStatusChip('Under Review', 'submitted_for_approval', const Color(0xFFA855F7)),
                const SizedBox(width: 8),
                _buildStatusChip('Revision Needed', 'rejected_revision_needed', const Color(0xFFE11D48)),
                const SizedBox(width: 8),
                _buildStatusChip('Approved', 'approved', const Color(0xFF14B8A6)),
                const SizedBox(width: 8),
                _buildStatusChip('Sent to Print', 'sent_to_print', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatusChip('Posted', 'posted', const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _buildStatusChip('Completed', 'completed', const Color(0xFF10B981)),
                if (widget.isSuperAdmin) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip('Pending Assignment', 'pending_assignment', const Color(0xFFF59E0B)),
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
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE11D48), strokeWidth: 2.5),
                  ),
                );
              }

              if (state is PurchaseRequestLoaded) {
                final list = state.requests.where((pr) {
                  // Role isolation: If logged in as Designer, ensure only PRs assigned to this designer are shown
                  if (widget.currentUser?.role == 'Designer' && widget.currentUser?.id != null) {
                    if (pr.assignedDesignerId != widget.currentUser!.id) {
                      return false;
                    }
                  }

                  final matchesQ = _searchQuery.isEmpty ||
                      pr.prNumber.toLowerCase().contains(_searchQuery) ||
                      (pr.wing?.name.toLowerCase().contains(_searchQuery) ?? false) ||
                      (pr.assignedDesigner?.name.toLowerCase().contains(_searchQuery) ?? false) ||
                      pr.items.any((it) => it.productName.toLowerCase().contains(_searchQuery));

                  final matchesStatus = _selectedStatus == null || pr.status == _selectedStatus;

                  // Scope filtering
                  bool matchesScope = true;
                  if (_selectedStatus == null) {
                    if (_currentScope == 'active') {
                      matchesScope = (pr.status != 'sent_to_print' && pr.status != 'posted');
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Center(
                      child: Text(
                        'No purchase requests match the selected filters.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                  )
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
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
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
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(
        color: isSelected ? activeColor : const Color(0xFF334155),
      ),
      onSelected: (selected) {
        setState(() => _selectedStatus = statusVal);
      },
    );
  }

  Widget _buildPRCard(BuildContext context, PurchaseRequestModel pr) {
    // Status visual theme configuration
    Color primaryColor = const Color(0xFFF59E0B);
    Color cardBorderColor = const Color(0xFF334155);
    Color cardBgTint = const Color(0xFF1E293B);

    if (pr.status == 'assigned_to_designer') {
      primaryColor = const Color(0xFF3B82F6); // Blue
      cardBorderColor = const Color(0xFF3B82F6).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF1E3A8A).withValues(alpha: 0.12);
    } else if (pr.status == 'in_progress') {
      primaryColor = const Color(0xFF6366F1); // Indigo
      cardBorderColor = const Color(0xFF6366F1).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF312E81).withValues(alpha: 0.12);
    } else if (pr.status == 'submitted_for_approval') {
      primaryColor = const Color(0xFFA855F7); // Purple
      cardBorderColor = const Color(0xFFA855F7).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF581C87).withValues(alpha: 0.12);
    } else if (pr.status == 'rejected_revision_needed') {
      primaryColor = const Color(0xFFE11D48); // Rose / Red
      cardBorderColor = const Color(0xFFFB7185).withValues(alpha: 0.5);
      cardBgTint = const Color(0xFF881337).withValues(alpha: 0.16);
    } else if (pr.status == 'approved') {
      primaryColor = const Color(0xFF14B8A6); // Teal
      cardBorderColor = const Color(0xFF14B8A6).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF0D9488).withValues(alpha: 0.12);
    } else if (pr.status == 'sent_to_print') {
      primaryColor = const Color(0xFF3B82F6); // Blue
      cardBorderColor = const Color(0xFF3B82F6).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF1E3A8A).withValues(alpha: 0.12);
    } else if (pr.status == 'posted') {
      primaryColor = const Color(0xFF8B5CF6); // Purple
      cardBorderColor = const Color(0xFFA855F7).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF581C87).withValues(alpha: 0.12);
    } else if (pr.status == 'completed') {
      primaryColor = const Color(0xFF10B981); // Emerald
      cardBorderColor = const Color(0xFF10B981).withValues(alpha: 0.4);
      cardBgTint = const Color(0xFF064E3B).withValues(alpha: 0.12);
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
            color: const Color(0xFF1E293B),
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
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 18, right: 16, top: 14, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PR Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.tag_rounded, size: 12, color: primaryColor),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            pr.wing?.name ?? 'General Wing',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Items summary
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pr.items.map((it) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_right_rounded, color: primaryColor, size: 16),
                              Expanded(
                                child: Text(
                                  '${it.productName} (Qty: ${it.quantity}${it.size != null ? ', ${it.size}' : ''})',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Revision Alert Snippet if revision requested
                    if (pr.status == 'rejected_revision_needed' && pr.adminReviewRemarks != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF881337).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFFDA4AF)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Revision Note: ${pr.adminReviewRemarks!}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFFFDA4AF), fontWeight: FontWeight.w600),
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
                            const Icon(Icons.event_rounded, color: Color(0xFF94A3B8), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              pr.expectedDeliveryDate ?? 'No date set',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            if (pr.items.any((it) => it.attachmentPath != null && it.attachmentPath!.isNotEmpty) ||
                                (pr.artworkFilePath != null && pr.artworkFilePath!.isNotEmpty)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF581C87).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.attach_file_rounded, size: 10, color: Color(0xFFD8B4FE)),
                                    SizedBox(width: 2),
                                    Text('Media', style: TextStyle(fontSize: 9, color: Color(0xFFD8B4FE), fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pr.assignedDesigner != null ? Icons.brush_rounded : Icons.person_off_outlined,
                                color: pr.assignedDesigner != null ? primaryColor : const Color(0xFFF59E0B),
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
                                  color: pr.assignedDesigner != null ? Colors.white : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (widget.isSuperAdmin)
                                OutlinedButton(
                                  onPressed: () => _showAssignDesignerDialog(context, pr),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFF59E0B),
                                    side: const BorderSide(color: Color(0xFFF59E0B)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: const Size(0, 24),
                                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: Text(pr.assignedDesigner != null ? 'Re-assign' : 'Assign'),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                'View Details',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                              Icon(Icons.chevron_right_rounded, color: primaryColor, size: 17),
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
    Color bg = const Color(0xFF78350F).withValues(alpha: 0.4);
    Color border = const Color(0xFFF59E0B);
    Color text = const Color(0xFFFCD34D);
    IconData icon = Icons.hourglass_empty_rounded;
    String label = 'Pending';

    if (status == 'assigned_to_designer') {
      bg = const Color(0xFF1E3A8A).withValues(alpha: 0.4);
      border = const Color(0xFF3B82F6);
      text = const Color(0xFF93C5FD);
      icon = Icons.assignment_ind_rounded;
      label = 'Assigned';
    } else if (status == 'in_progress') {
      bg = const Color(0xFF312E81).withValues(alpha: 0.4);
      border = const Color(0xFF6366F1);
      text = const Color(0xFFA5B4FC);
      icon = Icons.draw_rounded;
      label = 'In Progress';
    } else if (status == 'submitted_for_approval') {
      bg = const Color(0xFF581C87).withValues(alpha: 0.4);
      border = const Color(0xFFA855F7);
      text = const Color(0xFFD8B4FE);
      icon = Icons.hourglass_top_rounded;
      label = 'Under Review';
    } else if (status == 'rejected_revision_needed') {
      bg = const Color(0xFF881337).withValues(alpha: 0.5);
      border = const Color(0xFFFB7185);
      text = const Color(0xFFFDA4AF);
      icon = Icons.replay_rounded;
      label = 'Revision (#${pr.revisionCount})';
    } else if (status == 'approved') {
      bg = const Color(0xFF0D9488).withValues(alpha: 0.35);
      border = const Color(0xFF14B8A6);
      text = const Color(0xFF5EEAD4);
      icon = Icons.check_circle_rounded;
      label = 'Approved';
    } else if (status == 'sent_to_print') {
      bg = const Color(0xFF1E3A8A).withValues(alpha: 0.4);
      border = const Color(0xFF3B82F6);
      text = const Color(0xFF93C5FD);
      icon = Icons.print_rounded;
      label = 'Sent to Print';
    } else if (status == 'posted') {
      bg = const Color(0xFF581C87).withValues(alpha: 0.4);
      border = const Color(0xFFA855F7);
      text = const Color(0xFFD8B4FE);
      icon = Icons.campaign_rounded;
      label = 'Posted ✓';
    } else if (status == 'completed') {
      bg = const Color(0xFF064E3B).withValues(alpha: 0.4);
      border = const Color(0xFF10B981);
      text = const Color(0xFF6EE7B7);
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
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text),
          ),
        ],
      ),
    );
  }
}
