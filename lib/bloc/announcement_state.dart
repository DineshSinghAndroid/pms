import 'package:equatable/equatable.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementState extends Equatable {
  const AnnouncementState();

  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {
  const AnnouncementInitial();
}

class AnnouncementLoading extends AnnouncementState {
  const AnnouncementLoading();
}

class AnnouncementLoaded extends AnnouncementState {
  final AnnouncementModel announcement;

  const AnnouncementLoaded({required this.announcement});

  @override
  List<Object?> get props => [announcement];
}

class AnnouncementError extends AnnouncementState {
  final String errorMessage;

  const AnnouncementError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
