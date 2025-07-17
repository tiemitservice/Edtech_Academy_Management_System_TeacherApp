// lib/controllers/auth_controller.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  // Instance of FlutterSecureStorage for secure data storage (like tokens)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Saves the authentication token securely using FlutterSecureStorage.
  /// This token is typically received after a successful login.
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'token', value: token);
      print("Token saved: $token");
    } catch (e) {
      print("Error saving token: $e");
    }
  }

  /// Retrieves the authentication token securely from FlutterSecureStorage.
  /// Returns the token string or null if not found or an error occurs.
  Future<String?> getToken() async {
    try {
      print("Getting token");
      return await _storage.read(key: 'token');
    } catch (e) {
      print("Error reading token: $e");
      return null;
    }
  }

  /// Deletes the authentication token from secure storage.
  Future<void> deleteToken() async {
    print("Deleting token");
    await _storage.delete(key: 'token');
  }

  /// Checks if an authentication token exists in secure storage.
  /// Returns true if a token is found, false otherwise.
  Future<bool> hasToken() async {
    return await _storage.containsKey(key: 'token');
  }

  /// Logs out the user by clearing all stored authentication and user data.
  /// This includes data from both secure storage and shared preferences.
  Future<void> logout() async {
    print("Logging out...");
    await clearAll(); // Clears both secure and shared data
    // After logout, you might want to navigate to the login screen
    // Get.offAllNamed(AppRoutes.login); // Uncomment if you have AppRoutes.login
  }

  /// Clears all data stored in both FlutterSecureStorage and SharedPreferences.
  /// Useful for a complete logout or app reset.
  Future<void> clearAll() async {
    print("Clearing all data...");
    await _storage.deleteAll(); // Clears all data from secure storage

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all data from shared preferences
  }

  /// Saves the user's email to SharedPreferences.
  Future<void> saveUserEmail(String email) async {
    print("Saving user email: $email");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  /// Retrieves the user's email from SharedPreferences.
  /// Returns the email string or an empty string if not found.
  Future<String> getUserEmail() async {
    print("Getting user email");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? "";
  }

  /// Deletes the user's email from SharedPreferences.
  Future<void> deleteUserEmail() async {
    print("Deleting user email");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
  }

  /// Saves the user's ID to SharedPreferences.
  Future<void> saveUserId(String userId) async {
    print("Saving user id: $userId");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  /// Retrieves the user's ID from SharedPreferences.
  /// Returns the user ID string or an empty string if not found.
  Future<String> getUserId() async {
    print("Getting user id");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? "";
  }

  /// Deletes the user's ID from SharedPreferences.
  Future<void> deleteUserId() async {
    print("Deleting user id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  /// Saves the user's name to SharedPreferences.
  Future<void> saveUserName(String userName) async {
    print("Saving user name: $userName");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userName);
  }

  /// Retrieves the user's name from SharedPreferences.
  /// Returns the username string or null if not found.
  Future<String?> getUserName() async {
    print("Getting user name");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  /// Deletes the user's name from SharedPreferences.
  Future<void> deleteUserName() async {
    print("Deleting user name");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
  }

  /// Retrieves the user's ID from SharedPreferences (duplicate of getUserId, consider consolidating).
  /// This method seems to be a duplicate of `getUserId()`.
  /// It's recommended to use `getUserId()` for consistency.
  Future<String> getUserDetails() async {
    print("Getting user id (via getUserDetails)");
    final prefs = await SharedPreferences.getInstance();
    print("user id: ${prefs.getString('userId')}");
    return prefs.getString('userId') ?? "";
  }

  /// Saves the staff ID to SharedPreferences.
  /// This is the crucial ID for filtering teacher-specific data.
  Future<void> saveStaffId(String staffId) async {
    print("Saving staff id: $staffId");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffId', staffId);
  }

  /// Retrieves the staff ID from SharedPreferences.
  /// Returns the staff ID string or an empty string if not found.
  /// This method is used by services and controllers to filter data by the logged-in teacher.
  Future<String> getStaffId() async {
    print("Getting staff id");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('staffId') ?? "";
  }

  /// Deletes the staff ID from SharedPreferences.
  Future<void> deleteStaffId() async {
    print("Deleting staff id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staffId');
  }
}
