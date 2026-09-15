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

    // Get categories
    final catState = context.read<CategoryBloc>().state;
    final categories = catState is CategoryLoaded ? catState.categories : [];
    int? chosenCatId =
        productType?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create at least one Category before adding Product Types.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          productType != null
                              ? 'Edit Product Type'
                              : 'Add Product Type',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: PmsTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Select Category *
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
                              dropdownColor: Color(0xFFFFFFFF),
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

                    // 2. Product Name *
                    _buildTextField(
                      controller: nameCtrl,
                      label: 'Product Name *',
                      hint: 'e.g. Acrylic stand, Admission Form, Flex',
                    ),
                    const SizedBox(height: 12),

                    // 3. Product Code (Auto-Generated / Editable)
                    _buildTextField(
                      controller: codeCtrl,
                      label: 'Product Code (Auto-Generated e.g. 000112)',
                      hint: 'Leave blank to auto-generate',
                      isMonospace: true,
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final code = codeCtrl.text.trim();

                        if (name.isEmpty || chosenCatId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter Product Name and select Category',
                              ),
                              backgroundColor: Color(0xFFDC2626),
                            ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              productType != null
                                  ? '✓ Product Type updated!'
                                  : '✓ Product Type created!',
                            ),
                            backgroundColor: Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF059669),
                        foregroundColor: Color(0xFFFFFFFF),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Product Type deleted'),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC2626),
                foregroundColor: Color(0xFFFFFFFF),
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
            hintStyle: const TextStyle(color: PmsTheme.textSecondary, fontSize: 12),
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
                color: Color(0xFF059669),
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
      color: const Color(0xFF059669),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Product Types Master',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (widget.isSuperAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showProductTypeForm(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Product Type'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF059669),
                    foregroundColor: Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Search
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
            style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search product name or code (e.g. 000001)...',
              hintStyle: const TextStyle(
                color: PmsTheme.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: PmsTheme.textSecondary,
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: PmsTheme.textSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PmsTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF059669),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Filter Chips
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, catState) {
              if (catState is CategoryLoaded) {
                final categories = catState.categories;
                return SizedBox(
                  height: 36,
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

                      return ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? PmsTheme.textPrimary
                                : PmsTheme.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Color(0xFF059669),
                        backgroundColor: PmsTheme.glassSurface,
                        side: BorderSide(
                          color: isSelected
                              ? Color(0xFF059669)
                              : PmsTheme.glassBorder,
                        ),
                        onSelected: (selected) {
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

          const SizedBox(height: 16),

          // Product Types List
          BlocBuilder<ProductTypeBloc, ProductTypeState>(
            builder: (context, state) {
              if (state is ProductTypeLoading) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF059669),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              if (state is ProductTypeError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEF2F2).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFDC2626)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Failed to load product types: ${state.errorMessage}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProductTypeBloc>().add(
                            const FetchProductTypesEvent(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB91C1C),
                          foregroundColor: Color(0xFFFFFFFF),
                          textStyle: const TextStyle(fontSize: 11),
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
                      (pt.category?.name.toLowerCase().contains(_searchQuery) ??
                          false);

                  final matchesCat =
                      _selectedCategoryId == null ||
                      pt.categoryId == _selectedCategoryId;

                  return matchesQuery && matchesCat;
                }).toList();

                if (types.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
        color: PmsTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PmsTheme.glassBorder),
        boxShadow: PmsTheme.glassShadow,
                    ),
                    child: const Center(
                      child: Text(
                        'No product types found.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PmsTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: types.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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

    return Container(
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
              // Product Code Monospace Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: PmsTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PmsTheme.glassBorder),
                ),
                child: Text(
                  pt.productCode ?? '000000',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF059669),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PmsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: #${pt.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PmsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isHospital
                      ? Color(0xFFFEF2F2).withValues(alpha: 0.4)
                      : PmsTheme.backgroundGradientStart.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHospital ? Color(0xFFB91C1C) : PmsTheme.primary,
                  ),
                ),
                child: Text(
                  pt.category?.name ?? 'Category',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHospital ? Color(0xFFB91C1C) : PmsTheme.primary,
                  ),
                ),
              ),
            ],
          ),

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _showProductTypeForm(context, productType: pt),
                  icon: const Icon(Icons.edit, size: 12),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, pt),
                  icon: const Icon(Icons.delete_outline, size: 12),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
