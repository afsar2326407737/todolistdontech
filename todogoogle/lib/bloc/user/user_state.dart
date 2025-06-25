import 'package:equatable/equatable.dart';
import '../../model/user_model.dart';

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

class UserAuthenticated extends UserState {
  final UserModel user;

  const UserAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class UserUnauthenticated extends UserState {
  const UserUnauthenticated();
}

class UserOperationSuccess extends UserState {
  final String message;
  final UserModel? user;

  const UserOperationSuccess({required this.message, this.user});

  @override
  List<Object?> get props => [message, user];
}

class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object> get props => [message];
}

class UsersListLoaded extends UserState {
  final List<UserModel> users;

  const UsersListLoaded({required this.users});

  @override
  List<Object> get props => [users];
}

class UserSearchResultsLoaded extends UserState {
  final List<UserModel> users;
  final String searchTerm;

  const UserSearchResultsLoaded({
    required this.users,
    required this.searchTerm,
  });

  @override
  List<Object> get props => [users, searchTerm];
}

class PasswordChangedSuccess extends UserState {
  final String message;

  const PasswordChangedSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class UserDeletedSuccess extends UserState {
  final String message;

  const UserDeletedSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
