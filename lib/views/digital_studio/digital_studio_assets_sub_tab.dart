import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../models/digital_studio_asset_model.dart';
import '../../models/user_model.dart';
import '../../theme/pms_theme.dart';

class DigitalStudioAssetsSubTab extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isManager;
  final bool isDigitalStudioIncharge;

  const DigitalStudioAssetsSubTab({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    required this.isManager,
    required this.isDigitalStudioIncharge,
  });

  @override
  State<DigitalStudioAssetsSubTab> createState() =>
      _DigitalStudioAssetsSubTabState();
}

class _DigitalStudioAssetsSubTabState extends State<DigitalStudioAssetsSubTab> {
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool get canCreateAsset => widget.isSuperAdmin || widget.isManager;
  bool get canManage =>
      widget.isSuperAdmin || widget.isManager || widget.isDigitalStudioIncharge;
  bool get _isDigitalStudioEmployee =>
      widget.currentUser?.isDigitalStudioEmployee ?? false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DigitalStudioBloc, DigitalStudioState>(
      listener: (context, state) {
        if (state is DigitalStudioLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is DigitalStudioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DigitalStudioLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DigitalStudioLoaded) {
          var filteredAssets = state.assets.where((asset) {
            final matchesCategory =
                _selectedCategory == 'all' ||
                asset.category.toLowerCase() == _selectedCategory.toLowerCase();
            final matchesStatus =
                _selectedStatus == 'all' ||
                asset.currentStatus.toLowerCase() ==
                    _selectedStatus.toLowerCase();
            final matchesSearch =
                _searchQuery.isEmpty ||
                asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                asset.assetCode.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (asset.modelSerial?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
            return matchesCategory && matchesStatus && matchesSearch;
          }).toList();

          final total = state.assets.length;
          final available =
              state.assets.where((a) => a.isAvailable).length;
          final assigned = state.assets.where((a) => a.isAssigned).length;
          final maintenance =
              state.assets.where((a) => a.isMaintenance || a.isDamaged).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stats Overview Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: _isDigitalStudioEmployee
                      ? [
                          _buildSummaryCard(
                            label: 'My Assigned Gear',
                            count: total,
                            color: const Color(0xFF8B5CF6),
                            icon: Icons.devices_other_outlined,
                          ),
                        ]
                      : [
                          _buildSummaryCard(
                            label: 'Total Assets',
                            count: total,
                            color: const Color(0xFF3B82F6),
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            label: 'Available',
                            count: available,
                            color: PmsTheme.success,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            label: 'Assigned',
                            count: assigned,
                            color: const Color(0xFF8B5CF6),
                            icon: Icons.assignment_ind_outlined,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            label: 'Maintenance',
                            count: maintenance,
                            color: PmsTheme.warning,
                            icon: Icons.build_circle_outlined,
                          ),
                        ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _isDigitalStudioEmployee
                              ? 'Search assigned gear name, code, model...'
                              : 'Search asset name, code, model...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: PmsTheme.bgSoft,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                    if (canCreateAsset) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _openAddAssetDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Asset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PmsTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Category & Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('All Categories', 'all', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Cameras', 'Camera', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Drones', 'Drone', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Lenses', 'Lens', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Gimbals', 'Gimbal', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Audio', 'Audio', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Lighting', 'Lighting', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Tripods', 'Tripod', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    _buildFilterChip('Laptops', 'Laptop', _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
                    const VerticalDivider(width: 16),
                    _buildStatusChip('All Statuses', 'all', _selectedStatus,
                        (val) => setState(() => _selectedStatus = val)),
                    _buildStatusChip(
                        'Available', 'available', _selectedStatus,
                        (val) => setState(() => _selectedStatus = val)),
                    _buildStatusChip('Assigned', 'assigned', _selectedStatus,
                        (val) => setState(() => _selectedStatus = val)),
                    _buildStatusChip(
                        'Maintenance', 'maintenance', _selectedStatus,
                        (val) => setState(() => _selectedStatus = val)),
                  ],
                ),
              ),

              // 4. Asset List
              Expanded(
                child: RefreshIndicator(
                  color: PmsTheme.primary,
                  onRefresh: () async {
                    context.read<DigitalStudioBloc>().add(
                          RefreshDigitalStudioEvent(
                            phone: widget.currentUser?.phone,
                          ),
                        );
                    await context.read<DigitalStudioBloc>().stream.firstWhere(
                          (s) => s is DigitalStudioLoaded || s is DigitalStudioError,
                        );
                  },
                  child: filteredAssets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No assets found matching filters',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filteredAssets.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final asset = filteredAssets[index];
                            return _buildAssetCard(context, asset);
                          },
                        ),
                ),
              ),
            ],
          );
        }

        if (state is DigitalStudioError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DigitalStudioBloc>()
                        .add(RefreshDigitalStudioEvent(phone: widget.currentUser?.phone)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: PmsTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        selectedColor: PmsTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : PmsTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        backgroundColor: PmsTheme.bgSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        selectedColor: PmsTheme.textPrimary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : PmsTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        backgroundColor: PmsTheme.bgSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    DigitalStudioAssetModel asset,
  ) {
    Color statusBg = const Color(0xFFD1FAE5);
    Color statusColor = const Color(0xFF065F46);
    String statusLabel = 'Available';

    if (asset.isAssigned) {
      statusBg = const Color(0xFFEDE9FE);
      statusColor = const Color(0xFF5B21B6);
      statusLabel = 'Assigned';
    } else if (asset.isMaintenance) {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFF92400E);
      statusLabel = 'Maintenance';
    } else if (asset.isDamaged) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFF991B1B);
      statusLabel = 'Damaged';
    }

    return Container(
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code, Category & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PmsTheme.bgSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        asset.assetCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Text(
                      asset.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Asset Name & Model
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: PmsTheme.textPrimary,
            ),
          ),
          if (asset.modelSerial != null && asset.modelSerial!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Model/Serial: ${asset.modelSerial}',
              style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
            ),
          ],

          // Current Assignee
          if (asset.isAssigned && asset.currentAssignedUser != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: PmsTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isDigitalStudioEmployee
                          ? '👤 Allotted to You for your shoots'
                          : 'Allotted to: ${asset.currentAssignedUser!.name} (${asset.currentAssignedUser!.phone})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions Row
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              // View Lifecycle Logs
              TextButton.icon(
                onPressed: () => _showAssetLogsSheet(context, asset),
                icon: const Icon(Icons.history, size: 15),
                label: const Text('Logs & History', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: PmsTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),

              if (canManage) ...[
                // Set Available if Maintenance
                if (asset.isMaintenance || asset.isDamaged)
                  ElevatedButton(
                    onPressed: () => _setAssetStatus(context, asset, 'available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Mark Available'),
                  ),

                // More Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) {
                    if (val == 'maintenance') {
                      _setAssetStatus(context, asset, 'maintenance');
                    } else if (val == 'damaged') {
                      _setAssetStatus(context, asset, 'damaged');
                    } else if (val == 'available') {
                      _setAssetStatus(context, asset, 'available');
                    }
                  },
                  itemBuilder: (context) => [
                    if (!asset.isMaintenance)
                      const PopupMenuItem(
                        value: 'maintenance',
                        child: Text('Mark In Maintenance'),
                      ),
                    if (!asset.isDamaged)
                      const PopupMenuItem(
                        value: 'damaged',
                        child: Text('Mark Damaged'),
                      ),
                    if (!asset.isAvailable)
                      const PopupMenuItem(
                        value: 'available',
                        child: Text('Mark Available'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS & BOTTOM SHEETS
  // ==========================================

  void _openAddAssetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final modelController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'Camera';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Studio Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Name *',
                      hintText: 'e.g. Sony FX3 Camera',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category *', isDense: true),
                    items: DigitalStudioAssetModel.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v ?? 'Camera'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Code (Optional)',
                      hintText: 'Leave blank to auto-generate',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model / Serial Number',
                      hintText: 'e.g. SN-998822',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Specifications',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogCtx);
                context.read<DigitalStudioBloc>().add(
                      CreateAssetEvent(
                        payload: {
                          'name': nameController.text.trim(),
                          'category': category,
                          if (codeController.text.trim().isNotEmpty)
                            'asset_code': codeController.text.trim(),
                          if (modelController.text.trim().isNotEmpty)
                            'model_serial': modelController.text.trim(),
                          if (notesController.text.trim().isNotEmpty)
                            'notes': notesController.text.trim(),
                        },
                        phone: widget.currentUser?.phone,
                      ),
                    );
              },
              child: const Text('Save Asset'),
            ),
          ],
        ),
      ),
    );
  }



  void _setAssetStatus(
    BuildContext context,
    DigitalStudioAssetModel asset,
    String status,
  ) {
    context.read<DigitalStudioBloc>().add(
          UpdateAssetStatusEvent(
            assetId: asset.id,
            status: status,
            phone: widget.currentUser?.phone,
          ),
        );
  }

  void _showAssetLogsSheet(
    BuildContext context,
    DigitalStudioAssetModel asset,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: PmsTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${asset.name} (${asset.assetCode})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Complete Lifecycle & Audit Logs',
                          style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: asset.logs.isEmpty
                  ? Center(
                      child: Text(
                        'No logs recorded yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: asset.logs.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (context, idx) {
                        final log = asset.logs[idx];
                        Color dotColor = const Color(0xFF3B82F6);
                        if (log.action == 'assigned') {
                          dotColor = const Color(0xFF8B5CF6);
                        } else if (log.action == 'returned') {
                          dotColor = PmsTheme.success;
                        } else if (log.action == 'reassigned') {
                          dotColor = const Color(0xFF06B6D4);
                        } else if (log.action == 'maintenance' || log.action == 'damaged') {
                          dotColor = PmsTheme.error;
                        }

                        final dateStr = log.createdAt != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt!)
                            : 'N/A';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (idx < asset.logs.length - 1)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log.action.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: dotColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: PmsTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.remarks ?? 'Action performed',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
