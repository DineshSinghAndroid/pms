import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/sub_store_model.dart';
import '../../repositories/sub_store_repository.dart';
import 'sub_store_event.dart';
import 'sub_store_state.dart';

class SubStoreBloc extends Bloc<SubStoreEvent, SubStoreState> {
  final SubStoreRepository repository;

  SubStoreBloc({required this.repository}) : super(const SubStoreInitial()) {
    on<FetchSubStoreInventoryEvent>(_onFetchSubStoreInventory);
    on<RefreshSubStoreInventoryEvent>(_onRefreshSubStoreInventory);
    on<FetchSubStoreConsumptionsEvent>(_onFetchSubStoreConsumptions);
    on<RecordSubStoreConsumptionEvent>(_onRecordSubStoreConsumption);
    on<FetchSubStoresListEvent>(_onFetchSubStoresList);
    on<CreateSubStoreEntityEvent>(_onCreateSubStoreEntity);
    on<UpdateSubStoreEntityEvent>(_onUpdateSubStoreEntity);
    on<DeleteSubStoreEntityEvent>(_onDeleteSubStoreEntity);
  }

  Future<void> _onFetchSubStoreInventory(
    FetchSubStoreInventoryEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    emit(const SubStoreLoading());
    try {
      final futures = await Future.wait([
        repository.fetchInventory(
          stockStatus: event.stockStatus,
          search: event.search,
          subStoreId: event.subStoreId,
        ),
        repository.fetchSubStores(),
        repository.fetchConsumptions(
          subStoreId: event.subStoreId,
        ),
      ]);

      final result = futures[0] as SubStoreInventoryResult;
      final stores = futures[1] as List<SubStoreEntityModel>;
      final consumptions = futures[2] as List<SubStoreConsumptionModel>;

      emit(SubStoreLoaded(
        stats: result.stats,
        items: result.items,
        consumptions: consumptions,
        subStores: stores,
        selectedSubStoreId: event.subStoreId,
        selectedStockStatus: event.stockStatus ?? 'all',
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshSubStoreInventory(
    RefreshSubStoreInventoryEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    try {
      final futures = await Future.wait([
        repository.fetchInventory(
          stockStatus: event.stockStatus,
          search: event.search,
          subStoreId: event.subStoreId,
        ),
        repository.fetchSubStores(),
        repository.fetchConsumptions(
          subStoreId: event.subStoreId,
        ),
      ]);

      final result = futures[0] as SubStoreInventoryResult;
      final stores = futures[1] as List<SubStoreEntityModel>;
      final consumptions = futures[2] as List<SubStoreConsumptionModel>;

      emit(SubStoreLoaded(
        stats: result.stats,
        items: result.items,
        consumptions: consumptions,
        subStores: stores,
        selectedSubStoreId: event.subStoreId,
        selectedStockStatus: event.stockStatus ?? 'all',
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchSubStoreConsumptions(
    FetchSubStoreConsumptionsEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;
    try {
      final consumptions = await repository.fetchConsumptions(
        subStoreId: event.subStoreId ?? current.selectedSubStoreId,
        userId: event.userId,
        search: event.search,
      );
      emit(current.copyWith(consumptions: consumptions));
    } catch (e) {
      debugPrint('Error fetching consumptions: $e');
    }
  }

  Future<void> _onRecordSubStoreConsumption(
    RecordSubStoreConsumptionEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;

    emit(current.copyWith(isSaving: true));

    try {
      await repository.recordConsumption(
        productTypeId: event.productTypeId,
        quantity: event.quantity,
        purpose: event.purpose,
        department: event.department,
        remarks: event.remarks,
      );

      // Re-fetch sub store inventory & consumptions to update counts & KPI cards
      final refreshed = await repository.fetchInventory(
        stockStatus: current.selectedStockStatus,
        search: current.searchQuery,
        subStoreId: current.selectedSubStoreId,
      );
      final refreshedConsumptions = await repository.fetchConsumptions(
        subStoreId: current.selectedSubStoreId,
      );

      emit(current.copyWith(
        stats: refreshed.stats,
        items: refreshed.items,
        consumptions: refreshedConsumptions,
        isSaving: false,
      ));

      emit(const SubStoreActionSuccess(
        message: 'Consumption recorded successfully!',
      ));
    } catch (e) {
      emit(current.copyWith(isSaving: false));
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchSubStoresList(
    FetchSubStoresListEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;
    try {
      final stores = await repository.fetchSubStores();
      emit(current.copyWith(subStores: stores));
    } catch (e) {
      // silent or error
    }
  }

  Future<void> _onCreateSubStoreEntity(
    CreateSubStoreEntityEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;
    emit(current.copyWith(isSaving: true));

    try {
      await repository.createSubStore(event.data);
      final stores = await repository.fetchSubStores();
      emit(current.copyWith(
        subStores: stores,
        isSaving: false,
      ));
      emit(const SubStoreActionSuccess(message: 'Sub-Store created successfully!'));
    } catch (e) {
      emit(current.copyWith(isSaving: false));
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSubStoreEntity(
    UpdateSubStoreEntityEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;
    emit(current.copyWith(isSaving: true));

    try {
      await repository.updateSubStore(event.id, event.data);
      final stores = await repository.fetchSubStores();
      emit(current.copyWith(
        subStores: stores,
        isSaving: false,
      ));
      emit(const SubStoreActionSuccess(message: 'Sub-Store updated successfully!'));
    } catch (e) {
      emit(current.copyWith(isSaving: false));
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteSubStoreEntity(
    DeleteSubStoreEntityEvent event,
    Emitter<SubStoreState> emit,
  ) async {
    if (state is! SubStoreLoaded) return;
    final current = state as SubStoreLoaded;
    emit(current.copyWith(isSaving: true));

    try {
      await repository.deleteSubStore(event.id);
      final stores = await repository.fetchSubStores();
      emit(current.copyWith(
        subStores: stores,
        isSaving: false,
      ));
      emit(const SubStoreActionSuccess(message: 'Sub-Store deleted successfully!'));
    } catch (e) {
      emit(current.copyWith(isSaving: false));
      emit(SubStoreError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
