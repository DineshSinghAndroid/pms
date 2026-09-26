import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';

class DigitalStudioDutyAllotmentsSubTab extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isManager;
  final bool isDigitalStudioIncharge;
  final bool isDigitalStoreIncharge;

  const DigitalStudioDutyAllotmentsSubTab({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    required this.isManager,
    required this.isDigitalStudioIncharge,
    this.isDigitalStoreIncharge = false,
  });

  @override
  State<DigitalStudioDutyAllotmentsSubTab> createState() =>
      _DigitalStudioDutyAllotmentsSubTabState();
}

class _DigitalStudioDutyAllotmentsSubTabState
    extends State<DigitalStudioDutyAllotmentsSubTab> {
  String _selectedStatus = 'all';
  String _dateFilter = 'all'; // 'all', 'today', 'tomorrow', 'upcoming', 'custom'
  DateTime? _customDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'all',
    'allotted',
    'in_progress',
    'completed',
    'pending',
    'cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'allotted':
        return const Color(0xFF2563EB); // Blue
      case 'in_progress':
        return const Color(0xFFD97706); // Amber
      case 'completed':
        return const Color(0xFF059669); // Emerald
      case 'cancelled':
        return const Color(0xFFDC2626); // Red
      case 'pending':
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'camera':
        return const Color(0xFF2563EB);
      case 'lens':
        return const Color(0xFF7C3AED);
      case 'audio/mic':
      case 'audio':
      case 'mic':
        return const Color(0xFF059669);
      case 'drone':
        return const Color(0xFFEA580C);
      case 'lighting':
        return const Color(0xFFD97706);
      case 'tripod/gimbal':
      case 'tripod':
      case 'gimbal':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF6366F1);
    }
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shootDay = DateTime(date.year, date.month, date.day);

    switch (_dateFilter) {
      case 'today':
        return shootDay.isAtSameMomentAs(today);
      case 'tomorrow':
        return shootDay.isAtSameMomentAs(today.add(const Duration(days: 1)));
      case 'upcoming':
        return shootDay.isAfter(today.subtract(const Duration(seconds: 1)));
      case 'custom':
        if (_customDate == null) return true;
        final cDay = DateTime(_customDate!.year, _customDate!.month, _customDate!.day);
        return shootDay.isAtSameMomentAs(cDay);
      case 'all':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DigitalStudioBloc, DigitalStudioState>(
      builder: (context, state) {
        if (state is DigitalStudioLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }

        if (state is DigitalStudioError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                backgroundColor: const Color(0xFFFEF2F2),
                border: Border.all(color: PmsTheme.error.withValues(alpha: 0.35)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: PmsTheme.error, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      state.errorMessage,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<DigitalStudioBloc>().add(
                          RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is DigitalStudioLoaded) {
          final allRequests = state.crewRequests;

          final filteredList = allRequests.where((req) {
            // Status filter
            if (_selectedStatus != 'all' &&
                req.status.toLowerCase() != _selectedStatus.toLowerCase()) {
              return false;
            }

            // Date filter
            if (!_matchesDateFilter(req.reportingDateTime)) {
              return false;
            }

            // Search query filter (matches event name, wing name, employee names, asset names or codes)
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery;
              final matchEvent = req.eventName.toLowerCase().contains(q);
              final matchReqNum = req.requestNumber.toLowerCase().contains(q);
              final matchWing = (req.wing?.name ?? '').toLowerCase().contains(q);
              final matchEmployee = req.allottedEmployees.any((e) =>
                  e.name.toLowerCase().contains(q) ||
                  e.phone.toLowerCase().contains(q) ||
                  e.role.toLowerCase().contains(q));
              final matchAsset = req.allottedAssets.any((a) =>
                  a.name.toLowerCase().contains(q) ||
                  a.assetCode.toLowerCase().contains(q) ||
                  a.category.toLowerCase().contains(q));

              if (!matchEvent && !matchReqNum && !matchWing && !matchEmployee && !matchAsset) {
                return false;
              }
            }

            return true;
          }).toList();

          // Sort by reporting date descending / nearest upcoming first
          filteredList.sort((a, b) {
            return b.reportingDateTime.compareTo(a.reportingDateTime);
          });

          return RefreshIndicator(
            color: PmsTheme.primary,
            onRefresh: () async {
              context.read<DigitalStudioBloc>().add(
                RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
              );
              await context.read<DigitalStudioBloc>().stream.firstWhere(
                (s) => s is DigitalStudioLoaded || s is DigitalStudioError,
              );
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Info Banner for Digital Store Incharge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D9488).withValues(alpha: 0.12),
                        const Color(0xFF0284C7).withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duty & Instruments Allotment Schedule',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF134E4A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track on which date & time which employee is on duty at where along with allotted instruments.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal.shade900.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                  style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by employee, instrument, wing or event...',
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
                    filled: true,
                    fillColor: PmsTheme.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PmsTheme.glassBorder),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Quick Date Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip('All Dates', 'all'),
                      const SizedBox(width: 6),
                      _buildDateChip('Today', 'today'),
                      const SizedBox(width: 6),
                      _buildDateChip('Tomorrow', 'tomorrow'),
                      const SizedBox(width: 6),
                      _buildDateChip('Upcoming', 'upcoming'),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _dateFilter == 'custom' ? Colors.white : PmsTheme.textSecondary,
                        ),
                        label: Text(
                          _dateFilter == 'custom' && _customDate != null
                              ? DateFormat('d MMM yyyy').format(_customDate!)
                              : 'Select Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _dateFilter == 'custom' ? Colors.white : PmsTheme.textPrimary,
                          ),
                        ),
                        backgroundColor: _dateFilter == 'custom'
                            ? const Color(0xFF0D9488)
                            : PmsTheme.glassSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _dateFilter == 'custom'
                                ? const Color(0xFF0D9488)
                                : PmsTheme.glassBorder,
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _customDate ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateFilter = 'custom';
                              _customDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      final label = status == 'all'
                          ? 'All Statuses'
                          : status.replaceAll('_', ' ').toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: PmsFilterChip(
                          label: label,
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedStatus = status);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // Result Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Allotted Duties (${filteredList.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedStatus != 'all' || _dateFilter != 'all')
                      InkWell(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedStatus = 'all';
                            _dateFilter = 'all';
                            _customDate = null;
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // List of Duty Cards
                if (filteredList.isEmpty)
                  PmsEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No duty allotments found',
                    subtitle: 'Try changing your search terms or date/status filters.',
                  )
                else
                  ...filteredList.map((req) => _buildDutyAllotmentCard(context, req)),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = _dateFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : PmsTheme.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0D9488),
      backgroundColor: PmsTheme.glassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D9488) : PmsTheme.glassBorder,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _dateFilter = value;
            if (value != 'custom') _customDate = null;
          });
        }
      },
    );
  }

  Widget _buildDutyAllotmentCard(
    BuildContext context,
    DigitalStudioCrewRequestModel req,
  ) {
    final statusColor = _getStatusColor(req.status);
    final dateFormatted = DateFormat('EEE, d MMM yyyy').format(req.reportingDateTime);
    final startTimeFormatted = DateFormat('hh:mm a').format(req.reportingDateTime);
    final endTimeFormatted = DateFormat('hh:mm a').format(req.eventEndTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Date & Time & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Color(0xFF1E293B),
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '$startTimeFormatted - $endTimeFormatted',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PmsStatusChip(
                  label: req.status.replaceAll('_', ' ').toUpperCase(),
                  color: statusColor,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title & Request Code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.eventName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PmsTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            req.requestNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Location / Wing Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFEA580C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req.wing?.name ?? 'General Wing',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (req.remarks != null && req.remarks!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${req.remarks}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: PmsTheme.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ================= SECTION 1: ALLOTTED EMPLOYEES =================
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Allotted Employees (${req.allottedEmployees.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (req.allottedEmployees.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'No crew members allotted yet for this shoot.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: req.allottedEmployees.map((emp) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      emp.role,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                    if (emp.phone.isNotEmpty) ...[
                                      const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                      Text(
                                        emp.phone,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 14),

                // ================= SECTION 2: ALLOTTED INSTRUMENTS / EQUIPMENT =================
                Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF0D9488),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Allotted Instruments & Equipment (${req.allottedAssets.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (req.allottedAssets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.devices_other_rounded, color: Color(0xFF94A3B8), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'No instruments assigned to this duty.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: req.allottedAssets.map((asset) {
                      final catColor = _getCategoryColor(asset.category);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                asset.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      asset.assetCode,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                    if (asset.modelSerial != null && asset.modelSerial!.isNotEmpty) ...[
                                      const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                      Text(
                                        'S/N: ${asset.modelSerial}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
