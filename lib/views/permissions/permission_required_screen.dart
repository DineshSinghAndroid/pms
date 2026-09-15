import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/permission_service.dart';
import '../../widgets/app_logo.dart';

class PermissionRequiredScreen extends StatefulWidget {
  final VoidCallback onAllGranted;

  const PermissionRequiredScreen({super.key, required this.onAllGranted});

  @override
  State<PermissionRequiredScreen> createState() =>
      _PermissionRequiredScreenState();
}

class _PermissionRequiredScreenState extends State<PermissionRequiredScreen>
    with WidgetsBindingObserver {
  List<AppPermissionStatus> _permissionStatuses = [];
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final statuses = await PermissionService.checkAllPermissions();
    final allGranted = statuses.every((s) => s.isGranted);

    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
        _isLoading = false;
      });

      if (allGranted) {
        widget.onAllGranted();
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);
    final statuses = await PermissionService.requestAllPermissionsOneByOne();
    final allGranted = statuses.every((s) => s.isGranted);

    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
        _isRequesting = false;
      });

      if (allGranted) {
        widget.onAllGranted();
      } else {
        final anyPermanentlyDenied = statuses.any(
          (s) => !s.isGranted && s.isPermanentlyDenied,
        );
        if (anyPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Some permissions are permanently denied. Please enable them in App Settings.',
              ),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyMissing = _permissionStatuses.any((s) => !s.isGranted);
    final anyPermanentlyDenied = _permissionStatuses.any(
      (s) => !s.isGranted && s.isPermanentlyDenied,
    );

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand logo
                  const Center(child: AppLogo(size: 80)),

                  const SizedBox(height: 24),

                  const Text(
                    'Mandatory Permissions Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'To ensure security, job verification, and artwork proof uploads, PMS requires the following permissions. All permissions must be granted to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    )
                  else ...[
                    // List of Permission Cards
                    ..._permissionStatuses.map((perm) {
                      final IconData icon = perm.type == AppPermissionType.location
                          ? Icons.location_on_rounded
                          : Icons.camera_alt_rounded;

                      final isGranted = perm.isGranted;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isGranted
                                ? Color(0xFF059669).withValues(alpha: 0.4)
                                : Color(0xFFDC2626).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isGranted
                                    ? Color(0xFFECFDF5).withValues(alpha: 0.5)
                                    : Color(0xFFFEF2F2).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: isGranted
                                    ? Color(0xFF059669)
                                    : Color(0xFFB91C1C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        perm.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isGranted
                                              ? Color(0xFFECFDF5)
                                                    .withValues(alpha: 0.6)
                                              : Color(0xFFFEF2F2)
                                                    .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isGranted
                                                ? Color(0xFF059669)
                                                : Color(0xFFDC2626),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isGranted
                                                  ? Icons.check_circle_rounded
                                                  : Icons.cancel_rounded,
                                              size: 12,
                                              color: isGranted
                                                  ? Color(0xFF059669)
                                                  : Color(0xFFB91C1C),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isGranted ? 'Allowed' : 'Missing',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isGranted
                                                    ? Color(0xFF059669)
                                                    : Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    perm.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Primary Action: Grant Missing Permissions
                    if (anyMissing)
                      ElevatedButton.icon(
                        onPressed: _isRequesting ? null : _requestPermissions,
                        icon: _isRequesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : const Icon(Icons.verified_user_rounded, size: 18),
                        label: Text(
                          _isRequesting
                              ? 'Requesting Permissions...'
                              : 'Grant Missing Permissions',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Color(0xFFFFFFFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    if (anyPermanentlyDenied) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => PermissionService.openSettings(),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text(
                          'Open App Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Secondary Re-check Button
                    TextButton.icon(
                      onPressed: _checkPermissions,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      label: const Text(
                        'Re-check Status',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign out
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text(
                          'Log Out & Exit',
                          style: TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
