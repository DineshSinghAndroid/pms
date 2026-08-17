import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/announcement_repository.dart';
import 'announcement_event.dart';
import 'announcement_state.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository repository;

  AnnouncementBloc({required this.repository})
      : super(const AnnouncementInitial()) {
    on<FetchAnnouncementEvent>(_onFetchAnnouncement);
    on<RefreshAnnouncementEvent>(_onRefreshAnnouncement);
  }

  Future<void> _onFetchAnnouncement(
    FetchAnnouncementEvent event,
    Emitter<AnnouncementState> emit,
  ) async {
    emit(const AnnouncementLoading());
    try {
      final announcement = await repository.getLatestAnnouncement();
      emit(AnnouncementLoaded(announcement: announcement));
    } catch (e) {
      emit(AnnouncementError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshAnnouncement(
    RefreshAnnouncementEvent event,
    Emitter<AnnouncementState> emit,
  ) async {
    try {
      final announcement = await repository.getLatestAnnouncement();
      emit(AnnouncementLoaded(announcement: announcement));
    } catch (e) {
      emit(AnnouncementError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
