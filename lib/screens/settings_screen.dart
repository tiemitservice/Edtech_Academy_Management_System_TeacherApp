import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_font.dart';
import 'home/my_permission_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 2.0, // Slightly more pronounced shadow
        shadowColor: AppColors.primaryBlue.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppFonts.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 20, // Slightly larger title
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- General Settings Section ---
            _buildSettingsCard(
              title: "General",
              children: [
                _buildLanguageSetting(),
                _buildSettingTile(
                  icon: Icons.notifications_active_outlined,
                  label: "Notifications",
                  trailingWidget: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                        // TODO: Add logic here to update notification preferences.
                      });
                    },
                    activeColor: AppColors.successGreen,
                    inactiveTrackColor: AppColors.borderGrey,
                    inactiveThumbColor: AppColors.cardBackground,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_outlined,
                  label: "Dark Mode",
                  trailingWidget: Switch.adaptive(
                    value: false, // Placeholder
                    onChanged: (bool value) {
                      // TODO: Add logic here to toggle dark mode for the app.
                    },
                    activeColor: AppColors.successGreen,
                    inactiveTrackColor: AppColors.borderGrey,
                    inactiveThumbColor: AppColors.cardBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Account Settings Section ---
            _buildSettingsCard(
              title: "Account",
              children: [
                _buildSettingTile(
                  icon: Icons.person_outline,
                  label: "Edit Profile",
                  onTap: () {
                    Get.toNamed('/edit-profile');
                  },
                  showArrow: true,
                ),
                _buildSettingTile(
                  icon: Icons.lock_outline,
                  label: "Change Password",
                  onTap: () {
                    // TODO: Navigate to Change Password screen.
                  },
                  showArrow: true,
                ),
                _buildSettingTile(
                  icon: Icons.logout,
                  label: "Log Out",
                  onTap: () {
                    // TODO: Implement logout logic (e.g., show a confirmation dialog before logging out).
                  },
                  trailingWidget: const Icon(
                    Icons.exit_to_app,
                    color: AppColors.declineRed,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- About Section ---
            _buildSettingsCard(
              title: "About",
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline,
                  label: "Version",
                  trailingWidget: const Text(
                    "1.0.0", // Placeholder: Dynamically load the app version.
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.policy_outlined,
                  label: "Privacy Policy",
                  onTap: () {
                    // TODO: Open privacy policy link.
                  },
                  showArrow: true,
                ),
                _buildSettingTile(
                  icon: Icons.assignment_outlined,
                  label: "Terms of Service",
                  onTap: () {
                    // TODO: Open terms of service link.
                  },
                  showArrow: true,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Reset All Settings Button ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement logic to reset all settings.
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.declineRed,
                  side:
                      const BorderSide(color: AppColors.declineRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
                child: const Text("Reset All Settings"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build a consistent settings card for grouping items.
  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero, // Remove default card margin
      elevation: 8, // Increased elevation for a more prominent lift
      shadowColor: AppColors.primaryBlue.withOpacity(0.08), // Softer shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18), // More rounded corners
        side: const BorderSide(
            color: AppColors.borderGrey, width: 0.5), // Thin border
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22, // Larger section titles
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderGrey,
              ),
            ),
            // Use ListView.separated for consistent dividers between items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderGrey,
                indent: 48, // Indent the divider to align with text
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build a consistent single setting item row (using ListTile for better built-in features).
  Widget _buildSettingTile({
    required IconData icon,
    required String label,
    Widget? trailingWidget,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero, // Remove default ListTile padding
      leading: Container(
        padding: const EdgeInsets.all(8), // Slightly more padding
        decoration: BoxDecoration(
          color:
              AppColors.primaryBlue.withOpacity(0.12), // Slightly darker tint
          borderRadius:
              BorderRadius.circular(10), // More rounded icon background
        ),
        child:
            Icon(icon, size: 22, color: AppColors.primaryBlue), // Larger icon
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          fontFamily: AppFonts.fontFamily,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) trailingWidget,
          if (showArrow)
            const Padding(
              padding: EdgeInsets.only(left: 8.0), // Spacing for the arrow
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.mediumText,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Specific widget to build the Language selection dropdown.
  Widget _buildLanguageSetting() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            const Icon(Icons.language, size: 22, color: AppColors.primaryBlue),
      ),
      title: const Text(
        "Language",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          fontFamily: AppFonts.fontFamily,
        ),
      ),
      trailing: SizedBox(
        width: 130, // Adjusted width for cleaner look
        child: DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
          ),
          items: <String>['English', 'Khmer']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontFamily: AppFonts.fontFamily,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
                // IMPORTANT: This is where you would integrate your actual
                // localization logic. For example, if using GetX for localization:
                // Get.updateLocale(Locale(newValue == 'English' ? 'en' : 'km'));
              });
            }
          },
          style: const TextStyle(
            color: AppColors.darkText,
            fontFamily: AppFonts.fontFamily,
            fontSize: 14,
          ),
          dropdownColor: AppColors.cardBackground,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.mediumText,
          ),
        ),
      ),
    );
  }
}
