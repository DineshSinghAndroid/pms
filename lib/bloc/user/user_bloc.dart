import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc({required this.repository}) : super(const UserInitial()) {
    on<FetchUsersEvent>(_onFetchUsers);
    on<RefreshUsersEvent>(_onRefreshUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<ToggleUserActiveEvent>(_onToggleUserActive);
  }

  Future<void> _onFetchUsers(
    FetchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] FetchUsersEvent triggered (phone: ${event.phone})');
    emit(const UserLoading());
    try {
      final users = await repository.getUsers(phone: event.phone);
      debugPrint('✅ [UserBloc] Emitting UserLoaded with ${users.length} users');
      emit(UserLoaded(users: users));
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ [UserBloc] Emitting UserError: $cleanErr');
      emit(UserError(errorMessage: cleanErr));
    }
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] RefreshUsersEvent triggered (phone: ${event.phone})');
    try {
      final users = await repository.getUsers(phone: event.phone);
      debugPrint('✅ [UserBloc] Refreshed ${users.length} users');
      emit(UserLoaded(users: users));
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ [UserBloc] Refresh error: $cleanErr');
      emit(UserError(errorMessage: cleanErr));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] CreateUserEvent: ${event.payload}');
    try {
      await repository.createUser(event.payload, phone: event.phone);
      final users = await repository.getUsers(phone: event.phone);
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] UpdateUserEvent: ID ${event.userId}');
    try {
      await repository.updateUser(event.userId, event.payload, phone: event.phone);
      final users = await repository.getUsers(phone: event.phone);
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] DeleteUserEvent: ID ${event.userId}');
    try {
      await repository.deleteUser(event.userId, phone: event.phone);
      final users = await repository.getUsers(phone: event.phone);
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleUserActive(
    ToggleUserActiveEvent event,
    Emitter<UserState> emit,
  ) async {
    debugPrint('🔄 [UserBloc] ToggleUserActiveEvent: ID ${event.userId}');
    if (state is UserLoaded) {
      final currentList = (state as UserLoaded).users;
      try {
        final updatedUser = await repository.toggleUserActive(event.userId, phone: event.phone);
        final updatedList = currentList.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(UserLoaded(users: updatedList));
      } catch (e) {
        emit(
          UserError(errorMessage: e.toString().replaceAll('Exception: ', '')),
        );
      }
    }
  }
}
