import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/wing_repository.dart';
import 'wing_event.dart';
import 'wing_state.dart';

class WingBloc extends Bloc<WingEvent, WingState> {
  final WingRepository repository;

  WingBloc({required this.repository}) : super(const WingInitial()) {
    on<FetchWingsEvent>(_onFetchWings);
    on<RefreshWingsEvent>(_onRefreshWings);
    on<CreateWingEvent>(_onCreateWing);
    on<UpdateWingEvent>(_onUpdateWing);
    on<DeleteWingEvent>(_onDeleteWing);
  }

  Future<void> _onFetchWings(
    FetchWingsEvent event,
    Emitter<WingState> emit,
  ) async {
    emit(const WingLoading());
    try {
      final wings = await repository.getWings();
      emit(WingLoaded(wings: wings));
    } catch (e) {
      emit(WingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshWings(
    RefreshWingsEvent event,
    Emitter<WingState> emit,
  ) async {
    try {
      final wings = await repository.getWings();
      emit(WingLoaded(wings: wings));
    } catch (e) {
      emit(WingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateWing(
    CreateWingEvent event,
    Emitter<WingState> emit,
  ) async {
    try {
      await repository.createWing(event.payload);
      final wings = await repository.getWings();
      emit(WingLoaded(wings: wings));
    } catch (e) {
      emit(WingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateWing(
    UpdateWingEvent event,
    Emitter<WingState> emit,
  ) async {
    try {
      await repository.updateWing(event.wingId, event.payload);
      final wings = await repository.getWings();
      emit(WingLoaded(wings: wings));
    } catch (e) {
      emit(WingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteWing(
    DeleteWingEvent event,
    Emitter<WingState> emit,
  ) async {
    try {
      await repository.deleteWing(event.wingId);
      final wings = await repository.getWings();
      emit(WingLoaded(wings: wings));
    } catch (e) {
      emit(WingError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
