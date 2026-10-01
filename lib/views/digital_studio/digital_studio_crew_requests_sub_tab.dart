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

  bool get isDigitalStudioEmployee =>
      widget.currentUser?.isDigitalStudioEmployee ?? false;

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
          final myId = widget.currentUser?.id;
          final myPhone = widget.currentUser?.phone;
          var sourceRequests = state.crewRequests;
          if (isDigitalStudioEmployee) {
            sourceRequests = sourceRequests.where((req) {
              return req.allottedEmployees.any((e) =>
                  (myId != null && e.id == myId) ||
                  (myPhone != null &&
                      myPhone.isNotEmpty &&
                      e.phone.endsWith(myPhone.replaceAll(RegExp(r'\D'), ''))));
            }).toList();
          }

          var filteredRequests = sourceRequests.where((req) {
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
                    Expanded(
                      child: Text(
                        isDigitalStudioEmployee
                            ? 'My Assigned Duty Requests'
                            : 'Crew Requests Queue',
                        style: const TextStyle(
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
                    _buildFilterTab('All', 'all', sourceRequests.length),
                    _buildFilterTab(
                      'Pending',
                      'pending',
                      sourceRequests.where((r) => r.isPending).length,
                      badgeColor: PmsTheme.warning,
                    ),
                    _buildFilterTab(
                      'Allotted',
                      'allotted',
                      sourceRequests.where((r) => r.isAllotted).length,
                      badgeColor: const Color(0xFF8B5CF6),
                    ),
                    _buildFilterTab(
                      'In Progress',
                      'in_progress',
                      sourceRequests.where((r) => r.isInProgress).length,
                      badgeColor: const Color(0xFF3B82F6),
                    ),
                    _buildFilterTab(
                      'Completed',
                      'completed',
                      sourceRequests.where((r) => r.isCompleted).length,
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
                                      isDigitalStudioEmployee
                                          ? 'No assigned shoot duties found'
                                          : 'No crew requests found',
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

              if (isDigitalStudioEmployee && !req.isCompleted && !req.isCancelled && !req.isInProgress) ...[
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final startWindow = req.reportingDateTime.subtract(const Duration(minutes: 15));
                    final isTooEarly = now.isBefore(startWindow);

                    if (isTooEarly) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock_rounded, size: 14, color: Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'You can start work 15 minutes before duty time (${DateFormat('hh:mm a').format(startWindow)})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.lock_outline_rounded, size: 18),
                            label: const Text('Start Work (Locked)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade600,
                              disabledBackgroundColor: Colors.grey.shade200,
                              disabledForegroundColor: Colors.grey.shade500,
                              elevation: 0,
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
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF059669)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '📍 Ready to Start inside ${req.wing?.name ?? "Campus"}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _updateRequestStatus(req, 'in_progress'),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Start Work (GPS Verify)'),
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
                      );
                    }
                  },
                ),
              ],
              if (req.isInProgress && (isDigitalStudioEmployee || canAllot)) ...[
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) => StatefulBuilder(
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

          return DefaultTabController(
            length: 2,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.94,
              child: Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: true,
                body: Column(
                  children: [
                    // Top drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Allot Crew & Assets',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: PmsTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${req.eventName} (${req.wing?.name ?? "Wing"})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PmsTheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(bottomSheetCtx),
                          ),
                        ],
                      ),
                    ),

                    // Event Time & Requirement Summary Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: PmsTheme.bgSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: PmsTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${DateFormat('dd MMM, hh:mm a').format(req.reportingDateTime)} - ${DateFormat('hh:mm a').format(req.eventEndTime)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: PmsTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedEmployees.length >= req.requiredCrewCount
                                  ? PmsTheme.success.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Crew: ${selectedEmployees.length}/${req.requiredCrewCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedEmployees.length >= req.requiredCrewCount
                                    ? PmsTheme.success
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Segmented Tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: PmsTheme.textSecondary,
                        indicator: BoxDecoration(
                          color: PmsTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.people_alt_outlined, size: 18),
                            text: 'Crew Members (${selectedEmployees.length})',
                          ),
                          Tab(
                            icon: const Icon(Icons.videocam_outlined, size: 18),
                            text: 'Equipment (${selectedAssets.length})',
                          ),
                        ],
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Crew Members
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                                child: TextField(
                                  onChanged: (val) => setDialogState(() => crewQuery = val.trim().toLowerCase()),
                                  decoration: InputDecoration(
                                    hintText: 'Search crew by name or phone...',
                                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                    suffixIcon: crewQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () => setDialogState(() => crewQuery = ''),
                                          )
                                        : null,
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ),
                              if (busyCrew.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: InkWell(
                                    onTap: () => setDialogState(() => showBusyCrew = !showBusyCrew),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: showBusyCrew ? Colors.orange.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: showBusyCrew ? Colors.orange.shade200 : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            showBusyCrew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 16,
                                            color: showBusyCrew ? Colors.orange.shade900 : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              showBusyCrew
                                                  ? 'Occupied crew members are visible (${busyCrew.length})'
                                                  : '${busyCrew.length} occupied crew hidden (allotted to other events)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: showBusyCrew ? Colors.orange.shade900 : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            showBusyCrew ? 'Hide' : 'Show',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: showBusyCrew ? Colors.orange.shade900 : PmsTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: (visibleCrew.isEmpty && (!showBusyCrew || visibleBusyCrew.isEmpty))
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                                              const SizedBox(height: 8),
                                              Text(
                                                busyCrew.isNotEmpty
                                                    ? 'All matching crew members are allotted to concurrent events.'
                                                    : 'No crew members found',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        children: [
                                          ...visibleCrew.map((member) {
                                            final isSelected = selectedEmployees.contains(member.id);
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              elevation: isSelected ? 1 : 0,
                                              color: isSelected ? PmsTheme.primary.withOpacity(0.06) : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: isSelected ? PmsTheme.primary : Colors.grey.shade200,
                                                  width: isSelected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: CheckboxListTile(
                                                dense: false,
                                                value: isSelected,
                                                activeColor: PmsTheme.primary,
                                                title: Text(
                                                  member.name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${member.role.isNotEmpty ? member.role : "Crew"} · ${member.phone}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                                onChanged: (val) {
                                                  setDialogState(() {
                                                    if (val == true) {
                                                      selectedEmployees.add(member.id);
                                                    } else {
                                                      selectedEmployees.remove(member.id);
                                                    }
                                                  });
                                                },
                                              ),
                                            );
                                          }),
                                          if (showBusyCrew && visibleBusyCrew.isNotEmpty) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                                              child: Text(
                                                'Occupied on Concurrent Events (${visibleBusyCrew.length})',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                              ),
                                            ),
                                            ...visibleBusyCrew.map((member) {
                                              return Card(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                color: Colors.grey.shade50,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  side: BorderSide(color: Colors.red.shade100),
                                                ),
                                                child: Opacity(
                                                  opacity: 0.65,
                                                  child: CheckboxListTile(
                                                    dense: false,
                                                    value: false,
                                                    title: Text(
                                                      member.name,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                                    ),
                                                    subtitle: Text(
                                                      'Occupied: "${busyCrewMap[member.id]}"',
                                                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                                                    ),
                                                    onChanged: null,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                              ),
                            ],
                          ),

                          // Tab 2: Equipment & Assets
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                                child: TextField(
                                  onChanged: (val) => setDialogState(() => assetQuery = val.trim().toLowerCase()),
                                  decoration: InputDecoration(
                                    hintText: 'Search equipment by name or code...',
                                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                    suffixIcon: assetQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () => setDialogState(() => assetQuery = ''),
                                          )
                                        : null,
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ),
                              if (busyAssetsList.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: InkWell(
                                    onTap: () => setDialogState(() => showBusyAssets = !showBusyAssets),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: showBusyAssets ? Colors.orange.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: showBusyAssets ? Colors.orange.shade200 : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            showBusyAssets ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 16,
                                            color: showBusyAssets ? Colors.orange.shade900 : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              showBusyAssets
                                                  ? 'Occupied equipment is visible (${busyAssetsList.length})'
                                                  : '${busyAssetsList.length} occupied assets hidden (allotted to other events)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: showBusyAssets ? Colors.orange.shade900 : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            showBusyAssets ? 'Hide' : 'Show',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: showBusyAssets ? Colors.orange.shade900 : PmsTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: (visibleAssets.isEmpty && (!showBusyAssets || visibleBusyAssets.isEmpty))
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.videocam_off_outlined, size: 48, color: Colors.grey.shade400),
                                              const SizedBox(height: 8),
                                              Text(
                                                busyAssetsList.isNotEmpty
                                                    ? 'All matching assets are allotted to concurrent events.'
                                                    : 'No equipment found',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        children: [
                                          ...visibleAssets.map((asset) {
                                            final isSelected = selectedAssets.contains(asset.id);
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              elevation: isSelected ? 1 : 0,
                                              color: isSelected ? PmsTheme.primary.withOpacity(0.06) : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                side: BorderSide(
                                                  color: isSelected ? PmsTheme.primary : Colors.grey.shade200,
                                                  width: isSelected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: CheckboxListTile(
                                                dense: false,
                                                value: isSelected,
                                                activeColor: PmsTheme.primary,
                                                title: Text(
                                                  '${asset.name} (${asset.assetCode})',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${asset.category} · ${asset.currentStatus}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                                onChanged: (val) {
                                                  setDialogState(() {
                                                    if (val == true) {
                                                      selectedAssets.add(asset.id);
                                                    } else {
                                                      selectedAssets.remove(asset.id);
                                                    }
                                                  });
                                                },
                                              ),
                                            );
                                          }),
                                          if (showBusyAssets && visibleBusyAssets.isNotEmpty) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                                              child: Text(
                                                'Occupied Equipment (${visibleBusyAssets.length})',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                              ),
                                            ),
                                            ...visibleBusyAssets.map((asset) {
                                              return Card(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                color: Colors.grey.shade50,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  side: BorderSide(color: Colors.red.shade100),
                                                ),
                                                child: Opacity(
                                                  opacity: 0.65,
                                                  child: CheckboxListTile(
                                                    dense: false,
                                                    value: false,
                                                    title: Text(
                                                      '${asset.name} (${asset.assetCode})',
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                                    ),
                                                    subtitle: Text(
                                                      'Occupied: "${busyAssetMap[asset.id]}"',
                                                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                                                    ),
                                                    onChanged: null,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bottom Bar with Remarks & Actions
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            offset: const Offset(0, -2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: remarksController,
                            decoration: InputDecoration(
                              hintText: 'Add allotment remarks/notes (optional)...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(bottomSheetCtx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (selectedEmployees.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select at least 1 crew member.')),
                                      );
                                      return;
                                    }

                                    // Check for conflict
                                    for (final empId in selectedEmployees) {
                                      if (busyCrewMap.containsKey(empId) &&
                                          !req.allottedEmployees.any((e) => e.id == empId)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Crew member is already allotted to "${busyCrewMap[empId]}" during this time slot.',
                                            ),
                                            backgroundColor: Colors.red.shade700,
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    for (final astId in selectedAssets) {
                                      if (busyAssetMap.containsKey(astId) &&
                                          !req.allottedAssets.any((a) => a.id == astId)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Asset is already allotted to "${busyAssetMap[astId]}" during this time slot.',
                                            ),
                                            backgroundColor: Colors.red.shade700,
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    Navigator.pop(bottomSheetCtx);
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PmsTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    'Confirm Allotment (${selectedEmployees.length} Crew, ${selectedAssets.length} Gear)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      // Time Window Check (within 15 mins of reporting time)
      final now = DateTime.now();
      final startWindow = req.reportingDateTime.subtract(const Duration(minutes: 15));
      if (now.isBefore(startWindow)) {
        final diffMins = startWindow.difference(now).inMinutes + 1;
        if (!mounted) return;
        _showLocationErrorDialog(
          '⏰ Too Early to Start Work',
          'Duty can only be started within 15 minutes of the scheduled reporting time (${DateFormat('hh:mm a').format(req.reportingDateTime)}).\n\nPlease try again in $diffMins minute(s) or arrive at the campus within the valid time window.',
        );
        return;
      }

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
