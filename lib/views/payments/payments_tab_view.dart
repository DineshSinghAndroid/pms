import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/payment/payment_bloc.dart';
import 'package:pms/bloc/payment/payment_event.dart';
import 'package:pms/bloc/payment/payment_state.dart';
import 'package:pms/models/payment_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/views/payments/payment_details_sheet.dart';
import 'package:pms/views/payments/record_payment_sheet.dart';
import 'package:pms/theme/pms_theme.dart';
import 'package:pms/widgets/glass_card.dart';
import 'package:pms/widgets/pms_ui.dart';

class PaymentsTabView extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;

  const PaymentsTabView({
    super.key,
    this.currentUser,
    this.isSuperAdmin = true,
  });

  @override
  State<PaymentsTabView> createState() => _PaymentsTabViewState();
}

class _PaymentsTabViewState extends State<PaymentsTabView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPayments() {
    context.read<PaymentBloc>().add(
          FetchPaymentsEvent(
            search: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        );
  }

  void _openRecordPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentSheet(currentUser: widget.currentUser),
    );
  }

  void _openPaymentDetailsModal(ProductPaymentModel payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentDetailsSheet(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PmsPageHeader(
                    icon: Icons.payments_rounded,
                    title: 'Payments',
                    subtitle: 'Vendor settlement and invoice logs',
                    action: FilledButton.icon(
                      onPressed: _openRecordPaymentModal,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Record'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PmsTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search Payment #, Invoice #, product, or vendor...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        color: PmsTheme.primary,
                        onPressed: _loadPayments,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                      _loadPayments();
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) {
                  if (state is PaymentLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: PmsTheme.primary),
                    );
                  }

                  if (state is PaymentError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassCard(
                          backgroundColor: const Color(0xFFFEF2F2),
                          border: Border.all(
                            color: PmsTheme.error.withValues(alpha: 0.35),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: PmsTheme.error,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFB91C1C)),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadPayments,
                                style: FilledButton.styleFrom(
                                  backgroundColor: PmsTheme.error,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final payments = state is PaymentLoaded
                      ? state.payments
                      : <ProductPaymentModel>[];

                  if (payments.isEmpty) {
                    return RefreshIndicator(
                      color: PmsTheme.primary,
                      onRefresh: () async => _loadPayments(),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 40),
                          PmsEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Payments Recorded Yet',
                            subtitle:
                                'Record payments against delivered products to start tracking vendor settlement logs.',
                            actionLabel: 'Record Payment',
                            onAction: _openRecordPaymentModal,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: PmsTheme.primary,
                    onRefresh: () async => _loadPayments(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = payments[index];
                        return _buildPaymentCard(p);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordPaymentModal,
        backgroundColor: PmsTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Record Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ProductPaymentModel p) {
    final item = p.printOrderItem;
    final po = p.printOrder;
    final vendor = p.vendor ?? po?.vendor;
    final wing = p.wing ?? po?.wing;

    return Card(
      elevation: 0,
      color: PmsTheme.glassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PmsTheme.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Payment # & Invoice
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PmsTheme.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.paymentNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.invoiceNumber,
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product & PO
            Text(
              p.productsSummary.isNotEmpty
                  ? p.productsSummary
                  : (item?.productName ?? 'Print Order #${p.poNumber}'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: PmsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${wing?.name ?? 'Wing'} · PO: #${p.poNumber}${p.itemsCount > 1 ? ' (${p.itemsCount} products)' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: PmsTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Vendor & Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VENDOR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.textMuted,
                        ),
                      ),
                      Text(
                        vendor?.name ?? 'Vendor',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAYMENT DATE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.textMuted,
                        ),
                      ),
                      Text(
                        p.paymentDate ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.amount != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'AMOUNT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textMuted,
                          ),
                        ),
                        Text(
                          '₹${p.amount!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Footer: View Details button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By: ${p.paidByUser?.name ?? 'Admin'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: PmsTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openPaymentDetailsModal(p),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: PmsTheme.textPrimary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
