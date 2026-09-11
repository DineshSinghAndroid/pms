import 'package:equatable/equatable.dart';

import '../../models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  final List<UserModel> users;

  const UserLoaded({required this.users});

  @override
  List<Object?> get props => [users];
}

class UserError extends UserState {
  final String errorMessage;

  const UserError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
