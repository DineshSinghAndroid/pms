import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/print_order/print_order_bloc.dart';
import '../../bloc/print_order/print_order_event.dart';
import '../../bloc/purchase_request/purchase_request_bloc.dart';
import '../../bloc/purchase_request/purchase_request_event.dart';
import '../../bloc/purchase_request/purchase_request_state.dart';
import '../../models/print_order_model.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../models/purchase_request_model.dart';
import '../../models/user_model.dart';
import '../../models/vendor_model.dart';
import '../../repositories/print_order_repository.dart';
import '../../repositories/purchase_request_repository.dart';
import '../../repositories/vendor_repository.dart';
import '../../services/api_service.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/app_gradient_background.dart';
import '../print_orders/print_order_details_screen.dart';

class PRDetailsScreen extends StatefulWidget {
  final int prId;
  final bool isSuperAdmin;
  final UserModel? currentUser;

  const PRDetailsScreen({
    super.key,
    required this.prId,
    this.isSuperAdmin = false,
    this.currentUser,
  });

  @override
  State<PRDetailsScreen> createState() => _PRDetailsScreenState();
}

class _PRDetailsScreenState extends State<PRDetailsScreen> {
  bool get isDesigner =>
      widget.currentUser?.role.toLowerCase().trim() == 'designer';
  bool get isManager =>
      widget.currentUser?.role.toLowerCase().trim() == 'manager';
  bool get isSuperAdmin =>
      widget.isSuperAdmin ||
      widget.currentUser?.isSuperAdmin == true ||
      widget.currentUser?.role.toLowerCase().trim() == 'superadmin' ||
      widget.currentUser?.role.toLowerCase().trim() == 'super admin' ||
      widget.currentUser?.role.toLowerCase().trim() == 'super_admin';
  bool get isAdmin =>
      widget.currentUser?.role.toLowerCase().trim() == 'admin';
  bool get isDigitalStudioIncharge =>
      widget.currentUser?.role.toLowerCase().trim() == 'digital studio incharge' ||
      widget.currentUser?.role.toLowerCase().trim() == 'digital_studio_incharge';
  bool get canAssignDesigner =>
      isSuperAdmin || isAdmin || isManager || isDigitalStudioIncharge;
  bool canReassignDesigner(PurchaseRequestModel pr) =>
      canAssignDesigner && !pr.isDesignerAssignmentLocked;
  bool get isAdminOrManager => isSuperAdmin || isAdmin || isManager;
  bool get canReviewArtwork => isAdminOrManager;
  bool get canWorkOnArtwork => isDesigner;

  @override
  void initState() {
    super.initState();
    if (canAssignDesigner) {
      PurchaseRequestRepository().getDesigners();
    }
  }

  String _getAttachmentUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    if (clean.startsWith('storage/')) {
      return '${ApiService.baseUrl}/$clean';
    }
    return '${ApiService.baseUrl}/storage/$clean';
  }

  String _getMediaType(String? path) {
    if (path == null || path.isEmpty) return 'other';
    final lower = path.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm')) {
      return 'video';
    }
    if (lower.endsWith('.pdf')) {
      return 'pdf';
    }
    return 'document';
  }

  bool _isImage(String? path) => _getMediaType(path) == 'image';

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_monthName(local.month)} ${local.year}, $hour:$minuteStr $ampm';
  }

  bool _isPRCreator(PurchaseRequestModel pr) {
    if (widget.currentUser == null) return false;
    if (pr.createdByUserId != null &&
        pr.createdByUserId == widget.currentUser!.id) {
      return true;
    }
    if (pr.createdByUser != null &&
        pr.createdByUser!.id == widget.currentUser!.id) {
      return true;
    }
    if (pr.createdByUser?.phone != null &&
        pr.createdByUser!.phone == widget.currentUser!.phone) {
      return true;
    }
    return false;
  }

  bool _isPRDesigner(PurchaseRequestModel pr) {
    if (widget.currentUser == null) return false;
    final uid = widget.currentUser!.id;
    final phone = widget.currentUser!.phone;
    return isDesigner &&
        (pr.assignedDesignerId == uid ||
            pr.workStartedByUserId == uid ||
            (pr.assignedDesigner?.phone != null &&
                pr.assignedDesigner!.phone == phone) ||
            (pr.workStartedByUser?.phone != null &&
                pr.workStartedByUser!.phone == phone) ||
            pr.createdByUserId == uid);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file URL.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: PmsTheme.glassSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: PmsTheme.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      final total = loadingProgress.expectedTotalBytes;
                      final loaded = loadingProgress.cumulativeBytesLoaded;
                      return Container(
                        height: 200,
                        color: PmsTheme.background,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: PmsTheme.primary,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                total != null
                                    ? 'Loading image (${(loaded / (1024 * 1024)).toStringAsFixed(1)} / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB)...'
                                    : 'Loading image...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PmsTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        padding: const EdgeInsets.all(16),
                        color: PmsTheme.glassSurface,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFFDC2626),
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unable to preview image directly.',
                                style: TextStyle(
                                  color: PmsTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _openExternalUrl(imageUrl),
                                child: const Text(
                                  'Tap here to open in external viewer',
                                  style: TextStyle(
                                    color: PmsTheme.primary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openExternalUrl(imageUrl),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text(
                        'Open Full File',
                        style: TextStyle(fontSize: 12),
                      ),
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

  void _showSubmitWorkModal(BuildContext context, PurchaseRequestModel pr) {
    final remarksCtrl = TextEditingController();
    Uint8List? pickedBytes;
    String? pickedName;
    int? pickedSize;
    String? pickedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              color: PmsTheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pr.revisionCount > 0
                                  ? 'Resubmit Artwork (Rev #${pr.revisionCount + 1})'
                                  : 'Submit Artwork for Approval',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: PmsTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: PmsTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(bottomCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Admin Feedback if revision
                    if (pr.adminReviewRemarks != null &&
                        pr.status == 'rejected_revision_needed') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF2F2).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFDC2626).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Admin Feedback to Fix:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pr.adminReviewRemarks!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: PmsTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ATTACH MEDIA SECTION (2 OPTIONS: CLICK / CAMERA or EXPLORE FILES)
                    const Text(
                      'Attach Media / Proof (No upload limit · Image, Video, PDF, Any File)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Option 1: Click / Camera
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final photo = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 100,
                              );
                              if (photo != null) {
                                final bytes = await photo.readAsBytes();
                                setModalState(() {
                                  pickedBytes = bytes;
                                  pickedName = photo.name;
                                  pickedSize = bytes.length;
                                  pickedType = 'image';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: PmsTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: PmsTheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: PmsTheme.primary,
                                    size: 22,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Click / Camera',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: PmsTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Take live photo',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: PmsTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Option 2: Explore / Files (Any Image, Video, PDF, PSD, AI, ZIP)
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final file = await FilePicker.pickFile(
                                type: FileType.any,
                              );
                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                final size = await file.length();
                                setModalState(() {
                                  pickedBytes = bytes;
                                  pickedName = file.name;
                                  pickedSize = size;
                                  pickedType = _getMediaType(file.name);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: PmsTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: PmsTheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.folder_open_rounded,
                                    color: PmsTheme.primary,
                                    size: 22,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Explore Files',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: PmsTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Gallery, PDF, Video',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: PmsTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ATTACHED FILE PREVIEW CARD
                    if (pickedBytes != null && pickedName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PmsTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF059669)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        pickedType == 'image'
                                            ? Icons.image_rounded
                                            : pickedType == 'video'
                                            ? Icons.videocam_rounded
                                            : pickedType == 'pdf'
                                            ? Icons.picture_as_pdf_rounded
                                            : Icons.insert_drive_file_rounded,
                                        color: Color(0xFF059669),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pickedName!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: PmsTheme.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${pickedSize != null ? _formatFileSize(pickedSize!) : ''} · Ready to upload',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFB91C1C),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      pickedBytes = null;
                                      pickedName = null;
                                      pickedSize = null;
                                      pickedType = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (pickedType == 'image' &&
                                pickedBytes != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  pickedBytes!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Submission Remarks
                    const Text(
                      'Designer Notes & Submission Remarks *',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remarksCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PmsTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe artwork layout, media specs, color profiles, or corrections...',
                        hintStyle: const TextStyle(
                          color: PmsTheme.textSecondary,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: PmsTheme.background,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: PmsTheme.glassBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: () {
                        final remarks = remarksCtrl.text.trim();
                        final artName =
                            pickedName ?? 'artwork_${pr.prNumber}.png';

                        context.read<PurchaseRequestBloc>().add(
                          SubmitWorkEvent(
                            prId: pr.id,
                            remarks: remarks.isNotEmpty ? remarks : 'Artwork completed and submitted for admin review.',
                            artworkPath: artName,
                            artworkName: artName,
                            fileBytes: pickedBytes,
                            phone: widget.currentUser?.phone,
                            designerId: widget.currentUser?.id,
                          ),
                        );

                        Navigator.pop(bottomCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '✓ Artwork submitted to Super Admin for approval!',
                            ),
                            backgroundColor: PmsTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send to Admin for Approval'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PmsTheme.primary,
                        foregroundColor: Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, PurchaseRequestModel pr) {
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.assignment_return_rounded,
                color: Color(0xFFB91C1C),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Request Revision',
                style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter revision comments for Designer (${pr.assignedDesigner?.name ?? 'Designer'}):',
                style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: PmsTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Specify exact changes needed (e.g. font size, logo color, margin)...',
                  hintStyle: const TextStyle(
                    color: PmsTheme.textSecondary,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: PmsTheme.background,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: PmsTheme.glassBorder),
                  ),
                ),
              ),
            ],
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
                final remarks = remarksCtrl.text.trim();
                final finalRemarks = remarks.isNotEmpty
                    ? remarks
                    : 'Revision requested. Please review and make necessary changes.';

                context.read<PurchaseRequestBloc>().add(
                  RejectRevisionPREvent(
                    prId: pr.id,
                    remarks: finalRemarks,
                    phone: widget.currentUser?.phone,
                  ),
                );

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✓ PR ${pr.prNumber} returned to Designer with revision notes.',
                    ),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC2626),
                foregroundColor: Color(0xFFFFFFFF),
              ),
              child: const Text('Return to Designer'),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, PurchaseRequestModel pr) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Approve Artwork',
                style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to approve the artwork for PR ${pr.prNumber}? This will mark the design phase as completed.',
            style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
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
                context.read<PurchaseRequestBloc>().add(
                  ApprovePREvent(
                    prId: pr.id,
                    remarks: 'Artwork approved for printing.',
                    phone: widget.currentUser?.phone,
                  ),
                );

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ PR ${pr.prNumber} approved successfully!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF059669),
                foregroundColor: Color(0xFFFFFFFF),
              ),
              child: const Text('Confirm Approval'),
            ),
          ],
        );
      },
    );
  }

  // ================= ASSIGN DESIGNER MODAL =================
  void _showAssignDesignerDialog(
    BuildContext context,
    PurchaseRequestModel pr,
  ) async {
    if (pr.isDesignerAssignmentLocked) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pr.prNumber} is already ${pr.status.replaceAll('_', ' ')} and cannot be reassigned.',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    List<UserModel> designers = PurchaseRequestRepository.cachedDesigners ?? [];

    if (designers.isEmpty) {
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        designers = userState.users
            .where((u) =>
                (u.isDesigner ||
                    u.role.toLowerCase().contains('designer') ||
                    u.role.toLowerCase().contains('studio')) &&
                u.isActive)
            .toList();
      }
    }

    if (designers.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD97706)),
        ),
      );
      try {
        designers = await PurchaseRequestRepository().getDesigners();
      } catch (e) {
        debugPrint('Error fetching designers: $e');
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    if (!context.mounted) return;

    if (designers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active Designer users found. Please create or activate a Designer in Admin Portal.',
          ),
          backgroundColor: Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int chosenDesignerId = pr.assignedDesignerId ?? designers.first.id;
    if (!designers.any((d) => d.id == chosenDesignerId)) {
      chosenDesignerId = designers.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: PmsTheme.glassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_pin_rounded,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr.assignedDesigner != null
                              ? 'Re-assign Designer'
                              : 'Assign Designer',
                          style: const TextStyle(
                            color: PmsTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pr.prNumber,
                          style: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a Designer for Wing "${pr.wing?.name ?? 'General'}":',
                    style: const TextStyle(
                      color: PmsTheme.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PmsTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: chosenDesignerId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFFFFFFF),
                        style: const TextStyle(
                          fontSize: 13,
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        items: designers.map((d) {
                          final roleLabel = d.role == 'Designer' ? '' : ' [${d.role}]';
                          return DropdownMenuItem<int>(
                            value: d.id,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.brush_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.name}$roleLabel (${d.phone})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => chosenDesignerId = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: PmsTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    context.read<PurchaseRequestBloc>().add(
                          AssignDesignerEvent(
                            prId: pr.id,
                            designerId: chosenDesignerId,
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ PR ${pr.prNumber} assigned to Designer!',
                        ),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text(
                    'Confirm Assignment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    final bloc = context.read<PurchaseRequestBloc>();
    if (widget.currentUser != null && widget.currentUser!.role == 'Designer') {
      bloc.add(
        FetchPurchaseRequestsEvent(
          designerId: widget.currentUser!.id,
          phone: widget.currentUser!.phone,
        ),
      );
    } else if (widget.currentUser != null &&
        widget.currentUser!.isWingIncharge) {
      bloc.add(
        FetchPurchaseRequestsEvent(
          phone: widget.currentUser!.phone,
        ),
      );
    } else {
      bloc.add(const FetchPurchaseRequestsEvent());
    }

    try {
      await PurchaseRequestRepository().getPurchaseRequestDetails(widget.prId);
    } catch (_) {}

    await bloc.stream.firstWhere(
      (s) => s is PurchaseRequestLoaded || s is PurchaseRequestError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: PmsTheme.glassSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: PmsTheme.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PR Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: PmsTheme.textPrimary,
          ),
        ),
      ),
      body: BlocBuilder<PurchaseRequestBloc, PurchaseRequestState>(
        builder: (context, state) {
          if (state is PurchaseRequestLoading) {
            return const Center(
              child: CircularProgressIndicator(color: PmsTheme.primary),
            );
          }

          if (state is PurchaseRequestLoaded) {
            final prList = state.requests
                .where((x) => x.id == widget.prId)
                .toList();
            if (prList.isEmpty) {
              return RefreshIndicator(
                color: PmsTheme.primary,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Text(
                      'Purchase Request not found. Pull to refresh.',
                      style: TextStyle(color: PmsTheme.textSecondary),
                    ),
                  ),
                ),
              );
            }

            final pr = prList.first;
            return _buildPRDetailsContent(context, pr);
          }

          return RefreshIndicator(
            color: PmsTheme.primary,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                child: const Text(
                  'Error loading PR details. Pull to retry.',
                  style: TextStyle(color: PmsTheme.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildPRDetailsContent(BuildContext context, PurchaseRequestModel pr) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: PmsTheme.primary,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP PR HEADER & SUMMARY CARD
                  _buildHeaderCard(pr),

                const SizedBox(height: 12),

                // 2. LIVE DESIGN PHASE / ACTIVE REVIEW STATE
                _buildLiveStateCard(context, pr),

                const SizedBox(height: 12),

                // 3. ORDER SPECIFICATIONS & REQUESTED MATERIAL
                _buildOrderSpecificationsCard(context, pr),

                const SizedBox(height: 12),

                // 4. AUDIT TRAIL & REVISION TIMELINE (Compact & Clean)
                _buildAuditTrailTimeline(context, pr),
              ],
            ),
          ),
        ),
      ),

        // 5. STICKY BOTTOM ACTION FOOTER
        _buildBottomActionBar(context, pr),
      ],
    );
  }

  /// 1. Top Header Card
  Widget _buildHeaderCard(PurchaseRequestModel pr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PmsTheme.glassBorder),
                ),
                child: Text(
                  pr.prNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
              _buildStatusBadge(pr.status, pr),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: PmsTheme.glassBorder, height: 1),
          const SizedBox(height: 12),

          // Meta Grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campus / Wing',
                      style: TextStyle(fontSize: 10, color: PmsTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pr.wing?.name ?? 'General Wing',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requested By',
                      style: TextStyle(fontSize: 10, color: PmsTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pr.createdByUser?.name ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected Delivery',
                      style: TextStyle(fontSize: 10, color: PmsTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pr.expectedDeliveryDate ?? 'N/A'} (${pr.expectedDeliveryTime ?? 'Anytime'})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Assigned Designer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: PmsTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PmsTheme.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: pr.assignedDesigner != null
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    pr.assignedDesigner != null
                        ? Icons.brush_rounded
                        : Icons.person_off_outlined,
                    color: pr.assignedDesigner != null
                        ? PmsTheme.primary
                        : const Color(0xFFD97706),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.assignedDesigner != null
                            ? 'ASSIGNED DESIGNER'
                            : 'DESIGNER STATUS',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pr.assignedDesigner != null
                            ? '${pr.assignedDesigner!.name} (${pr.assignedDesigner!.phone})'
                            : 'Unassigned (Assignment Needed)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pr.assignedDesigner != null
                              ? PmsTheme.textPrimary
                              : const Color(0xFFD97706),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (canReassignDesigner(pr)) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignDesignerDialog(context, pr),
                    icon: Icon(
                      pr.assignedDesigner != null
                          ? Icons.swap_horiz_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 16,
                      
                    ),
                    label: Text(
                      pr.assignedDesigner != null ? 'Re-assign' : 'Assign',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pr.assignedDesigner != null
                          ? PmsTheme.primary
                          : const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 1.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Live Design Phase / Active Review State Card
  Widget _buildLiveStateCard(BuildContext context, PurchaseRequestModel pr) {
    if (pr.status == 'rejected_revision_needed') {
      final hasArtwork =
          pr.artworkFilePath != null && pr.artworkFilePath!.isNotEmpty;
      final fileUrl = hasArtwork ? _getAttachmentUrl(pr.artworkFilePath) : '';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFFFEF2F2).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFDC2626).withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_return_rounded,
                  color: Color(0xFFB91C1C),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Admin Revision Feedback (Revision #${pr.revisionCount > 0 ? pr.revisionCount : 1})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              pr.adminReviewRemarks ??
                  'Please review requested changes and submit revised artwork.',
              style: const TextStyle(
                fontSize: 12,
                color: PmsTheme.textPrimary,
                height: 1.3,
              ),
            ),
            if (hasArtwork) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  if (_isImage(pr.artworkFilePath)) {
                    _showImageDialog(
                      context,
                      fileUrl,
                      pr.artworkFileName ?? 'Previous Artwork',
                    );
                  } else {
                    _openExternalUrl(fileUrl);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PmsTheme.glassSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PmsTheme.textSecondary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        color: PmsTheme.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'View Last Submitted File \n(${pr.artworkFileName ?? 'Artwork'})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: PmsTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (pr.status == 'submitted_for_approval') {
      final fileUrl = _getAttachmentUrl(pr.artworkFilePath);
      final isImg = _isImage(pr.artworkFilePath);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFFF5F3FF).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PmsTheme.primary.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: PmsTheme.textSecondary,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Artwork Proof Submitted for Approval',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isImg)
                  InkWell(
                    onTap: () => _showImageDialog(
                      context,
                      fileUrl,
                      'Artwork Proof - ${pr.prNumber}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PmsTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'View Image',
                        style: TextStyle(
                          fontSize: 10,
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _openExternalUrl(fileUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PmsTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Open File',
                        style: TextStyle(
                          fontSize: 10,
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'File: ${pr.artworkFileName ?? pr.artworkFilePath ?? 'artwork_upload'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: PmsTheme.textPrimary,
              ),
            ),
            if (pr.designerSubmissionRemarks != null &&
                pr.designerSubmissionRemarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Designer Note: ${pr.designerSubmissionRemarks}',
                style: const TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
              ),
            ],
            if (isImg && fileUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showImageDialog(
                  context,
                  fileUrl,
                  'Artwork Proof - ${pr.prNumber}',
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fileUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: PmsTheme.bgSoft,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: PmsTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (pr.status == 'approved' ||
        pr.status == 'sent_to_print' ||
        pr.status == 'posted' ||
        pr.status == 'completed') {
      final fileUrl = _getAttachmentUrl(pr.artworkFilePath);
      final isImg = _isImage(pr.artworkFilePath);

      String title = 'Approved Artwork';
      Color headerColor = Color(0xFF059669);
      IconData headerIcon = Icons.check_circle_rounded;
      if (pr.status == 'sent_to_print') {
        title = 'Dispatched to Print Vendor';
        headerColor = PmsTheme.primary;
        headerIcon = Icons.print_rounded;
      } else if (pr.status == 'posted') {
        title = 'Forwarded for Post Publishing';
        headerColor = PmsTheme.textSecondary;
        headerIcon = Icons.campaign_rounded;
      } else if (pr.status == 'completed') {
        title = 'Completed & Delivered';
        headerColor = Color(0xFF059669);
        headerIcon = Icons.task_alt_rounded;
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFFECFDF5).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF059669).withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(headerIcon, color: headerColor, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (pr.artworkFilePath != null &&
                    pr.artworkFilePath!.isNotEmpty)
                  InkWell(
                    onTap: () {
                      if (isImg) {
                        _showImageDialog(context, fileUrl, 'Approved Artwork');
                      } else {
                        _openExternalUrl(fileUrl);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'View Artwork',
                        style: TextStyle(
                          fontSize: 10,
                          color: PmsTheme.textPrimary,
                          fontWeight: FontWeight.bold,
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

    if (pr.status == 'in_progress') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PmsTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.brush_rounded, color: PmsTheme.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Design work in progress by ${pr.workStartedByUser?.name ?? pr.assignedDesigner?.name ?? 'Designer'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: PmsTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (pr.status == 'pending_assignment') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFCD34D),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designer Assignment Pending',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Assign an active Designer to begin artwork creation.',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canReassignDesigner(pr)) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _showAssignDesignerDialog(context, pr),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  'Assign Designer to this PR',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (pr.status == 'assigned_to_designer') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: PmsTheme.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PmsTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: PmsTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.assignedDesigner != null
                            ? 'Assigned to: ${pr.assignedDesigner!.name}'
                            : 'Assigned to Designer',
                        style: const TextStyle(
                          color: PmsTheme.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pending Work Start by Designer',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canReassignDesigner(pr)) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showAssignDesignerDialog(context, pr),
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text(
                  'Re-assign to Another Designer',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PmsTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// 3. Order Specifications & Requested Products Card
  Widget _buildOrderSpecificationsCard(
    BuildContext context,
    PurchaseRequestModel pr,
  ) {
    // Manager and Admin ALWAYS see task details without lock. Only non-admin designers see lock before work starts.
    final bool isLockedForDesigner = !isAdminOrManager &&
        isDesigner &&
        (pr.status == 'assigned_to_designer' || pr.status == 'pending_assignment');

    if (isLockedForDesigner) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PmsTheme.warning),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFFD97706),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Task Details Locked',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Work has not been started yet. Click the button below to start work and unlock all material specifications, product dimensions, remarks, and reference proofs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFB45309),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PurchaseRequestBloc>().add(
                  StartWorkEvent(
                    prId: pr.id,
                    phone: widget.currentUser?.phone,
                    designerId: widget.currentUser?.id,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✓ Work started! Task specifications unlocked.',
                    ),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text(
                'Start Work (Unlock Details)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Requested Material & Specs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pr.items.length} item(s)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: PmsTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Requester Instructions / Remarks
          if (pr.remarks != null && pr.remarks!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PmsTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        color: PmsTheme.primary,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Requester Order Instructions',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pr.remarks!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PmsTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Product Items List
          ...pr.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final it = entry.value;
            final attachmentUrl = _getAttachmentUrl(it.attachmentPath);
            final isImg = _isImage(it.attachmentPath);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PmsTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PmsTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (it.productType?.productCode != null)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: PmsTheme.glassSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  it.productType!.productCode!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                '#${idx + 1}. ${it.productName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PmsTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFDC2626).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Qty: ${it.quantity}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    it.size != null && it.size!.isNotEmpty
                        ? 'Size: ${it.size}'
                        : 'Size: Not specified',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PmsTheme.textSecondary,
                    ),
                  ),

                  // Optional Sample Attachment
                  if (it.attachmentPath != null &&
                      it.attachmentPath!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Sample: ${it.attachmentName ?? it.attachmentPath}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: PmsTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (isImg) {
                              _showImageDialog(
                                context,
                                attachmentUrl,
                                it.productName,
                              );
                            } else {
                              _openExternalUrl(attachmentUrl);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PmsTheme.glassBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'View Sample',
                              style: TextStyle(
                                fontSize: 9,
                                color: PmsTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 4. Compact Audit Trail & Revision Timeline
  Widget _buildAuditTrailTimeline(
    BuildContext context,
    PurchaseRequestModel pr,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: PmsTheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Audit Trail & Revision History',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (pr.revisionCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFDC2626).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Revisions: ${pr.revisionCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (pr.activities.isEmpty)
            const Text(
              'No activity logs recorded yet.',
              style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
            )
          else
            ...pr.activities.map((act) {
              final actDate = _formatDateTime(act.createdAt);

              Color badgeBg = PmsTheme.background;
              Color badgeBorder = PmsTheme.glassBorder;
              Color badgeText = PmsTheme.textSecondary;
              String actionTitle = act.action;

              if (act.action == 'work_started') {
                badgeBg = PmsTheme.backgroundGradientStart.withValues(alpha: 0.4);
                badgeBorder = PmsTheme.primary;
                badgeText = PmsTheme.primary;
                actionTitle = 'Work Started';
              } else if (act.action == 'submitted_for_approval') {
                badgeBg = Color(0xFFF5F3FF).withValues(alpha: 0.4);
                badgeBorder = PmsTheme.primary;
                badgeText = PmsTheme.textSecondary;
                actionTitle = 'Artwork Submitted';
              } else if (act.action == 'rejected_with_revision') {
                badgeBg = Color(0xFFFEF2F2).withValues(alpha: 0.4);
                badgeBorder = Color(0xFFDC2626);
                badgeText = Color(0xFFB91C1C);
                actionTitle = 'Revision Requested';
              } else if (act.action == 'approved') {
                badgeBg = Color(0xFFECFDF5).withValues(alpha: 0.4);
                badgeBorder = Color(0xFF059669);
                badgeText = Color(0xFF059669);
                actionTitle = 'Approved';
              }

              final hasActAttach =
                  act.attachmentPath != null && act.attachmentPath!.isNotEmpty;
              final actUrl = hasActAttach
                  ? _getAttachmentUrl(act.attachmentPath)
                  : '';
              final isActImg = hasActAttach && _isImage(act.attachmentPath);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PmsTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            actionTitle,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ),
                        Text(
                          actDate,
                          style: const TextStyle(
                            fontSize: 10,
                            color: PmsTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (act.remarks != null && act.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _sanitizeAuditRemarks(act.remarks!, pr),
                        style: const TextStyle(
                          fontSize: 11,
                          color: PmsTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (hasActAttach) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          if (isActImg) {
                            _showImageDialog(
                              context,
                              actUrl,
                              act.attachmentName ?? 'Proof',
                            );
                          } else {
                            _openExternalUrl(actUrl);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.glassSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: PmsTheme.textSecondary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActImg
                                    ? Icons.image_rounded
                                    : Icons.attach_file_rounded,
                                size: 12,
                                color: PmsTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'View Attached Proof \n(${act.attachmentName ?? 'File'})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: PmsTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _sanitizeAuditRemarks(String remarks, PurchaseRequestModel pr) {
    if (isAdminOrManager) return remarks;

    String sanitized = remarks;

    final vendorNames = <String>{};
    if (pr.activePrintOrder?.vendor?.name != null &&
        pr.activePrintOrder!.vendor!.name.isNotEmpty) {
      vendorNames.add(pr.activePrintOrder!.vendor!.name);
    }
    for (final po in pr.printOrders) {
      if (po.vendor?.name != null && po.vendor!.name.isNotEmpty) {
        vendorNames.add(po.vendor!.name);
      }
    }

    for (final vName in vendorNames) {
      final trimmed = vName.trim();
      if (trimmed.isNotEmpty && trimmed != 'XXXX' && !trimmed.contains('XXXX')) {
        sanitized = sanitized.replaceAll(
          RegExp(RegExp.escape(trimmed), caseSensitive: false),
          'XXXX',
        );
      }
    }

    sanitized = sanitized.replaceAll(
      RegExp(r"Vendor\s*['\x22][^'\x22]+['\x22]", caseSensitive: false),
      "Vendor 'XXXX'",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"dispatched to Vendor\s+[^\s,;]+(?:\s+[^\s,;]+)*\s+by", caseSensitive: false),
      "dispatched to Vendor 'XXXX' by",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+Vendor\s+[^,;\n\r]+\s+was cancelled", caseSensitive: false),
      "to Printing Vendor was cancelled",
    );
    sanitized = sanitized.replaceAll(
      RegExp(r"to\s+[^,;\n\r]+\s+was cancelled", caseSensitive: false),
      "to Printing Vendor was cancelled",
    );

    return sanitized;
  }

  Widget _buildBottomActionBar(BuildContext context, PurchaseRequestModel pr) {
    final bool isCreatorWingIncharge =
        widget.currentUser?.isWingIncharge == true && _isPRCreator(pr);
    final bool isAssignedDesigner = isDesigner && _isPRDesigner(pr);
    final bool canReviewThisPR = canReviewArtwork || isCreatorWingIncharge;
    final bool canDispatchApproved =
        widget.isSuperAdmin || isManager || isAssignedDesigner;

    // 1. DESIGNER & CREATIVE EXECUTION ACTIONS (Only for Designers when NOT Admin/Manager)
    if (isDesigner && !isAdminOrManager) {
      if (pr.status == 'assigned_to_designer' ||
          pr.status == 'pending_assignment') {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: PmsTheme.glassSurface,
            border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<PurchaseRequestBloc>().add(
                StartWorkEvent(
                  prId: pr.id,
                  phone: widget.currentUser?.phone,
                  designerId: widget.currentUser?.id,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✓ Work started! Task details unlocked.',
                  ),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text(
              '🔒 Start Work (Unlock Task Details)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }

      if (pr.status == 'in_progress' ||
          pr.status == 'rejected_revision_needed') {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: PmsTheme.glassSurface,
            border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showSubmitWorkModal(context, pr),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(
              pr.status == 'rejected_revision_needed'
                  ? 'Resubmit Artwork for Approval'
                  : 'Submit Work for Approval',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: PmsTheme.primary,
              foregroundColor: Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }

      if (isDesigner && pr.status == 'submitted_for_approval') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: PmsTheme.glassSurface,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PmsTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, color: PmsTheme.primary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Artwork Submitted · Waiting for Incharge Approval',
                  style: TextStyle(
                    color: PmsTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Admin / Manager / Wing Incharge status cards before submission for approval
    if (!isDesigner || isAdminOrManager) {
      if (pr.status == 'pending_assignment') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: PmsTheme.glassSurface,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFCD34D),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Designer Assignment Pending',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Assign an active Designer so they can begin creating artwork.',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canReassignDesigner(pr)) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignDesignerDialog(context, pr),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text(
                      'Assign Designer to this PR',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      if (pr.status == 'assigned_to_designer') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: PmsTheme.glassSurface,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PmsTheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PmsTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: PmsTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.assignedDesigner != null
                                ? 'Assigned to Designer: ${pr.assignedDesigner!.name}'
                                : 'Assigned to Designer',
                            style: const TextStyle(
                              color: PmsTheme.primaryDark,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pending Work Start by Designer',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canReassignDesigner(pr)) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignDesignerDialog(context, pr),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text(
                      'Re-assign to Another Designer',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }

    // 2. REVIEW & APPROVAL ACTIONS (Super Admin, Manager, Digital Studio Incharge, and PR Creator Wing Incharge)
    if (canReviewThisPR) {
      if (pr.status == 'submitted_for_approval') {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: PmsTheme.glassSurface,
            border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, pr),
                  icon: const Icon(Icons.assignment_return_rounded, size: 16),
                  label: const Text('Request Revision'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(context, pr),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve Artwork'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (pr.status == 'rejected_revision_needed') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: PmsTheme.glassSurface,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFDC2626).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: Color(0xFFB91C1C),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  pr.revisionCount > 0
                      ? 'Submitted for Revision (#${pr.revisionCount}) \nWaiting for Designer'
                      : 'Submitted for Revision \nWaiting for Designer',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (pr.status == 'in_progress') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: PmsTheme.glassSurface,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PmsTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.brush_rounded, color: PmsTheme.primary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Designer is Currently Working on this PR',
                  style: TextStyle(
                    color: PmsTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 3. APPROVED & DISPATCH ACTIONS (Super Admin, Manager, Digital Studio Incharge, and Assigned Designer)
    if (pr.status == 'approved' ||
        pr.status == 'sent_to_print' ||
        pr.status == 'posted' ||
        pr.status == 'completed') {
      if (isCreatorWingIncharge && !widget.isSuperAdmin && !isManager) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: PmsTheme.glassSurface,
            border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pr.status == 'completed'
                        ? 'Purchase Request Completed & Delivered ✓'
                        : (pr.status == 'sent_to_print'
                            ? 'Artwork Approved & Sent to Print!'
                            : (pr.status == 'posted'
                                ? 'Artwork Approved & Published!'
                                : 'Artwork Approved! Pending Dispatch.')),
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (canDispatchApproved) {
        return _buildApprovedActionsBar(context, pr);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildApprovedActionsBar(
    BuildContext context,
    PurchaseRequestModel pr,
  ) {
    final activePO = pr.activePrintOrder;
    final isSentToPrint = pr.status == 'sent_to_print' || activePO != null;
    final isPosted = pr.status == 'posted' || pr.isPosted;
    final isCompleted = pr.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: PmsTheme.glassSurface,
        border: Border(top: BorderSide(color: PmsTheme.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Sent to Print Card (Mutual exclusivity: Post It is hidden)
          if (isSentToPrint && !isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: PmsTheme.backgroundGradientStart.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PmsTheme.primary.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PmsTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: PmsTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSuperAdmin || isManager
                              ? 'Sent to Print to ${activePO?.vendor?.name ?? 'Vendor'}'
                              : 'Sent to Print to XXXX (Printing Vendor)',
                          style: const TextStyle(
                            color: PmsTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activePO?.poNumber ?? ''} · Status: ${(activePO?.status ?? 'dispatched').replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(
                            color: PmsTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (activePO != null) ...[
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrintOrderDetailsScreen(
                              printOrder: activePO,
                              userProfile: widget.currentUser,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: PmsTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: PmsTheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'View PO',
                          style: TextStyle(
                            fontSize: 10,
                            color: PmsTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.isSuperAdmin)
                    OutlinedButton(
                      onPressed: () => _confirmCancelPrint(pr, activePO),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFFB91C1C),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancel Print',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 2. Sent for Post Card (Mutual exclusivity: Send to Print is hidden)
          if (isPosted && !isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFF5F3FF).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PmsTheme.primary.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PmsTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: PmsTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forwarded for Post Publishing ✓',
                          style: TextStyle(
                            color: PmsTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pr.postedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Posted on ${_formatDateTime(pr.postedAt)}',
                            style: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _confirmCancelPost(pr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFB91C1C),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Cancel Post',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Completed State Banner
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Color(0xFFECFDF5).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Color(0xFF059669).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Purchase Request Completed & Delivered ✓',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (activePO != null)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrintOrderDetailsScreen(
                              printOrder: activePO,
                              userProfile: widget.currentUser,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF059669).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(0xFF059669).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'View PO',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 4. Mutually exclusive selection buttons if in 'approved' status (and not yet sent to print or post)
          if (!isSentToPrint && !isPosted && !isCompleted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPostItDialog(pr),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text(
                      'Post It',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary, // Purple
                      foregroundColor: Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSendToPrintModal(pr),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'Send to Print',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary, // Blue
                      foregroundColor: Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  void _confirmCancelPrint(PurchaseRequestModel pr, PrintOrderModel? activePO) {
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
              'Cancel Print Order',
              style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel print order ${activePO?.poNumber ?? ''} dispatched to ${activePO?.vendor?.name ?? 'vendor'}? PR status will revert to Approved.',
          style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'No, Keep Order',
              style: TextStyle(color: PmsTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<PurchaseRequestBloc>().add(
                CancelPrintPREvent(
                  prId: pr.id,
                  phone: widget.currentUser?.phone,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✓ Print order for ${pr.prNumber} cancelled. Status reverted to Approved.',
                  ),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Color(0xFFFFFFFF),
            ),
            child: const Text('Cancel Print Order'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPost(PurchaseRequestModel pr) {
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
          'Are you sure you want to cancel the post publishing request for ${pr.prNumber}?',
          style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'No, Keep Post',
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
                  content: Text('✓ Post request for ${pr.prNumber} cancelled.'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Color(0xFFFFFFFF),
            ),
            child: const Text('Cancel Post Request'),
          ),
        ],
      ),
    );
  }

  void _showPostItDialog(PurchaseRequestModel pr) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: PmsTheme.glassSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PmsTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: PmsTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Submit Post Request',
              style: TextStyle(
                color: PmsTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forward approved artwork for ${pr.prNumber} for digital & social media posting?',
              style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: const TextStyle(color: PmsTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Optional instructions (e.g. publish on Instagram & Facebook)...',
                hintStyle: const TextStyle(
                  color: PmsTheme.textSecondary,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: PmsTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: PmsTheme.glassBorder),
                ),
              ),
            ),
          ],
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
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final repo = PurchaseRequestRepository();
                final phone = widget.currentUser?.phone;
                await repo.postIt(
                  pr.id,
                  remarks: remarksController.text.trim().isNotEmpty
                      ? remarksController.text.trim()
                      : 'Artwork forwarded for social / digital post publishing.',
                  phone: phone,
                );

                if (!mounted) return;
                // Show thank you popup
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: PmsTheme.glassSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF059669).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF059669),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Thank You!',
                          style: TextStyle(
                            color: PmsTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Post request received for ${pr.prNumber}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PmsTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (mounted) {
                              context.read<PurchaseRequestBloc>().add(
                                FetchPurchaseRequestsEvent(
                                  designerId: isDesigner
                                      ? widget.currentUser?.id
                                      : null,
                                  phone: widget.currentUser?.phone,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PmsTheme.primary,
                            foregroundColor: Color(0xFFFFFFFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PmsTheme.primary,
              foregroundColor: Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit Post',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSendToPrintModal(PurchaseRequestModel pr) async {
    List<VendorModel> vendors = [];
    try {
      vendors = await VendorRepository().getVendors();
    } catch (_) {}

    if (!mounted) return;

    final printOrderRemarksCtrl = TextEditingController();

    final itemStates = pr.items.map((it) {
      return _SendToPrintItemState(
        item: it,
        quantityCtrl: TextEditingController(text: '${it.quantity}'),
        sizeCtrl: TextEditingController(text: it.size ?? ''),
        defaultAttachmentPath: pr.artworkFilePath ?? it.attachmentPath,
        defaultAttachmentName:
            pr.artworkFileName ?? it.attachmentName ?? 'Approved Proof',
      );
    }).toList();

    VendorModel? selectedVendor = vendors.isNotEmpty ? vendors.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: PmsTheme.glassSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: PmsTheme.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PmsTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.print_rounded,
                              color: PmsTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Send to Print',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: PmsTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${pr.prNumber} · ${pr.wing?.name ?? 'General Wing'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PmsTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close, color: PmsTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(color: PmsTheme.glassBorder, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECT PRINTING VENDOR *',
                          style: TextStyle(
                            color: PmsTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (vendors.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PmsTheme.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No vendors found. Please register a vendor first.',
                              style: TextStyle(
                                color: PmsTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: PmsTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: PmsTheme.glassBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<VendorModel>(
                                value: selectedVendor,
                                isExpanded: true,
                                dropdownColor: Color(0xFFFFFFFF),
                                items: vendors.map((v) {
                                  return DropdownMenuItem<VendorModel>(
                                    value: v,
                                    child: Text(
                                      '${v.name} (+91 ${v.mobile1})',
                                      style: const TextStyle(
                                        color: PmsTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedVendor = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        const Text(
                          'PRODUCTS TO PRINT (ADJUST QTY & ATTACHMENTS)',
                          style: TextStyle(
                            color: PmsTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...itemStates.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final state = entry.value;
                          return _buildSendToPrintItemCard(
                            idx: idx,
                            state: state,
                            setModalState: setModalState,
                          );
                        }),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PmsTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PmsTheme.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Target Wing (Read-Only):',
                                          style: TextStyle(
                                            color: PmsTheme.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pr.wing?.name ?? 'General Wing',
                                          style: const TextStyle(
                                            color: PmsTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Expected Delivery (Read-Only):',
                                          style: TextStyle(
                                            color: PmsTheme.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${pr.expectedDeliveryDate ?? 'ASAP'} (${pr.expectedDeliveryTime ?? 'Anytime'})',
                                          style: const TextStyle(
                                            color: PmsTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (pr.remarks != null &&
                                  pr.remarks!.isNotEmpty) ...[
                                const Divider(
                                  color: PmsTheme.glassBorder,
                                  height: 16,
                                ),
                                const Text(
                                  'Requester Remarks (Read-Only):',
                                  style: TextStyle(
                                    color: PmsTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pr.remarks!,
                                  style: const TextStyle(
                                    color: PmsTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'PRINT ORDER REMARKS FOR VENDOR / PRINTER',
                          style: TextStyle(
                            color: PmsTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: printOrderRemarksCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            color: PmsTheme.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Specific instructions (e.g. 300 GSM Star Flex, 4 corner eyelets, urgent delivery)...',
                            hintStyle: const TextStyle(
                              color: PmsTheme.textSecondary,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: PmsTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: PmsTheme.glassBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (selectedVendor == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a printing vendor.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              final dispatchItems = itemStates.map((ic) {
                                return CreatePrintOrderItemParam(
                                  productTypeId: ic.item.productTypeId,
                                  productName: ic.item.productName,
                                  quantity:
                                      int.tryParse(
                                        ic.quantityCtrl.text.trim(),
                                      ) ??
                                      1,
                                  size: ic.sizeCtrl.text.trim().isNotEmpty
                                      ? ic.sizeCtrl.text.trim()
                                      : null,
                                  attachmentPath: ic.pickedBytes == null
                                      ? ic.defaultAttachmentPath
                                      : null,
                                  attachmentName: ic.pickedBytes != null
                                      ? ic.pickedName
                                      : ic.defaultAttachmentName,
                                  fileBytes: ic.pickedBytes,
                                );
                              }).toList();

                              try {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Dispatching Print Order to Vendor...',
                                    ),
                                    backgroundColor: PmsTheme.primary,
                                  ),
                                );

                                final repo = PrintOrderRepository();
                                final phone = widget.currentUser?.phone;
                                final po = await repo.createPrintOrder(
                                  vendorId: selectedVendor!.id,
                                  purchaseRequestId: pr.id,
                                  wingId: pr.wingId,
                                  expectedDeliveryDate: pr.expectedDeliveryDate,
                                  expectedDeliveryTime: pr.expectedDeliveryTime,
                                  requesterRemarks: pr.remarks,
                                  printOrderRemarks:
                                      printOrderRemarksCtrl.text
                                          .trim()
                                          .isNotEmpty
                                      ? printOrderRemarksCtrl.text.trim()
                                      : null,
                                  phone: phone,
                                  items: dispatchItems,
                                );

                                if (!mounted) return;
                                this.context.read<PrintOrderBloc>().add(
                                  FetchPrintOrders(phone: phone),
                                );

                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✓ Print Order ${po.poNumber} dispatched to ${selectedVendor!.name}!',
                                    ),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'Dispatch Print Order',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PmsTheme.primary,
                              foregroundColor: Color(0xFFFFFFFF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSendToPrintItemCard({
    required int idx,
    required _SendToPrintItemState state,
    required StateSetter setModalState,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PmsTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PmsTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: PmsTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: PmsTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.item.productName,
                  style: const TextStyle(
                    color: PmsTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: state.quantityCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: PmsTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: const TextStyle(
                      color: PmsTheme.textSecondary,
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: Color(0xFFFFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: PmsTheme.glassBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: state.sizeCtrl,
                  style: const TextStyle(
                    color: PmsTheme.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Size / Dimension',
                    labelStyle: const TextStyle(
                      color: PmsTheme.textSecondary,
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: Color(0xFFFFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: PmsTheme.glassBorder),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Attachment selection per item
          if (state.pickedBytes != null && state.pickedName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF059669)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Attached: ${state.pickedName}',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setModalState(() {
                        state.pickedBytes = null;
                        state.pickedName = null;
                        state.pickedType = null;
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: PmsTheme.textSecondary,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (state.defaultAttachmentPath != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    color: PmsTheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Using Proof: ${state.defaultAttachmentName ?? 'Artwork'}',
                      style: const TextStyle(
                        color: PmsTheme.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 90,
                    );
                    if (photo != null) {
                      final bytes = await photo.readAsBytes();
                      setModalState(() {
                        state.pickedBytes = bytes;
                        state.pickedName = photo.name;
                        state.pickedType = 'image';
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 14),
                  label: const Text(
                    'Click Photo',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PmsTheme.primary,
                    side: const BorderSide(color: PmsTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final file = await FilePicker.pickFile(type: FileType.any);
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      setModalState(() {
                        state.pickedBytes = bytes;
                        state.pickedName = file.name;
                        state.pickedType = _getMediaType(file.name);
                      });
                    }
                  },
                  icon: const Icon(Icons.folder_open_rounded, size: 14),
                  label: const Text(
                    'Explore Files',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PmsTheme.primary,
                    side: const BorderSide(color: PmsTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildStatusBadge(String status, PurchaseRequestModel pr) {
    Color bg = Color(0xFFFFF7ED).withValues(alpha: 0.4);
    Color border = Color(0xFFD97706);
    Color text = Color(0xFFD97706);
    IconData icon = Icons.hourglass_empty_rounded;
    String label = 'Pending Assignment';

    if (status == 'assigned_to_designer') {
      bg = PmsTheme.backgroundGradientStart.withValues(alpha: 0.4);
      border = PmsTheme.primary;
      text = PmsTheme.primary;
      icon = Icons.assignment_ind_rounded;
      label = 'Assigned';
    } else if (status == 'in_progress') {
      bg = PmsTheme.backgroundGradientStart.withValues(alpha: 0.4);
      border = PmsTheme.primary;
      text = PmsTheme.primary;
      icon = Icons.draw_rounded;
      label = 'In Progress';
    } else if (status == 'submitted_for_approval') {
      bg = Color(0xFFF5F3FF).withValues(alpha: 0.4);
      border = PmsTheme.primary;
      text = PmsTheme.textSecondary;
      icon = Icons.hourglass_top_rounded;
      label = 'Under Review';
    } else if (status == 'rejected_revision_needed') {
      bg = Color(0xFFFEF2F2).withValues(alpha: 0.5);
      border = Color(0xFFDC2626);
      text = Color(0xFFB91C1C);
      icon = Icons.replay_rounded;
      label = 'Revision (#${pr.revisionCount})';
    } else if (status == 'approved') {
      bg = Color(0xFF059669).withValues(alpha: 0.35);
      border = Color(0xFF059669);
      text = Color(0xFF059669);
      icon = Icons.check_circle_rounded;
      label = 'Approved';
    } else if (status == 'sent_to_print') {
      bg = PmsTheme.backgroundGradientStart.withValues(alpha: 0.4);
      border = PmsTheme.primary;
      text = PmsTheme.primary;
      icon = Icons.print_rounded;
      label = 'Sent to Print';
    } else if (status == 'posted') {
      bg = Color(0xFFF5F3FF).withValues(alpha: 0.4);
      border = PmsTheme.primary;
      text = PmsTheme.textSecondary;
      icon = Icons.campaign_rounded;
      label = 'Posted ✓';
    } else if (status == 'completed') {
      bg = Color(0xFFECFDF5).withValues(alpha: 0.4);
      border = Color(0xFF059669);
      text = Color(0xFF059669);
      icon = Icons.task_alt_rounded;
      label = 'Completed ✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}

class _SendToPrintItemState {
  final PurchaseRequestItemModel item;
  final TextEditingController quantityCtrl;
  final TextEditingController sizeCtrl;
  final String? defaultAttachmentPath;
  final String? defaultAttachmentName;
  Uint8List? pickedBytes;
  String? pickedName;
  String? pickedType;

  _SendToPrintItemState({
    required this.item,
    required this.quantityCtrl,
    required this.sizeCtrl,
    this.defaultAttachmentPath,
    this.defaultAttachmentName,
  });
}
