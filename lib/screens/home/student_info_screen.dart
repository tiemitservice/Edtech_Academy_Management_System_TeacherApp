// lib/screens/home/student_info_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:school_management_system_teacher_app/models/student.dart'; // Assuming your Student model is here
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart'; // Assuming this widget exists
import 'package:school_management_system_teacher_app/controllers/student_info_controller.dart'; // Assuming this controller exists
import 'package:shimmer/shimmer.dart'; // For shimmer effect
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Assuming AppColors is here
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:school_management_system_teacher_app/services/address_service.dart'; // Import AddressService

class StudentInfoScreen extends StatelessWidget {
  final String studentId;

  const StudentInfoScreen({Key? key, required this.studentId})
      : super(key: key);

  // Helper function to launch a phone call
  Future<void> _launchPhone(String phoneNumber) async {
    // Ensure phoneNumber is not null or empty before launching
    if (phoneNumber.isEmpty) {
      Get.snackbar(
        'No Number',
        'Phone number not available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          'Call Failed',
          'Could not launch dialer for $phoneNumber',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.declineRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while trying to call: ${e.toString().split(':')[0]}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    }
  }

  // Helper function to launch an email app
  Future<void> _launchEmail(String emailAddress) async {
    // Ensure emailAddress is not null or empty before launching
    if (emailAddress.isEmpty) {
      Get.snackbar(
        'No Email',
        'Email address not available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          'Email Failed',
          'Could not launch email app for $emailAddress',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.declineRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while trying to email: ${e.toString().split(':')[0]}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final StudentInfoController controller =
        Get.find<StudentInfoController>(tag: studentId);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "STUDENT DETAILS",
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppFonts.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmerLoading();
        } else if (controller.errorMessage.isNotEmpty) {
          return _buildErrorState(controller.errorMessage.value,
              () => controller.fetchStudentDetails());
        } else if (controller.student.value == null) {
          return _buildEmptyState();
        } else {
          final student = controller.student.value!;
          return _buildStudentDetails(student);
        }
      }),
    );
  }

  Widget _buildStudentDetails(Student student) {
    // Ensure AddressService is initialized globally (e.g., in main.dart via Get.put)
    final AddressService addressService = Get.find<AddressService>();

    final bool hasFamilyInfo = (student.fatherName?.isNotEmpty ?? false) ||
        (student.fatherPhone?.isNotEmpty ?? false) ||
        (student.motherName?.isNotEmpty ?? false) ||
        (student.motherPhone?.isNotEmpty ?? false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture and Basic Info
          Center(
            child: Column(
              children: [
                SuperProfilePicture(
                  imageUrl: student.avatarUrl,
                  fullName: student.displayName,
                  radius: 60,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  textColor: AppColors.darkText,
                  fontFamily: AppFonts.fontFamily,
                ),
                const SizedBox(height: 16),
                Text(
                  student.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(student.gender == 'Male' ? Icons.male : Icons.female,
                        color: student.gender == 'Male'
                            ? Colors.blue
                            : Colors.pink,
                        size: 20),
                    const SizedBox(width: 4),
                    Text(
                      student.gender,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.mediumText,
                        fontFamily: AppFonts.fontFamily,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: student.status == true
                            ? AppColors.successGreen
                            : AppColors.declineRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      student.status == true ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 16,
                        color: student.status == true
                            ? AppColors.successGreen
                            : AppColors.declineRed,
                        fontFamily: AppFonts.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Personal Details
          _buildInfoCard(
            title: 'Personal Details',
            children: [
              _buildInfoRow(
                  Icons.person_outline, 'English Name', student.engName),
              _buildInfoRow(Icons.person_outline, 'Khmer Name', student.khName),
              _buildInfoRow(
                  Icons.cake_outlined,
                  'Date of Birth',
                  student.dateOfBirth != null
                      ? DateFormat('dd MMM yyyy').format(student.dateOfBirth!)
                      : 'N/A'),
              // Student Phone Number - Correctly handles null/empty and launches
              _buildTappableInfoRow(
                  Icons.phone,
                  'Phone Number',
                  student.phoneNumber,
                  // Corrected onTap logic: only provide a function if phoneNumber is valid
                  student.phoneNumber.isNotEmpty == true
                      ? () => _launchPhone(student.phoneNumber)
                      : null), // Pass null if not tappable
              // Student Email - Correctly handles null/empty and launches
              _buildTappableInfoRow(
                  Icons.email,
                  'Email',
                  student.email,
                  // Corrected onTap logic: only provide a function if email is valid
                  student.email?.isNotEmpty == true
                      ? () => _launchEmail(student.email!)
                      : null), // Pass null if not tappable

              // Separate address components
              const Divider(
                  height: 20,
                  thickness: 0.5,
                  color: AppColors.borderGrey), // Separator for address
              _buildInfoRow(Icons.location_on_outlined, 'Village',
                  addressService.getVillageName(student.village)),
              _buildInfoRow(Icons.location_on_outlined, 'Commune',
                  addressService.getCommuneName(student.commune)),
              _buildInfoRow(Icons.location_on_outlined, 'District',
                  addressService.getDistrictName(student.district)),
              _buildInfoRow(Icons.location_on_outlined, 'Province',
                  addressService.getProvinceName(student.province)),
            ],
          ),

          // Family Information
          _buildInfoCard(
            title: 'Family Information',
            children: [
              if (hasFamilyInfo) ...[
                _buildInfoRow(
                    Icons.person, 'Father\'s Name', student.fatherName),
                // Father's Phone - Correctly handles null/empty and launches
                _buildTappableInfoRow(
                    Icons.phone,
                    'Father\'s Phone',
                    student.fatherPhone,
                    student.fatherPhone?.isNotEmpty == true
                        ? () => _launchPhone(student.fatherPhone!)
                        : null),
                _buildInfoRow(
                    Icons.person, 'Mother\'s Name', student.motherName),
                // Mother's Phone - Correctly handles null/empty and launches
                _buildTappableInfoRow(
                    Icons.phone,
                    'Mother\'s Phone',
                    student.motherPhone,
                    student.motherPhone?.isNotEmpty == true
                        ? () => _launchPhone(student.motherPhone!)
                        : null),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Family information not available.',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build a styled information card (no changes)
  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 6,
      shadowColor: AppColors.borderGrey.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppColors.borderGrey.withOpacity(0.5), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
            ),
            const Divider(
                height: 28, thickness: 1.5, color: AppColors.borderGrey),
            ...children,
          ],
        ),
      ),
    );
  }

  // Original helper to build a single information row with icon and text (no changes)
  // This is used for non-tappable rows.
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mediumText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.darkText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modified helper to build a tappable information row
  Widget _buildTappableInfoRow(
      IconData icon, String label, String? value, VoidCallback? onTap) {
    // onTap can now be null, so GestureDetector's onTap will be null too.
    final bool isValueAvailable = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: onTap, // Directly pass the onTap callback
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isValueAvailable ? value : 'N/A',
                    style: TextStyle(
                      fontSize: 17,
                      color: isValueAvailable
                          ? AppColors.primaryBlue
                          : AppColors
                              .darkText, // Use primary blue for active links
                      fontFamily: AppFonts.fontFamily,
                      decoration: isValueAvailable
                          ? TextDecoration.underline
                          : TextDecoration.none, // Underline active links
                    ),
                  ),
                ],
              ),
            ),
            if (isValueAvailable) // Show launch icon only if value is available
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              ),
          ],
        ),
      ),
    );
  }

  // Shimmer loading state for StudentInfoScreen (no changes)
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBaseColor,
      highlightColor: AppColors.skeletonHighlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(radius: 60, backgroundColor: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 24, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 100, color: Colors.white),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildShimmerCard(),
            _buildShimmerCard(),
            _buildShimmerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 18, width: 180, color: Colors.white),
            const Divider(height: 20, thickness: 1, color: Colors.white),
            Container(height: 16, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 16, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 16, width: 150, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // Error state for StudentInfoScreen (no changes)
  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.declineRed, size: 60),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Student Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mediumText,
                fontFamily: AppFonts.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry',
                  style: TextStyle(fontFamily: AppFonts.fontFamily)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state for StudentInfoScreen (no changes)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded,
                size: 150, color: AppColors.mediumText.withOpacity(0.5)),
            const SizedBox(height: 24),
            const Text(
              'Student Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The student details could not be loaded. It might not exist or there was an issue.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mediumText,
                fontFamily: AppFonts.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
