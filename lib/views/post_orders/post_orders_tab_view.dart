import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pms/bloc/purchase_request/purchase_request_bloc.dart';
import 'package:pms/bloc/purchase_request/purchase_request_event.dart';
import 'package:pms/bloc/purchase_request/purchase_request_state.dart';
import 'package:pms/models/purchase_request_model.dart';
import 'package:pms/models/user_model.dart';
import 'package:pms/services/api_service.dart';
import 'package:pms/views/post_orders/post_order_details_screen.dart';
import 'package:pms/theme/pms_theme.dart';

class PostOrdersTabView extends StatefulWidget {
  final UserModel? currentUser;
  final bool isSuperAdmin;
  final bool isDesigner;

  const PostOrdersTabView({
    super.key,
    this.currentUser,
    required this.isSuperAdmin,
    this.isDesigner = false,
  });

  @override
  State<PostOrdersTabView> createState() => _PostOrdersTabViewState();
}

class _PostOrdersTabViewState extends State<PostOrdersTabView> {
  String _searchQuery = '';
  int? _selectedWingId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPostOrders();
  }

  void _loadPostOrders() {
    final phone = widget.currentUser?.phone;
    if (widget.isDesigner && widget.currentUser != null) {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(
          designerId: widget.currentUser!.id,
          phone: phone,
        ),
      );
    } else {
      context.read<PurchaseRequestBloc>().add(
        const FetchPurchaseRequestsEvent(),
      );
    }
  }

  String _getAttachmentUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiService.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base/storage/$cleanPath';
  }

  bool _isImage(String? path) {
    if (path == null) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  List<PurchaseRequestModel> _filterPostOrders(
    List<PurchaseRequestModel> allPRs,
  ) {
    final postOrders = allPRs
        .where((pr) => pr.status == 'posted' || pr.isPosted)
        .toList();

    return postOrders.where((pr) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          q.isEmpty ||
          pr.prNumber.toLowerCase().contains(q) ||
          (pr.wing?.name.toLowerCase().contains(q) ?? false) ||
          (pr.assignedDesigner?.name.toLowerCase().contains(q) ?? false) ||
          (pr.postRemarks?.toLowerCase().contains(q) ?? false) ||
          pr.items.any((it) => it.productName.toLowerCase().contains(q));

      final matchesWing =
          _selectedWingId == null || pr.wingId == _selectedWingId;

      return matchesSearch && matchesWing;
    }).toList();
  }

  void _confirmCancelPost(BuildContext context, PurchaseRequestModel pr) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PmsTheme.glassSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFB91C1C), size: 20),
            SizedBox(width: 8),
            Text(
              'Cancel Post Request',
              style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel the post request for ${pr.prNumber}? Status will revert to Approved and move back to the Purchase Requests screen.',
          style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'No, Keep Posted',
              style: TextStyle(color: PmsTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<PurchaseRequestBloc>().add(
                CancelPostPREvent(
                  prId: pr.id,
                  phone: widget.currentUser?.phone,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ Post request for ${pr.prNumber} cancelled. Status reverted to Approved.',
                  ),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Color(0xFFFFFFFF),
            ),
            child: const Text('Cancel Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
      builder: (context, state) {
        final allRequests = state is PurchaseRequestLoaded
            ? state.requests
            : <PurchaseRequestModel>[];
        final filteredOrders = _filterPostOrders(allRequests);

        // Collect unique wings for filter chips
        final wingMap = <int, String>{};
        for (final pr in allRequests) {
          if ((pr.status == 'posted' || pr.isPosted) && pr.wing != null) {
            wingMap[pr.wing!.id] = pr.wing!.name;
          }
        }

        return Column(
          children: [
            // Top Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: PmsTheme.glassSurface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                      color: PmsTheme.textPrimary,
                      fontSize: 13,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search PR #, wing, product, or post remarks...',
                      hintStyle: const TextStyle(
                        color: PmsTheme.textSecondary,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: PmsTheme.textSecondary,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: PmsTheme.textSecondary,
                                size: 16,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: PmsTheme.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: PmsTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: PmsTheme.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: PmsTheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  if (wingMap.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildWingChip('All Wings', null),
                          ...wingMap.entries.map(
                            (w) => _buildWingChip(w.value, w.key),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Post Orders List / Empty State
            Expanded(
              child: RefreshIndicator(
                color: PmsTheme.primary,
                onRefresh: () async {
                  _loadPostOrders();
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: filteredOrders.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F3FF)
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.campaign_outlined,
                                    color: PmsTheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Post Orders Found',
                                  style: TextStyle(
                                    color: PmsTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Approve a Purchase Request and tap "Post It" to forward artwork for digital & social publishing.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: PmsTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final pr = filteredOrders[index];
                          return _buildPostOrderCard(context, pr);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWingChip(String label, int? wingId) {
    final isSelected = _selectedWingId == wingId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedWingId = wingId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? PmsTheme.primary : PmsTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? PmsTheme.primary : PmsTheme.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? PmsTheme.textPrimary : PmsTheme.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostOrderCard(BuildContext context, PurchaseRequestModel pr) {
    final artworkUrl = _getAttachmentUrl(pr.artworkFilePath);
    final isImg = _isImage(pr.artworkFilePath);
    final posterName =
        pr.postedByUser?.name ?? pr.assignedDesigner?.name ?? 'Admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PmsTheme.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostOrderDetailsScreen(
                  postOrder: pr,
                  userProfile: widget.currentUser,
                  isSuperAdmin: widget.isSuperAdmin,
                  isDesigner: widget.isDesigner,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: PR# + Wing + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F3FF).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: PmsTheme.primary),
                            ),
                            child: Text(
                              pr.prNumber,
                              style: const TextStyle(
                                color: PmsTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (pr.wing != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: PmsTheme.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: PmsTheme.glassBorder),
                                ),
                                child: Text(
                                  pr.wing!.name,
                                  style: const TextStyle(
                                    color: PmsTheme.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F3FF).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PmsTheme.primary),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            size: 12,
                            color: PmsTheme.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Posted ✓',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: PmsTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Middle: Artwork Proof & Products Overview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artwork Thumbnail Preview
                    if (pr.artworkFilePath != null &&
                        pr.artworkFilePath!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 58,
                          height: 58,
                          color: PmsTheme.background,
                          child: isImg
                              ? Image.network(
                                  artworkUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: PmsTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Products list
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...pr.items
                              .take(2)
                              .map(
                                (it) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    '• ${it.productName} (Qty: ${it.quantity}${it.size != null ? ', ${it.size}' : ''})',
                                    style: const TextStyle(
                                      color: PmsTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          if (pr.items.length > 2)
                            Text(
                              '+${pr.items.length - 2} more item(s)',
                              style: const TextStyle(
                                color: PmsTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (pr.postRemarks != null &&
                              pr.postRemarks!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Remarks: ${pr.postRemarks!}',
                              style: const TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Divider(height: 1, color: PmsTheme.glassBorder),

                const SizedBox(height: 10),

                // Bottom Row: Publisher info & Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pr.postedAt != null
                            ? 'Posted by $posterName on ${pr.postedAt!.day.toString().padLeft(2, '0')}/${pr.postedAt!.month.toString().padLeft(2, '0')}'
                            : 'Posted by $posterName',
                        style: const TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _confirmCancelPost(context, pr),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFEF2F2).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Color(0xFFDC2626).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'Cancel Post',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: PmsTheme.textPrimary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
