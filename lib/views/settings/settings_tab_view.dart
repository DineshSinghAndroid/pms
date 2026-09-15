import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/app_update_service.dart';
import 'app_update_settings_dialog.dart';
import '../../theme/pms_theme.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open page: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
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
          // 1. System Settings Header
          const Row(
            children: [
              Icon(Icons.settings_rounded, color: PmsTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'System Settings & Connection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

          const SizedBox(height: 24),

          // 2. App Updates & Version Management Section
          const Row(
            children: [
              Icon(Icons.system_update_rounded,
                  color: PmsTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'App Updates & Version Control',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
            ),
            child: Column(
              children: [
                // Check for Updates Tile
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
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

                // Admin Update Management Tile (Visible for Admins)
                if (canManageUpdates) ...[
                  const Divider(color: PmsTheme.glassBorder, height: 1),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
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
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
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

          const SizedBox(height: 24),

          // 3. Legal Compliance Section
          const Row(
            children: [
              Icon(Icons.gavel_outlined, color: PmsTheme.textSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Legal & Institutional Compliance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
            ),
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
                  subtitle: 'Acceptable use, role governance, and jurisdiction',
                  icon: Icons.description_outlined,
                  url: '${ApiService.liveServerUrl}/terms-and-conditions',
                ),
                const Divider(color: PmsTheme.glassBorder, height: 1),
                _buildPolicyTile(
                  context,
                  title: 'Request Account & Data Deletion',
                  subtitle: 'Submit deletion request (Google Play Compliance)',
                  icon: Icons.person_remove_outlined,
                  url: '${ApiService.liveServerUrl}/delete-account',
                  iconColor: const Color(0xFFDC2626),
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
          borderRadius: BorderRadius.circular(10),
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
