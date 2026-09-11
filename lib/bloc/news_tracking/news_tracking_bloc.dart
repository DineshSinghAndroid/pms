import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/newspaper_model.dart';
import '../../models/newspaper_size_model.dart';
import '../../models/wing_model.dart';
import '../../repositories/news_tracking_repository.dart';
import 'news_tracking_event.dart';
import 'news_tracking_state.dart';

class NewsTrackingBloc extends Bloc<NewsTrackingEvent, NewsTrackingState> {
  final NewsTrackingRepository repository;

  NewsTrackingBloc({required this.repository})
      : super(NewsTrackingInitial()) {
    on<FetchNewsTrackingDataEvent>(_onFetchData);
    on<CreateNewsEntryEvent>(_onCreateEntry);
    on<UpdateNewsEntryEvent>(_onUpdateEntry);
    on<DeleteNewsEntryEvent>(_onDeleteEntry);
    on<CreateNewspaperMasterEvent>(_onCreateNewspaper);
    on<CreateSizeMasterEvent>(_onCreateSize);
  }

  Future<void> _onFetchData(
    FetchNewsTrackingDataEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NewsTrackingLoaded) {
      emit(NewsTrackingLoading());
    }

    try {
      final masters = await repository.getMasters(phone: event.phone);
      final newspapers = masters['newspapers'] as List<NewspaperModel>? ?? [];
      final sizes = masters['sizes'] as List<NewspaperSizeModel>? ?? [];
      final wings = masters['wings'] as List<WingModel>? ?? [];

      final entriesData = await repository.getEntries(
        search: event.search,
        wingId: event.wingId,
        newspaperId: event.newspaperId,
        sizeId: event.sizeId,
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
        phone: event.phone,
      );

      final entries = entriesData['entries'] as List<dynamic>? ?? [];
      final pagination = entriesData['pagination'] as Map<String, dynamic>? ?? {};
      final stats = entriesData['stats'] as Map<String, dynamic>? ?? {};

      emit(NewsTrackingLoaded(
        entries: entries.cast(),
        newspapers: newspapers,
        sizes: sizes,
        wings: wings,
        pagination: pagination,
        stats: stats,
        activeSearch: event.search,
        activeWingId: event.wingId,
        activeNewspaperId: event.newspaperId,
        activeSizeId: event.sizeId,
        activeStartDate: event.startDate,
        activeEndDate: event.endDate,
      ));
    } catch (e) {
      emit(NewsTrackingError(e.toString()));
    }
  }

  Future<void> _onCreateEntry(
    CreateNewsEntryEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    try {
      await repository.createEntry(
        adName: event.adName,
        publishDate: event.publishDate,
        wingId: event.wingId,
        newspaperId: event.newspaperId,
        newspaperSizeId: event.newspaperSizeId,
        link1: event.link1,
        link2: event.link2,
        remark: event.remark,
        localFilePath: event.localFilePath,
        phone: event.phone,
      );

      emit(const NewsTrackingActionSuccess('News entry created successfully'));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    } catch (e) {
      emit(NewsTrackingError(e.toString().replaceAll('Exception: ', '')));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    }
  }

  Future<void> _onUpdateEntry(
    UpdateNewsEntryEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    try {
      await repository.updateEntry(
        id: event.id,
        adName: event.adName,
        publishDate: event.publishDate,
        wingId: event.wingId,
        newspaperId: event.newspaperId,
        newspaperSizeId: event.newspaperSizeId,
        link1: event.link1,
        link2: event.link2,
        remark: event.remark,
        localFilePath: event.localFilePath,
        phone: event.phone,
      );

      emit(const NewsTrackingActionSuccess('News entry updated successfully'));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    } catch (e) {
      emit(NewsTrackingError(e.toString().replaceAll('Exception: ', '')));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    }
  }

  Future<void> _onDeleteEntry(
    DeleteNewsEntryEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    try {
      await repository.deleteEntry(event.id, phone: event.phone);
      emit(const NewsTrackingActionSuccess('News entry deleted successfully'));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    } catch (e) {
      emit(NewsTrackingError(e.toString().replaceAll('Exception: ', '')));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    }
  }

  Future<void> _onCreateNewspaper(
    CreateNewspaperMasterEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    try {
      await repository.createNewspaper(event.name, phone: event.phone);
      emit(const NewsTrackingActionSuccess('Newspaper publication added'));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    } catch (e) {
      emit(NewsTrackingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSize(
    CreateSizeMasterEvent event,
    Emitter<NewsTrackingState> emit,
  ) async {
    try {
      await repository.createSize(event.name, phone: event.phone);
      emit(const NewsTrackingActionSuccess('Ad dimension size added'));
      add(FetchNewsTrackingDataEvent(phone: event.phone));
    } catch (e) {
      emit(NewsTrackingError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
