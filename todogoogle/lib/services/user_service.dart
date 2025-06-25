import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (999 * DateTime.now().microsecond / 1000).round()).toString();
  }

  // Sign up new user
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      // Create new user
      final String userId = _generateUserId();
      final String hashedPassword = _hashPassword(password);

      final UserModel newUser = UserModel(
        id: userId,
        email: email.toLowerCase().trim(),
        password: hashedPassword,
        name: name.trim(),
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(newUser.toMap());

      return newUser.toSafeModel(); // Return without password
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  // Login user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final String hashedPassword = _hashPassword(password);

      // Query user by email and password
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('password', isEqualTo: hashedPassword)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final Map<String, dynamic> userData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;

      final UserModel user = UserModel.fromMap(userData);
      return user.toSafeModel(); // Return without password
    } catch (e) {
      throw Exception('Failed to login: ${e.toString()}');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData).toSafeModel();
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final Map<String, dynamic> userData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;

      return UserModel.fromMap(userData).toSafeModel();
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }

  // Update user data
  Future<UserModel> updateUser({
    required String userId,
    String? name,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name.trim();
      }

      if (email != null) {
        // Check if new email already exists
        final existingUser = await getUserByEmail(email);
        if (existingUser != null && existingUser.id != userId) {
          throw Exception('Email already exists');
        }
        updateData['email'] = email.toLowerCase().trim();
      }

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update(updateData);

      // Return updated user
      final updatedUser = await getUserById(userId);
      if (updatedUser == null) {
        throw Exception('User not found after update');
      }

      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Change password
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get current user data with password
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      final UserModel user = UserModel.fromMap(userData);

      // Verify current password
      final String hashedCurrentPassword = _hashPassword(currentPassword);
      if (user.password != hashedCurrentPassword) {
        throw Exception('Current password is incorrect');
      }

      // Update with new password
      final String hashedNewPassword = _hashPassword(newPassword);
      await _firestore.collection(_collectionName).doc(userId).update({
        'password': hashedNewPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
            ).toSafeModel(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String searchTerm) async {
    try {
      final String lowerSearchTerm = searchTerm.toLowerCase().trim();

      // Search by name
      final QuerySnapshot nameQuery = await _firestore
          .collection(_collectionName)
          .where('name', isGreaterThanOrEqualTo: lowerSearchTerm)
          .where('name', isLessThan: '${lowerSearchTerm}z')
          .get();

      // Search by email
      final QuerySnapshot emailQuery = await _firestore
          .collection(_collectionName)
          .where('email', isGreaterThanOrEqualTo: lowerSearchTerm)
          .where('email', isLessThan: '${lowerSearchTerm}z')
          .get();

      // Combine results and remove duplicates
      final Set<String> userIds = <String>{};
      final List<UserModel> users = <UserModel>[];

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        final userData = doc.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(userData).toSafeModel();

        if (!userIds.contains(user.id)) {
          userIds.add(user.id);
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to search users: ${e.toString()}');
    }
  }
}
