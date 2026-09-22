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
    final nameCtrl = TextEditingController(text: wing?.name ?? '');
    final codeCtrl = TextEditingController(text: wing?.code ?? '');
    final locCtrl = TextEditingController(text: wing?.location ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PmsSheetHeader(
                  title: wing != null
                      ? 'Edit Institute Wing'
                      : 'Add Institute Wing',
                  subtitle: wing != null
                      ? 'Update wing name, code and location'
                      : 'Register a campus or institute wing',
                  onClose: () => Navigator.pop(modalCtx),
                ),
                const SizedBox(height: 8),

                _buildTextField(
                  controller: nameCtrl,
                  label: 'Wing / Campus Name *',
                  hint: 'e.g. Prince Academy (CBSE), PCP Sikar',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: codeCtrl,
                        label: 'Wing Code',
                        hint: 'PA-01, PCP-01',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: locCtrl,
                        label: 'Campus Location',
                        hint: 'Palwas Road, Sikar',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final code = codeCtrl.text.trim();
                    final loc = locCtrl.text.trim();

                    if (name.isEmpty) {
                      showPmsSnackBar(
                        context,
                        'Please enter Wing Name',
                        kind: PmsSnackKind.error,
                      );
                      return;
                    }

                    final payload = {
                      'name': name,
                      'code': code.isNotEmpty ? code : null,
                      'location': loc.isNotEmpty ? loc : null,
                    };

                    if (wing != null) {
                      context.read<WingBloc>().add(
                        UpdateWingEvent(wingId: wing.id, payload: payload),
                      );
                    } else {
                      context.read<WingBloc>().add(CreateWingEvent(payload));
                    }

                    Navigator.pop(modalCtx);
                    showPmsSnackBar(
                      context,
                      wing != null ? '✓ Wing updated!' : '✓ Wing created!',
                      kind: PmsSnackKind.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PmsTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    wing != null ? 'Save Changes' : 'Create Wing',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: PmsTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: PmsTheme.textSecondary,
              fontSize: 12,
            ),
            filled: true,
            fillColor: PmsTheme.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: PmsTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
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

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit wing',
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
