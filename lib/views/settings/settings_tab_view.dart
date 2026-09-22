import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/app_update_service.dart';
import 'app_update_settings_dialog.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_ui.dart';

class SettingsTabView extends StatefulWidget {
  final bool isSuperAdmin;
  final bool isAdmin;
  final String? userPhone;

  const SettingsTabView({
    super.key,
    this.isSuperAdmin = false,
    this.isAdmin = false,
    this.userPhone,
  });

  @override
  State<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends State<SettingsTabView> {
  final AppUpdateService _updateService = AppUpdateService();
  int _appBuildNumber = 4;
  String _appVersion = '2.0.0';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPackageDetails();
  }

  Future<void> _loadPackageDetails() async {
    final buildNum = await AppUpdateService.getCurrentBuildNumber();
    final ver = await AppUpdateService.getCurrentVersionString();
    if (mounted) {
      setState(() {
        _appBuildNumber = buildNum;
        _appVersion = ver;
      });
    }
  }

  Future<void> _launchUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        showPmsSnackBar(
          context,
          'Could not open page: $e',
          kind: PmsSnackKind.error,
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      await _updateService.checkForUpdate(context, showToastIfUpToDate: true);
    } catch (e) {
      if (mounted) {
        showPmsSnackBar(
          context,
          'Failed to check for updates: $e',
          kind: PmsSnackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _openUpdateSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppUpdateSettingsDialog(userPhone: widget.userPhone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canManageUpdates = widget.isSuperAdmin;

    return RefreshIndicator(
      color: PmsTheme.primary,
      onRefresh: () async {
        await Future.wait([
          _loadPackageDetails(),
          _updateService.fetchUpdateInfo(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PmsPageHeader(
              icon: Icons.settings_rounded,
              title: 'System Settings',
              subtitle: 'App info, updates, and legal compliance',
            ),
            const SizedBox(height: 18),

            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection & Build',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: PmsTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow('Application', 'PMS Admin Mobile'),
                  const Divider(color: PmsTheme.glassBorder, height: 20),
                  _buildInfoRow(
                    'App Version',
                    'v$_appVersion (Build #$_appBuildNumber)',
                  ),
                  const Divider(color: PmsTheme.glassBorder, height: 20),
                  _buildInfoRow('Organization', 'Prince Eduhub'),
                  const Divider(color: PmsTheme.glassBorder, height: 20),
                  _buildInfoRow('Backend Base URL', ApiService.baseUrl),
                  const Divider(color: PmsTheme.glassBorder, height: 20),
                  _buildInfoRow('State Management', 'BLoC (flutter_bloc 9.x)'),
                  const Divider(color: PmsTheme.glassBorder, height: 20),
                  _buildInfoRow('Network Client', 'Dio HTTP 5.x'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            GlassCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PmsTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isCheckingUpdate
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: PmsTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: PmsTheme.primary,
                              size: 20,
                            ),
                    ),
                    title: const Text(
                      'Check for Updates',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      _isCheckingUpdate
                          ? 'Checking server for latest build...'
                          : 'Currently installed: Build #$_appBuildNumber',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: PmsTheme.textMuted,
                    ),
                    onTap: _isCheckingUpdate ? null : _checkForUpdates,
                  ),

                  if (canManageUpdates) ...[
                    const Divider(color: PmsTheme.glassBorder, height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: PmsTheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: PmsTheme.secondary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Manage App Updates (Super Admin)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: PmsTheme.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Set target build number, toggle force update, store links',
                        style: TextStyle(
                          fontSize: 11,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PmsTheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SUPER ADMIN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: PmsTheme.secondary,
                          ),
                        ),
                      ),
                      onTap: _openUpdateSettingsDialog,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            GlassCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildPolicyTile(
                    context,
                    title: 'Privacy Policy',
                    subtitle: 'Data usage, permissions, and deletion policy',
                    icon: Icons.privacy_tip_outlined,
                    url: '${ApiService.liveServerUrl}/privacy-policy',
                  ),
                  const Divider(color: PmsTheme.glassBorder, height: 1),
                  _buildPolicyTile(
                    context,
                    title: 'Terms & Conditions',
                    subtitle:
                        'Acceptable use, role governance, and jurisdiction',
                    icon: Icons.description_outlined,
                    url: '${ApiService.liveServerUrl}/terms-and-conditions',
                  ),
                  const Divider(color: PmsTheme.glassBorder, height: 1),
                  _buildPolicyTile(
                    context,
                    title: 'Request Account & Data Deletion',
                    subtitle:
                        'Submit deletion request (Google Play Compliance)',
                    icon: Icons.person_remove_outlined,
                    url: '${ApiService.liveServerUrl}/delete-account',
                    iconColor: PmsTheme.error,
                    iconBg: const Color(0xFFFEF2F2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String url,
    Color iconColor = PmsTheme.primary,
    Color iconBg = PmsTheme.backgroundGradientStart,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: PmsTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: PmsTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.open_in_new_rounded,
        size: 16,
        color: PmsTheme.textMuted,
      ),
      onTap: () => _launchUrl(context, url),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PmsTheme.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: PmsTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
