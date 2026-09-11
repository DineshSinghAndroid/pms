import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/payment/payment_bloc.dart';
import 'package:pms/bloc/payment/payment_event.dart';
import 'package:pms/bloc/payment/payment_state.dart';
import 'package:pms/models/payment_model.dart';

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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A), // Slate 900
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Emerald 500
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.paymentNumber,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
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
                            'Payment Record & Lifecycle',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Day 1 historical timeline',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
                        color: const Color(0xFFF8FAFC),
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
                                    color: Color(0xFF0F172A),
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
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'ORDERED PRODUCTS:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (payment.items.isNotEmpty)
                            ...payment.items.map((it) {
                              final name = it is Map
                                  ? it['product_name'] ?? 'Product'
                                  : (it.productName ?? 'Product');
                              final qty = it is Map
                                  ? it['quantity'] ?? 1
                                  : (it.quantity ?? 1);
                              final sz = it is Map
                                  ? it['size'] ?? 'Standard'
                                  : (it.size ?? 'Standard');
                              final rec = it is Map
                                  ? (it['received_quantity'] ?? qty)
                                  : qty;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 14, color: Color(0xFF059669)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$name · $qty pcs ($sz)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Recv: $rec/$qty',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                          else if (item != null)
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 14, color: Color(0xFF059669)),
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
                            color: Color(0xFF0F172A),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
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
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF0F172A),
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
    Color dotColor = const Color(0xFF4F46E5); // Indigo
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
                  color: const Color(0xFFF8FAFC),
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
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (stage.date != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            stage.date!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('Requester: ${d['requester_name'] ?? 'Staff'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('Approved By: ${d['approved_by'] ?? 'Admin'} (${d['approved_at'] ?? ''})',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            Text('Ordered Quantity: ${d['ordered_quantity'] ?? 1} · Size: ${d['size'] ?? 'Standard'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
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
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
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
