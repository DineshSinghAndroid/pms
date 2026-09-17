import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';
import '../../theme/pms_theme.dart';

class DigitalStudioCalendarSubTab extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isManager;
  final bool isDigitalStudioIncharge;
  final bool isDesigner;

  const DigitalStudioCalendarSubTab({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    this.isManager = false,
    this.isDigitalStudioIncharge = false,
    this.isDesigner = false,
  });

  @override
  State<DigitalStudioCalendarSubTab> createState() =>
      _DigitalStudioCalendarSubTabState();
}

class _DigitalStudioCalendarSubTabState
    extends State<DigitalStudioCalendarSubTab> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  int? _selectedEmployeeId;
  String _selectedStatusFilter = 'all';

  bool get _canManage =>
      widget.isSuperAdmin ||
      widget.isManager ||
      widget.isDigitalStudioIncharge;

  bool get _isDigitalStudioEmployee =>
      widget.currentUser?.isDigitalStudioEmployee ?? false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);

    if (_isDigitalStudioEmployee && widget.currentUser != null) {
      _selectedEmployeeId = widget.currentUser!.id;
    }
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DigitalStudioBloc, DigitalStudioState>(
      builder: (context, state) {
        if (state is DigitalStudioLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DigitalStudioLoaded) {
          return _buildCalendarContent(context, state);
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

  Widget _buildCalendarContent(BuildContext context, DigitalStudioLoaded state) {
    final allSchedules = state.schedules;

    // Events on selected date
    final selectedDayEvents = allSchedules.where((s) {
      final matchesDate = s.reportingDateTime.year == _selectedDate.year &&
          s.reportingDateTime.month == _selectedDate.month &&
          s.reportingDateTime.day == _selectedDate.day;

      final matchesEmployee = _selectedEmployeeId == null ||
          s.allottedEmployees.any((e) => e.id == _selectedEmployeeId);

      final matchesStatus = _selectedStatusFilter == 'all' ||
          (_selectedStatusFilter == 'needs_attention' && s.isPending) ||
          s.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesDate && matchesEmployee && matchesStatus;
    }).toList();

    // Check duty status of the target employee on the selected date
    final targetEmpId = _selectedEmployeeId ??
        (_isDigitalStudioEmployee ? widget.currentUser?.id : null);

    final targetEmpEventsOnSelectedDate = targetEmpId != null
        ? allSchedules.where((s) {
            final matchesDate = s.reportingDateTime.year == _selectedDate.year &&
                s.reportingDateTime.month == _selectedDate.month &&
                s.reportingDateTime.day == _selectedDate.day;
            final hasEmployee = s.allottedEmployees.any((e) => e.id == targetEmpId);
            return matchesDate && hasEmployee && (s.isAllotted || s.isInProgress);
          }).toList()
        : <DigitalStudioCrewRequestModel>[];

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DigitalStudioBloc>().add(
              RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
            );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          // 1. FILTER & CONTROLS TOOLBAR
          _buildFilterToolbar(state),
          const SizedBox(height: 12),

          // 2. MONTH CALENDAR CARD (Image replica)
          _buildMonthCalendarCard(allSchedules),
          const SizedBox(height: 12),

          // 3. COLOR LEGEND BAR
          _buildColorLegendBar(),
          const SizedBox(height: 14),

          // 4. EMPLOYEE DUTY STATUS (OFF vs BOOKED)
          if (targetEmpId != null) ...[
            _buildEmployeeDutyCard(targetEmpEventsOnSelectedDate, state),
            const SizedBox(height: 14),
          ],

          // 5. SELECTED DAY AGENDA HEADER
          _buildSelectedDayHeader(selectedDayEvents.length),
          const SizedBox(height: 10),

          // 6. EVENT CARDS LIST
          if (selectedDayEvents.isEmpty)
            _buildEmptySelectedDayState()
          else
            ...selectedDayEvents.map((e) => _buildScheduleEventCard(context, e, state)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. FILTERS TOOLBAR
  // ===========================================================================
  Widget _buildFilterToolbar(DigitalStudioLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isDigitalStudioEmployee ? Icons.event_note_rounded : Icons.tune_rounded,
                size: 18,
                color: PmsTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isDigitalStudioEmployee ? 'My Duty Schedule' : 'Calendar Filters',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PmsTheme.textPrimary,
                  ),
                ),
              ),
              if ((!_isDigitalStudioEmployee && _selectedEmployeeId != null) || _selectedStatusFilter != 'all')
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (!_isDigitalStudioEmployee) {
                        _selectedEmployeeId = null;
                      }
                      _selectedStatusFilter = 'all';
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: PmsTheme.error,
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 11)),
                ),
              ElevatedButton(
                onPressed: _jumpToToday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: PmsTheme.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                  ),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isDigitalStudioEmployee)
            // Clean Status Filter for Employee (No other employee names dropdown)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: PmsTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PmsTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: PmsTheme.textSecondary),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All My Shoots', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: 'allotted',
                            child: Text('🟢 Booked / Allotted', style: TextStyle(fontSize: 12, color: Color(0xFF059669))),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('🔵 In Progress', style: TextStyle(fontSize: 12, color: PmsTheme.primary)),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('⚪ Completed', style: TextStyle(fontSize: 12, color: PmsTheme.textSecondary)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Full Filters for Admin / Incharge
            Row(
              children: [
                // Employee Filter
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: PmsTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PmsTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedEmployeeId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: PmsTheme.textSecondary),
                        hint: const Text('All Crew Staff', style: TextStyle(fontSize: 12, color: PmsTheme.textSecondary)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Crew Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          ...state.crewMembers.map(
                            (u) => DropdownMenuItem<int?>(
                              value: u.id,
                              child: Text(
                                u.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedEmployeeId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status Filter
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: PmsTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PmsTheme.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: PmsTheme.textSecondary),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Statuses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          DropdownMenuItem(
                            value: 'needs_attention',
                            child: Text('🔴 Needs Attention', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                          ),
                          DropdownMenuItem(
                            value: 'allotted',
                            child: Text('🟢 Allotted (Booked)', style: TextStyle(fontSize: 12, color: Color(0xFF059669))),
                          ),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('🔵 In Progress', style: TextStyle(fontSize: 12, color: PmsTheme.primary)),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('⚪ Completed', style: TextStyle(fontSize: 12, color: PmsTheme.textSecondary)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MONTH CALENDAR CARD (EXACT REPLICA OF THE IMAGE)
  // ===========================================================================
  Widget _buildMonthCalendarCard(List<DigitalStudioCrewRequestModel> allSchedules) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayIndex = DateTime(year, month, 1).weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final daysInPrevMonth = DateTime(year, month, 0).day;
    final totalCells = (firstDayIndex + daysInMonth > 35) ? 42 : 35;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final monthTitle = DateFormat('MMMM  yyyy').format(_displayedMonth);

    return Container(
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Deep Blue Header (< Month Year >)
          Container(
            color: PmsTheme.primaryDark, // Deep Blue as in reference image
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
                  onPressed: _prevMonth,
                  tooltip: 'Previous Month',
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  monthTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 26),
                  onPressed: _nextMonth,
                  tooltip: 'Next Month',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Days of Week Header Row: M T W T F S S
          Container(
            color: PmsTheme.glassSurface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                _WeekdayHeader(label: 'M'),
                _WeekdayHeader(label: 'T'),
                _WeekdayHeader(label: 'W'),
                _WeekdayHeader(label: 'T'),
                _WeekdayHeader(label: 'F'),
                _WeekdayHeader(label: 'S'),
                _WeekdayHeader(label: 'S'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: PmsTheme.bgSoft),

          // 7-Column Month Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              DateTime cellDate;
              bool isCurrentMonth = true;

              if (index < firstDayIndex) {
                // Previous month trailing days
                final dayNum = daysInPrevMonth - firstDayIndex + index + 1;
                cellDate = DateTime(year, month - 1, dayNum);
                isCurrentMonth = false;
              } else if (index >= firstDayIndex + daysInMonth) {
                // Next month overflow days
                final dayNum = index - (firstDayIndex + daysInMonth) + 1;
                cellDate = DateTime(year, month + 1, dayNum);
                isCurrentMonth = false;
              } else {
                // Current month day
                final dayNum = index - firstDayIndex + 1;
                cellDate = DateTime(year, month, dayNum);
                isCurrentMonth = true;
              }

              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              final isToday = cellDate.year == todayDate.year &&
                  cellDate.month == todayDate.month &&
                  cellDate.day == todayDate.day;

              // Find events on this cellDate
              final eventsOnDate = allSchedules.where((s) {
                return s.reportingDateTime.year == cellDate.year &&
                    s.reportingDateTime.month == cellDate.month &&
                    s.reportingDateTime.day == cellDate.day;
              }).toList();

              final hasPending = eventsOnDate.any((s) => s.isPending);
              final hasAllotted = eventsOnDate.any((s) => s.isAllotted);
              final hasInProgress = eventsOnDate.any((s) => s.isInProgress);
              final hasCompleted = eventsOnDate.any((s) => s.isCompleted);

              // Check if selected employee is booked on this day
              final targetEmpId = _selectedEmployeeId ??
                  (_isDigitalStudioEmployee ? widget.currentUser?.id : null);
              final isEmpBooked = targetEmpId != null &&
                  eventsOnDate.any((s) =>
                      s.allottedEmployees.any((e) => e.id == targetEmpId) &&
                      (s.isAllotted || s.isInProgress));

              return _buildCalendarDayCell(
                cellDate: cellDate,
                dayNum: cellDate.day,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                hasPending: hasPending,
                hasAllotted: hasAllotted,
                hasInProgress: hasInProgress,
                hasCompleted: hasCompleted,
                isEmpBooked: isEmpBooked,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayCell({
    required DateTime cellDate,
    required int dayNum,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required bool hasPending,
    required bool hasAllotted,
    required bool hasInProgress,
    required bool hasCompleted,
    required bool isEmpBooked,
  }) {
    Color textColor = PmsTheme.textPrimary;
    FontWeight fontWeight = FontWeight.w600;

    if (!isCurrentMonth) {
      textColor = const Color(0xFFCBD5E1);
      fontWeight = FontWeight.w400;
    } else if (isToday) {
      textColor = PmsTheme.primaryDark;
      fontWeight = FontWeight.w900;
    }

    if (isSelected) {
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = cellDate;
          if (cellDate.month != _displayedMonth.month) {
            _displayedMonth = DateTime(cellDate.year, cellDate.month, 1);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? PmsTheme.primaryDark
              : (isToday
                  ? const Color(0xFFEEF2FF)
                  : (isSelected ? PmsTheme.bgSoft : Colors.transparent)),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFF93C5FD), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            const SizedBox(height: 3),

            // Color-Coded Indicator Dots
            if (isCurrentMonth &&
                (hasPending || hasAllotted || hasInProgress || hasCompleted || isEmpBooked))
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPending)
                    _buildStatusDot(
                      color: isSelected ? Colors.amberAccent : PmsTheme.error,
                      tooltip: 'Needs Attention / Pending Allotment',
                    ),
                  if (hasAllotted)
                    _buildStatusDot(
                      color: isSelected ? Colors.greenAccent : PmsTheme.success,
                      tooltip: 'Confirmed Allotment / Booked',
                    ),
                  if (hasInProgress)
                    _buildStatusDot(
                      color: isSelected ? Colors.lightBlueAccent : const Color(0xFF3B82F6),
                      tooltip: 'In Progress',
                    ),
                  if (isEmpBooked)
                    _buildStatusDot(
                      color: isSelected ? Colors.purpleAccent : const Color(0xFF8B5CF6),
                      tooltip: 'Staff Booked on this date',
                    ),
                  if (hasCompleted && !hasPending && !hasAllotted && !hasInProgress)
                    _buildStatusDot(
                      color: isSelected ? Colors.white70 : PmsTheme.textMuted,
                      tooltip: 'Completed',
                    ),
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot({required Color color, required String tooltip}) {
    return Container(
      width: 5.5,
      height: 5.5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. COLOR LEGEND BAR
  // ===========================================================================
  Widget _buildColorLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PmsTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PmsTheme.glassBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _isDigitalStudioEmployee
              ? [
                  _buildLegendItem(PmsTheme.success, 'Shoot Scheduled (Booked)'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFF3B82F6), 'In Progress'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFF8B5CF6), 'Duty Booked'),
                  const SizedBox(width: 12),
                  _buildLegendItem(PmsTheme.textMuted, 'Completed'),
                ]
              : [
                  _buildLegendItem(PmsTheme.error, 'Needs Attention (Pending)'),
                  const SizedBox(width: 12),
                  _buildLegendItem(PmsTheme.success, 'Allotted / Booked'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFF3B82F6), 'In Progress'),
                  const SizedBox(width: 12),
                  _buildLegendItem(const Color(0xFF8B5CF6), 'Staff Booked'),
                  const SizedBox(width: 12),
                  _buildLegendItem(PmsTheme.textMuted, 'Completed'),
                ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: PmsTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. EMPLOYEE DUTY STATUS CARD (OFF vs BOOKED)
  // ===========================================================================
  Widget _buildEmployeeDutyCard(
    List<DigitalStudioCrewRequestModel> empEvents,
    DigitalStudioLoaded state,
  ) {
    final targetEmpId = _selectedEmployeeId ??
        (_isDigitalStudioEmployee ? widget.currentUser?.id : null);

    UserModel? empUser;
    if (targetEmpId != null) {
      empUser = state.crewMembers.where((u) => u.id == targetEmpId).firstOrNull ??
          (widget.currentUser?.id == targetEmpId ? widget.currentUser : null);
    }

    final empName = empUser?.name ?? 'Selected Employee';
    final isBooked = empEvents.isNotEmpty;

    if (isBooked) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: PmsTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
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
                          _isDigitalStudioEmployee ? 'You are Booked' : '$empName is Booked',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${empEvents.length} Shoot(s)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Assigned to ${empEvents.map((e) => e.eventName).join(', ')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDigitalStudioEmployee ? 'You have Off / No Shoots' : '$empName is Off / Available',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B21B6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'No shoots scheduled on this date. Available for upcoming event allotments.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6D28D9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // ===========================================================================
  // 5. SELECTED DAY HEADER
  // ===========================================================================
  Widget _buildSelectedDayHeader(int count) {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    return Row(
      children: [
        const Icon(Icons.event_note_rounded, size: 20, color: PmsTheme.primaryDark),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: PmsTheme.textPrimary,
                ),
              ),
              const Text(
                'Schedule and allotted crew for this day',
                style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: count > 0 ? PmsTheme.primaryDark : PmsTheme.glassBorder,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count Event${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: count > 0 ? Colors.white : PmsTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelectedDayState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PmsTheme.glassBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No Events Scheduled',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No studio crew requests or bookings found for ${DateFormat('dd MMM yyyy').format(_selectedDate)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: PmsTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. EVENT CARD
  // ===========================================================================
  Widget _buildScheduleEventCard(
    BuildContext context,
    DigitalStudioCrewRequestModel event,
    DigitalStudioLoaded state,
  ) {
    Color statusBg = const Color(0xFFD1FAE5);
    Color statusColor = const Color(0xFF065F46);
    String statusLabel = 'Allotted';

    if (event.isPending) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFB91C1C);
      statusLabel = '🔴 Needs Attention (Pending)';
    } else if (event.isInProgress) {
      statusBg = const Color(0xFFDBEAFE);
      statusColor = PmsTheme.primaryDark;
      statusLabel = '🔵 In Progress';
    } else if (event.isCompleted) {
      statusBg = PmsTheme.bgSoft;
      statusColor = PmsTheme.textSecondary;
      statusLabel = '⚪ Completed';
    } else if (event.isCancelled) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFF991B1B);
      statusLabel = 'Cancelled';
    } else {
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF047857);
      statusLabel = '🟢 Allotted';
    }

    final startStr = DateFormat('hh:mm a').format(event.reportingDateTime);
    final endStr = DateFormat('hh:mm a').format(event.eventEndTime);

    final isCurrentUserAllotted = widget.currentUser != null &&
        event.allottedEmployees.any((e) => e.id == widget.currentUser!.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUserAllotted
              ? const Color(0xFF818CF8)
              : (event.isPending ? const Color(0xFFFCA5A5) : PmsTheme.glassBorder),
          width: isCurrentUserAllotted || event.isPending ? 1.5 : 1.0,
        ),
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
          // Header: Wing Badge & Status Badge
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.wing?.name ?? 'General Wing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.requestNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PmsTheme.textSecondary,
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
                  borderRadius: BorderRadius.circular(8),
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

          // Event Name
          Text(
            event.eventName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: PmsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Time range
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: PmsTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$startStr  -  $endStr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: PmsTheme.bgSoft),
          const SizedBox(height: 10),

          // Allotted Crew Members
          if (!_isDigitalStudioEmployee)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.groups_outlined, size: 16, color: PmsTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: event.allottedEmployees.isEmpty
                      ? const Text(
                          'No crew allotted yet (Action Required)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: event.allottedEmployees.map((crew) {
                            final isMe = widget.currentUser?.id == crew.id;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFFEDE9FE) : PmsTheme.bgSoft,
                                borderRadius: BorderRadius.circular(6),
                                border: isMe ? Border.all(color: const Color(0xFFC4B5FD)) : null,
                              ),
                              child: Text(
                                isMe ? '👤 You (${crew.name})' : '👤 ${crew.name}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                                  color: isMe ? const Color(0xFF6D28D9) : const Color(0xFF334155),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined, size: 16, color: PmsTheme.secondary),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC4B5FD)),
                  ),
                  child: const Text(
                    '👤 You are Assigned to this Shoot',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),

          // Allotted Assets / Equipment (if any)
          if (event.allottedAssets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.videocam_outlined, size: 16, color: PmsTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: event.allottedAssets.map((asset) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PmsTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: PmsTheme.glassBorder),
                        ),
                        child: Text(
                          '📷 ${asset.name} (${asset.assetCode})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: PmsTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],

          // Action Buttons for Allotted & In-Progress Events (Start Work / Mark Completed)
          if (!event.isCompleted && !event.isCancelled && !event.isInProgress) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateRequestStatus(event, 'in_progress'),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Work (GPS Verify)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 1.5,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (event.isInProgress) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateRequestStatus(event, 'completed'),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PmsTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 1.5,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // Quick Action for Pending Requests
          if (_canManage && event.isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAllotDialog(context, event, state),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Allot Crew & Equipment Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // ALLOTMENT MODAL DIALOG
  // ===========================================================================
  void _openAllotDialog(
    BuildContext context,
    DigitalStudioCrewRequestModel req,
    DigitalStudioLoaded state,
  ) {
    final selectedEmpIds = <int>{...req.allottedEmployees.map((e) => e.id)};
    final selectedAssetIds = <int>{...req.allottedAssets.map((a) => a.id)};
    final remarksCtrl = TextEditingController(text: req.remarks ?? '');
    String crewQuery = '';
    String assetQuery = '';

    final availableAssets = state.availableAssets;
    final allCrew = state.crewMembers;

    final reqStart = req.reportingDateTime;
    final reqEnd = req.eventEndTime;

    final overlappingReqs = state.crewRequests.where((r) {
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final visibleCrew = allCrew.where((c) {
            if (crewQuery.isEmpty) return true;
            return c.name.toLowerCase().contains(crewQuery) ||
                c.role.toLowerCase().contains(crewQuery);
          }).toList();
          final visibleAssets = availableAssets.where((a) {
            if (assetQuery.isEmpty) return true;
            return a.name.toLowerCase().contains(assetQuery) ||
                a.assetCode.toLowerCase().contains(assetQuery) ||
                a.category.toLowerCase().contains(assetQuery);
          }).toList();

          return AlertDialog(
            title: Text(
              'Allot Crew for ${req.eventName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Time: ${DateFormat('dd MMM, hh:mm a').format(req.reportingDateTime)} - ${DateFormat('hh:mm a').format(req.eventEndTime)}',
                    style: const TextStyle(fontSize: 12, color: PmsTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // Select Crew Members
                  const Text('Select Crew Staff *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (val) => setModalState(
                      () => crewQuery = val.trim().toLowerCase(),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search crew by name...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: PmsTheme.glassBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: visibleCrew.map((c) {
                        final isChecked = selectedEmpIds.contains(c.id);
                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          title: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(c.role, style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedEmpIds.add(c.id);
                              } else {
                                selectedEmpIds.remove(c.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Select Assets
                  const Text('Select Studio Equipment (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (val) => setModalState(
                      () => assetQuery = val.trim().toLowerCase(),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search equipment by name or code...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (availableAssets.isEmpty)
                    const Text('No available equipment in studio inventory.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else if (visibleAssets.isEmpty)
                    const Text('No equipment matches your search.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: PmsTheme.glassBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: visibleAssets.map((a) {
                          final isChecked = selectedAssetIds.contains(a.id);
                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            title: Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('${a.category} · ${a.assetCode}', style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary)),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedAssetIds.add(a.id);
                                } else {
                                  selectedAssetIds.remove(a.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedEmpIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least 1 crew member.')),
                    );
                    return;
                  }

                  for (final empId in selectedEmpIds) {
                    if (busyCrewMap.containsKey(empId) && !req.allottedEmployees.any((e) => e.id == empId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Crew member is already allotted: ${busyCrewMap[empId]}'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                      return;
                    }
                  }

                  for (final astId in selectedAssetIds) {
                    if (busyAssetMap.containsKey(astId) && !req.allottedAssets.any((a) => a.id == astId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Equipment/Product is already allotted: ${busyAssetMap[astId]}'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                      return;
                    }
                  }

                  context.read<DigitalStudioBloc>().add(
                        AllotCrewRequestEvent(
                          requestId: req.id,
                          employeeIds: selectedEmpIds.toList(),
                          assetIds: selectedAssetIds.toList(),
                          remarks: remarksCtrl.text.trim(),
                          phone: widget.currentUser?.phone,
                        ),
                      );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: PmsTheme.primaryDark),
                child: const Text(
                  'Confirm Allotment',
                  style: TextStyle(color: Colors.white),
                ),
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
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          _showLocationErrorDialog(
            'Location Services Disabled',
            'Please enable Location Services (GPS) on your device to mark work as started.',
          );
          return;
        }

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
        Navigator.of(context, rootNavigator: true).pop();
        _showLocationErrorDialog(
          'GPS Acquisition Failed',
          'Unable to acquire current location: ${e.toString()}',
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      lat = position.latitude;
      lng = position.longitude;

      if (req.wing != null &&
          req.wing!.latitude != null &&
          req.wing!.longitude != null) {
        double distanceMeters = Geolocator.distanceBetween(
          lat,
          lng,
          req.wing!.latitude!,
          req.wing!.longitude!,
        );

        double maxAllowedMeters = req.wing!.geofenceRadiusMeters.toDouble();

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

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: PmsTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
