import 'package:equatable/equatable.dart';

abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered on initial load
class FetchAnnouncementEvent extends AnnouncementEvent {
  const FetchAnnouncementEvent();
}

/// Event triggered on manual pull-to-refresh
class RefreshAnnouncementEvent extends AnnouncementEvent {
  const RefreshAnnouncementEvent();
}
