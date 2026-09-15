import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/pms_theme.dart';

class DeleteAccountDialog extends StatefulWidget {
  final User user;
  final UserModel? userProfile;

  const DeleteAccountDialog({
    super.key,
    required this.user,
    this.userProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required User user,
    UserModel? userProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAccountDialog(
        user: user,
        userProfile: userProfile,
      ),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _understood = false;

  String get _displayName =>
      widget.userProfile?.name.trim().isNotEmpty == true
          ? widget.userProfile!.name
          : (widget.user.displayName ?? 'User');

  String get _phone =>
      widget.userProfile?.phone ?? widget.user.phoneNumber ?? '';

  Future<void> _openWebForm() async {
    final url = '${ApiService.liveServerUrl}/delete-account';
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open web form: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  Future<void> _submitDeletionRequest() async {
    if (!_understood) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the deletion statement to proceed.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiService().client;
      final response = await dio.post(
        '${ApiService.baseUrl}/api/delete-account-request',
        data: {
          'name': _displayName,
          'phone': _phone,
          'email': widget.user.email,
          'reason': _reasonController.text.trim(),
        },
      );

      final refId = response.data['reference_id'] ?? 'DEL-REQUEST';

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Request Submitted', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your deletion request has been recorded under Reference ID: $refId.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your profile and access will be de-registered within 7 business days in accordance with Google Play Developer policy. You will now be logged out.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: PmsTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('OK, Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: PmsTheme.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: PmsTheme.glassSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Icon(
                    Icons.person_remove_outlined,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: PmsTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Account & Data Deletion Request',
                        style: TextStyle(
                          fontSize: 11,
                          color: PmsTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: PmsTheme.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Warning Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Permanent Action',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deleting your account for $_phone will permanently erase your user profile, credentials, and notification tokens. Completed institutional purchase records remain archived for accounting audits.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF7F1D1D),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reason field
            const Text(
              'Reason for deletion (optional):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'e.g. Completed contract, resignation, etc.',
                hintStyle: const TextStyle(fontSize: 12, color: PmsTheme.textMuted),
                contentPadding: const EdgeInsets.all(12),
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
                  borderSide: const BorderSide(color: Color(0xFFDC2626)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Confirmation Checkbox
            InkWell(
              onTap: () => setState(() => _understood = !_understood),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _understood,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (val) => setState(() => _understood = val ?? false),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'I understand my account will be permanently closed and my access revoked.',
                        style: TextStyle(fontSize: 11.5, color: PmsTheme.textSecondary, height: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDeletionRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Request Account Deletion',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 10),

            // Web link button (Mandatory for Play Console link requirement)
            OutlinedButton.icon(
              onPressed: _openWebForm,
              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
              label: const Text(
                'Open Public Web Form',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PmsTheme.textSecondary,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
