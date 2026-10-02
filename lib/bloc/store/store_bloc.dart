import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/store_repository.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreRepository repository;

  StoreBloc({required this.repository}) : super(const StoreInitial()) {
    on<FetchStoreInventoryEvent>(_onFetchStoreInventory);
    on<RefreshStoreInventoryEvent>(_onRefreshStoreInventory);
    on<AdjustStockEvent>(_onAdjustStock);
  }

  Future<void> _onFetchStoreInventory(
    FetchStoreInventoryEvent event,
    Emitter<StoreState> emit,
  ) async {
    emit(const StoreLoading());
    try {
      final result = await repository.fetchInventory(
        categoryId: event.categoryId,
        stockStatus: event.stockStatus,
        search: event.search,
      );

      emit(StoreLoaded(
        stats: result.stats,
        categories: result.categories,
        products: result.products,
        selectedCategoryId: event.categoryId,
        selectedStockStatus: event.stockStatus ?? 'all',
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(StoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshStoreInventory(
    RefreshStoreInventoryEvent event,
    Emitter<StoreState> emit,
  ) async {
    try {
      final result = await repository.fetchInventory(
        categoryId: event.categoryId,
        stockStatus: event.stockStatus,
        search: event.search,
      );

      emit(StoreLoaded(
        stats: result.stats,
        categories: result.categories,
        products: result.products,
        selectedCategoryId: event.categoryId,
        selectedStockStatus: event.stockStatus ?? 'all',
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(StoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAdjustStock(
    AdjustStockEvent event,
    Emitter<StoreState> emit,
  ) async {
    if (state is! StoreLoaded) return;
    final current = state as StoreLoaded;

    emit(current.copyWith(isAdjusting: true));

    try {
      final updatedProduct = await repository.adjustStock(
        event.productId,
        adjustmentType: event.adjustmentType,
        quantity: event.quantity,
        remarks: event.remarks,
      );

      // Re-fetch to get accurate global stats and refreshed list
      final refreshed = await repository.fetchInventory(
        categoryId: current.selectedCategoryId,
        stockStatus: current.selectedStockStatus,
        search: current.searchQuery,
      );

      emit(StoreLoaded(
        stats: refreshed.stats,
        categories: refreshed.categories,
        products: refreshed.products,
        selectedCategoryId: current.selectedCategoryId,
        selectedStockStatus: current.selectedStockStatus,
        searchQuery: current.searchQuery,
        isAdjusting: false,
      ));
    } catch (e) {
      emit(current.copyWith(isAdjusting: false));
      // Re-emit or show error
      emit(StoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
