import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/vendor/vendor_state.dart';
import '../../models/vendor_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';

class VendorListSection extends StatefulWidget {
  final bool isSuperAdmin;

  const VendorListSection({super.key, this.isSuperAdmin = true});

  @override
  State<VendorListSection> createState() => _VendorListSectionState();
}

class _VendorListSectionState extends State<VendorListSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showVendorForm(BuildContext context, {VendorModel? vendor}) {
    final nameCtrl = TextEditingController(text: vendor?.name ?? '');
    final mobile1Ctrl = TextEditingController(text: vendor?.mobile1 ?? '');
    final mobile2Ctrl = TextEditingController(text: vendor?.mobile2 ?? '');
    final emailCtrl = TextEditingController(text: vendor?.email ?? '');
    final addressCtrl = TextEditingController(text: vendor?.address ?? '');
    bool isLoginAllowed = vendor?.isLoginAllowed ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PmsSheetHeader(
                      title: vendor != null
                          ? 'Edit Printing Vendor'
                          : 'Add New Printing Vendor',
                      subtitle: vendor != null
                          ? 'Update contact and login access'
                          : 'Register a press or printing partner',
                      onClose: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Vendor Name *',
                      hint: 'e.g. Royal Offset Printers',
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: mobile1Ctrl,
                            label: 'Mobile 1 (Login) *',
                            hint: '9829012345',
                            keyboardType: TextInputType.phone,
                            prefix: '+91 ',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: mobile2Ctrl,
                            label: 'Mobile 2 (Optional)',
                            hint: 'Secondary',
                            keyboardType: TextInputType.phone,
                            prefix: '+91 ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: emailCtrl,
                      label: 'Email Address',
                      hint: 'vendor@company.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: addressCtrl,
                      label: 'Physical Address',
                      hint: 'Press Address, City, State...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isLoginAllowed,
                            activeColor: PmsTheme.primary,
                            onChanged: (val) {
                              setModalState(() {
                                isLoginAllowed = val ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allow App Login Access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PmsTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Vendor can log in using Mobile 1 OTP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PmsTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final mobile1 = mobile1Ctrl.text.trim();
                        final mobile2 = mobile2Ctrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final address = addressCtrl.text.trim();

                        if (name.isEmpty || mobile1.isEmpty) {
                          showPmsSnackBar(
                            context,
                            'Please fill Vendor Name and Mobile 1',
                            kind: PmsSnackKind.error,
                          );
                          return;
                        }

                        final payload = {
                          'name': name,
                          'mobile1': mobile1,
                          'mobile2': mobile2.isNotEmpty ? mobile2 : null,
                          'email': email.isNotEmpty ? email : null,
                          'address': address.isNotEmpty ? address : null,
                          'is_login_allowed': isLoginAllowed,
                        };

                        if (vendor != null) {
                          context.read<VendorBloc>().add(
                            UpdateVendorEvent(
                              vendorId: vendor.id,
                              payload: payload,
                            ),
                          );
                        } else {
                          context.read<VendorBloc>().add(
                            CreateVendorEvent(payload),
                          );
                        }

                        Navigator.pop(ctx);
                        showPmsSnackBar(
                          context,
                          vendor != null
                              ? '✓ Vendor updated!'
                              : '✓ Vendor created!',
                          kind: PmsSnackKind.success,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PmsTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        vendor != null ? 'Save Changes' : 'Create Vendor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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

  void _confirmDelete(BuildContext context, VendorModel vendor) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Vendor',
            style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete vendor "${vendor.name}"?',
            style: const TextStyle(color: PmsTheme.textSecondary, fontSize: 13),
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
                context.read<VendorBloc>().add(DeleteVendorEvent(vendor.id));
                Navigator.pop(dialogCtx);
                showPmsSnackBar(
                  context,
                  '✓ Vendor deleted',
                  kind: PmsSnackKind.error,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PmsTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: PmsTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: PmsTheme.textSecondary,
              fontSize: 12,
            ),
            prefixText: prefix,
            prefixStyle: const TextStyle(
              color: PmsTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: PmsTheme.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PmsTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: PmsTheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PmsPageHeader(
          icon: Icons.storefront_rounded,
          title: 'Printing Vendors',
          subtitle: 'Directory of presses and printing partners',
          action: widget.isSuperAdmin
              ? FilledButton.icon(
                  onPressed: () => _showVendorForm(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Vendor'),
                )
              : null,
        ),

        const SizedBox(height: 18),

        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val.trim().toLowerCase());
          },
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search vendors by name, phone or address...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),

        const SizedBox(height: 18),

        BlocBuilder<VendorBloc, VendorState>(
          builder: (context, state) {
            if (state is VendorLoading) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }

            if (state is VendorError) {
              return GlassCard(
                backgroundColor: const Color(0xFFFEF2F2),
                border: Border.all(
                  color: PmsTheme.error.withValues(alpha: 0.35),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Couldn’t load vendors',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.errorMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        context.read<VendorBloc>().add(
                              const FetchVendorsEvent(),
                            );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: PmsTheme.error,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is VendorLoaded) {
              final vendors = state.vendors.where((v) {
                if (_searchQuery.isEmpty) return true;
                return v.name.toLowerCase().contains(_searchQuery) ||
                    v.mobile1.toLowerCase().contains(_searchQuery) ||
                    (v.mobile2?.toLowerCase().contains(_searchQuery) ??
                        false) ||
                    (v.address?.toLowerCase().contains(_searchQuery) ??
                        false) ||
                    (v.email?.toLowerCase().contains(_searchQuery) ?? false);
              }).toList();

              if (vendors.isEmpty) {
                return PmsEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No matching vendors',
                  subtitle:
                      'Try another search, or add a new printing vendor.',
                  actionLabel: widget.isSuperAdmin ? 'Add Vendor' : null,
                  onAction: widget.isSuperAdmin
                      ? () => _showVendorForm(context)
                      : null,
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vendors.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return _buildVendorCard(context, vendor);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildVendorCard(BuildContext context, VendorModel vendor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PmsTheme.primary,
                      PmsTheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: PmsTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.print_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID #${vendor.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.isSuperAdmin
                    ? () {
                        context.read<VendorBloc>().add(
                              ToggleVendorLoginEvent(vendor.id),
                            );
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: PmsStatusChip(
                  label: vendor.isLoginAllowed
                      ? 'Login Allowed'
                      : 'Login Disabled',
                  color: vendor.isLoginAllowed
                      ? PmsTheme.success
                      : PmsTheme.textSecondary,
                  icon: vendor.isLoginAllowed
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.phone_iphone_rounded,
                color: PmsTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '+91 ${vendor.mobile1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PmsTheme.textPrimary,
                ),
              ),
              if (vendor.mobile2 != null && vendor.mobile2!.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(color: PmsTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '+91 ${vendor.mobile2}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PmsTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          if (vendor.email != null && vendor.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: PmsTheme.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vendor.email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PmsTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (vendor.address != null && vendor.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: PmsTheme.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vendor.address!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PmsTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit vendor',
                  onPressed: () =>
                      _showVendorForm(context, vendor: vendor),
                ),
                const SizedBox(width: 8),
                PmsIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete vendor',
                  color: PmsTheme.error,
                  onPressed: () => _confirmDelete(context, vendor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
