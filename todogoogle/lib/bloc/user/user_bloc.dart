import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/user_model.dart';
import '../../services/user_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserService _userService;
  
  UserBloc({UserService? userService})
      : _userService = userService ?? UserService(),
        super(const UserInitial()) {
    
    // Register event handlers
    on<SignUpEvent>(_onSignUp);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<GetUserByIdEvent>(_onGetUserById);
    // on<UpdateUserEvent>(_onUpdateUser);
    on<ChangePasswordEvent>(_onChangePassword);
    // on<DeleteUserEvent>(_onDeleteUser);
    // on<GetAllUsersEvent>(_onGetAllUsers);
    // on<SearchUsersEvent>(_onSearchUsers);
    // on<ClearUserStateEvent>(_onClearUserState);
    on<LoadUserFromLocalEvent>(_onLoadUserFromLocal);
  }

  // Sign up handler
  Future<void> _onSignUp(SignUpEvent event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    
    try {
      final UserModel user = await _userService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      
      // Save user to local storage
      await _saveUserToLocal(user);
      
      emit(UserAuthenticated(user: user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // Login handler
  Future<void> _onLogin(LoginEvent event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    
    try {
      final UserModel user = await _userService.login(
        email: event.email,
        password: event.password,
      );
      
      // Save user to local storage
      await _saveUserToLocal(user);
      
      emit(UserAuthenticated(user: user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // Logout handler
  Future<void> _onLogout(LogoutEvent event, Emitter<UserState> emit) async {
    try {
      // Clear user from local storage
      await _clearUserFromLocal();
      
      emit(const UserUnauthenticated());
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // Get user by ID handler
  Future<void> _onGetUserById(GetUserByIdEvent event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    
    try {
      final UserModel? user = await _userService.getUserById(event.userId);
      
      if (user != null) {
        emit(UserAuthenticated(user: user));
      } else {
        emit(const UserError(message: 'User not found'));
      }
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // // Update user handler
  // Future<void> _onUpdateUser(UpdateUserEvent event, Emitter<UserState> emit) async {
  //   emit(const UserLoading());
    
  //   try {
  //     final UserModel updatedUser = await _userService.updateUser(
  //       userId: event.userId,
  //       name: event.name,
  //       email: event.email,
  //     );
      
  //     // Update user in local storage
  //     await _saveUserToLocal(updatedUser);
      
  //     emit(UserOperationSuccess(
  //       message: 'User updated successfully',
  //       user: updatedUser,
  //     ));
  //   } catch (e) {
  //     emit(UserError(message: e.toString()));
  //   }
  // }

  // Change password handler
  Future<void> _onChangePassword(ChangePasswordEvent event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    
    try {
      await _userService.changePassword(
        userId: event.userId,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      
      emit(const PasswordChangedSuccess(message: 'Password changed successfully'));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // // Delete user handler
  // Future<void> _onDeleteUser(DeleteUserEvent event, Emitter<UserState> emit) async {
  //   emit(const UserLoading());
    
  //   try {
  //     await _userService.deleteUser(event.userId);
      
  //     // Clear user from local storage if deleting current user
  //     await _clearUserFromLocal();
      
  //     emit(const UserDeletedSuccess(message: 'User deleted successfully'));
  //   } catch (e) {
  //     emit(UserError(message: e.toString()));
  //   }
  // }

  // // Get all users handler
  // Future<void> _onGetAllUsers(GetAllUsersEvent event, Emitter<UserState> emit) async {
  //   emit(const UserLoading());
    
  //   try {
  //     final List<UserModel> users = await _userService.getAllUsers();
      
  //     emit(UsersListLoaded(users: users));
  //   } catch (e) {
  //     emit(UserError(message: e.toString()));
  //   }
  // }

  // // Search users handler
  // Future<void> _onSearchUsers(SearchUsersEvent event, Emitter<UserState> emit) async {
  //   emit(const UserLoading());
    
  //   try {
  //     final List<UserModel> users = await _userService.searchUsers(event.searchTerm);
      
  //     emit(UserSearchResultsLoaded(
  //       users: users,
  //       searchTerm: event.searchTerm,
  //     ));
  //   } catch (e) {
  //     emit(UserError(message: e.toString()));
  //   }
  // }

  // // Clear user state handler
  // Future<void> _onClearUserState(ClearUserStateEvent event, Emitter<UserState> emit) async {
  //   emit(const UserInitial());
  // }

  // Load user from local storage handler
  Future<void> _onLoadUserFromLocal(LoadUserFromLocalEvent event, Emitter<UserState> emit) async {
    try {
      final UserModel? user = await _getUserFromLocal();
      
      if (user != null) {
        emit(UserAuthenticated(user: user));
      } else {
        emit(const UserUnauthenticated());
      }
    } catch (e) {
      emit(const UserUnauthenticated());
    }
  }

  // Helper method to save user to local storage
  Future<void> _saveUserToLocal(UserModel user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userJson = jsonEncode(user.toMap());
      await prefs.setString('current_user', userJson);
    } catch (e) {
      // Handle error silently or log it
      print('Error saving user to local storage: $e');
    }
  }

  // Helper method to get user from local storage
  Future<UserModel?> _getUserFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return UserModel.fromMap(userMap);
      }
      
      return null;
    } catch (e) {
      print('Error getting user from local storage: $e');
      return null;
    }
  }

  // Helper method to clear user from local storage
  Future<void> _clearUserFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      print('Error clearing user from local storage: $e');
    }
  }

  // Get current user from state
  UserModel? get currentUser {
    if (state is UserAuthenticated) {
      return (state as UserAuthenticated).user;
    }
    return null;
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    return state is UserAuthenticated;
  }
}