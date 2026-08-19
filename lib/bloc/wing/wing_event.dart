import 'package:equatable/equatable.dart';

abstract class WingEvent extends Equatable {
  const WingEvent();

  @override
  List<Object?> get props => [];
}

class FetchWingsEvent extends WingEvent {
  const FetchWingsEvent();
}

class RefreshWingsEvent extends WingEvent {
  const RefreshWingsEvent();
}

class CreateWingEvent extends WingEvent {
  final Map<String, dynamic> payload;

  const CreateWingEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateWingEvent extends WingEvent {
  final int wingId;
  final Map<String, dynamic> payload;

  const UpdateWingEvent({required this.wingId, required this.payload});

  @override
  List<Object?> get props => [wingId, payload];
}

class DeleteWingEvent extends WingEvent {
  final int wingId;

  const DeleteWingEvent(this.wingId);

  @override
  List<Object?> get props => [wingId];
}
