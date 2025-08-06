import 'dart:convert';
import 'dart:io'; // For SocketException

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart'; // Import for Clipboard functionality

import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

// --- Data Models (Ensuring consistency with API response) ---
class StaffProfileForDrawer {
  final String imageUrl;
  final String fullName;
  final String email;
  final String? positionId;
  final String phoneNumber;

  StaffProfileForDrawer({
    required this.imageUrl,
    required this.fullName,
    required this.email,
    this.positionId,
    required this.phoneNumber,
  });

  factory StaffProfileForDrawer.fromJson(Map<String, dynamic> json) {
    return StaffProfileForDrawer(
      imageUrl: json['image'] as String? ?? '',
      fullName: json['en_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      positionId: json['position'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}

class PositionForDrawer {
  final String id;
  final String name;

  PositionForDrawer({required this.id, required this.name});

  factory PositionForDrawer.fromJson(Map<String, dynamic> json) {
    return PositionForDrawer(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Position',
    );
  }
}

// --- API Endpoints (Highly recommend moving these to a global constants file) ---
class _DrawerApiConstants {
  static const String baseUrl = 'http://188.166.242.109:5000';
  static const String staffsEndpoint = '/api/staffs';
  static const String positionsEndpoint = '/api/positions';
}

class CustomDrawer extends StatefulWidget {
  final VoidCallback onLogout;

  CustomDrawer({
    super.key,
    required this.onLogout,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late final AuthController _authController;

  StaffProfileForDrawer? _userProfile;
  String? _userPositionName;
  List<PositionForDrawer> _allPositions = [];

  bool _isLoading = true;
  String? _errorMessage;

  // --- UI Constants ---
  static const Color _primaryBlue = AppColors.primaryBlue;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _lightGrey = Color(0xFFF7F9FC);
  static const Color _shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color _shimmerHighlightColor = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    try {
      _authController = Get.find<AuthController>();
      _fetchDrawerData();
    } catch (e) {
      print("ERROR: AuthController not found in CustomDrawer: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'App Initialization Error. Please restart.';
          _isLoading = false;
        });
      }
    }
  }

  // --- Data Fetching Methods for the Drawer ---
  Future<void> _fetchDrawerData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _userProfile = null;
        _userPositionName = null;
      });
    }

    try {
      final userEmail = await _authController.getUserEmail();
      if (userEmail.isEmpty) {
        throw Exception('User not logged in or email not found.');
      }

      final positionsFuture = _fetchAllPositions();
      final userProfileResponseFuture = http.get(
        Uri.parse(
            '${_DrawerApiConstants.baseUrl}${_DrawerApiConstants.staffsEndpoint}?email=$userEmail'),
      );

      await Future.wait([positionsFuture, userProfileResponseFuture]);

      final userProfileResponse = await userProfileResponseFuture;

      if (userProfileResponse.statusCode == 200) {
        final jsonData = json.decode(userProfileResponse.body);
        final List<dynamic> staffList = jsonData['data'];

        final userMap = staffList.firstWhereOrNull(
          (staff) => staff['email'] == userEmail,
        );

        if (userMap != null) {
          _userProfile = StaffProfileForDrawer.fromJson(userMap);
          if (_userProfile!.positionId != null && _allPositions.isNotEmpty) {
            final matchedPosition = _allPositions.firstWhereOrNull(
              (pos) => pos.id == _userProfile!.positionId,
            );
            _userPositionName = matchedPosition?.name;
          }
        } else {
          _errorMessage = 'Profile data not found for this user.';
        }
      } else {
        _errorMessage =
            'Failed to load profile data: Status ${userProfileResponse.statusCode}.';
      }
    } on SocketException {
      _errorMessage = 'Network Error: No internet connection.';
    } on Exception catch (e) {
      _errorMessage =
          'An unexpected error occurred: ${e.toString().split(':')[0]}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAllPositions() async {
    try {
      final response = await http.get(Uri.parse(
          '${_DrawerApiConstants.baseUrl}${_DrawerApiConstants.positionsEndpoint}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> positionListJson = jsonData['data'];
        _allPositions = positionListJson
            .map((json) => PositionForDrawer.fromJson(json))
            .toList();
      } else {
        print(
            'ERROR: CustomDrawer: Failed to load positions: ${response.statusCode}');
      }
    } on SocketException {
      print('ERROR: CustomDrawer: No internet connection for positions.');
    } on Exception catch (e) {
      print('ERROR: CustomDrawer: Exception fetching positions: $e');
    }
  }

  // --- NEW: Copy to Clipboard Function ---
  Future<void> _copyToClipboard(String text, String type) async {
    if (text.isEmpty || text == 'No Email' || text == 'No Phone') {
      Get.snackbar(
        'Cannot Copy',
        '$type not available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied!',
      '$type copied to clipboard: $text',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.successGreen,
      colorText: Colors.white,
    );
  }

  // Helper method for menu items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = _primaryBlue,
    Color textColor = _darkText,
    FontWeight fontWeight = FontWeight.w500,
    double iconSize = 24,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: _primaryBlue.withOpacity(0.1),
      highlightColor: _primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: fontWeight,
                  fontFamily: AppFonts.fontFamily,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  // // --- Method for the stylish logout confirmation dialog ---
  // void _showStylishLogoutConfirmDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         elevation: 10,
  //         backgroundColor: Colors.white,
  //         title: Column(
  //           children: [
  //             Icon(
  //               Icons.warning_amber_rounded,
  //               color: Colors.redAccent,
  //               size: 48,
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               "Confirm Logout",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //                 color: _darkText,
  //                 fontFamily: AppFonts.fontFamily,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           "Are you sure you want to end your session?",
  //           textAlign: TextAlign.center,
  //           style: TextStyle(
  //             fontSize: 16,
  //             color: Colors.grey.shade700,
  //             fontFamily: AppFonts.fontFamily,
  //             height: 1.4,
  //           ),
  //         ),
  //         actionsAlignment: MainAxisAlignment.spaceAround,
  //         actionsPadding:
  //             const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
  //         actions: <Widget>[
  //           OutlinedButton(
  //             onPressed: () {
  //               Navigator.of(dialogContext).pop(false);
  //             },
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: _primaryBlue,
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //                 side: BorderSide(color: _primaryBlue.withOpacity(0.5)),
  //               ),
  //               minimumSize: Size(Get.width * 0.35, 45),
  //             ),
  //             child: Text(
  //               "Cancel",
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 fontFamily: AppFonts.fontFamily,
  //               ),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(dialogContext).pop(true);
  //             },
  //             style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.red.shade600,
  //                 foregroundColor: Colors.white,
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 minimumSize: Size(Get.width * 0.35, 45),
  //                 elevation: 3,
  //                 shadowColor: const Color.fromARGB(0, 0, 0, 0)),
  //             child: Text(
  //               "Logout",
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 fontFamily: AppFonts.fontFamily,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   ).then((confirmed) {
  //     if (confirmed != null && confirmed) {
  //       Navigator.pop(context); // Close the drawer
  //       widget.onLogout();
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Determine the current route
    final currentRoute = Get.currentRoute; // <--- Get current route here

    final bool hasVerifiedPosition = _userPositionName != null &&
        (_userPositionName!.toLowerCase() == 'teacher' ||
            _userPositionName!.toLowerCase() == 'hr' ||
            _userPositionName!.toLowerCase() == 'admin');

    final String displayName = _userProfile?.fullName.isNotEmpty == true
        ? _userProfile!.fullName
        : 'Guest User';
    final String imageUrl = _userProfile?.imageUrl ?? '';
    final String displayEmail = _userProfile?.email.isNotEmpty == true
        ? _userProfile!.email
        : 'No Email';
    final String displayPhone = _userProfile?.phoneNumber.isNotEmpty == true
        ? _userProfile!.phoneNumber
        : 'No Phone';

    return Drawer(
      backgroundColor: _lightGrey,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryBlue,
                  _primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _isLoading
                    ? Shimmer.fromColors(
                        baseColor: _shimmerBaseColor.withOpacity(0.4),
                        highlightColor: _shimmerHighlightColor.withOpacity(0.4),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white54,
                        ),
                      )
                    : SuperProfilePicture(
                        imageUrl: imageUrl,
                        fullName: displayName,
                        radius: 35,
                        borderColor: Colors.white,
                        borderWidth: 2,
                        backgroundColor: Colors.white,
                        textColor: _primaryBlue,
                        fontFamily: AppFonts.fontFamily,
                      ),
                const SizedBox(height: 15),
                if (_isLoading)
                  _buildShimmerUserInfo()
                else if (_errorMessage != null)
                  _buildErrorDisplay()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppFonts.fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasVerifiedPosition)
                            Padding(
                              padding: const EdgeInsets.only(left: 6.0),
                              child: Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Email - Now copies to clipboard
                      InkWell(
                        onTap: () => _copyToClipboard(displayEmail, 'Email'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  displayEmail,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: AppFonts.fontFamily,
                                    decoration: displayEmail != 'No Email'
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Phone Number - Now copies to clipboard
                      InkWell(
                        onTap: () =>
                            _copyToClipboard(displayPhone, 'Phone Number'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  displayPhone,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: AppFonts.fontFamily,
                                    decoration: displayPhone != 'No Phone'
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // Conditionally display the Home button and its divider
                if (currentRoute !=
                    AppRoutes.home) // <--- NEW CONDITION APPLIED HERE
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Get.offAllNamed(
                          AppRoutes.home); // Navigate to home and clear stack
                    },
                  ),
                if (currentRoute !=
                    AppRoutes.home) // <--- Apply condition for divider too
                  const Divider(height: 1),

                _buildDrawerItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Students permissions',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.studentPermission);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box_outlined,
                  title: 'Ask for Permission',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.myPermission);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.school_outlined,
                  title: 'All my Classes',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.classManagement);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.profile);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.editProfile);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: const Color.fromARGB(0, 255, 255, 255),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 5,
                ),
                icon: const Icon(Icons.logout, size: 24),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                  fontFamily: AppFonts.fontFamily, // Apply NotoSerifKhmer
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
                  fontFamily: AppFonts.fontFamily, // Apply NotoSerifKhmer
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
                          fontFamily: AppFonts.fontFamily, // Apply NotoSerifKhmer
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
                          fontFamily: AppFonts.fontFamily, // Apply NotoSerifKhmer
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
      Get.offAllNamed(
          '/login'); // Navigate to login and clear all previous routes
    }
  }
  // --- New/Updated Helper Widgets for Loading and Error States ---

  Widget _buildShimmerUserInfo() {
    return Shimmer.fromColors(
      baseColor: _shimmerBaseColor.withOpacity(0.4),
      highlightColor: _shimmerHighlightColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade200, size: 28),
        const SizedBox(height: 8),
        Text(
          'Failed to load profile!',
          style: TextStyle(
            color: Colors.red.shade200,
            fontSize: 18,
            fontFamily: AppFonts.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _errorMessage ?? 'Unknown error occurred.',
          style: TextStyle(
            color: Colors.red.shade100,
            fontSize: 13,
            fontFamily: AppFonts.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _fetchDrawerData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white54, width: 0.5),
            ),
            child: Text(
              'Tap to Retry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: AppFonts.fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
