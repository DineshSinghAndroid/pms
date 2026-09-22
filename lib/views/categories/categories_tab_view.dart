import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/category/category_state.dart';
import '../../models/category_model.dart';
import '../../theme/pms_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pms_status_chip.dart';
import '../../widgets/pms_ui.dart';

class CategoriesTabView extends StatefulWidget {
  final bool isSuperAdmin;

  const CategoriesTabView({super.key, this.isSuperAdmin = true});

  @override
  State<CategoriesTabView> createState() => _CategoriesTabViewState();
}

class _CategoriesTabViewState extends State<CategoriesTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryForm(BuildContext context, {CategoryModel? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PmsTheme.glassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
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
                  title: category != null
                      ? 'Edit Print Category'
                      : 'Add Print Category',
                  subtitle: category != null
                      ? 'Update category name and description'
                      : 'Create a material grouping for product types',
                  onClose: () => Navigator.pop(modalCtx),
                ),
                const SizedBox(height: 8),

                _buildTextField(
                  controller: nameCtrl,
                  label: 'Category Name *',
                  hint: 'e.g. Education, Hospital, Study Material',
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: descCtrl,
                  label: 'Description',
                  hint: 'Brief summary of materials in this category...',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final desc = descCtrl.text.trim();

                    if (name.isEmpty) {
                      showPmsSnackBar(
                        context,
                        'Please enter category name',
                        kind: PmsSnackKind.error,
                      );
                      return;
                    }

                    final payload = {
                      'name': name,
                      'description': desc.isNotEmpty ? desc : null,
                    };

                    if (category != null) {
                      context.read<CategoryBloc>().add(
                        UpdateCategoryEvent(
                          categoryId: category.id,
                          payload: payload,
                        ),
                      );
                    } else {
                      context.read<CategoryBloc>().add(
                        CreateCategoryEvent(payload),
                      );
                    }

                    Navigator.pop(modalCtx);
                    showPmsSnackBar(
                      context,
                      category != null
                          ? '✓ Category updated!'
                          : '✓ Category created!',
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
                    category != null ? 'Save Changes' : 'Create Category',
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
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: PmsTheme.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Category',
            style: TextStyle(color: PmsTheme.textPrimary, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}"? Linked product types will also be deleted.',
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
                context.read<CategoryBloc>().add(
                  DeleteCategoryEvent(category.id),
                );
                Navigator.pop(dialogCtx);
                showPmsSnackBar(
                  context,
                  '✓ Category deleted',
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
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: PmsTheme.textPrimary),
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
        context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
        await context.read<CategoryBloc>().stream.firstWhere(
              (state) => state is CategoryLoaded || state is CategoryError,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PmsPageHeader(
              icon: Icons.category_rounded,
              title: 'Print Categories',
              subtitle: 'Material groupings for product types',
              action: widget.isSuperAdmin
                  ? FilledButton.icon(
                      onPressed: () => _showCategoryForm(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Category'),
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
                hintText: 'Search categories...',
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

            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }

                if (state is CategoryError) {
                  return GlassCard(
                    backgroundColor: const Color(0xFFFEF2F2),
                    border: Border.all(
                      color: PmsTheme.error.withValues(alpha: 0.35),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Couldn’t load categories',
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
                            context.read<CategoryBloc>().add(
                                  const FetchCategoriesEvent(),
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

                if (state is CategoryLoaded) {
                  final categories = state.categories.where((c) {
                    if (_searchQuery.isEmpty) return true;
                    return c.name.toLowerCase().contains(_searchQuery) ||
                        (c.description?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();

                  if (categories.isEmpty) {
                    return PmsEmptyState(
                      icon: Icons.folder_off_rounded,
                      title: 'No categories found',
                      subtitle:
                          'Try another search, or add a new print category.',
                      actionLabel:
                          widget.isSuperAdmin ? 'Add Category' : null,
                      onAction: widget.isSuperAdmin
                          ? () => _showCategoryForm(context)
                          : null,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return _buildCategoryCard(context, cat);
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

  Widget _buildCategoryCard(BuildContext context, CategoryModel cat) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Icons.folder_special_rounded,
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
                      cat.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: PmsTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Slug: ${cat.slug ?? ''}',
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
                label: '${cat.productTypesCount} Types',
                color: PmsTheme.primary,
              ),
            ],
          ),

          if (cat.description != null && cat.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              cat.description!,
              style: const TextStyle(
                fontSize: 12.5,
                color: PmsTheme.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (widget.isSuperAdmin) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PmsIconAction(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit category',
                  onPressed: () =>
                      _showCategoryForm(context, category: cat),
                ),
                const SizedBox(width: 8),
                PmsIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete category',
                  color: PmsTheme.error,
                  onPressed: () => _confirmDelete(context, cat),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
