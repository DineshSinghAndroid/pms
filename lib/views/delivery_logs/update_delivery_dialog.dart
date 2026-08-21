import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/print_order/print_order_bloc.dart';
import 'package:pms/bloc/print_order/print_order_event.dart';
import 'package:pms/bloc/print_order/print_order_state.dart';
import 'package:pms/models/print_order_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _selectPO(PrintOrderModel po) {
    setState(() {
      _selectedPO = po;
      _itemControllers.clear();
      for (var it in po.items) {
        final remaining = (it.quantity - it.receivedQuantity).clamp(0, it.quantity);
        _itemControllers[it.id] = TextEditingController(text: remaining.toString());
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
    final activeList = widget.printOrders.where((p) => p.status != 'cancelled').toList();
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
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final challan = _challanController.text.trim();
    if (challan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan Number is required.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final itemsPayload = <Map<String, dynamic>>[];
    int totalNewQty = 0;

    for (var it in _selectedPO!.items) {
      final ctrl = _itemControllers[it.id];
      final qty = int.tryParse(ctrl?.text.trim() ?? '') ?? 0;
      itemsPayload.add({
        'id': it.id,
        'received_quantity': qty,
      });
      totalNewQty += qty;
    }

    if (totalNewQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 1 received item quantity.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final phone = widget.userProfile?.phone;
    final dateStr = '${_deliveryDate.year.toString().padLeft(4, '0')}-${_deliveryDate.month.toString().padLeft(2, '0')}-${_deliveryDate.day.toString().padLeft(2, '0')}';

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
      backgroundColor: const Color(0xFF1E293B),
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
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF34D399), size: 20),
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
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Log product shipment quantities & Challan number',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white60, size: 20),
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
                        color: Color(0xFF818CF8),
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
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by PO #, vendor, or wing...',
                          hintStyle:
                              const TextStyle(color: Colors.white38, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.white54, size: 18),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: _filteredPOs.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No matching Print Orders found.',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 12)),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredPOs.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Color(0xFF1E293B), height: 1),
                                itemBuilder: (context, idx) {
                                  final po = _filteredPOs[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${po.poNumber} · ${po.vendor?.name ?? "Vendor"}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${po.wing?.name ?? "Wing"} · ${po.items.length} Products · Status: ${po.status}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF38BDF8),
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
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6)),
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
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: const Color(0xFF475569)),
                                      ),
                                      child: Text(
                                        _selectedPO!.poNumber,
                                        style: const TextStyle(
                                          color: Color(0xFF2DD4BF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedPO!.vendor?.name ?? 'Vendor',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => setState(() => _selectedPO = null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 28),
                                  ),
                                  child: const Text('Change PO',
                                      style: TextStyle(
                                          color: Color(0xFF38BDF8), fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Target Wing: ${_selectedPO!.wing?.name ?? "General Wing"} · Delivery: ${_selectedPO!.expectedDeliveryDate ?? "ASAP"}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                            if (_selectedPO!.printOrderRemarks != null &&
                                _selectedPO!.printOrderRemarks!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Order Note: ${_selectedPO!.printOrderRemarks}',
                                style: const TextStyle(
                                  color: Color(0xFFFCD34D),
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
                      const Text(
                        '2. PRODUCTS & QUANTITIES RECEIVED *',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedPO!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final it = _selectedPO!.items[idx];
                          final ctrl = _itemControllers[it.id];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${idx + 1}. ${it.productName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Size: ${it.size ?? "Standard"} · Ordered: ${it.quantity} · Already Recv: ${it.receivedQuantity}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (it.attachmentPath != null &&
                                        it.attachmentPath!.isNotEmpty)
                                      IconButton(
                                        onPressed: () {
                                          final fullUrl = it.attachmentPath!
                                                  .startsWith('http')
                                              ? it.attachmentPath!
                                              : 'http://192.168.1.146:8000/storage/${it.attachmentPath}';
                                          _launchUrl(fullUrl);
                                        },
                                        tooltip: 'Download Proof',
                                        icon: const Icon(
                                            Icons.download_rounded,
                                            color: Color(0xFF38BDF8),
                                            size: 18),
                                      ),
                                  ],
                                ),
                                const Divider(
                                    color: Color(0xFF1E293B), height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Qty Received Now:',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 90,
                                          height: 36,
                                          child: TextField(
                                            controller: ctrl,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFF1E293B),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: Color(0xFF334155)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: Color(0xFF334155)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '/ ${it.quantity}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                          color: Color(0xFF818CF8),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Challan Number *',
                          labelStyle: const TextStyle(
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.bold),
                          hintText: 'e.g. CH-2026-9812',
                          hintStyle:
                              const TextStyle(color: Colors.white38, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
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
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery Date',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 10)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_deliveryDate.day}/${_deliveryDate.month}/${_deliveryDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.calendar_today_rounded,
                                  color: Color(0xFF818CF8), size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remark / Delivery Note
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Remark / Delivery Note',
                          labelStyle:
                              const TextStyle(color: Colors.white70, fontSize: 12),
                          hintText:
                              'e.g. Received partial 200 copies in good condition at gate...',
                          hintStyle:
                              const TextStyle(color: Colors.white38, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF334155)),
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
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submitDelivery,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Save & Record Delivery',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
