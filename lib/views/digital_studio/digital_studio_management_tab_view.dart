import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/digital_studio/digital_studio_state.dart';
import '../../models/user_model.dart';
import 'digital_studio_assets_sub_tab.dart';
import 'digital_studio_calendar_sub_tab.dart';
import 'digital_studio_crew_requests_sub_tab.dart';
import '../../theme/pms_theme.dart';

class DigitalStudioManagementTabView extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isManager;
  final bool isDigitalStudioIncharge;
  final bool isDesigner;
  final bool isWingIncharge;

  const DigitalStudioManagementTabView({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    required this.isManager,
    required this.isDigitalStudioIncharge,
    required this.isDesigner,
    required this.isWingIncharge,
  });

  @override
  State<DigitalStudioManagementTabView> createState() =>
      _DigitalStudioManagementTabViewState();
}

class _DigitalStudioManagementTabViewState
    extends State<DigitalStudioManagementTabView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;

  bool get isWingInchargeOnly =>
      widget.isWingIncharge &&
      !widget.isSuperAdmin &&
      !widget.isManager &&
      !widget.isDigitalStudioIncharge;

  bool get isDigitalStudioEmployee =>
      widget.currentUser?.isDigitalStudioEmployee ?? false;

  @override
  void initState() {
    super.initState();
    if (!isWingInchargeOnly) {
      const tabCount = 3;
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging || _tabController!.index != _currentTabIndex) {
          setState(() {
            _currentTabIndex = _tabController!.index;
          });
        }
      });
    }

    // Ensure data is loaded
    context.read<DigitalStudioBloc>().add(
          FetchDigitalStudioDataEvent(phone: widget.currentUser?.phone),
        );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isWingInchargeOnly) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header for Wing Incharge
            Container(
              color: PmsTheme.glassSurface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.videocam_outlined,
                      color: PmsTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Digital Studio Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Submit and track crew & equipment requests for your wing',
                          style: TextStyle(
                            fontSize: 12,
                            color: PmsTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<DigitalStudioBloc>().add(
                        RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing requests...'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: PmsTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PmsTheme.glassBorder),

            // Body: Crew Requests only
            Expanded(
              child: DigitalStudioCrewRequestsSubTab(
                currentUser: widget.currentUser,
                isSuperAdmin: widget.isSuperAdmin,
                isManager: widget.isManager,
                isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                isWingIncharge: widget.isWingIncharge,
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<DigitalStudioBloc, DigitalStudioState>(
      builder: (context, state) {
        int pendingRequestsCount = 0;
        int totalAssetsCount = 0;

        if (state is DigitalStudioLoaded) {
          totalAssetsCount = state.assets.length;
          pendingRequestsCount = state.crewRequests
              .where((r) => r.status == 'pending')
              .length;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Sub-Tab Bar
              Container(
                color: PmsTheme.glassSurface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.videocam_outlined,
                            color: PmsTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDigitalStudioEmployee
                                    ? 'My Schedule & Duty'
                                    : 'Digital Studio Management',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: PmsTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDigitalStudioEmployee
                                    ? 'Your personal shoot schedule & assigned studio gear'
                                    : 'Assets lifecycle, schedule calendar & crew allotment',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PmsTheme.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.read<DigitalStudioBloc>().add(
                              RefreshDigitalStudioEvent(phone: widget.currentUser?.phone),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing Digital Studio...'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: PmsTheme.textSecondary,
                            size: 20,
                          ),
                          tooltip: 'Refresh Data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom Segmented / Tab Bar
                    if (_tabController != null)
                      Container(
                        height: 46,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PmsTheme.bgSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PmsTheme.glassBorder),
                        ),
                        child: TabBar(
                          controller: _tabController!,
                          indicator: BoxDecoration(
                            color: PmsTheme.glassSurface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                          labelColor: PmsTheme.primary,
                          unselectedLabelColor: PmsTheme.textSecondary,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: isDigitalStudioEmployee
                              ? [
                                  // Tab 0: Requests for Employee
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.assignment_turned_in_outlined, size: 15),
                                          SizedBox(width: 4),
                                          Text('My Duty Requests'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab 1: Calendar for Employee
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.calendar_month_outlined, size: 15),
                                          SizedBox(width: 4),
                                          Text('My Schedule'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab 2: Assigned Assets for Employee
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.devices_other_outlined, size: 15),
                                          const SizedBox(width: 4),
                                          const Text('My Equipment'),
                                          if (totalAssetsCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _currentTabIndex == 2
                                                    ? PmsTheme.primary.withValues(alpha: 0.1)
                                                    : PmsTheme.glassBorder,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$totalAssetsCount',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _currentTabIndex == 2
                                                      ? PmsTheme.primary
                                                      : PmsTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  // Tab 0: Assets (Admin / Incharge)
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.devices_other_outlined, size: 15),
                                          const SizedBox(width: 4),
                                          const Text('Assets'),
                                          if (totalAssetsCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _currentTabIndex == 0
                                                    ? PmsTheme.primary.withValues(alpha: 0.1)
                                                    : PmsTheme.glassBorder,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$totalAssetsCount',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _currentTabIndex == 0
                                                      ? PmsTheme.primary
                                                      : PmsTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab 1: Calendar (Admin / Incharge)
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.calendar_month_outlined, size: 15),
                                          SizedBox(width: 4),
                                          Text('Calendar'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab 2: Requests (Admin / Incharge)
                                  Tab(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.group_outlined, size: 15),
                                          const SizedBox(width: 4),
                                          const Text('Requests'),
                                          if (pendingRequestsCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: PmsTheme.error,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$pendingRequestsCount',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                      ),
                  ],
                ),
              ),

              // Sub-Tabs View Body
              if (_tabController != null)
                Expanded(
                  child: TabBarView(
                    controller: _tabController!,
                    children: isDigitalStudioEmployee
                        ? [
                            // Tab 0: Requests Queue for Employee (shows assigned tasks + Start Work button)
                            DigitalStudioCrewRequestsSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                              isWingIncharge: widget.isWingIncharge,
                            ),

                            // Tab 1: Schedule Calendar for Employee
                            DigitalStudioCalendarSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                              isDesigner: widget.isDesigner,
                            ),

                            // Tab 2: Assigned Assets for Employee
                            DigitalStudioAssetsSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                            ),
                          ]
                        : [
                            // Tab 1: Assets Management
                            DigitalStudioAssetsSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                            ),

                            // Tab 2: Schedule Calendar
                            DigitalStudioCalendarSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                              isDesigner: widget.isDesigner,
                            ),

                            // Tab 3: Crew Requests Queue & Allotment
                            DigitalStudioCrewRequestsSubTab(
                              currentUser: widget.currentUser,
                              isSuperAdmin: widget.isSuperAdmin,
                              isManager: widget.isManager,
                              isDigitalStudioIncharge: widget.isDigitalStudioIncharge,
                              isWingIncharge: widget.isWingIncharge,
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
