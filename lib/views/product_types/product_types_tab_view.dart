import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/category/category_state.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_event.dart';
import '../../bloc/product_type/product_type_state.dart';
import '../../models/product_type_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';

class ProductTypesTabView extends StatefulWidget {
  final bool isSuperAdmin;

  const ProductTypesTabView({super.key, this.isSuperAdmin = true});

  @override
  State<ProductTypesTabView> createState() => _ProductTypesTabViewState();
}

class _ProductTypesTabViewState extends State<ProductTypesTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductTypeForm(
    BuildContext context, {
    ProductTypeModel? productType,
  }) {
    final nameCtrl = TextEditingController(text: productType?.name ?? '');
    final codeCtrl = TextEditingController(
      text: productType?.productCode ?? '',
    );

    final catState = context.read<CategoryBloc>().state;
    final categories = catState is CategoryLoaded ? catState.categories : [];
    int? chosenCatId =
        productType?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);

    if (categories.isEmpty) {
      showPmsSnackBar(
        context,
        'Please create at least one Category before adding Product Types.',
        kind: PmsSnackKind.error,
      );
      return;
    }

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
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PmsSheetHeader(
                      title: productType != null
                          ? 'Edit Product Type'
                          : 'Add Product Type',
                      subtitle: productType != null
                          ? 'Update name, code and category'
                          : 'Link a product to a print category',
                      onClose: () => Navigator.pop(modalCtx),
                    ),
                    const SizedBox(height: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Category *',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PmsTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PmsTheme.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: chosenCatId,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                fontSize: 13,
                                color: PmsTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              items: categories.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    chosenCatId = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Product Name *',
                      hint: 'e.g. Acrylic stand, Admission Form, Flex',
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: codeCtrl,
                      label: 'Product Code (Auto-Generated e.g. 000112)',
                      hint: 'Leave blank to auto-generate',
                      isMonospace: true,
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim();

                        if (name.isEmpty || chosenCatId == null) {
                          showPmsSnackBar(
                            context,
                            'Please enter Product Name and select Category',
                            kind: PmsSnackKind.error,
                          );
                          return;
                        }

                        final payload = {
                          'category_id': chosenCatId,
                          'name': name,
                          if (code.isNotEmpty) 'product_code': code,
                        };

                        if (productType != null) {
                          context.read<ProductTypeBloc>().add(
                            UpdateProductTypeEvent(
                              productTypeId: productType.id,
                              payload: payload,
                            ),
                          );
                        } else {
                          context.read<ProductTypeBloc>().add(
                            CreateProductTypeEvent(payload),
                          );
                        }

                        Navigator.pop(modalCtx);
                        showPmsSnackBar(
                          context,
                          productType != null
                              ? '✓ Product Type updated!'
                              : '✓ Product Type created!',
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
                        productType != null
                            ? 'Save Changes'
                            : 'Create Product Type',
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

  void _confirmDelete(BuildContext context, ProductTypeModel productType) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Product Type',
            style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete "${productType.name}" (${productType.productCode ?? ''})?',
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
                context.read<ProductTypeBloc>().add(
                  DeleteProductTypeEvent(productType.id),
                );
                Navigator.pop(dialogCtx);
                showPmsSnackBar(
                  context,
                  '✓ Product Type deleted',
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
    bool isMonospace = false,
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
          style: TextStyle(
            fontSize: 13,
            color: PmsTheme.textPrimary,
            fontFamily: isMonospace ? 'monospace' : null,
            fontWeight: isMonospace ? FontWeight.bold : FontWeight.normal,
            letterSpacing: isMonospace ? 1.5 : 0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: PmsTheme.textSecondary,
              fontSize: 12,
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
    return RefreshIndicator(
      color: PmsTheme.primary,
      onRefresh: () async {
        context.read<ProductTypeBloc>().add(
              RefreshProductTypesEvent(categoryId: _selectedCategoryId),
            );
        context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
        await context.read<ProductTypeBloc>().stream.firstWhere(
              (state) => state is ProductTypeLoaded || state is ProductTypeError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PmsPageHeader(
              icon: Icons.layers_rounded,
              title: 'Product Types Master',
              subtitle: 'Catalog of printable products by category',
              action: widget.isSuperAdmin
                  ? FilledButton.icon(
                      onPressed: () => _showProductTypeForm(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Product Type'),
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
                hintText: 'Search product name or code (e.g. 000001)...',
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

            const SizedBox(height: 12),

            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, catState) {
                if (catState is CategoryLoaded) {
                  final categories = catState.categories;
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final isSelected = isAll
                            ? _selectedCategoryId == null
                            : _selectedCategoryId == categories[index - 1].id;
                        final label = isAll
                            ? 'All Categories'
                            : categories[index - 1].name;

                        return PmsFilterChip(
                          label: label,
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = isAll
                                  ? null
                                  : categories[index - 1].id;
                            });
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 18),

            BlocBuilder<ProductTypeBloc, ProductTypeState>(
              builder: (context, state) {
                if (state is ProductTypeLoading) {
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }

                if (state is ProductTypeError) {
                  return GlassCard(
                    backgroundColor: const Color(0xFFFEF2F2),
                    border: Border.all(
                      color: PmsTheme.error.withValues(alpha: 0.35),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Couldn’t load product types',
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
                            context.read<ProductTypeBloc>().add(
                                  const FetchProductTypesEvent(),
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

                if (state is ProductTypeLoaded) {
                  final types = state.productTypes.where((pt) {
                    final matchesQuery =
                        _searchQuery.isEmpty ||
                        pt.name.toLowerCase().contains(_searchQuery) ||
                        (pt.productCode?.toLowerCase().contains(_searchQuery) ??
                            false) ||
                        (pt.category?.name
                                .toLowerCase()
                                .contains(_searchQuery) ??
                            false);

                    final matchesCat =
                        _selectedCategoryId == null ||
                        pt.categoryId == _selectedCategoryId;

                    return matchesQuery && matchesCat;
                  }).toList();

                  if (types.isEmpty) {
                    return PmsEmptyState(
                      icon: Icons.layers_clear_rounded,
                      title: 'No product types found',
                      subtitle:
                          'Try another search or category filter, or add a product type.',
                      actionLabel:
                          widget.isSuperAdmin ? 'Add Product Type' : null,
                      onAction: widget.isSuperAdmin
                          ? () => _showProductTypeForm(context)
                          : null,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: types.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pt = types[index];
                      return _buildProductTypeCard(context, pt);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeCard(BuildContext context, ProductTypeModel pt) {
    final isHospital = pt.category?.name == 'Hospital';
    final categoryColor = isHospital ? PmsTheme.error : PmsTheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PmsTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PmsTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  pt.productCode ?? '000000',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: PmsTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pt.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID #${pt.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PmsTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PmsStatusChip(
                label: pt.category?.name ?? 'Category',
                color: categoryColor,
              ),
            ],
          ),

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit product type',
                  onPressed: () =>
                      _showProductTypeForm(context, productType: pt),
                ),
                const SizedBox(width: 8),
                PmsIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete product type',
                  color: PmsTheme.error,
                  onPressed: () => _confirmDelete(context, pt),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
