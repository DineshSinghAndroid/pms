import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/payment/payment_bloc.dart';
import 'package:pms/bloc/payment/payment_event.dart';
import 'package:pms/bloc/payment/payment_state.dart';
import 'package:pms/models/eligible_payment_item_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/theme/pms_theme.dart';

class RecordPaymentSheet extends StatefulWidget {
  final UserModel? currentUser;

  const RecordPaymentSheet({super.key, this.currentUser});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _searchController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'Bank Transfer';
  EligiblePaymentItemModel? _selectedItem;
  String _searchQuery = '';

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDisplayDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(const FetchEligiblePaymentItemsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _invoiceController.dispose();
    _amountController.dispose();
    _refController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a fully completed order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_selectedItem!.isFullyCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot record payment. Order #${_selectedItem!.poNumber} is not fully received yet (${_selectedItem!.totalReceivedQuantity}/${_selectedItem!.totalOrderedQuantity} pcs). Store incharges must receive all products first.',
          ),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    if (_invoiceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice / Bill number is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dateStr = _formatDate(_selectedDate);
    final amountVal = double.tryParse(_amountController.text.trim());

    context.read<PaymentBloc>().add(
          RecordPaymentEvent(
            printOrderId: _selectedItem!.printOrderId,
            printOrderItemId: _selectedItem!.items.isNotEmpty ? _selectedItem!.items.first.id : null,
            invoiceNumber: _invoiceController.text.trim(),
            paymentDate: dateStr,
            amount: amountVal,
            paymentMethod: _selectedMethod,
            transactionReference: _refController.text.trim().isEmpty
                ? null
                : _refController.text.trim(),
            remarks: _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
            phone: widget.currentUser?.phone,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentActionSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is PaymentLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is PaymentLoaded && state.isSubmitting;
        final eligibleItems = state is PaymentLoaded ? state.eligibleItems : <EligiblePaymentItemModel>[];

        final filteredItems = eligibleItems.where((it) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final inProducts = it.items.any((p) =>
              p.productName.toLowerCase().contains(q) ||
              p.productCode.toLowerCase().contains(q));
          return it.productName.toLowerCase().contains(q) ||
              it.poNumber.toLowerCase().contains(q) ||
              it.vendorName.toLowerCase().contains(q) ||
              it.wingName.toLowerCase().contains(q) ||
              it.productCode.toLowerCase().contains(q) ||
              inProducts;
        }).toList();

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
                  color: const Color(0xFFECFDF5), // Emerald 50
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PmsTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Select fully received print order against vendor invoice',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Step 1: Candidate search
                    const Text(
                      '1. SELECT DELIVERED PRINT ORDER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search PO #, vendor, wing, or product name...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: PmsTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Candidates List
                    if (filteredItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: PmsTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'No candidate products found to pay.',
                          style: TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 190,
                        child: ListView.separated(
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isFully = item.isFullyCompleted;
                            final isSelected =
                                _selectedItem?.printOrderId == item.printOrderId;
                            final title = item.itemsCount > 1
                                ? '#${item.poNumber} · ${item.productName} (+${item.itemsCount - 1} more)'
                                : '#${item.poNumber} · ${item.productName}';

                            if (isFully) {
                              // Selectable Green
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedItem = item;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFECFDF5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFA7F3D0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF059669),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: PmsTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${item.vendorName} · ${item.wingName}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: PmsTheme.textSecondary,
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
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '✓ Fully Completed (${item.totalReceivedQuantity}/${item.totalOrderedQuantity} pcs)',
                                          style: const TextStyle(
                                            color: Color(0xFF065F46),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // Non-selectable Yellow
                              final instruction = item.totalReceivedQuantity > 0
                                  ? 'Partially Received (${item.totalReceivedQuantity} / ${item.totalOrderedQuantity})'
                                  : 'Not Received (0 / ${item.totalOrderedQuantity})';

                              return InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '⚠️ Order #${item.poNumber} is not fully received yet ($instruction). Only fully completed orders can be selected for payment. Store incharges must receive all products first.',
                                      ),
                                      backgroundColor: Colors.amber.shade900,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB), // Amber 50
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D), // Amber 300
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFB45309), // Amber 700
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF78350F),
                                              ),
                                            ),
                                            Text(
                                              '${item.vendorName} · ${item.wingName}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF92400E),
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
                                          color: const Color(0xFFFDE68A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '⚠️ $instruction',
                                          style: const TextStyle(
                                            color: Color(0xFF78350F),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Step 2: Selected Item Order Details Preview Card
                    if (_selectedItem != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF059669),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '#${_selectedItem!.poNumber} · ${_selectedItem!.vendorName} (Fully Received)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedItem = null;
                                    });
                                  },
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFA7F3D0)),
                            const SizedBox(height: 4),
                            Text(
                              'Wing: ${_selectedItem!.wingName} · PR #: ${_selectedItem!.prNumber}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Products in Order: ${_selectedItem!.itemsCount} item(s) · Total Qty: ${_selectedItem!.totalReceivedQuantity} pcs',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'Remark: ${_selectedItem!.printOrderRemarks ?? _selectedItem!.requesterRemarks ?? 'Standard print specifications'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Order Items Breakdown:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: PmsTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_selectedItem!.items.isNotEmpty)
                              ..._selectedItem!.items.map(
                                (prod) => Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: PmsTheme.glassSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${_selectedItem!.poNumber} - ${prod.productName}${prod.productCode.isNotEmpty ? ' (${prod.productCode})' : ''} Received',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'Qty: ${prod.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Size: ${prod.size ?? 'Standard'}',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Wing: ${_selectedItem!.wingName}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        'Received/Pending: ${prod.receivedQuantity} / ${prod.pendingQuantity}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      if (prod.attachmentName != null &&
                                          prod.attachmentName!.isNotEmpty)
                                        Text(
                                          'File: ${prod.attachmentName}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: PmsTheme.glassSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${_selectedItem!.poNumber} - ${_selectedItem!.productName}${_selectedItem!.productCode.isNotEmpty ? ' (${_selectedItem!.productCode})' : ''} Received',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${_selectedItem!.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Size: ${_selectedItem!.size ?? 'Standard'}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Wing: ${_selectedItem!.wingName}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Received/Pending: ${_selectedItem!.receivedQuantity} / ${_selectedItem!.pendingQuantity}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              'Store Incharge Receiving History:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_selectedItem!.receivingHistory.isNotEmpty)
                              ..._selectedItem!.receivingHistory.map(
                                (h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    h.formattedEntry,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                '• ${_selectedItem!.totalReceivedQuantity} Qty Received by Store Incharge (Challan: CH-Verified)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF334155),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step 3: Payment form fields
                      const Text(
                        '2. INVOICE & PAYMENT DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Invoice Number
                      TextField(
                        controller: _invoiceController,
                        decoration: InputDecoration(
                          labelText: 'Invoice / Bill Number *',
                          hintText: 'e.g. INV-2026-0921',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date & Amount row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Payment Date *',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _formatDisplayDate(_selectedDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount (₹)',
                                hintText: 'e.g. 1500.00',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Text('Bank Transfer / NEFT / RTGS'),
                          ),
                          DropdownMenuItem(
                            value: 'Cheque',
                            child: Text('Cheque'),
                          ),
                          DropdownMenuItem(
                            value: 'UPI',
                            child: Text('UPI / QR'),
                          ),
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMethod = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reference
                      TextField(
                        controller: _refController,
                        decoration: InputDecoration(
                          labelText: 'UTR / Cheque Reference (Optional)',
                          hintText: 'e.g. UTR987654321',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remarks
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Remarks / Notes',
                          hintText: 'e.g. Settled against delivery challan...',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PmsTheme.glassSurface,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (_selectedItem == null || isSubmitting) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Payment',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
}
