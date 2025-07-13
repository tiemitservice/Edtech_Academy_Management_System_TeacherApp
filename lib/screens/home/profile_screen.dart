import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';

/// Represents the data structure for a staff member's profile.
class StaffProfile {
  final String imageUrl;
  final String fullName;
  final String email;

  StaffProfile({
    required this.imageUrl,
    required this.fullName,
    required this.email,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      imageUrl: json['image'] as String? ?? '',
      fullName: json['en_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController _authController;

  StaffProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _errorRed = Color(0xFFDC3545);
  static const Color _profileAvatarDefaultBgColor = Colors.grey;
  static const Color _profileAvatarDefaultTextColor = Colors.white;

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  @override
  void initState() {
    super.initState();
    try {
      _authController = Get.find<AuthController>();
      _fetchUserProfile();
    } catch (e) {
      print("ERROR: AuthController not found in ProfileScreen: $e");
      setState(() {
        _errorMessage = 'Initialization Error: Could not find user session.';
        _isLoading = false;
      });
      // Also show a snackbar for immediate feedback
      Get.snackbar('Initialization Error',
          'Could not find user session. Please ensure you are logged in.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          messageText: Text(
              'Could not find user session. Please ensure you are logged in.',
              style: const TextStyle(
                  fontFamily: _fontFamily, color: Colors.white)),
          titleText: Text('Initialization Error',
              style: const TextStyle(
                  fontFamily: _fontFamily, color: Colors.white)));
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userProfile = null;
    });

    try {
      final userEmail = await _authController.getUserEmail();
      print(
          "DEBUG: ProfileScreen _fetchUserProfile: User email from AuthController: $userEmail");

      if (userEmail.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User email not found. Please log in again.';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(Uri.parse(
          'https://edtech-academy-management-system-server.onrender.com/api/staffs?email=$userEmail'));
      print(
          "DEBUG: ProfileScreen _fetchUserProfile: API Response Status: ${response.statusCode}");
      print(
          "DEBUG: ProfileScreen _fetchUserProfile: API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> staffList = jsonData['data'];

        final userMap = staffList.firstWhereOrNull(
          (staff) => staff['email'] == userEmail,
        );

        if (userMap != null) {
          if (mounted) {
            setState(() {
              _userProfile = StaffProfile.fromJson(userMap);
              _isLoading = false;
            });
          }
          _checkIncompleteProfileData();
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'profile_not_found';
              _isLoading = false;
            });
          }
          print("User not found with email: $userEmail");
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load profile data: Server responded with status ${response.statusCode}.';
            _isLoading = false;
          });
        }
        print('Failed to load data: ${response.statusCode}');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
      print('Error fetching profile: $e');
    }
  }

  void _checkIncompleteProfileData() {
    if (_userProfile != null) {
      if (_userProfile!.fullName.trim().isEmpty ||
          _userProfile!.email.trim().isEmpty) {
        _errorMessage =
            'Your profile information is incomplete. Please edit your profile to add your full name and email.';
      } else if (_userProfile!.imageUrl.isEmpty) {
        _errorMessage =
            'Consider uploading a profile picture to personalize your account!';
      } else {
        _errorMessage = null;
      }
      if (mounted) {
        setState(() {}); // Rebuild to show updated _errorMessage state
      }
    }
  }

  /// Displays the profile image in full screen.
  void _viewFullScreenImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      Get.to(() => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
            body: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 100,
                  );
                },
              ),
            ),
          ));
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final shouldLogout = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to log out from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: _fontFamily, // Apply NotoSerifKhmer
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black87),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _fontFamily, // Apply NotoSerifKhmer
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _authController.deleteToken();
                        Get.back(result: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontFamily: _fontFamily, // Apply NotoSerifKhmer
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      await _authController.deleteToken();
      Get.toNamed('/login'); // Navigate to login and clear stack
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Get.toNamed('/home'); // Navigate to home and clear stack
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.black,
              fontFamily: _fontFamily), // Apply NotoSerifKhmer
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _errorMessage != null
              ? _buildErrorView(_errorMessage!)
              : _buildProfileView(),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Container(
              height: 18,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            ...List.generate(3, (_) => _buildSkeletonTile()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    bool isProfileNotFound = message == 'profile_not_found';
    // Check for specific error messages that indicate a network issue
    bool isConnectionError = message.contains('Network Error') ||
        message.contains('No internet connection');
    bool isGenericApiError = message.contains('Failed to load profile data') ||
        message.contains('An unexpected error occurred');
    bool isWarning = message.contains('incomplete') ||
        message.contains('Consider uploading');

    IconData icon = Icons.info_outline;
    Color iconColor = Colors.orange;
    String title = 'Information';
    String displayMessage = message;
    Color titleColor = Colors.orange.shade800;
    Color textColor = Colors.grey.shade700;
    VoidCallback? onMainActionButtonTap;
    String mainActionButtonText = 'Retry';

    if (isProfileNotFound) {
      icon = Icons.person_off_outlined;
      iconColor = _errorRed;
      title = 'Profile Not Found';
      displayMessage =
          'We couldn\'t find your profile data. It might be deleted or an issue occurred with your account. Please try logging in again.';
      titleColor = _errorRed;
      textColor = _darkText;
      onMainActionButtonTap = () async {
        await _authController.deleteToken(); // Clear token
        Get.toNamed('/login'); // Navigate to login
      };
      mainActionButtonText = 'Log In Again';
    } else if (isConnectionError || isGenericApiError) {
      icon = Icons.error_outline;
      iconColor = _errorRed;
      title = 'Error';
      displayMessage = message;
      titleColor = _errorRed;
      textColor = _darkText;
      onMainActionButtonTap = _fetchUserProfile;
      mainActionButtonText = 'Retry';
    } else if (isWarning) {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.amber.shade700;
      title = 'Important!';
      displayMessage = message;
      titleColor = Colors.amber.shade800;
      textColor = _darkText;
      onMainActionButtonTap = () {
        // Navigate to edit profile, and refresh this screen on return
        Get.toNamed('/edit-profile')?.then((result) {
          // You might get 'true' on successful edit, or null/false otherwise.
          // Refresh regardless to ensure state consistency.
          _fetchUserProfile();
        });
      };
      mainActionButtonText = 'Edit Profile';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
            ),
            if (onMainActionButtonTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onMainActionButtonTap,
                icon: Icon(isProfileNotFound
                    ? Icons.login
                    : (isWarning ? Icons.edit : Icons.refresh)),
                label: Text(mainActionButtonText,
                    style: const TextStyle(
                        fontFamily: _fontFamily)), // Apply NotoSerifKhmer
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    if (_userProfile == null) {
      // This case should ideally be handled by _errorMessage, but as a fallback
      return Center(
        child: Text(
          'Failed to load profile data. Please refresh.',
          style: TextStyle(
              color: _darkText,
              fontFamily: _fontFamily), // Apply NotoSerifKhmer
        ),
      );
    }

    return SingleChildScrollView(
      // Added SingleChildScrollView to prevent overflow on small screens
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {
                if (_userProfile!.imageUrl.isNotEmpty) {
                  _viewFullScreenImage(_userProfile!.imageUrl);
                }
              },
              child: SuperProfilePicture(
                imageUrl: _userProfile!.imageUrl,
                fullName: _userProfile!.fullName,
                radius: 50,
                backgroundColor: _profileAvatarDefaultBgColor,
                borderColor: _primaryBlue,
                borderWidth: 2,
                textColor: _profileAvatarDefaultTextColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userProfile!.fullName.isNotEmpty
                ? _userProfile!.fullName
                : 'No Name Provided',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                color: _userProfile!.fullName.isNotEmpty
                    ? _darkText
                    : Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _userProfile!.email.isNotEmpty
                  ? _userProfile!.email
                  : 'No Email Provided',
              style: TextStyle(
                color: _primaryBlue,
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                fontStyle: _userProfile!.email.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null &&
              !_isLoading &&
              _errorMessage != 'profile_not_found')
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errorMessage!.contains('incomplete') ||
                          _errorMessage!.contains('Consider uploading')
                      ? Colors.orange.shade50.withOpacity(0.8)
                      : _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _errorMessage!.contains('incomplete') ||
                            _errorMessage!.contains('Consider uploading')
                        ? Colors.orange.shade200
                        : _errorRed.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _errorMessage!.contains('incomplete') ||
                              _errorMessage!.contains('Consider uploading')
                          ? Icons.info_outline
                          : Icons.error_outline,
                      color: _errorMessage!.contains('incomplete') ||
                              _errorMessage!.contains('Consider uploading')
                          ? Colors.orange.shade700
                          : _errorRed,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: _errorMessage!.contains('incomplete') ||
                                  _errorMessage!.contains('Consider uploading')
                              ? Colors.orange.shade900
                              : _darkText,
                          fontSize: 13,
                          fontFamily: _fontFamily, // Apply NotoSerifKhmer
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile',
                style:
                    TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.toNamed('/edit-profile')?.then((result) {
                // Refresh profile data when returning from edit screen
                _fetchUserProfile();
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings',
                style:
                    TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Get.snackbar(
                  'Coming Soon', 'Settings screen is under development!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: _primaryBlue.withOpacity(0.8),
                  colorText: Colors.white,
                  messageText: Text('Settings screen is under development!',
                      style: const TextStyle(
                          fontFamily: _fontFamily, color: Colors.white)),
                  titleText: Text('Coming Soon',
                      style: const TextStyle(
                          fontFamily: _fontFamily, color: Colors.white)));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(
                    color: Colors.red,
                    fontFamily: _fontFamily)), // Apply NotoSerifKhmer
            onTap: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
