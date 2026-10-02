import 'package:equatable/equatable.dart';
import '../../models/sub_store_model.dart';

abstract class SubStoreState extends Equatable {
  const SubStoreState();

  @override
  List<Object?> get props => [];
}

class SubStoreInitial extends SubStoreState {
  const SubStoreInitial();
}

class SubStoreLoading extends SubStoreState {
  const SubStoreLoading();
}

class SubStoreLoaded extends SubStoreState {
  final SubStoreStatsModel stats;
  final List<SubStoreStockModel> items;
  final List<SubStoreConsumptionModel> consumptions;
  final List<SubStoreEntityModel> subStores;
  final int? selectedSubStoreId;
  final String selectedStockStatus;
  final String searchQuery;
  final bool isSaving;

  const SubStoreLoaded({
    required this.stats,
    required this.items,
    this.consumptions = const [],
    this.subStores = const [],
    this.selectedSubStoreId,
    this.selectedStockStatus = 'all',
    this.searchQuery = '',
    this.isSaving = false,
  });

  SubStoreLoaded copyWith({
    SubStoreStatsModel? stats,
    List<SubStoreStockModel>? items,
    List<SubStoreConsumptionModel>? consumptions,
    List<SubStoreEntityModel>? subStores,
    int? selectedSubStoreId,
    bool clearSubStoreFilter = false,
    String? selectedStockStatus,
    String? searchQuery,
    bool? isSaving,
  }) {
    return SubStoreLoaded(
      stats: stats ?? this.stats,
      items: items ?? this.items,
      consumptions: consumptions ?? this.consumptions,
      subStores: subStores ?? this.subStores,
      selectedSubStoreId: clearSubStoreFilter
          ? null
          : (selectedSubStoreId ?? this.selectedSubStoreId),
      selectedStockStatus: selectedStockStatus ?? this.selectedStockStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        items,
        consumptions,
        subStores,
        selectedSubStoreId,
        selectedStockStatus,
        searchQuery,
        isSaving,
      ];
}

class SubStoreError extends SubStoreState {
  final String message;

  const SubStoreError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SubStoreActionSuccess extends SubStoreState {
  final String message;

  const SubStoreActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
