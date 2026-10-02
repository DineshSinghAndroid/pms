import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';
import '../../models/store_inventory_model.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoreLoaded extends StoreState {
  final StoreStatsModel stats;
  final List<CategoryModel> categories;
  final List<StoreProductModel> products;
  final int? selectedCategoryId;
  final String selectedStockStatus;
  final String searchQuery;
  final bool isAdjusting;

  const StoreLoaded({
    required this.stats,
    required this.categories,
    required this.products,
    this.selectedCategoryId,
    this.selectedStockStatus = 'all',
    this.searchQuery = '',
    this.isAdjusting = false,
  });

  StoreLoaded copyWith({
    StoreStatsModel? stats,
    List<CategoryModel>? categories,
    List<StoreProductModel>? products,
    int? selectedCategoryId,
    bool clearCategoryId = false,
    String? selectedStockStatus,
    String? searchQuery,
    bool? isAdjusting,
  }) {
    return StoreLoaded(
      stats: stats ?? this.stats,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      selectedCategoryId: clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedStockStatus: selectedStockStatus ?? this.selectedStockStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      isAdjusting: isAdjusting ?? this.isAdjusting,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        categories,
        products,
        selectedCategoryId,
        selectedStockStatus,
        searchQuery,
        isAdjusting,
      ];
}

class StoreError extends StoreState {
  final String message;

  const StoreError({required this.message});

  @override
  List<Object?> get props => [message];
}
