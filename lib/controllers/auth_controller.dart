import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Saves the token securely
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'token', value: token);
      print("Token saved: $token");
    } catch (e) {
      print("Error saving token: $e");
    }
  }

  /// Retrieves the token securely
  Future<String?> getToken() async {
    try {
      print("Getting token");
      return await _storage.read(key: 'token');
    } catch (e) {
      print("Error reading token: $e");
      return null;
    }
  }

  /// Deletes the token securely
  Future<void> deleteToken() async {
    print("Deleting token");
    await _storage.delete(key: 'token');
  }

  /// Checks if the token exists
  Future<bool> hasToken() async {
    return await _storage.containsKey(key: 'token');
  }

  Future<void> logout() async {
    print("Logging out...");
    await clearAll(); // Clears both secure and shared data
  }

  Future<void> clearAll() async {
    print("Clearing all data...");
    await _storage.deleteAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all shared preferences
  }

  // save user Email
  Future<void> saveUserEmail(String email) async {
    print("Saving user email: $email");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  // get user Email
  Future<String> getUserEmail() async {
    print("Getting user email");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? "";
  }

  // delete user email
  Future<void> deleteUserEmail() async {
    print("Deleting user email");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
  }

// save user id
  Future<void> saveUserId(String userId) async {
    print("Saving user id: $userId");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // get user id
  Future<String> getUserId() async {
    print("Getting user id");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? "";
  }

  // delete user id
  Future<void> deleteUserId() async {
    print("Deleting user id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // save user name
  Future<void> saveUserName(String userName) async {
    print("Saving user name: $userName");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userName);
  }

  // get user name
  Future<String?> getUserName() async {
    print("Getting user name");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // delete user name
  Future<void> deleteUserName() async {
    print("Deleting user name");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
  }

  // get user id
  Future<String> getUserDetails() async {
    print("Getting user id");
    final prefs = await SharedPreferences.getInstance();
    print("user id: ${prefs.getString('userId')}");
    return prefs.getString('userId') ?? "";
  }

  // save staff id
  Future<void> saveStaffId(String staffId) async {
    print("Saving staff id: $staffId");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffId', staffId);
  }

  // get staff id
  Future<String> getStaffId() async {
    print("Getting staff id");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('staffId') ?? "";
  }

  // delete staff id
  Future<void> deleteStaffId() async {
    print("Deleting staff id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staffId');
  }
}
