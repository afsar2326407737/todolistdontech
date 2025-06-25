import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class SignUpEvent extends UserEvent {
  final String email;
  final String password;
  final String name;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class LoginEvent extends UserEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutEvent extends UserEvent {
  const LogoutEvent();
}

class GetUserByIdEvent extends UserEvent {
  final String userId;

  const GetUserByIdEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class ChangePasswordEvent extends UserEvent {
  final String userId;
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEvent({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [userId, currentPassword, newPassword];
}

class LoadUserFromLocalEvent extends UserEvent {
  const LoadUserFromLocalEvent();
}

class UpdateProfileEvent extends UserEvent {
  final String userId;
  final String name;
  final String email;

  const UpdateProfileEvent({
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  List<Object> get props => [userId, name, email];
}

class UpdateProfileImageEvent extends UserEvent {
  final String userId;
  final String imagePath;

  const UpdateProfileImageEvent({
    required this.userId,
    required this.imagePath,
  });

  @override
  List<Object> get props => [userId, imagePath];
}
