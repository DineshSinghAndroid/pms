import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';
import '../../models/digital_studio_asset_model.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';
import '../../models/wing_model.dart';
import '../../theme/pms_theme.dart';

class DigitalStudioCrewRequestsSubTab extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isManager;
  final bool isDigitalStudioIncharge;
  final bool isWingIncharge;

  const DigitalStudioCrewRequestsSubTab({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    required this.isManager,
    required this.isDigitalStudioIncharge,
    required this.isWingIncharge,
  });

  @override
  State<DigitalStudioCrewRequestsSubTab> createState() =>
      _DigitalStudioCrewRequestsSubTabState();
}

class _DigitalStudioCrewRequestsSubTabState
    extends State<DigitalStudioCrewRequestsSubTab> {
  String _selectedStatus = 'all';

  bool get canAllot {
    final r = (widget.currentUser?.role ?? '').toLowerCase().trim();
    return widget.isSuperAdmin ||
        widget.currentUser?.isSuperAdmin == true ||
        widget.isManager ||
        widget.isDigitalStudioIncharge ||
        r == 'superadmin' ||
        r == 'super admin' ||
        r == 'super_admin' ||
        r == 'admin' ||
        r == 'manager' ||
        r == 'digital studio incharge' ||
        r == 'digital_studio_incharge';
  }

  bool get canRequest =>
      widget.isSuperAdmin || widget.isManager || widget.isWingIncharge;

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
          var filteredRequests = state.crewRequests.where((req) {
            if (_selectedStatus == 'all') return true;
            return req.status.toLowerCase() == _selectedStatus.toLowerCase();
          }).toList();

          filteredRequests.sort((a, b) {
            final dtA = a.createdAt ?? a.reportingDateTime;
            final dtB = b.createdAt ?? b.reportingDateTime;
            final cmp = dtB.compareTo(dtA);
            if (cmp != 0) return cmp;
            return b.id.compareTo(a.id);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Crew Requests Queue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canRequest)
                      ElevatedButton.icon(
                        onPressed: () => _openCreateRequestDialog(context),
                        icon: const Icon(Icons.add_task, size: 17),
                        label: const Text('New Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PmsTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterTab('All', 'all', state.crewRequests.length),
                    _buildFilterTab(
                      'Pending',
                      'pending',
                      state.crewRequests.where((r) => r.isPending).length,
                      badgeColor: PmsTheme.warning,
                    ),
                    _buildFilterTab(
                      'Allotted',
                      'allotted',
                      state.crewRequests.where((r) => r.isAllotted).length,
                      badgeColor: const Color(0xFF8B5CF6),
                    ),
                    _buildFilterTab(
                      'In Progress',
                      'in_progress',
                      state.crewRequests.where((r) => r.isInProgress).length,
                      badgeColor: const Color(0xFF3B82F6),
                    ),
                    _buildFilterTab(
                      'Completed',
                      'completed',
                      state.crewRequests.where((r) => r.isCompleted).length,
                      badgeColor: PmsTheme.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Request List
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
                  child: filteredRequests.isEmpty
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
                                      Icons.checklist_rtl_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No crew requests found',
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
                            vertical: 6,
                          ),
                          itemCount: filteredRequests.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = filteredRequests[index];
                            return _buildRequestCard(
                              context,
                              req,
                              state.crewMembers,
                              state.availableAssets,
                              allRequests: state.crewRequests,
                            );
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => context.read<DigitalStudioBloc>().add(
                          RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
                        ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
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

  Widget _buildFilterTab(String label, String value, int count, {Color? badgeColor}) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? PmsTheme.textPrimary : PmsTheme.bgSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : PmsTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (badgeColor ?? Colors.grey.shade300).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (badgeColor ?? PmsTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    DigitalStudioCrewRequestModel req,
    List<UserModel> crewMembers,
    List<DigitalStudioAssetModel> availableAssets, {
    required List<DigitalStudioCrewRequestModel> allRequests,
  }) {
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFF92400E);

    if (req.isAllotted) {
      statusBg = const Color(0xFFEDE9FE);
      statusColor = const Color(0xFF5B21B6);
    } else if (req.isInProgress) {
      statusBg = const Color(0xFFDBEAFE);
      statusColor = PmsTheme.primaryDark;
    } else if (req.isCompleted) {
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF065F46);
    } else if (req.isCancelled) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFF991B1B);
    }

    final startStr = DateFormat('dd MMM yyyy, hh:mm a').format(req.reportingDateTime);
    final endStr = DateFormat('hh:mm a').format(req.eventEndTime);

    return Container(
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Request Code, Wing & Status
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PmsTheme.backgroundGradientStart,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        req.wing?.name ?? 'Campus Wing',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      req.requestNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
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
                  req.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Event Title
          Text(
            req.eventName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: PmsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Requested By: ${req.requestedBy?.name ?? 'Wing Staff'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PmsTheme.textSecondary,
                  ),
                ),
              ),
              if (req.createdAt != null)
                Text(
                  'Req: ${DateFormat('dd MMM, hh:mm a').format(req.createdAt!)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Date & Time
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: PmsTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '$startStr - $endStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PmsTheme.backgroundGradientStart,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${req.requiredCrewCount} Crew Required',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: PmsTheme.primary,
                  ),
                ),
              ),
            ],
          ),

          // Allotted Info
          if (req.allottedEmployees.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.people, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Allotted Crew: ${req.allottedEmployees.map((e) => e.name).join(', ')}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  if (req.allottedAssets.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.camera_alt, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Allotted Assets: ${req.allottedAssets.map((a) => '${a.name} (${a.assetCode})').join(', ')}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (req.remarks != null && req.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remarks: ${req.remarks}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: PmsTheme.textSecondary),
            ),
          ],

          if (req.workStartedAt != null || req.workStartVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Work Started: ${req.workStartedAt != null ? DateFormat('dd MMM, hh:mm a').format(req.workStartedAt!.toLocal()) : ''}'
                      '${req.workStartDistanceMeters != null ? ' (GPS Verified: ${req.workStartDistanceMeters!.toStringAsFixed(0)}m from Wing)' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canAllot && (req.isPending || req.isAllotted)) ...[
                ElevatedButton.icon(
                  onPressed: () => _openAllotDialog(
                    context,
                    req,
                    crewMembers,
                    availableAssets,
                    allRequests,
                  ),
                  icon: Icon(
                    req.isPending
                        ? Icons.person_add_alt_1_rounded
                        : Icons.swap_horiz_rounded,
                    size: 18,
                  ),
                  label: Text(
                    req.isPending ? 'Allot Crew & Equipment' : 'Re-allot Crew & Gear',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: req.isPending
                        ? PmsTheme.secondary
                        : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],

              if (!req.isCompleted && !req.isCancelled && !req.isInProgress) ...[
                ElevatedButton.icon(
                  onPressed: () => _updateRequestStatus(req, 'in_progress'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 1.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],

              if (req.isInProgress) ...[
                ElevatedButton.icon(
                  onPressed: () => _updateRequestStatus(req, 'completed'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PmsTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 1.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],

              if (canAllot && !req.isCompleted && !req.isCancelled)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                  tooltip: 'Cancel Request',
                  onPressed: () => _updateRequestStatus(req, 'cancelled'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS
  // ==========================================

  void _openCreateRequestDialog(BuildContext context) {
    final eventNameController = TextEditingController();
    final crewCountController = TextEditingController(text: '1');
    final remarksController = TextEditingController();

    WingModel? selectedWing;
    DateTime reportingDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay reportingTime = const TimeOfDay(hour: 10, minute: 0);
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay endTime = const TimeOfDay(hour: 14, minute: 0);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Studio Crew Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wing Picker
                BlocBuilder<WingBloc, WingState>(
                  builder: (context, wingState) {
                    var wings = wingState is WingLoaded ? wingState.wings : <WingModel>[];
                    if (widget.isWingIncharge || widget.currentUser?.isWingIncharge == true) {
                      final assignedIds = widget.currentUser?.assignedWings.map((w) => w.id).toSet() ?? {};
                      if (assignedIds.isNotEmpty) {
                        wings = wings.where((w) => assignedIds.contains(w.id)).toList();
                      } else {
                        wings = widget.currentUser?.assignedWings ?? [];
                      }
                    }

                    if (selectedWing == null && wings.isNotEmpty) {
                      selectedWing = wings.first;
                    } else if (selectedWing != null && !wings.any((w) => w.id == selectedWing!.id)) {
                      selectedWing = wings.isNotEmpty ? wings.first : null;
                    }

                    if (wings.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text(
                          'No allotted wings found for your account. Please contact Super Admin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<WingModel>(
                      initialValue: selectedWing,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Select Campus Wing *', isDense: true),
                      items: wings
                          .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                          .toList(),
                      onChanged: (w) => setDialogState(() => selectedWing = w),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Event Name
                TextField(
                  controller: eventNameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name *',
                    hintText: 'e.g. Annual Convocation 2026',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Required Crew Count
                TextField(
                  controller: crewCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Required Crew Count *',
                    hintText: 'e.g. 2',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Reporting Date & Time Pickers
                const Text('Reporting Date & Time *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final firstDate = DateTime(now.year, now.month, now.day);
                          final initialDate = reportingDate.isBefore(firstDate) ? firstDate : reportingDate;
                          final p = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: firstDate,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (p != null) {
                            setDialogState(() {
                              reportingDate = p;
                              if (endDate.isBefore(p)) {
                                endDate = p;
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(DateFormat('dd MMM yyyy').format(reportingDate), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: reportingTime,
                          );
                          if (t != null) setDialogState(() => reportingTime = t);
                        },
                        icon: const Icon(Icons.access_time, size: 14),
                        label: Text(reportingTime.format(context), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Event End Date & Time Pickers
                const Text('Event End Date & Time *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final firstDate = reportingDate;
                          final initialDate = endDate.isBefore(firstDate) ? firstDate : endDate;
                          final p = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: firstDate,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (p != null) setDialogState(() => endDate = p);
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(DateFormat('dd MMM yyyy').format(endDate), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (t != null) setDialogState(() => endTime = t);
                        },
                        icon: const Icon(Icons.access_time, size: 14),
                        label: Text(endTime.format(context), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions / Remarks',
                    hintText: 'e.g. Need 4K stage recording and drone coverage',
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
                if (eventNameController.text.trim().isEmpty || selectedWing == null) {
                  return;
                }

                final startDateTime = DateTime(
                  reportingDate.year,
                  reportingDate.month,
                  reportingDate.day,
                  reportingTime.hour,
                  reportingTime.minute,
                );

                final endDateTime = DateTime(
                  endDate.year,
                  endDate.month,
                  endDate.day,
                  endTime.hour,
                  endTime.minute,
                );

                if (endDateTime.isBefore(startDateTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after reporting time')),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);
                context.read<DigitalStudioBloc>().add(
                      CreateCrewRequestEvent(
                        payload: {
                          'wing_id': selectedWing!.id,
                          'event_name': eventNameController.text.trim(),
                          'required_crew_count': int.tryParse(crewCountController.text) ?? 1,
                          'reporting_date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(startDateTime),
                          'event_end_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(endDateTime),
                          if (remarksController.text.trim().isNotEmpty)
                            'remarks': remarksController.text.trim(),
                        },
                        phone: widget.currentUser?.phone,
                      ),
                    );
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAllotDialog(
    BuildContext context,
    DigitalStudioCrewRequestModel req,
    List<UserModel> crewMembers,
    List<DigitalStudioAssetModel> availableAssets,
    List<DigitalStudioCrewRequestModel> allRequests,
  ) {
    final selectedEmployees = <int>{...req.allottedEmployees.map((e) => e.id)};
    final selectedAssets = <int>{...req.allottedAssets.map((a) => a.id)};
    final remarksController = TextEditingController(text: req.remarks);

    final reqStart = req.reportingDateTime;
    final reqEnd = req.eventEndTime;

    // Find overlapping requests from all requests (status allotted or in_progress)
    final overlappingReqs = allRequests.where((r) {
      if (r.id == req.id) return false;
      if (!r.isAllotted && !r.isInProgress) return false;
      return r.reportingDateTime.isBefore(reqEnd) && r.eventEndTime.isAfter(reqStart);
    }).toList();

    final busyCrewMap = <int, String>{};
    final busyAssetMap = <int, String>{};

    for (final r in overlappingReqs) {
      final wingName = r.wing?.name ?? 'Wing';
      final requesterName = r.requestedBy?.name ?? 'Wing Staff';
      final timeStr = '${DateFormat('hh:mm a').format(r.reportingDateTime)} - ${DateFormat('hh:mm a').format(r.eventEndTime)}';
      final infoStr = 'Allotted to "$wingName" (By: $requesterName) for "${r.eventName}" [$timeStr]';

      for (final emp in r.allottedEmployees) {
        busyCrewMap[emp.id] = infoStr;
      }
      for (final ast in r.allottedAssets) {
        busyAssetMap[ast.id] = infoStr;
      }
    }

    // Merge available assets with assets already allotted to this request
    final allSelectableAssets = <DigitalStudioAssetModel>[
      ...availableAssets,
      ...req.allottedAssets.where((a) => !availableAssets.any((av) => av.id == a.id)),
    ];

    // Separate available vs busy crew members
    final availableCrew = crewMembers
        .where((m) => !busyCrewMap.containsKey(m.id) || selectedEmployees.contains(m.id))
        .toList();
    final busyCrew = crewMembers
        .where((m) => busyCrewMap.containsKey(m.id) && !selectedEmployees.contains(m.id))
        .toList();

    // Separate available vs busy assets
    final availableAssetsList = allSelectableAssets
        .where((a) => !busyAssetMap.containsKey(a.id) || selectedAssets.contains(a.id))
        .toList();
    final busyAssetsList = allSelectableAssets
        .where((a) => busyAssetMap.containsKey(a.id) && !selectedAssets.contains(a.id))
        .toList();

    bool showBusyCrew = false;
    bool showBusyAssets = false;
    String crewQuery = '';
    String assetQuery = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool matchesCrew(UserModel member) {
            if (crewQuery.isEmpty) return true;
            return member.name.toLowerCase().contains(crewQuery) ||
                member.phone.toLowerCase().contains(crewQuery);
          }

          bool matchesAsset(DigitalStudioAssetModel asset) {
            if (assetQuery.isEmpty) return true;
            return asset.name.toLowerCase().contains(assetQuery) ||
                asset.assetCode.toLowerCase().contains(assetQuery) ||
                asset.category.toLowerCase().contains(assetQuery);
          }

          final visibleCrew = availableCrew.where(matchesCrew).toList();
          final visibleBusyCrew = busyCrew.where(matchesCrew).toList();
          final visibleAssets =
              availableAssetsList.where(matchesAsset).toList();
          final visibleBusyAssets =
              busyAssetsList.where(matchesAsset).toList();

          return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Allot Crew & Assets: ${req.eventName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: PmsTheme.bgSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: PmsTheme.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${DateFormat('dd MMM, hh:mm a').format(req.reportingDateTime)} - ${DateFormat('hh:mm a').format(req.eventEndTime)}',
                                style: const TextStyle(fontSize: 12, color: PmsTheme.textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required Crew Count: ${req.requiredCrewCount}',
                          style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Crew Selection Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Crew *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (busyCrew.isNotEmpty)
                        GestureDetector(
                          onTap: () => setDialogState(() => showBusyCrew = !showBusyCrew),
                          child: Text(
                            showBusyCrew ? 'Hide Occupied (${busyCrew.length})' : 'Show Occupied (${busyCrew.length})',
                            style: TextStyle(
                              fontSize: 11,
                              color: showBusyCrew ? Colors.indigo : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (busyCrew.isNotEmpty && !showBusyCrew)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        'ℹ️ ${busyCrew.length} crew member(s) hidden (already allotted to concurrent events)',
                        style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (val) => setDialogState(
                      () => crewQuery = val.trim().toLowerCase(),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search crew by name or phone...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (visibleCrew.isEmpty && (!showBusyCrew || visibleBusyCrew.isEmpty))
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                busyCrew.isNotEmpty
                                    ? '⚠️ All crew members are allotted to concurrent events during this time slot.'
                                    : 'No crew members available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: busyCrew.isNotEmpty ? Colors.red.shade700 : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              ...visibleCrew.map((member) {
                                final isSelected = selectedEmployees.contains(member.id);
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(member.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  subtitle: Text(member.phone, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedEmployees.add(member.id);
                                      } else {
                                        selectedEmployees.remove(member.id);
                                      }
                                    });
                                  },
                                );
                              }),
                              if (showBusyCrew && visibleBusyCrew.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  color: Colors.red.shade50,
                                  child: Text(
                                    'Occupied / Allotted to Other Events (${visibleBusyCrew.length})',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                  ),
                                ),
                                ...visibleBusyCrew.map((member) {
                                  return Opacity(
                                    opacity: 0.6,
                                    child: CheckboxListTile(
                                      dense: true,
                                      title: Text(
                                        member.name,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                      ),
                                      subtitle: Text(
                                        'Allotted to: "${busyCrewMap[member.id]}"',
                                        style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                      ),
                                      value: false,
                                      onChanged: null,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Asset Selection Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Equipment & Assets',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (busyAssetsList.isNotEmpty)
                        GestureDetector(
                          onTap: () => setDialogState(() => showBusyAssets = !showBusyAssets),
                          child: Text(
                            showBusyAssets ? 'Hide Occupied (${busyAssetsList.length})' : 'Show Occupied (${busyAssetsList.length})',
                            style: TextStyle(
                              fontSize: 11,
                              color: showBusyAssets ? Colors.indigo : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (busyAssetsList.isNotEmpty && !showBusyAssets)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        'ℹ️ ${busyAssetsList.length} asset(s) hidden (already allotted to concurrent events)',
                        style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (val) => setDialogState(
                      () => assetQuery = val.trim().toLowerCase(),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search equipment by name or code...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (visibleAssets.isEmpty && (!showBusyAssets || visibleBusyAssets.isEmpty))
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                busyAssetsList.isNotEmpty
                                    ? '⚠️ All matching assets are allotted to concurrent events during this time slot.'
                                    : 'No assets available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: busyAssetsList.isNotEmpty ? Colors.red.shade700 : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            children: [
                              ...visibleAssets.map((asset) {
                                final isSelected = selectedAssets.contains(asset.id);
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text('${asset.name} (${asset.assetCode})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  subtitle: Text('${asset.category} · ${asset.currentStatus}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedAssets.add(asset.id);
                                      } else {
                                        selectedAssets.remove(asset.id);
                                      }
                                    });
                                  },
                                );
                              }),
                              if (showBusyAssets && visibleBusyAssets.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  color: Colors.red.shade50,
                                  child: Text(
                                    'Occupied Assets (${visibleBusyAssets.length})',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                  ),
                                ),
                                ...visibleBusyAssets.map((asset) {
                                  return Opacity(
                                    opacity: 0.6,
                                    child: CheckboxListTile(
                                      dense: true,
                                      title: Text(
                                        '${asset.name} (${asset.assetCode})',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                      ),
                                      subtitle: Text(
                                        'Allotted to: "${busyAssetMap[asset.id]}"',
                                        style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                      ),
                                      value: false,
                                      onChanged: null,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: 'Allotment Remarks', isDense: true),
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
                if (selectedEmployees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least 1 employee')),
                  );
                  return;
                }

                // Check for conflict
                for (final empId in selectedEmployees) {
                  if (busyCrewMap.containsKey(empId) && !req.allottedEmployees.any((e) => e.id == empId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Crew member is already allotted to "${busyCrewMap[empId]}" during this time slot.'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                }

                for (final astId in selectedAssets) {
                  if (busyAssetMap.containsKey(astId) && !req.allottedAssets.any((a) => a.id == astId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Asset is already allotted to "${busyAssetMap[astId]}" during this time slot.'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(dialogCtx);
                context.read<DigitalStudioBloc>().add(
                      AllotCrewRequestEvent(
                        requestId: req.id,
                        employeeIds: selectedEmployees.toList(),
                        assetIds: selectedAssets.toList(),
                        remarks: remarksController.text.trim(),
                        phone: widget.currentUser?.phone,
                      ),
                    );
              },
              child: const Text('Confirm Allotment'),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _updateRequestStatus(
    DigitalStudioCrewRequestModel req,
    String status,
  ) async {
    double? lat;
    double? lng;

    if (status == 'in_progress') {
      try {
        // 1. Check if location service is enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          _showLocationErrorDialog(
            'Location Services Disabled',
            'Please enable Location Services (GPS) on your device to mark work as started.',
          );
          return;
        }

        // 2. Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (!mounted) return;
            _showLocationErrorDialog(
              'Location Permission Denied',
              'Location permission is required to verify your presence at the wing location before starting work.',
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          _showLocationErrorDialog(
            'Location Permission Permanently Denied',
            'Location permissions are permanently denied in device settings. Please enable location permissions in app settings to proceed.',
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        _showLocationErrorDialog(
          'App Rebuild Required',
          'Native location plugin bindings not registered in running app build: ${e.toString()}\n\nPlease stop and rebuild/restart the app from Android Studio / Xcode / terminal (flutter run) to link native iOS GPS drivers.',
        );
        return;
      }

      // Show loader dialog while acquiring GPS coordinates
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Acquiring GPS Location...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        _showLocationErrorDialog(
          'GPS Acquisition Failed',
          'Unable to acquire current location: ${e.toString()}',
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      lat = position.latitude;
      lng = position.longitude;

      // 3. Client-side geofence boundary verification if Wing has coordinates configured
      if (req.wing != null &&
          req.wing!.latitude != null &&
          req.wing!.longitude != null) {
        double distanceMeters = Geolocator.distanceBetween(
          lat,
          lng,
          req.wing!.latitude!,
          req.wing!.longitude!,
        );

        double maxAllowedMeters =
            req.wing!.geofenceRadiusMeters.toDouble();

        if (distanceMeters > maxAllowedMeters) {
          _showLocationErrorDialog(
            '📍 Out of Geofence Boundary',
            'You are currently ${distanceMeters.toStringAsFixed(1)} meters away from ${req.wing?.name ?? "the Wing"}.\n\nYou must be within ${maxAllowedMeters.toStringAsFixed(0)} meters of the Wing boundary to start work.',
          );
          return;
        }
      }
    }

    if (!mounted) return;

    context.read<DigitalStudioBloc>().add(
          UpdateCrewRequestStatusEvent(
            requestId: req.id,
            status: status,
            phone: widget.currentUser?.phone,
            latitude: lat,
            longitude: lng,
          ),
        );
  }

  void _showLocationErrorDialog(
    String title,
    String message,
  ) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: PmsTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
