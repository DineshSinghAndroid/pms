import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_event.dart';
import '../../bloc/wing/wing_state.dart';
import '../../models/wing_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';
import 'wing_form_sheet.dart';

class WingsTabView extends StatefulWidget {
  final bool isSuperAdmin;

  const WingsTabView({super.key, this.isSuperAdmin = true});

  @override
  State<WingsTabView> createState() => _WingsTabViewState();
}

class _WingsTabViewState extends State<WingsTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWingForm(BuildContext context, {WingModel? wing}) {
    WingFormSheet.show(context, wing: wing);
  }

  void _confirmDelete(BuildContext context, WingModel wing) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Wing',
            style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete "${wing.name}"?',
            style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: PmsTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<WingBloc>().add(DeleteWingEvent(wing.id));
                Navigator.pop(dialogCtx);
                showPmsSnackBar(
                  context,
                  '✓ Wing deleted',
                  kind: PmsSnackKind.error,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PmsTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: PmsTheme.primary,
      onRefresh: () async {
        context.read<WingBloc>().add(const RefreshWingsEvent());
        await context.read<WingBloc>().stream.firstWhere(
              (state) => state is WingLoaded || state is WingError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PmsPageHeader(
              icon: Icons.apartment_rounded,
              title: 'Wings Management',
              subtitle: 'Campuses and institute wing directory',
              action: widget.isSuperAdmin
                  ? FilledButton.icon(
                      onPressed: () => _showWingForm(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Wing'),
                    )
                  : null,
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
              style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search wings by name, code or location...',
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
              ),
            ),

            const SizedBox(height: 18),

            BlocBuilder<WingBloc, WingState>(
              builder: (context, state) {
                if (state is WingLoading) {
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }

                if (state is WingError) {
                  return GlassCard(
                    backgroundColor: const Color(0xFFFEF2F2),
                    border: Border.all(
                      color: PmsTheme.error.withValues(alpha: 0.35),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Couldn’t load wings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.errorMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            context
                                .read<WingBloc>()
                                .add(const FetchWingsEvent());
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PmsTheme.error,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is WingLoaded) {
                  final wings = state.wings.where((w) {
                    if (_searchQuery.isEmpty) return true;
                    return w.name.toLowerCase().contains(_searchQuery) ||
                        (w.code?.toLowerCase().contains(_searchQuery) ??
                            false) ||
                        (w.location?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();

                  if (wings.isEmpty) {
                    return PmsEmptyState(
                      icon: Icons.apartment_outlined,
                      title: 'No wings found',
                      subtitle:
                          'Try another search, or add a new institute wing.',
                      actionLabel:
                          widget.isSuperAdmin ? 'Add Wing' : null,
                      onAction: widget.isSuperAdmin
                          ? () => _showWingForm(context)
                          : null,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final wing = wings[index];
                      return _buildWingCard(context, wing);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWingCard(BuildContext context, WingModel wing) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PmsTheme.primary,
                      PmsTheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: PmsTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wing.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (wing.location != null && wing.location!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: PmsTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              wing.location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: PmsTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (wing.code != null && wing.code!.isNotEmpty)
                PmsStatusChip(
                  label: wing.code!,
                  color: PmsTheme.primary,
                ),
            ],
          ),

          // Geofence & Coordinates details
          if (wing.latitude != null && wing.longitude != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pin_drop_rounded, size: 12, color: PmsTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${wing.latitude!.toStringAsFixed(4)}, ${wing.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar_rounded, size: 12, color: PmsTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${wing.geofenceRadiusMeters}m Geofence',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: PmsTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
                  SizedBox(width: 4),
                  Text(
                    'Geofence not configured',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_location_alt_rounded,
                  tooltip: 'Edit wing & geofence',
                  onPressed: () => _showWingForm(context, wing: wing),
                ),
                const SizedBox(width: 8),
                PmsIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete wing',
                  color: PmsTheme.error,
                  onPressed: () => _confirmDelete(context, wing),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
