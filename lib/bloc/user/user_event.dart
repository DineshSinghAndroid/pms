import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsersEvent extends UserEvent {
  final String? phone;
  const FetchUsersEvent({this.phone});

  @override
  List<Object?> get props => [phone];
}

class RefreshUsersEvent extends UserEvent {
  final String? phone;
  const RefreshUsersEvent({this.phone});

  @override
  List<Object?> get props => [phone];
}

class CreateUserEvent extends UserEvent {
  final Map<String, dynamic> payload;
  final String? phone;

  const CreateUserEvent(this.payload, {this.phone});

  @override
  List<Object?> get props => [payload, phone];
}

class UpdateUserEvent extends UserEvent {
  final int userId;
  final Map<String, dynamic> payload;
  final String? phone;

  const UpdateUserEvent({required this.userId, required this.payload, this.phone});

  @override
  List<Object?> get props => [userId, payload, phone];
}

class DeleteUserEvent extends UserEvent {
  final int userId;
  final String? phone;

  const DeleteUserEvent(this.userId, {this.phone});

  @override
  List<Object?> get props => [userId, phone];
}

class ToggleUserActiveEvent extends UserEvent {
  final int userId;
  final String? phone;

  const ToggleUserActiveEvent(this.userId, {this.phone});

  @override
  List<Object?> get props => [userId, phone];
}
