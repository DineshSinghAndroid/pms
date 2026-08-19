import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/vendor/vendor_state.dart';
import '../../models/vendor_model.dart';

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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vendor != null ? 'Edit Printing Vendor' : 'Add New Printing Vendor',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Vendor Name *',
                      hint: 'e.g. Royal Offset Printers',
                    ),
                    const SizedBox(height: 12),

                    // Mobile 1 & 2
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

                    // Email
                    _buildTextField(
                      controller: emailCtrl,
                      label: 'Email Address',
                      hint: 'vendor@company.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Address
                    _buildTextField(
                      controller: addressCtrl,
                      label: 'Physical Address',
                      hint: 'Press Address, City, State...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Allow App Login Checkbox
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isLoginAllowed,
                            activeColor: const Color(0xFF2563EB),
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
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Vendor can log in using Mobile 1 OTP',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final mobile1 = mobile1Ctrl.text.trim();
                        final mobile2 = mobile2Ctrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final address = addressCtrl.text.trim();

                        if (name.isEmpty || mobile1.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill Vendor Name and Mobile 1'),
                              backgroundColor: Color(0xFFE11D48),
                            ),
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
                                UpdateVendorEvent(vendorId: vendor.id, payload: payload),
                              );
                        } else {
                          context.read<VendorBloc>().add(CreateVendorEvent(payload));
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(vendor != null ? '✓ Vendor updated!' : '✓ Vendor created!'),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        vendor != null ? 'Save Changes' : 'Create Vendor',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Vendor', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(
            'Are you sure you want to delete vendor "${vendor.name}"?',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<VendorBloc>().add(DeleteVendorEvent(vendor.id));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Vendor deleted'),
                    backgroundColor: Color(0xFFE11D48),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
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
        // Section Header & Add Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.storefront_rounded, color: Color(0xFF60A5FA), size: 20),
                SizedBox(width: 8),
                Text(
                  'Printing Vendors Directory',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (widget.isSuperAdmin)
              ElevatedButton.icon(
                onPressed: () => _showVendorForm(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val.trim().toLowerCase());
          },
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search vendors by name, phone or address...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Vendor Cards List Builder
        BlocBuilder<VendorBloc, VendorState>(
          builder: (context, state) {
            if (state is VendorLoading) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2.5),
                ),
              );
            }

            if (state is VendorError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C0519).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE11D48)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to load vendors: ${state.errorMessage}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFECDD3)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<VendorBloc>().add(const FetchVendorsEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBE123C),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 11),
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
                    (v.mobile2?.toLowerCase().contains(_searchQuery) ?? false) ||
                    (v.address?.toLowerCase().contains(_searchQuery) ?? false) ||
                    (v.email?.toLowerCase().contains(_searchQuery) ?? false);
              }).toList();

              if (vendors.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Center(
                    child: Text(
                      'No matching vendors found.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vendors.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.print_rounded, color: Color(0xFF60A5FA), size: 18),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: #${vendor.id}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // App Login Status Badge
              InkWell(
                onTap: widget.isSuperAdmin
                    ? () {
                        context.read<VendorBloc>().add(ToggleVendorLoginEvent(vendor.id));
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vendor.isLoginAllowed
                        ? const Color(0xFF065F46).withValues(alpha: 0.5)
                        : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: vendor.isLoginAllowed ? const Color(0xFF059669) : const Color(0xFF475569),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: vendor.isLoginAllowed ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.isLoginAllowed ? 'Login Allowed' : 'Login Disabled',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: vendor.isLoginAllowed ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),

          // Contact details
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: Color(0xFF94A3B8), size: 14),
              const SizedBox(width: 6),
              Text(
                '+91 ${vendor.mobile1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
              ),
              if (vendor.mobile2 != null && vendor.mobile2!.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(width: 8),
                Text('+91 ${vendor.mobile2}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ],
          ),

          if (vendor.email != null && vendor.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 14),
                const SizedBox(width: 6),
                Text(vendor.email!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ],

          if (vendor.address != null && vendor.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vendor.address!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Admin action buttons
          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showVendorForm(context, vendor: vendor),
                  icon: const Icon(Icons.edit, size: 12),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF60A5FA),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, vendor),
                  icon: const Icon(Icons.delete_outline, size: 12),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFDA4AF),
                    side: const BorderSide(color: Color(0xFFE11D48)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
