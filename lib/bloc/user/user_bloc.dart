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
    emit(const UserLoading());
    try {
      final users = await repository.getUsers();
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      final users = await repository.getUsers();
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.createUser(event.payload);
      final users = await repository.getUsers();
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.updateUser(event.userId, event.payload);
      final users = await repository.getUsers();
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.deleteUser(event.userId);
      final users = await repository.getUsers();
      emit(UserLoaded(users: users));
    } catch (e) {
      emit(UserError(
          errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleUserActive(
    ToggleUserActiveEvent event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentList = (state as UserLoaded).users;
      try {
        final updatedUser = await repository.toggleUserActive(event.userId);
        final updatedList = currentList.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        emit(UserLoaded(users: updatedList));
      } catch (e) {
        emit(UserError(
            errorMessage: e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
