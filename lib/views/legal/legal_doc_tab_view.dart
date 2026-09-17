import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/pms_theme.dart';

enum LegalDocType {
  privacyPolicy,
  termsAndConditions,
}

class LegalDocTabView extends StatelessWidget {
  final LegalDocType type;

  const LegalDocTabView({
    super.key,
    required this.type,
  });

  String get _title => type == LegalDocType.privacyPolicy
      ? 'Privacy Policy'
      : 'Terms & Conditions';

  String get _url => type == LegalDocType.privacyPolicy
      ? '${ApiService.liveServerUrl}/privacy-policy'
      : '${ApiService.liveServerUrl}/terms-and-conditions';

  Future<void> _openInBrowser(BuildContext context) async {
    final uri = Uri.parse(_url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PmsTheme.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PmsTheme.glassBorder),
                boxShadow: PmsTheme.glassShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PmsTheme.backgroundGradientStart,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      type == LegalDocType.privacyPolicy
                          ? Icons.privacy_tip_outlined
                          : Icons.description_outlined,
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
                          _title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Prince Eduhub PMS · Valid for 2026',
                          style: TextStyle(
                            fontSize: 11,
                            color: PmsTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openInBrowser(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text(
                      'Open URL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Content Body
            if (type == LegalDocType.privacyPolicy)
              _buildPrivacyContent(context)
            else
              _buildTermsContent(context),

            const SizedBox(height: 20),

            // Bottom Open In Browser Banner
            InkWell(
              onTap: () => _openInBrowser(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [PmsTheme.primaryDark, PmsTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: PmsTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'View Live Web Policy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Prince Eduhub PMS Portal',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBFDBFE),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    return Column(
      children: [
        _buildSectionCard(
          title: '1. Overview & Institution',
          icon: Icons.business_outlined,
          children: [
            _buildParagraph(
              'Prince Eduhub PMS (Package: com.pms.prince.pms) is the internal procurement, printing, and operations management platform for Prince Eduhub, Sikar, Rajasthan, India.',
            ),
            _buildParagraph(
              'This application is solely for authorized employees, faculty, contractors, designers, and printing vendors. We do not sell your personal data or use it for programmatic advertising.',
            ),
          ],
        ),
        _buildSectionCard(
          title: '2. Information We Collect',
          icon: Icons.storage_outlined,
          children: [
            _buildBulletPoint('Profile Data', 'Name, mobile phone number, institutional role, and affiliated campus wing.'),
            _buildBulletPoint('Authentication', 'SMS OTP verification tokens via Google Firebase Authentication.'),
            _buildBulletPoint('Media & Documents', 'Invoices, delivery challans, creative artwork designs, and newspaper tracking photos uploaded by users.'),
            _buildBulletPoint('Device Tokens', 'Firebase Cloud Messaging (FCM) push tokens for real-time notification audio and alerts.'),
          ],
        ),
        _buildSectionCard(
          title: '3. Device Permissions',
          icon: Icons.security_outlined,
          children: [
            _buildBulletPoint('Notifications', 'Delivering purchase approvals, design uploads, and dispatch status alerts.'),
            _buildBulletPoint('Camera & Media', 'Attaching bills, delivery proofs, and artwork files directly to print orders.'),
            _buildBulletPoint('Internet State', 'Connecting to the secure PMS server via TLS encryption.'),
          ],
        ),
        _buildSectionCard(
          title: '4. Account & Data Deletion',
          icon: Icons.delete_outline_rounded,
          children: [
            _buildParagraph(
              'Any user or vendor may request permanent account deletion and removal of personal records by emailing info@princeeduhub.com with their registered phone number.',
            ),
            _buildParagraph(
              'Requests are processed within 7 business days in accordance with Google Play Developer Program policies.',
            ),
          ],
        ),
        _buildSectionCard(
          title: '5. Contact & Support',
          icon: Icons.contact_support_outlined,
          children: [
            _buildParagraph('Prince Eduhub, Palwas Road / Piprali Road, Sikar, Rajasthan - 332001'),
            _buildParagraph('Email: info@princeeduhub.com'),
            _buildParagraph('Phone: +91 '),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    return Column(
      children: [
        _buildSectionCard(
          title: '1. Acceptance of Terms',
          icon: Icons.gavel_outlined,
          children: [
            _buildParagraph(
              'By accessing or using the Prince Eduhub PMS application or administrative portal, you agree to comply with all institutional guidelines and terms outlined herein.',
            ),
          ],
        ),
        _buildSectionCard(
          title: '2. Authorized User Accounts',
          icon: Icons.verified_user_outlined,
          children: [
            _buildParagraph(
              'Access is granted strictly to designated personnel of Prince Eduhub. Login sessions and OTP credentials must be kept confidential and never shared.',
            ),
            _buildParagraph(
              'Access will be immediately revoked upon cessation of employment or termination of vendor contract.',
            ),
          ],
        ),
        _buildSectionCard(
          title: '3. User Role Commitments',
          icon: Icons.assignment_turned_in_outlined,
          children: [
            _buildBulletPoint('Designers', 'Must ensure artwork accuracy, proper print dimensions, and timely uploads.'),
            _buildBulletPoint('Vendors', 'Must supply accurate delivery quantities, authentic bills, and uphold print quality.'),
            _buildBulletPoint('Incharges & Managers', 'Must physically inspect deliveries and approve purchase orders responsibly.'),
          ],
        ),
        _buildSectionCard(
          title: '4. Acceptable Use',
          icon: Icons.rule_folder_outlined,
          children: [
            _buildParagraph(
              'Users must not falsify delivery slips, upload unauthorized copyrighted media, reverse engineer the APIs, or use institutional data for unauthorized purposes.',
            ),
          ],
        ),
        _buildSectionCard(
          title: '5. Governing Law',
          icon: Icons.account_balance_outlined,
          children: [
            _buildParagraph(
              'These terms are governed by the laws of India. Any disputes are subject to the exclusive jurisdiction of the competent courts in Sikar, Rajasthan.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Icon(icon, size: 18, color: PmsTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: PmsTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: PmsTheme.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: PmsTheme.textSecondary, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
