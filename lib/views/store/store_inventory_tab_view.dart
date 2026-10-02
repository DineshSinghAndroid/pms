import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/store/store_bloc.dart';
import '../../bloc/store/store_event.dart';
import '../../bloc/store/store_state.dart';
import '../../models/store_inventory_model.dart';
import '../../models/sub_store_model.dart';
import '../../models/user_model.dart';
import '../../repositories/store_repository.dart';
import '../../repositories/sub_store_repository.dart';
import '../../theme/pms_theme.dart';

class StoreInventoryTabView extends StatefulWidget {
  final UserModel? userProfile;
  final bool isSuperAdmin;

  const StoreInventoryTabView({
    super.key,
    this.userProfile,
    required this.isSuperAdmin,
  });

  @override
  State<StoreInventoryTabView> createState() => _StoreInventoryTabViewState();
}

class _StoreInventoryTabViewState extends State<StoreInventoryTabView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _selectedStockStatus = 'all';
  String _searchQuery = '';

  String get _role => (widget.userProfile?.role ?? '').toLowerCase().trim();
  bool get isSuperAdmin =>
      widget.isSuperAdmin ||
      widget.userProfile?.isSuperAdmin == true ||
      _role == 'superadmin' ||
      _role == 'super admin';
  bool get isManager => _role == 'manager';
  bool get isStoreIncharge =>
      _role == 'store incharge' ||
      _role == 'store_incharge' ||
      widget.userProfile?.role == 'Store Incharge';

  bool get canManageStock => isSuperAdmin || isManager || isStoreIncharge;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    context.read<StoreBloc>().add(FetchStoreInventoryEvent(
          categoryId: _selectedCategoryId,
          stockStatus: _selectedStockStatus,
          search: _searchQuery,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter({int? categoryId, String? stockStatus, String? search}) {
    setState(() {
      if (categoryId != null || categoryId == 0) {
        _selectedCategoryId = categoryId == 0 ? null : categoryId;
      }
      if (stockStatus != null) {
        _selectedStockStatus = stockStatus;
      }
      if (search != null) {
        _searchQuery = search;
      }
    });

    context.read<StoreBloc>().add(FetchStoreInventoryEvent(
          categoryId: _selectedCategoryId,
          stockStatus: _selectedStockStatus,
          search: _searchQuery,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoreBloc, StoreState>(
      listener: (context, state) {
        if (state is StoreError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StoreLoading) {
          return const Center(
            child: CircularProgressIndicator(color: PmsTheme.primary),
          );
        }

        if (state is StoreError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to Load Store Inventory',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadInventory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state is StoreLoaded ? state : null;
        final stats = loaded?.stats ?? const StoreStatsModel();
        final categories = loaded?.categories ?? [];
        final products = loaded?.products ?? [];

        return RefreshIndicator(
          color: PmsTheme.primary,
          onRefresh: () async {
            context.read<StoreBloc>().add(RefreshStoreInventoryEvent(
                  categoryId: _selectedCategoryId,
                  stockStatus: _selectedStockStatus,
                  search: _searchQuery,
                ));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header title & info banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PmsTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warehouse_rounded, color: PmsTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Inventory',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: PmsTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              isStoreIncharge
                                  ? 'Stock for your assigned store categories'
                                  : 'Real-time stock monitoring & audit logs',
                              style: const TextStyle(
                                fontSize: 12,
                                color: PmsTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadInventory,
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh_rounded, color: PmsTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),

              // KPI Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Items',
                          value: stats.totalProducts.toString(),
                          icon: Icons.layers_outlined,
                          color: const Color(0xFF6366F1),
                          bgColor: const Color(0xFFEEF2FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Stock',
                          value: NumberFormat('#,###').format(stats.totalStock),
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'In Stock',
                          value: stats.inStockProducts.toString(),
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Out of Stock',
                          value: stats.outOfStockProducts.toString(),
                          icon: Icons.error_outline_rounded,
                          color: const Color(0xFFE11D48),
                          bgColor: const Color(0xFFFFF1F2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter Chips
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        _buildCategoryChip(
                          label: 'All Categories',
                          isSelected: _selectedCategoryId == null,
                          onTap: () => _applyFilter(categoryId: 0),
                        ),
                        const SizedBox(width: 8),
                        ...categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(
                              label: cat.name,
                              isSelected: _selectedCategoryId == cat.id,
                              onTap: () => _applyFilter(categoryId: cat.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Search Bar & Stock Status Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products by name or code...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: PmsTheme.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilter(search: '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: PmsTheme.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (val) => _applyFilter(search: val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip('All Items', 'all'),
                          const SizedBox(width: 8),
                          _buildStatusChip('In Stock', 'in_stock'),
                          const SizedBox(width: 8),
                          _buildStatusChip('Out of Stock', 'out_of_stock'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Products List or Empty State
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No Products Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No product matches "$_searchQuery".'
                                : 'No products available for selected category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildProductCard(product);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? PmsTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? PmsTheme.primary : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: PmsTheme.primary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : PmsTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStockStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(stockStatus: value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(StoreProductModel product) {
    final isInStock = product.isInStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Code Row
            Row(
              children: [
                if (product.categoryName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.categoryName!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (product.productCode != null && product.productCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.productCode!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                const Spacer(),
                // Stock Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInStock ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isInStock ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInStock ? Icons.check_circle_rounded : Icons.highlight_off_rounded,
                        size: 13,
                        color: isInStock ? const Color(0xFF059669) : const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isInStock ? '${product.currentStock} in stock' : 'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInStock ? const Color(0xFF047857) : const Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            if (product.description != null && product.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View Logs Button
                OutlinedButton.icon(
                  onPressed: () => _showProductLogsSheet(context, product),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Logs & History', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (canManageStock) ...[
                  const SizedBox(width: 8),
                  // Adjust Stock Button
                  ElevatedButton.icon(
                    onPressed: () => _showAdjustStockDialog(context, product),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Adjust Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (product.currentStock > 0) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showTransferStockDialog(context, product),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= MODAL: STOCK LOGS SHEET =================
  void _showProductLogsSheet(BuildContext context, StoreProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stock Movement & Delivery Logs (Current: ${product.currentStock})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // FutureBuilder for Logs
              Expanded(
                child: FutureBuilder<List<ProductStockLogModel>>(
                  future: context.read<StoreRepository>().fetchStockLogs(product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: PmsTheme.primary),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Error loading logs: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'No Stock Movements Yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Deliveries and manual adjustments will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final isPositive = log.quantityChange >= 0;
                        final formattedDate = log.createdAt != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt!)
                            : 'Unknown Date';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Action Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getActionColor(log.action).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      log.actionLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getActionColor(log.action),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Quantity Change Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${isPositive ? "+" : ""}${log.quantityChange}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Balance Transition
                              Row(
                                children: [
                                  Text(
                                    'Prev: ${log.previousStock}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const Icon(Icons.arrow_right_alt_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  Text(
                                    'New: ${log.currentStock}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),

                              if (log.userName != null || (log.remarks != null && log.remarks!.isNotEmpty)) ...[
                                const SizedBox(height: 6),
                                if (log.userName != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'By: ${log.userName} (${log.userRole ?? ""})',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                if (log.remarks != null && log.remarks!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    log.remarks!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'delivery_received':
        return const Color(0xFF16A34A);
      case 'manual_addition':
        return const Color(0xFF2563EB);
      case 'manual_deduction':
        return const Color(0xFFD97706);
      case 'damaged':
        return const Color(0xFFDC2626);
      case 'audit_correction':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF475569);
    }
  }

  // ================= MODAL: ADJUST STOCK DIALOG =================
  void _showAdjustStockDialog(BuildContext context, StoreProductModel product) {
    String adjustmentType = 'manual_addition';
    final qtyController = TextEditingController(text: '1');
    final remarksController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final qty = int.tryParse(qtyController.text) ?? 0;
            int projectedStock = product.currentStock;
            if (adjustmentType == 'manual_addition') {
              projectedStock += qty;
            } else if (adjustmentType == 'manual_deduction' || adjustmentType == 'damaged') {
              projectedStock = (product.currentStock - qty).clamp(0, 9999999);
            } else if (adjustmentType == 'audit_correction') {
              projectedStock = qty;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adjust Product Stock',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Stock pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Balance:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              Text(
                                '${product.currentStock} Units',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Adjustment Type
                        const Text(
                          'Adjustment Action',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: adjustmentType,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'manual_addition', child: Text('Manual Addition (+)')),
                            DropdownMenuItem(value: 'manual_deduction', child: Text('Manual Deduction (-)')),
                            DropdownMenuItem(value: 'damaged', child: Text('Damaged / Lost Item (-)')),
                            DropdownMenuItem(value: 'audit_correction', child: Text('Audit Correction (= New Total)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                adjustmentType = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Quantity Input & Stepper
                        const Text(
                          'Quantity',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num <= 0) {
                                    return 'Enter valid quantity > 0';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickStepButton('+5', 5, qtyController, setModalState),
                            const SizedBox(width: 4),
                            _buildQuickStepButton('+10', 10, qtyController, setModalState),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Remarks Input
                        const Text(
                          'Reason / Remarks *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: remarksController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'e.g. Physical inventory audit, damaged in store...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Remarks are mandatory';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Projected Balance Preview
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Resulting Stock:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                              ),
                              Text(
                                '$projectedStock Units',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final inputQty = int.parse(qtyController.text.trim());
                      final inputRemarks = remarksController.text.trim();

                      Navigator.pop(dialogContext);

                      context.read<StoreBloc>().add(AdjustStockEvent(
                            productId: product.id,
                            adjustmentType: adjustmentType,
                            quantity: inputQty,
                            remarks: inputRemarks,
                          ));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updating stock for ${product.name}...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PmsTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Adjustment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStepButton(
    String label,
    int increment,
    TextEditingController controller,
    void Function(void Function()) setModalState,
  ) {
    return InkWell(
      onTap: () {
        final current = int.tryParse(controller.text) ?? 0;
        controller.text = (current + increment).toString();
        setModalState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  void _showTransferStockDialog(BuildContext context, StoreProductModel product) async {
    final qtyController = TextEditingController(text: '1');
    final remarksController = TextEditingController();
    int? selectedUserId;
    List<SubStoreInchargeModel> incharges = [];
    bool isLoadingIncharges = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingIncharges && incharges.isEmpty) {
              SubStoreRepository().fetchIncharges().then((data) {
                if (dialogCtx.mounted) {
                  setModalState(() {
                    incharges = data;
                    isLoadingIncharges = false;
                    if (data.isNotEmpty) {
                      selectedUserId = data.first.id;
                    }
                  });
                }
              }).catchError((e) {
                if (dialogCtx.mounted) {
                  setModalState(() {
                    isLoadingIncharges = false;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Transfer to Sub-Store',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available in Main Store: ${product.currentStock} Units',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Select Sub-Store Incharge *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (isLoadingIncharges)
                      const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (incharges.isEmpty)
                      const Text('No Sub-Store Incharges found.', style: TextStyle(color: Colors.red, fontSize: 12))
                    else
                      DropdownButtonFormField<int>(
                        value: selectedUserId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: incharges.map((u) {
                          return DropdownMenuItem<int>(
                            value: u.id,
                            child: Text(
                              '${u.name} (${u.phone ?? ''})',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => selectedUserId = val);
                        },
                      ),
                    const SizedBox(height: 14),
                    const Text('Transfer Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickStepButton('+5', 5, qtyController, setModalState),
                        const SizedBox(width: 4),
                        _buildQuickStepButton('+10', 10, qtyController, setModalState),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Remarks (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly replenishment...',
                        hintStyle: const TextStyle(fontSize: 12, color: PmsTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (isSubmitting || selectedUserId == null)
                      ? null
                      : () async {
                          final qty = int.tryParse(qtyController.text) ?? 0;
                          if (qty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid quantity > 0')),
                            );
                            return;
                          }
                          if (qty > product.currentStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Quantity exceeds available stock (${product.currentStock})')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);

                          try {
                            await SubStoreRepository().transferStock(
                              toUserId: selectedUserId!,
                              productTypeId: product.id,
                              quantity: qty,
                              remarks: remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
                            );
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            _loadInventory();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stock transferred to Sub-Store successfully!'),
                                  backgroundColor: Color(0xFF059669),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to transfer: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Transfer Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
