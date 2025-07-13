import 'dart:async'; // For TimeoutException
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart'; // Ensure this widget is correctly implemented and accessible

// ======================================================================
// CONSTANTS (Moved for better organization and consistency)
// ======================================================================

class AppColors {
  static const Color primaryBlue = Color(0xFF1469C7);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF7F8C8D);
  static const Color errorRed = Color(0xFFDC3545);
  static const Color warningOrange = Color(0xFFF39C12); // Specific for warnings
  static const Color successGreen = Color(0xFF27AE60);
  static const Color profileAvatarDefaultBgColor = Colors.grey;
  static const Color profileAvatarDefaultTextColor = Colors.white;
  static const Color shimmerBaseColor = Color(0xFFE0E0E0); // Light grey
  static const Color shimmerHighlightColor = Color(0xFFF0F0F0); // Lighter grey
}

class AppFonts {
  static const String fontFamily =
      'KantumruyPro'; // Ensure this font is correctly set up in pubspec.yaml
}

class AppDurations {
  static const Duration apiTimeout =
      Duration(seconds: 10); // Standard API timeout
  static const Duration snackbarDuration = Duration(seconds: 3);
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String editProfile = '/edit-profile'; // Example route
}

class AppApi {
  static const String baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api';
  static const String staffsEndpoint = '$baseUrl/staffs';
}

// ======================================================================
// DATA MODEL
// ======================================================================

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
      // Assuming 'image' for imageUrl and 'eng_name' for full name based on common patterns
      // If your API uses 'image_url' or 'name', adjust accordingly.
      imageUrl: json['image'] as String? ?? '',
      fullName: json['eng_name'] as String? ??
          '', // Corrected based on typical API response for English name
      email: json['email'] as String? ?? '',
    );
  }
}

// ======================================================================
// PROFILE SCREEN
// ======================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController _authController;

  StaffProfile? _userProfile;
  bool _isLoading = true;
  String?
      _errorMessage; // Stores critical errors (e.g., network, profile not found)
  String?
      _warningMessage; // Stores non-critical warnings (e.g., incomplete profile)

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  void _initializeProfile() {
    try {
      _authController = Get.find<AuthController>();
      _fetchUserProfile();
    } catch (e) {
      debugPrint("ERROR: AuthController not found in ProfileScreen: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Initialization Error: Could not find user session.';
          _isLoading = false;
        });
      }
      _showSnackbar(
        'Initialization Error',
        'Could not find user session. Please ensure you are logged in.',
        isSuccess: false,
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    // Reset states before fetching
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Clear previous critical error
        _warningMessage = null; // Clear previous warning
        _userProfile = null;
      });
    }

    try {
      final userEmail = await _authController.getUserEmail();
      debugPrint(
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

      final response = await http
          .get(Uri.parse('${AppApi.staffsEndpoint}?email=$userEmail'))
          .timeout(AppDurations.apiTimeout); // Add timeout

      debugPrint(
          "DEBUG: ProfileScreen _fetchUserProfile: API Response Status: ${response.statusCode}");
      debugPrint(
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
            _checkIncompleteProfileData(); // Check for warnings after profile is set
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'profile_not_found'; // Use a specific key for this error
              _isLoading = false;
            });
          }
          debugPrint("User not found with email: $userEmail");
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load profile data: Server responded with status ${response.statusCode}.';
            _isLoading = false;
          });
        }
        debugPrint('Failed to load data: ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network Error: The request timed out. Please check your internet connection.';
          _isLoading = false;
        });
      }
      _showSnackbar(
          'Network Error', 'Profile data could not be loaded due to a timeout.',
          isSuccess: false);
    } on http.ClientException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Network Error: Could not connect to the server. ${e.message}';
          _isLoading = false;
        });
      }
      _showSnackbar('Network Error',
          'Could not connect to the server. Please check your internet connection.',
          isSuccess: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
      _showSnackbar(
          'Error', 'An unexpected error occurred while fetching profile.',
          isSuccess: false);
      debugPrint('Error fetching profile: $e');
    }
  }

  /// Checks for incomplete profile data and sets a warning message if found.
  void _checkIncompleteProfileData() {
    if (_userProfile != null) {
      String? newWarning;
      if (_userProfile!.fullName.trim().isEmpty ||
          _userProfile!.email.trim().isEmpty) {
        newWarning =
            'Your profile information is incomplete. Please edit your profile to add your full name and email.';
      } else if (_userProfile!.imageUrl.isEmpty) {
        newWarning =
            'Consider uploading a profile picture to personalize your account!';
      }

      // Only update if the warning message has changed
      if (_warningMessage != newWarning) {
        if (mounted) {
          setState(() {
            _warningMessage = newWarning;
          });
        }
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

  /// Shows a confirmation dialog before logging out.
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
                  fontFamily: AppFonts.fontFamily,
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
                  fontFamily: AppFonts.fontFamily,
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
                          fontFamily: AppFonts.fontFamily,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(
                          result: true), // Only dismiss dialog with result
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
                          fontFamily: AppFonts.fontFamily,
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
      Get.offAllNamed(AppRoutes.login); // Navigate to login and clear stack
    }
  }

  /// Helper to display a GetX snackbar.
  void _showSnackbar(String title, String message, {bool isSuccess = true}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? AppColors.successGreen : AppColors.errorRed,
      colorText: Colors.white,
      messageText: Text(message,
          style: const TextStyle(
              fontFamily: AppFonts.fontFamily, color: Colors.white)),
      titleText: Text(title,
          style: const TextStyle(
              fontFamily: AppFonts.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold)),
      duration: AppDurations.snackbarDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure consistent background
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Get.offAllNamed(AppRoutes.home); // Navigate to home and clear stack
          },
        ),
        title: const Text(
          'Profile',
          style:
              TextStyle(color: Colors.black, fontFamily: AppFonts.fontFamily),
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

  // --- Builder Methods ---

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBaseColor,
        highlightColor: AppColors.shimmerHighlightColor,
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white, // Shimmer will apply over this
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
              color: Colors.white, // Shimmer will apply over this
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white, // Shimmer will apply over this
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white, // Shimmer will apply over this
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    bool isProfileNotFound = message == 'profile_not_found';
    bool isConnectionError = message.contains('Network Error');
    bool isGenericApiError = message.contains('Failed to load profile data') ||
        message.contains('An unexpected error occurred');

    IconData icon = Icons.info_outline;
    Color iconColor = AppColors.warningOrange;
    String title = 'Information';
    String displayMessage = message;
    Color titleColor = AppColors.warningOrange;
    Color textColor = AppColors.darkText;
    VoidCallback? onMainActionButtonTap = _fetchUserProfile; // Default retry
    String mainActionButtonText = 'Retry';

    if (isProfileNotFound) {
      icon = Icons.person_off_outlined;
      iconColor = AppColors.errorRed;
      title = 'Profile Not Found';
      displayMessage =
          'We couldn\'t find your profile data. It might be deleted or an issue occurred with your account. Please try logging in again.';
      titleColor = AppColors.errorRed;
      onMainActionButtonTap = () async {
        await _authController.deleteToken(); // Clear token
        Get.offAllNamed(AppRoutes.login); // Navigate to login
      };
      mainActionButtonText = 'Log In Again';
    } else if (isConnectionError || isGenericApiError) {
      icon =
          Icons.cloud_off_rounded; // More specific icon for network/API issues
      iconColor = AppColors.errorRed;
      title = 'Error';
      // displayMessage already holds the error message
      titleColor = AppColors.errorRed;
      // onMainActionButtonTap remains _fetchUserProfile (Retry)
    }
    // No specific else if for 'warnings' here, as _errorMessage is for critical issues.
    // Warnings are handled by _warningMessage separate state.

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
                  fontFamily: AppFonts.fontFamily),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  fontFamily: AppFonts.fontFamily),
            ),
            ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onMainActionButtonTap,
              icon: Icon(isProfileNotFound
                  ? Icons.login
                  : (isConnectionError || isGenericApiError
                      ? Icons.refresh
                      : Icons.info_outline)), // Adjust icon for retry/login
              label: Text(mainActionButtonText,
                  style: const TextStyle(fontFamily: AppFonts.fontFamily)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
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
    // This null check is a fallback, ideally _userProfile should not be null here
    if (_userProfile == null) {
      return _buildErrorView(
          'Unexpected error: Profile data is null after loading.');
    }

    return SingleChildScrollView(
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
                backgroundColor: AppColors.profileAvatarDefaultBgColor,
                borderColor: AppColors.primaryBlue,
                borderWidth: 2,
                textColor: AppColors.profileAvatarDefaultTextColor,
                // Make sure SuperProfilePicture also accepts fontFamily if you want consistent text style for initials
                fontFamily: AppFonts.fontFamily,
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
                fontFamily: AppFonts.fontFamily,
                color: _userProfile!.fullName.isNotEmpty
                    ? AppColors.darkText
                    : AppColors.mediumText), // Use mediumText for "No Name"
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECF9), // Specific light blue
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _userProfile!.email.isNotEmpty
                  ? _userProfile!.email
                  : 'No Email Provided',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontFamily: AppFonts.fontFamily,
                fontStyle: _userProfile!.email.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Display warning message if any
          if (_warningMessage != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warningOrange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warningOrange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _warningMessage!,
                        style: const TextStyle(
                          color: AppColors
                              .darkText, // Use darkText for warning message
                          fontSize: 13,
                          fontFamily: AppFonts.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.darkText),
            title: const Text('Edit Profile',
                style: TextStyle(
                    fontFamily: AppFonts.fontFamily,
                    color: AppColors.darkText)),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.mediumText),
            onTap: () {
              Get.toNamed(AppRoutes.editProfile)?.then((result) {
                // Refresh profile data when returning from edit screen
                _fetchUserProfile();
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.darkText),
            title: const Text('Settings',
                style: TextStyle(
                    fontFamily: AppFonts.fontFamily,
                    color: AppColors.darkText)),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.mediumText),
            onTap: () {
              _showSnackbar(
                  'Coming Soon', 'Settings screen is under development!',
                  isSuccess:
                      true); // Use isSuccess: true for "Coming Soon" snackbar
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.errorRed),
            title: const Text('Logout',
                style: TextStyle(
                    color: AppColors.errorRed,
                    fontFamily: AppFonts.fontFamily)),
            onTap: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
