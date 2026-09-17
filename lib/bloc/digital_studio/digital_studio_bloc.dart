import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/digital_studio_asset_model.dart';
import '../../models/digital_studio_crew_request_model.dart';
import '../../models/user_model.dart';
import '../../repositories/digital_studio_repository.dart';
import 'digital_studio_event.dart';
import 'digital_studio_state.dart';

class DigitalStudioBloc extends Bloc<DigitalStudioEvent, DigitalStudioState> {
  final DigitalStudioRepository repository;

  DigitalStudioBloc({required this.repository})
    : super(const DigitalStudioInitial()) {
    on<FetchDigitalStudioDataEvent>(_onFetchData);
    on<RefreshDigitalStudioEvent>(_onRefreshData);
    on<CreateAssetEvent>(_onCreateAsset);
    on<AssignAssetEvent>(_onAssignAsset);
    on<ReturnAssetEvent>(_onReturnAsset);
    on<ReassignAssetEvent>(_onReassignAsset);
    on<UpdateAssetStatusEvent>(_onUpdateAssetStatus);
    on<CreateCrewRequestEvent>(_onCreateCrewRequest);
    on<AllotCrewRequestEvent>(_onAllotCrewRequest);
    on<UpdateCrewRequestStatusEvent>(_onUpdateCrewRequestStatus);
  }

  Future<void> _onFetchData(
    FetchDigitalStudioDataEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    emit(const DigitalStudioLoading());
    try {
      final assetsFuture = repository.getAssets(phone: event.phone).catchError((_) => <DigitalStudioAssetModel>[]);
      final crewRequestsFuture = repository.getCrewRequests(
        wingId: event.wingId,
        phone: event.phone,
      ).catchError((_) => <DigitalStudioCrewRequestModel>[]);
      final schedulesFuture = repository.getScheduleCalendar(phone: event.phone).catchError((_) => <DigitalStudioCrewRequestModel>[]);
      final crewMembersFuture = repository.getCrewMembers().catchError((_) => <UserModel>[]);
      final availableAssetsFuture = repository.getAvailableAssets().catchError((_) => <DigitalStudioAssetModel>[]);

      final results = await Future.wait([
        assetsFuture,
        crewRequestsFuture,
        schedulesFuture,
        crewMembersFuture,
        availableAssetsFuture,
      ]);

      emit(
        DigitalStudioLoaded(
          assets: results[0] as List<DigitalStudioAssetModel>,
          crewRequests: results[1] as List<DigitalStudioCrewRequestModel>,
          schedules: results[2] as List<DigitalStudioCrewRequestModel>,
          crewMembers: results[3] as List<UserModel>,
          availableAssets: results[4] as List<DigitalStudioAssetModel>,
        ),
      );
    } catch (e) {
      emit(
        DigitalStudioError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRefreshData(
    RefreshDigitalStudioEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      final assetsFuture = repository.getAssets(phone: event.phone).catchError((_) => <DigitalStudioAssetModel>[]);
      final crewRequestsFuture = repository.getCrewRequests(
        wingId: event.wingId,
        phone: event.phone,
      ).catchError((_) => <DigitalStudioCrewRequestModel>[]);
      final schedulesFuture = repository.getScheduleCalendar(phone: event.phone).catchError((_) => <DigitalStudioCrewRequestModel>[]);
      final crewMembersFuture = repository.getCrewMembers().catchError((_) => <UserModel>[]);
      final availableAssetsFuture = repository.getAvailableAssets().catchError((_) => <DigitalStudioAssetModel>[]);

      final results = await Future.wait([
        assetsFuture,
        crewRequestsFuture,
        schedulesFuture,
        crewMembersFuture,
        availableAssetsFuture,
      ]);

      emit(
        DigitalStudioLoaded(
          assets: results[0] as List<DigitalStudioAssetModel>,
          crewRequests: results[1] as List<DigitalStudioCrewRequestModel>,
          schedules: results[2] as List<DigitalStudioCrewRequestModel>,
          crewMembers: results[3] as List<UserModel>,
          availableAssets: results[4] as List<DigitalStudioAssetModel>,
        ),
      );
    } catch (e) {
      emit(
        DigitalStudioError(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _emitActionError(Emitter<DigitalStudioState> emit, Object error) {
    final msg = error.toString().replaceAll('Exception: ', '');
    if (state is DigitalStudioLoaded) {
      emit((state as DigitalStudioLoaded).copyWith(errorMessage: msg));
    } else {
      emit(DigitalStudioError(errorMessage: msg));
    }
  }

  Future<void> _onCreateAsset(
    CreateAssetEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.createAsset(event.payload, phone: event.phone);
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onAssignAsset(
    AssignAssetEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.assignAsset(
        event.assetId,
        userId: event.userId,
        requestId: event.requestId,
        remarks: event.remarks,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onReturnAsset(
    ReturnAssetEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.returnAsset(
        event.assetId,
        remarks: event.remarks,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onReassignAsset(
    ReassignAssetEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.reassignAsset(
        event.assetId,
        userId: event.userId,
        requestId: event.requestId,
        remarks: event.remarks,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onUpdateAssetStatus(
    UpdateAssetStatusEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.updateAssetStatus(
        event.assetId,
        status: event.status,
        remarks: event.remarks,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onCreateCrewRequest(
    CreateCrewRequestEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.createCrewRequest(event.payload, phone: event.phone);
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onAllotCrewRequest(
    AllotCrewRequestEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.allotCrewRequest(
        event.requestId,
        employeeIds: event.employeeIds,
        assetIds: event.assetIds,
        remarks: event.remarks,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onUpdateCrewRequestStatus(
    UpdateCrewRequestStatusEvent event,
    Emitter<DigitalStudioState> emit,
  ) async {
    try {
      await repository.updateCrewRequestStatus(
        event.requestId,
        status: event.status,
        latitude: event.latitude,
        longitude: event.longitude,
        phone: event.phone,
      );
      add(RefreshDigitalStudioEvent(phone: event.phone));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }
}
