import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/sub_store/sub_store_bloc.dart';
import '../../bloc/sub_store/sub_store_event.dart';
import '../../bloc/sub_store/sub_store_state.dart';
import '../../models/sub_store_model.dart';
import '../../models/user_model.dart';
import '../../repositories/sub_store_repository.dart';
import '../../theme/pms_theme.dart';

class SubStoreInventoryTabView extends StatefulWidget {
  final UserModel? userProfile;

  const SubStoreInventoryTabView({
    super.key,
    this.userProfile,
  });

  @override
  State<SubStoreInventoryTabView> createState() => _SubStoreInventoryTabViewState();
}

class _SubStoreInventoryTabViewState extends State<SubStoreInventoryTabView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _consumptionSearchController = TextEditingController();
  String _selectedStockStatus = 'all';
  String _searchQuery = '';
  String _consumptionSearchQuery = '';
  int _selectedTabIndex = 0; // 0: Stock Balance, 1: Consumption Logs
  int? _selectedSubStoreId;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    context.read<SubStoreBloc>().add(FetchSubStoreInventoryEvent(
          stockStatus: _selectedStockStatus,
          search: _searchQuery,
          subStoreId: _selectedSubStoreId,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _consumptionSearchController.dispose();
    super.dispose();
  }

  void _applyFilter({String? stockStatus, String? search}) {
    setState(() {
      if (stockStatus != null) _selectedStockStatus = stockStatus;
      if (search != null) _searchQuery = search;
    });

    context.read<SubStoreBloc>().add(FetchSubStoreInventoryEvent(
          stockStatus: _selectedStockStatus,
          search: _searchQuery,
          subStoreId: _selectedSubStoreId,
        ));
  }

  List<SubStoreConsumptionModel> _getFilteredConsumptions(List<SubStoreConsumptionModel> all) {
    if (_consumptionSearchQuery.isEmpty) return all;
    final q = _consumptionSearchQuery;
    return all.where((c) {
      final pName = c.productType?.name.toLowerCase() ?? '';
      final pCode = c.productType?.productCode?.toLowerCase() ?? '';
      final uName = c.user?.name.toLowerCase() ?? '';
      final sName = c.subStore?.name.toLowerCase() ?? '';
      final cNum = c.consumptionNumber?.toLowerCase() ?? '';
      final purpose = c.purpose?.toLowerCase() ?? '';
      final dept = c.departmentOrWing?.toLowerCase() ?? '';
      final remarks = c.remarks?.toLowerCase() ?? '';

      return pName.contains(q) ||
          pCode.contains(q) ||
          uName.contains(q) ||
          sName.contains(q) ||
          cNum.contains(q) ||
          purpose.contains(q) ||
          dept.contains(q) ||
          remarks.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubStoreBloc, SubStoreState>(
      listener: (context, state) {
        if (state is SubStoreActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is SubStoreError) {
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
        if (state is SubStoreLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          );
        }

        SubStoreStatsModel stats = const SubStoreStatsModel();
        List<SubStoreStockModel> items = [];
        List<SubStoreConsumptionModel> consumptions = [];
        List<SubStoreEntityModel> subStores = [];

        if (state is SubStoreLoaded) {
          stats = state.stats;
          items = state.items;
          consumptions = state.consumptions;
          subStores = state.subStores;
        }

        final filteredConsumptions = _getFilteredConsumptions(consumptions);

        return RefreshIndicator(
          color: const Color(0xFF0D9488),
          onRefresh: () async {
            context.read<SubStoreBloc>().add(RefreshSubStoreInventoryEvent(
                  stockStatus: _selectedStockStatus,
                  search: _searchQuery,
                  subStoreId: _selectedSubStoreId,
                ));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(subStores: subStores),
                      const SizedBox(height: 12),
                      _buildStatsGrid(stats),
                      const SizedBox(height: 14),
                      _buildTabBar(items.length, consumptions.length),
                      const SizedBox(height: 12),
                      if (_selectedTabIndex == 0)
                        _buildSearchAndFilters(items)
                      else
                        _buildConsumptionSearchAndFilters(consumptions),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_selectedTabIndex == 0) ...[
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return _buildStockCard(item);
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ] else ...[
                if (filteredConsumptions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyConsumptionsState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final c = filteredConsumptions[index];
                          return _buildConsumptionCard(c);
                        },
                        childCount: filteredConsumptions.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(int stockCount, int consumptionsCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: _selectedTabIndex == 0 ? const Color(0xFF0D9488) : PmsTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stock Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                        color: _selectedTabIndex == 0 ? const Color(0xFF0D9488) : PmsTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$stockCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 0 ? const Color(0xFF0D9488) : PmsTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_edu_rounded,
                      size: 16,
                      color: _selectedTabIndex == 1 ? const Color(0xFFD97706) : PmsTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Consumptions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                        color: _selectedTabIndex == 1 ? const Color(0xFFD97706) : PmsTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? const Color(0xFFD97706).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$consumptionsCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1 ? const Color(0xFFD97706) : PmsTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({List<SubStoreEntityModel> subStores = const []}) {
    final isStoreIncharge = widget.userProfile?.isStoreIncharge == true;
    final isSuperAdmin = widget.userProfile?.isSuperAdmin == true;
    final isManager = widget.userProfile?.isManager == true;
    final canFilter = isStoreIncharge || isSuperAdmin || isManager;
    final titleText = canFilter ? 'Sub-Store Inventory & Logs' : 'My Sub-Store Stock';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D9488).withValues(alpha: 0.15),
            const Color(0xFF065F46).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warehouse_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: PmsTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            canFilter ? 'Management' : 'Sub-Store',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canFilter
                          ? 'Track stock balances and live consumption logs across physical sub-stores.'
                          : 'Manage stock received from Main Store & track consumptions.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canFilter && subStores.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedSubStoreId,
                  isExpanded: true,
                  hint: const Text('All Sub-Stores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Sub-Stores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ...subStores.map((s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text('${s.name} (${s.code ?? 'SUB'})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSubStoreId = val);
                    context.read<SubStoreBloc>().add(FetchSubStoreInventoryEvent(
                      stockStatus: _selectedStockStatus,
                      search: _searchQuery,
                      subStoreId: val,
                    ));
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SubStoreStatsModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildStatCard(
              title: 'Total Items',
              value: '${stats.totalProducts}',
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFF2563EB),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Available Stock',
              value: '${stats.totalStock}',
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFF0D9488),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'In Stock Items',
              value: '${stats.inStockProducts}',
              icon: Icons.done_all_rounded,
              accentColor: const Color(0xFF059669),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Total Consumed',
              value: '${stats.totalConsumed}',
              icon: Icons.local_shipping_outlined,
              accentColor: const Color(0xFFD97706),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PmsTheme.textSecondary,
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

  Widget _buildSearchAndFilters(List<SubStoreStockModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => _applyFilter(search: val),
          decoration: InputDecoration(
            hintText: 'Search product name, code...',
            hintStyle: const TextStyle(fontSize: 13, color: PmsTheme.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0D9488)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilter(search: '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Items', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('In Stock', 'in_stock'),
              const SizedBox(width: 8),
              _buildFilterChip('Depleted', 'out_of_stock'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStockStatus == status;
    return InkWell(
      onTap: () => _applyFilter(stockStatus: status),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : PmsTheme.glassBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : PmsTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(SubStoreStockModel item) {
    final p = item.productType;
    final stock = item.currentStock;
    final isInStock = item.isInStock;
    final catName = p?.categoryName ?? 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInStock ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
          width: isInStock ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    p?.productCode ?? 'PG-ITEM',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Text(
                    '📦 $catName',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInStock ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isInStock ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isInStock ? const Color(0xFF059669) : const Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isInStock ? '$stock Available' : 'Depleted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInStock ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p?.name ?? 'Unnamed Product',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PmsTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (p?.subName != null && p!.subName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                p.subName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PmsTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warehouse_rounded, size: 16, color: Color(0xFF0D9488)),
                      const SizedBox(width: 6),
                      Text(
                        'Sub-Store: $stock Units',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.outbox_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        'Consumed: ${item.totalConsumed} Units',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isInStock) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openRecordConsumptionSheet(context, item),
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                      label: const Text('Record Consumption'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _openHistorySheet(context, item),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Sub-Store Stock Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PmsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When the Main Store Incharge transfers stock to your Sub-Store, items will appear here immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: PmsTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConsumptionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                size: 48,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Consumption Logs Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PmsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When Sub-Store Incharges record item consumptions for campus departments, records will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: PmsTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionSearchAndFilters(List<SubStoreConsumptionModel> consumptions) {
    return TextField(
      controller: _consumptionSearchController,
      onChanged: (val) => setState(() => _consumptionSearchQuery = val.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search product, incharge, purpose, wing...',
        hintStyle: const TextStyle(fontSize: 13, color: PmsTheme.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFD97706)),
        suffixIcon: _consumptionSearchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _consumptionSearchController.clear();
                  setState(() => _consumptionSearchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PmsTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PmsTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(SubStoreConsumptionModel c) {
    final p = c.productType;
    final u = c.user;
    final s = c.subStore;
    final dateStr = c.consumedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(c.consumedAt!)
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Consumption # badge & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 13, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        c.consumptionNumber ?? '#CNS-${c.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PmsTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Product Name & Quantity badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p?.name ?? 'Product #${c.productTypeId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PmsTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (p?.productCode != null && p!.productCode!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                p.productCode!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: PmsTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (p.categoryName != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                p.categoryName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 2),
                      Text(
                        '-${c.quantity} Units',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Sub-Store and Recorded By details
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 14, color: Color(0xFF0D9488)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          s?.name ?? 'Sub-Store',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (u?.name != null)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: PmsTheme.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            u!.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: PmsTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Department / Wing & Purpose
            if (c.departmentOrWing != null && c.departmentOrWing!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.apartment_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Dept / Wing: ${c.departmentOrWing}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4338CA),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (c.purpose != null && c.purpose!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_outlined, size: 14, color: PmsTheme.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Purpose: ${c.purpose}${c.remarks != null && c.remarks!.isNotEmpty ? ' (${c.remarks})' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openRecordConsumptionSheet(BuildContext context, SubStoreStockModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordConsumptionModal(
        item: item,
        parentContext: context,
      ),
    );
  }

  void _openHistorySheet(BuildContext context, SubStoreStockModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubStoreHistoryModal(item: item),
    );
  }
}

class _RecordConsumptionModal extends StatefulWidget {
  final SubStoreStockModel item;
  final BuildContext parentContext;

  const _RecordConsumptionModal({
    required this.item,
    required this.parentContext,
  });

  @override
  State<_RecordConsumptionModal> createState() => _RecordConsumptionModalState();
}

class _RecordConsumptionModalState extends State<_RecordConsumptionModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  int get _maxStock => widget.item.currentStock;

  @override
  void dispose() {
    _qtyController.dispose();
    _purposeController.dispose();
    _deptController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _stepQty(int delta) {
    int current = int.tryParse(_qtyController.text) ?? 1;
    int next = (current + delta).clamp(1, _maxStock);
    _qtyController.text = next.toString();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0 || qty > _maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity must be between 1 and $_maxStock')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    widget.parentContext.read<SubStoreBloc>().add(
          RecordSubStoreConsumptionEvent(
            productTypeId: widget.item.productTypeId,
            quantity: qty,
            purpose: _purposeController.text.trim(),
            department: _deptController.text.trim().isEmpty ? null : _deptController.text.trim(),
            remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.productType;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.outbox_rounded, color: Color(0xFF0F766E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Record Stock Consumption',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        Text(
                          p?.name ?? 'Product',
                          style: const TextStyle(fontSize: 12, color: PmsTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available in Sub-Store:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                    Text(
                      '$_maxStock Units',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Consumption Quantity *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PmsTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _stepQty(-1),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: const Color(0xFF0D9488),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        final v = int.tryParse(val ?? '');
                        if (v == null || v <= 0) return 'Invalid';
                        if (v > _maxStock) return 'Max $_maxStock';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _stepQty(1),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: const Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickQtyBtn('+5', 5),
                  const SizedBox(width: 4),
                  _buildQuickQtyBtn('+10', 10),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Purpose of Consumption *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PmsTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  hintText: 'e.g. Annual Day Banner, Reception Handout...',
                  hintStyle: const TextStyle(fontSize: 12, color: PmsTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Purpose is mandatory';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Department / Recipient (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PmsTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deptController,
                decoration: InputDecoration(
                  hintText: 'e.g. Senior Wing, Lab 2, Front Desk...',
                  hintStyle: const TextStyle(fontSize: 12, color: PmsTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Remarks (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PmsTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any additional notes...',
                  hintStyle: const TextStyle(fontSize: 12, color: PmsTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Confirm Consumption',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQtyBtn(String label, int delta) {
    return InkWell(
      onTap: () => _stepQty(delta),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ),
    );
  }
}

class _SubStoreHistoryModal extends StatefulWidget {
  final SubStoreStockModel item;

  const _SubStoreHistoryModal({required this.item});

  @override
  State<_SubStoreHistoryModal> createState() => _SubStoreHistoryModalState();
}

class _SubStoreHistoryModalState extends State<_SubStoreHistoryModal> {
  late Future<List<SubStoreStockLogModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = SubStoreRepository().fetchLogs(widget.item.productTypeId);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.productType;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub-Store Stock History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${p?.name ?? 'Product'} (${p?.productCode ?? 'PG'})',
                    style: const TextStyle(fontSize: 12, color: PmsTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: FutureBuilder<List<SubStoreStockLogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load history: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No history recorded for this item yet.',
                      style: TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final l = logs[index];
                    final isPos = l.isPositive;
                    final dateStr = l.createdAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!)
                        : '--';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPos ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPos ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPos ? const Color(0xFF059669) : const Color(0xFFE11D48),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.actionLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: PmsTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isPos ? '+${l.quantityChange}' : '${l.quantityChange}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isPos ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Balance: ${l.currentStock} Units | $dateStr',
                                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
                              ),
                              if (l.remarks != null && l.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  l.remarks!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
