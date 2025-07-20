import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Still using GetX for navigation and dialogs
// We'll remove AuthController import from here later if you truly don't want it.
// For the logout action, we still need a way to trigger it.
// Let's assume you'll pass a logout callback.
// import 'package:school_management_system_teacher_app/controllers/auth_controller.dart'; // <--- REMOVE THIS IMPORT
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Make sure this path is correct

class CustomDrawer extends StatelessWidget {
  // Define parameters to receive user data
  final String userDisplayName;
  // final String userDisplayEmail;
  final String userDisplayImageUrl;
  final VoidCallback onLogout; // Callback for logout

  // Constructor to receive the data
  CustomDrawer({
    super.key,
    required this.userDisplayName,
    // required this.userDisplayEmail,
    required this.userDisplayImageUrl,
    required this.onLogout, // Require the logout callback
  });

  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _lightGrey = Color(0xFFF7F9FC);

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
                  fontFamily: AppFonts.fontFamily, // Apply your custom font
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

  // --- Method for the stylish logout confirmation dialog ---
  void _showStylishLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // User can tap outside to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // More rounded corners
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded, // Warning icon
                color: Colors.orange.shade600,
                size: 48,
              ),
              const SizedBox(height: 10),
              Text(
                "Confirm Logout",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _darkText, // Using your existing dark text color
                  fontFamily: AppFonts.fontFamily,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to end your session?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontFamily: AppFonts.fontFamily,
              height: 1.4, // Improve line spacing
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround, // Distribute buttons
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false); // Dismiss dialog, return false
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    _primaryBlue, // Primary blue for cancel button text
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: _primaryBlue.withOpacity(0.5)), // Subtle border
                ),
                minimumSize: Size(Get.width * 0.35, 45), // Responsive width
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.fontFamily,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true); // Dismiss dialog, return true
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, // Red for logout button
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(Get.width * 0.35, 45), // Responsive width
                elevation: 3,
              ),
              child: Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.fontFamily,
                ),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) {
      // This block runs after the dialog is closed and a value is returned
      if (confirmed != null && confirmed) {
        Navigator.pop(context); // Close the drawer
        onLogout(); // <--- Call the passed-in logout callback
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _lightGrey,
      child: Column(
        children: <Widget>[
          // Custom Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 20.0),
            decoration: const BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(25),
              ),
            ),
            // NO Obx needed here if data is passed via constructor
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SuperProfilePicture(
                  imageUrl:
                      userDisplayImageUrl, // <--- Use the passed-in image URL
                  fullName: userDisplayName, // <--- Use the passed-in name
                  radius: 35,
                  backgroundColor: Colors.white,
                  textColor: _primaryBlue,
                  fontFamily: AppFonts.fontFamily,
                ),
                const SizedBox(height: 15),
                Text(
                  userDisplayName, // <--- Use the passed-in name
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
                // Text(
                //   userDisplayEmail, // <--- Use the passed-in email
                //   style: TextStyle(
                //     color: Colors.white70,
                //     fontSize: 14,
                //     fontFamily: AppFonts.fontFamily,
                //   ),
                // ),
              ],
            ),
          ),

          // Menu Items List (remains largely the same)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
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

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Call the new, stylish confirmation dialog method
                  _showStylishLogoutConfirmDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
}
