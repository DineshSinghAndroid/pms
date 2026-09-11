import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({super.key});

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
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE2E8F0)),
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
        ],
      ),
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
