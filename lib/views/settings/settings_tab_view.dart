import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({super.key});

  Future<void> _launchUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'System Settings & Connection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Application', 'PMS Admin Mobile'),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _buildInfoRow('Organization', 'Prince Eduhub'),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _buildInfoRow('Backend Base URL', ApiService.baseUrl),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _buildInfoRow('State Management', 'BLoC (flutter_bloc 9.x)'),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _buildInfoRow('Network Client', 'Dio HTTP 5.x'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Row(
            children: [
              Icon(Icons.gavel_outlined, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'Legal & Institutional Compliance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                _buildPolicyTile(
                  context,
                  title: 'Terms & Conditions',
                  subtitle: 'Acceptable use, role governance, and jurisdiction',
                  icon: Icons.description_outlined,
                  url: '${ApiService.liveServerUrl}/terms-and-conditions',
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
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
    );
  }

  Widget _buildPolicyTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String url,
    Color iconColor = const Color(0xFF2563EB),
    Color iconBg = const Color(0xFFEFF6FF),
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
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(
        Icons.open_in_new_rounded,
        size: 16,
        color: Color(0xFF94A3B8),
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
            color: Color(0xFF64748B),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
