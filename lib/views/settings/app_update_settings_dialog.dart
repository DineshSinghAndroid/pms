import 'package:flutter/material.dart';

import '../../models/app_update_info.dart';
import '../../services/app_update_service.dart';
import '../../widgets/app_update_dialog.dart';

class AppUpdateSettingsDialog extends StatefulWidget {
  final String? userPhone;

  const AppUpdateSettingsDialog({super.key, this.userPhone});

  @override
  State<AppUpdateSettingsDialog> createState() =>
      _AppUpdateSettingsDialogState();
}

class _AppUpdateSettingsDialogState extends State<AppUpdateSettingsDialog> {
  final AppUpdateService _service = AppUpdateService();

  final TextEditingController _buildNumberController = TextEditingController();
  final TextEditingController _playStoreController = TextEditingController();
  final TextEditingController _appStoreController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isForceUpdate = false;
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentAppBuild = 4;
  String _currentAppVersion = '2.0.0';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _buildNumberController.dispose();
    _playStoreController.dispose();
    _appStoreController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final buildNum = await AppUpdateService.getCurrentBuildNumber();
    final verName = await AppUpdateService.getCurrentVersionString();
    final config = await _service.fetchUpdateInfo();

    if (mounted) {
      setState(() {
        _currentAppBuild = buildNum;
        _currentAppVersion = verName;
        _isLoading = false;

        if (config != null) {
          _buildNumberController.text = config.latestBuildNumber.toString();
          _isForceUpdate = config.isForceUpdate;
          _playStoreController.text = config.playStoreUrl;
          _appStoreController.text = config.appStoreUrl;
          _titleController.text = config.title;
          _messageController.text = config.message;
        } else {
          _buildNumberController.text = buildNum.toString();
          _isForceUpdate = false;
          _playStoreController.text =
              'https://play.google.com/store/apps/details?id=com.pms.prince.pms';
          _appStoreController.text =
              'https://apps.apple.com/app/com.pms.prince.pms';
          _titleController.text = 'New Update Available';
          _messageController.text =
              'A new version of PMS Admin is available with improvements and fixes.';
        }
      });
    }
  }

  AppUpdateInfo _buildCurrentModel() {
    final int buildNum =
        int.tryParse(_buildNumberController.text.trim()) ?? _currentAppBuild;
    return AppUpdateInfo(
      latestBuildNumber: buildNum,
      isForceUpdate: _isForceUpdate,
      playStoreUrl: _playStoreController.text.trim(),
      appStoreUrl: _appStoreController.text.trim(),
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'New Update Available',
      message: _messageController.text.trim(),
    );
  }

  Future<void> _handleSave() async {
    final int? buildNum = int.tryParse(_buildNumberController.text.trim());
    if (buildNum == null || buildNum < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid build number (>= 1).'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final info = _buildCurrentModel();
      await _service.saveUpdateInfo(info, userPhone: widget.userPhone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'App update settings saved successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _previewPopup() {
    final info = _buildCurrentModel();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppUpdateDialog(
        updateInfo: info,
        currentBuildNumber: _currentAppBuild,
        currentVersionName: _currentAppVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Update & Version Control',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'OTA configuration based on build number',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Current Device Version Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current app build: #$_currentAppBuild (v$_currentAppVersion)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Build Number
                    const Text(
                      'Target / Latest Build Number',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _buildNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 5',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.tag_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                        helperText:
                            'Devices with build number < this number will be asked to update.',
                        helperStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Force Update Switch Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isForceUpdate
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isForceUpdate
                              ? const Color(0xFFFECDD3)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _isForceUpdate,
                        onChanged: (val) => setState(() => _isForceUpdate = val),
                        activeThumbColor: const Color(0xFFDC2626),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Force Update (Mandatory)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isForceUpdate
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          _isForceUpdate
                              ? 'Blocks app access until user updates. Hides Later button.'
                              : 'Users can choose Later or skip.',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isForceUpdate
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Update Title
                    const Text(
                      'Popup Heading / Title',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. New Update Available!',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.title_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Play Store / Play Console Link
                    const Text(
                      'Play Console / Play Store URL (Android)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _playStoreController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText:
                            'https://play.google.com/store/apps/details?id=com.pms.prince.pms',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.android_rounded,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Apple Store / Apple Console Link
                    const Text(
                      'Apple Console / App Store URL (iOS)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _appStoreController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://apps.apple.com/app/com.pms.prince.pms',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.apple_rounded,
                          color: Color(0xFF334155),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Release Notes / Message
                    const Text(
                      'Release Notes / What\'s New',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe new features, fixes, improvements...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons: Preview & Save
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previewPopup,
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text(
                              'Preview Popup',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFFC7D2FE)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 16),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Config',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
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
              ),
      ),
    );
  }
}
