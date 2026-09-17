import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/news_tracking/news_tracking_bloc.dart';
import '../../bloc/news_tracking/news_tracking_event.dart';
import '../../bloc/news_tracking/news_tracking_state.dart';
import '../../models/newspaper_entry_model.dart';
import '../../models/newspaper_model.dart';
import '../../models/user_model.dart';
import '../../models/wing_model.dart';
import 'add_edit_newspaper_entry_dialog.dart';
import '../../theme/pms_theme.dart';

class NewsTrackingTabView extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final String? userPhone;

  const NewsTrackingTabView({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    this.userPhone,
  });

  @override
  State<NewsTrackingTabView> createState() => _NewsTrackingTabViewState();
}

class _NewsTrackingTabViewState extends State<NewsTrackingTabView> {
  final _searchController = TextEditingController();
  int? _selectedWingId;
  int? _selectedNewspaperId;
  int? _selectedSizeId;

  String get _actingPhone =>
      widget.currentUser?.phone ?? widget.userPhone ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<NewsTrackingBloc>().add(
      FetchNewsTrackingDataEvent(
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        wingId: _selectedWingId,
        newspaperId: _selectedNewspaperId,
        sizeId: _selectedSizeId,
        phone: _actingPhone,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddModal(NewsTrackingLoaded state) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditNewspaperEntryDialog(
        wings: state.wings,
        newspapers: state.newspapers,
        sizes: state.sizes,
        phone: _actingPhone,
      ),
    );
  }

  void _openEditModal(NewsTrackingLoaded state, NewspaperEntryModel entry) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditNewspaperEntryDialog(
        entry: entry,
        wings: state.wings,
        newspapers: state.newspapers,
        sizes: state.sizes,
        phone: _actingPhone,
      ),
    );
  }

  void _deleteEntry(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this newspaper entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NewsTrackingBloc>().add(
                DeleteNewsEntryEvent(id: id, phone: _actingPhone),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open link: $url')),
            );
          }
        }
      }
    }
  }

  void _viewMedia(String rawUrl, String title) {
    String url = rawUrl.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.toLowerCase().endsWith('.pdf')) {
      _launchUrl(url);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: 'Open in browser',
                    onPressed: () => _launchUrl(url),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('Failed to load image preview'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _launchUrl(url),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open direct link'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewsTrackingBloc, NewsTrackingState>(
      listener: (context, state) {
        if (state is NewsTrackingActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else if (state is NewsTrackingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE11D48),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is NewsTrackingLoading) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          );
        }

        if (state is NewsTrackingLoaded) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: const Color(0xFF059669),
              child: CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Add button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                        ),
                                        child: const Text(
                                          'Press & Media',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'News Tracking',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: PmsTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () => _openAddModal(state),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Add Entry',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // KPI Cards
                          Row(
                            children: [
                              _buildKpiCard(
                                title: 'Total Ads',
                                value: '${state.totalEntries}',
                                color: const Color(0xFF059669),
                                icon: Icons.newspaper_rounded,
                              ),
                              const SizedBox(width: 8),
                              _buildKpiCard(
                                title: 'This Month',
                                value: '${state.thisMonthEntries}',
                                color: PmsTheme.primary,
                                icon: Icons.calendar_today_rounded,
                              ),
                              const SizedBox(width: 8),
                              _buildKpiCard(
                                title: 'Newspapers',
                                value: '${state.totalNewspapers}',
                                color: PmsTheme.secondary,
                                icon: Icons.layers_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (v) => _loadData(),
                            decoration: InputDecoration(
                              hintText: 'Search ad campaign, remarks...',
                              prefixIcon: const Icon(Icons.search, size: 20, color: PmsTheme.textSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _loadData();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: PmsTheme.glassBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: PmsTheme.glassBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Quick filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Wing filter
                                FilterChip(
                                  label: Text(
                                    _selectedWingId == null
                                        ? 'All Wings'
                                        : state.wings
                                            .firstWhere(
                                              (w) => w.id == _selectedWingId,
                                              orElse: () => WingModel(id: 0, name: 'Wing'),
                                            )
                                            .name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedWingId != null
                                          ? const Color(0xFF059669)
                                          : PmsTheme.textSecondary,
                                    ),
                                  ),
                                  selected: _selectedWingId != null,
                                  onSelected: (selected) {
                                    _showWingSelector(state);
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Newspaper filter
                                FilterChip(
                                  label: Text(
                                    _selectedNewspaperId == null
                                        ? 'All Publications'
                                        : state.newspapers
                                            .firstWhere(
                                              (n) => n.id == _selectedNewspaperId,
                                              orElse: () => const NewspaperModel(id: 0, name: 'Paper'),
                                            )
                                            .name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedNewspaperId != null
                                          ? const Color(0xFF059669)
                                          : PmsTheme.textSecondary,
                                    ),
                                  ),
                                  selected: _selectedNewspaperId != null,
                                  onSelected: (selected) {
                                    _showNewspaperSelector(state);
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Reset filters
                                if (_selectedWingId != null ||
                                    _selectedNewspaperId != null ||
                                    _selectedSizeId != null)
                                  ActionChip(
                                    avatar: const Icon(Icons.close, size: 14, color: Color(0xFFE11D48)),
                                    label: const Text(
                                      'Clear',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedWingId = null;
                                        _selectedNewspaperId = null;
                                        _selectedSizeId = null;
                                      });
                                      _loadData();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Entries List
                  if (state.entries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: PmsTheme.bgSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.newspaper_rounded,
                                size: 32,
                                color: PmsTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No newspaper entries found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try changing filters or add a new entry',
                              style: TextStyle(fontSize: 12, color: PmsTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = state.entries[index];
                            return _buildEntryCard(state, entry);
                          },
                          childCount: state.entries.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Initialize News Tracking...')),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: PmsTheme.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PmsTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: PmsTheme.textSecondary,
                  ),
                ),
                Icon(icon, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(NewsTrackingLoaded state, NewspaperEntryModel item) {
    final dateFormat = DateFormat('dd MMM yyyy');
    DateTime? dt = DateTime.tryParse(item.publishDate);
    final dateDisplay = dt != null ? dateFormat.format(dt) : item.publishDate;

    final hasFile = item.computedFileUrl != null && item.computedFileUrl!.isNotEmpty;
    final hasLink1 = item.link1 != null && item.link1!.isNotEmpty;
    final hasLink2 = item.link2 != null && item.link2!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges (Wing, Publication, Size, Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Wing badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PmsTheme.backgroundGradientStart,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          item.wing?.name ?? 'Unassigned Wing',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.primaryDark,
                          ),
                        ),
                      ),
                      // Newspaper badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Text(
                          item.newspaper?.name ?? 'Publication',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                      ),
                      // Size badge
                      if (item.newspaperSize?.name != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PmsTheme.bgSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.newspaperSize!.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: PmsTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  dateDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: PmsTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ad Campaign Title
            Text(
              item.adName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: PmsTheme.textPrimary,
              ),
            ),

            if (item.remark != null && item.remark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.remark!,
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: PmsTheme.bgSoft),
            const SizedBox(height: 10),

            // Action / Link buttons row
            Row(
              children: [
                if (hasFile) ...[
                  InkWell(
                    onTap: () => _viewMedia(item.computedFileUrl!, item.adName),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Clipping',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                if (hasLink1) ...[
                  InkWell(
                    onTap: () {
                      final l1 = item.link1!;
                      if (l1.contains(RegExp(r'\.(jpg|jpeg|png|webp|gif)$', caseSensitive: false))) {
                        _viewMedia(l1, '${item.adName} (Link 1)');
                      } else {
                        _launchUrl(l1);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PmsTheme.backgroundGradientStart,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, size: 14, color: PmsTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Link 1',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: PmsTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                if (hasLink2) ...[
                  InkWell(
                    onTap: () {
                      final l2 = item.link2!;
                      if (l2.contains(RegExp(r'\.(jpg|jpeg|png|webp|gif)$', caseSensitive: false))) {
                        _viewMedia(l2, '${item.adName} (Link 2)');
                      } else {
                        _launchUrl(l2);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_outlined, size: 14, color: Color(0xFF9333EA)),
                          SizedBox(width: 4),
                          Text(
                            'Link 2',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Edit & Delete
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: PmsTheme.textSecondary),
                  tooltip: 'Edit Entry',
                  onPressed: () => _openEditModal(state, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE11D48)),
                  tooltip: 'Delete Entry',
                  onPressed: () => _deleteEntry(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWingSelector(NewsTrackingLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter by Campus Wing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('All Wings', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedWingId == null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedWingId = null);
                _loadData();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.wings.length,
                itemBuilder: (context, idx) {
                  final w = state.wings[idx];
                  return ListTile(
                    title: Text(w.name),
                    selected: _selectedWingId == w.id,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedWingId = w.id);
                      _loadData();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewspaperSelector(NewsTrackingLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter by Publication',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('All Publications', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNewspaperId == null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedNewspaperId = null);
                _loadData();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.newspapers.length,
                itemBuilder: (context, idx) {
                  final n = state.newspapers[idx];
                  return ListTile(
                    title: Text(n.name),
                    selected: _selectedNewspaperId == n.id,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedNewspaperId = n.id);
                      _loadData();
                    },
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
