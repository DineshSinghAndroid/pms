import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsersEvent extends UserEvent {
  const FetchUsersEvent();
}

class RefreshUsersEvent extends UserEvent {
  const RefreshUsersEvent();
}

class CreateUserEvent extends UserEvent {
  final Map<String, dynamic> payload;

  const CreateUserEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateUserEvent extends UserEvent {
  final int userId;
  final Map<String, dynamic> payload;

  const UpdateUserEvent({required this.userId, required this.payload});

  @override
  List<Object?> get props => [userId, payload];
}

class DeleteUserEvent extends UserEvent {
  final int userId;

  const DeleteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ToggleUserActiveEvent extends UserEvent {
  final int userId;

  const ToggleUserActiveEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
