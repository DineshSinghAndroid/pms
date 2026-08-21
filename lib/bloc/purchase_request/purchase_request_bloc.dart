import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/purchase_request_repository.dart';
import 'purchase_request_event.dart';
import 'purchase_request_state.dart';

class PurchaseRequestBloc extends Bloc<PurchaseRequestEvent, PurchaseRequestState> {
  final PurchaseRequestRepository repository;

  PurchaseRequestBloc({required this.repository}) : super(const PurchaseRequestInitial()) {
    on<FetchPurchaseRequestsEvent>(_onFetchPurchaseRequests);
    on<CreatePurchaseRequestEvent>(_onCreatePurchaseRequest);
    on<AssignDesignerEvent>(_onAssignDesigner);
    on<StartWorkEvent>(_onStartWork);
    on<SubmitWorkEvent>(_onSubmitWork);
    on<ApprovePREvent>(_onApprovePR);
    on<RejectRevisionPREvent>(_onRejectRevisionPR);
    on<PostItPREvent>(_onPostItPR);
    on<CancelPostPREvent>(_onCancelPostPR);
    on<CancelPrintPREvent>(_onCancelPrintPR);
    on<DeletePurchaseRequestEvent>(_onDeletePurchaseRequest);
  }

  Future<void> _onFetchPurchaseRequests(
    FetchPurchaseRequestsEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    emit(const PurchaseRequestLoading());
    try {
      final requests = await repository.getPurchaseRequests(
        designerId: event.designerId,
        phone: event.phone,
        status: event.status,
        wingId: event.wingId,
      );
      emit(PurchaseRequestLoaded(requests: requests));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onCreatePurchaseRequest(
    CreatePurchaseRequestEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.createPurchaseRequest(event.payload);
      add(const FetchPurchaseRequestsEvent());
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onAssignDesigner(
    AssignDesignerEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.assignDesigner(event.prId, event.designerId);
      add(const FetchPurchaseRequestsEvent());
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onStartWork(
    StartWorkEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.startWork(event.prId, phone: event.phone);
      add(FetchPurchaseRequestsEvent(designerId: event.designerId, phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onSubmitWork(
    SubmitWorkEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.submitWork(
        event.prId,
        remarks: event.remarks,
        artworkPath: event.artworkPath,
        artworkName: event.artworkName,
        fileBytes: event.fileBytes,
        phone: event.phone,
      );
      add(FetchPurchaseRequestsEvent(designerId: event.designerId, phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onApprovePR(
    ApprovePREvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.approvePR(event.prId, remarks: event.remarks, phone: event.phone);
      add(FetchPurchaseRequestsEvent(phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onRejectRevisionPR(
    RejectRevisionPREvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.rejectRevisionPR(event.prId, remarks: event.remarks, phone: event.phone);
      add(FetchPurchaseRequestsEvent(phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onPostItPR(
    PostItPREvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.postIt(event.prId, remarks: event.remarks, phone: event.phone);
      add(FetchPurchaseRequestsEvent(phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onCancelPostPR(
    CancelPostPREvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.cancelPost(event.prId, phone: event.phone);
      add(FetchPurchaseRequestsEvent(phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onCancelPrintPR(
    CancelPrintPREvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.cancelPrint(event.prId, phone: event.phone);
      add(FetchPurchaseRequestsEvent(phone: event.phone));
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeletePurchaseRequest(
    DeletePurchaseRequestEvent event,
    Emitter<PurchaseRequestState> emit,
  ) async {
    try {
      await repository.deletePurchaseRequest(event.prId);
      add(const FetchPurchaseRequestsEvent());
    } catch (e) {
      emit(PurchaseRequestError(errorMessage: e.toString()));
    }
  }
}
