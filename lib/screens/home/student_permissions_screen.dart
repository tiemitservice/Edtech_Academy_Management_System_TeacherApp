import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart'; // For skeleton loading
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';

// Assuming SuperProfilePicture is defined and accessible
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
// Import the controller

// Re-defining constants for clarity if not imported globally from common files
class AppColors {
  static const Color primaryBlue = Color(0xFF1469C7);
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color cardBackground = Colors.white;
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF7F8C8D);
  static const Color borderGrey = Color(0xFFE0E6ED);
  static const Color declineRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color pendingOrange = Color(0xFFF39C12);
  static const Color skeletonBaseColor = Color(0xFFE0E0E0);
  static const Color skeletonHighlightColor = Color(0xFFF0F0F0);
}

class AppFonts {
  static const String fontFamily =
      'KantumruyPro'; // IMPORTANT: Ensure this matches the 'family' name in your pubspec.yaml
}

class StudentPermissionsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final int studentsCount;
  final String
      subjectName; // Added subject name for completeness from other screens

  const StudentPermissionsScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.studentsCount,
    this.subjectName = 'N/A', // Default to N/A if not provided
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the already initialized controller.
    final StudentPermissionController controller =
        Get.find<StudentPermissionController>();

    // Call fetchStudentPermissions when the screen is first built
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure the widget tree is built
    // before attempting to fetch data, avoiding 'setState called during build' issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch if the list is empty or an error occurred and we want to retry
      if (controller.studentPermissions.isEmpty ||
          controller.errorMessage.isNotEmpty) {
        controller.fetchStudentPermissions();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            // Obx will react to changes in controller.isLoading, controller.errorMessage, and controller.studentPermissions.
            // This ensures the correct UI state (loading, error, empty, or data list) is displayed.
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildShimmerList(); // Show shimmer while data is loading
              } else if (controller.errorMessage.isNotEmpty) {
                // Pass a lambda function for onRetry to correctly call fetchStudentPermissions
                return _buildErrorState(
                    controller.errorMessage.value,
                    () => controller
                        .fetchStudentPermissions()); // Show error message with retry
              } else if (controller.studentPermissions.isEmpty) {
                return _buildEmptyState(); // Show message when no permissions are found
              } else {
                // Display the list of student permission cards
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.studentPermissions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final permission = controller.studentPermissions[index];
                    // Each card reacts to its own permission.isExpanded state via an inner Obx
                    return StudentPermissionCard(
                      permission: permission,
                      controller:
                          controller, // Pass the controller for actions (e.g., updating status)
                      classId: classId, // Pass the classId to the card
                    );
                  },
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  /// Builds the custom AppBar for the screen.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0, // Flat app bar for a modern look
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        "STUDENT'S PERMISSION",
        style: TextStyle(
          color: Colors.white,
          fontFamily: AppFonts.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true, // Center the title in the app bar
    );
  }

  /// Builds the header section displaying class and student counts.
  Widget _buildHeader() {
    return Container(
      color: AppColors
          .primaryBlue, // Background behind the rounded card to create a smooth transition
      child: Container(
        decoration: const BoxDecoration(
          color:
              AppColors.cardBackground, // White background for the header card
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the top
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                children: [
                  Text(
                    className, // Class Name
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // Bold for prominence
                      color: AppColors.darkText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis, // Truncate long class names
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subject: $subjectName', // Subject Name
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors
                          .mediumText, // Slightly softer color for secondary info
                      fontFamily: AppFonts.fontFamily,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis, // Truncate long subject names
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue
                          .withOpacity(0.1), // Light blue background for badge
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'All Students: $studentsCount', // Student Count
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                        fontFamily: AppFonts.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20), // Spacing between text and SVG
            SvgPicture.asset(
              'assets/images/onboarding/teacher_check.svg', // Placeholder SVG
              height: 100, // Fixed height for visual consistency
              width: 100,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a list of shimmering skeleton loaders for the loading state.
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBaseColor,
      highlightColor: AppColors.skeletonHighlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // Number of shimmer items
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildPermissionCardSkeleton(),
      ),
    );
  }

  /// Builds a single skeleton loader item for a permission card.
  Widget _buildPermissionCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white), // Shimmer will fill this
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 16, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(height: 13, width: 100, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(height: 20, width: 70, color: Colors.white),
            const SizedBox(width: 8),
            Container(height: 24, width: 24, color: Colors.white),
          ]),
          const SizedBox(height: 16),
          // Optionally add shimmer for expanded details
          Container(height: 16, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 16, width: 150, color: Colors.white),
        ],
      ),
    );
  }

  /// Builds the error state view when data fetching fails.
  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.declineRed, size: 60),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Permissions',
              style: TextStyle(
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
              style: TextStyle(
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

  /// Builds the empty state view when there are no permissions to display.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/onboarding/teacher_read.svg', // Placeholder SVG
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Student Permissions Found',
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
              'There are no permission requests from students in this class at the moment.',
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

// ======================================================================
// StudentPermissionCard (Extracting individual card for better readability and state management)
// This widget will be responsible for displaying a single permission item
// and handling its local expansion state and actions.
// ======================================================================

class StudentPermissionCard extends StatelessWidget {
  final PermissionItem permission;
  final StudentPermissionController controller; // Pass the controller
  final String classId; // Added classId to be passed from parent

  const StudentPermissionCard({
    Key? key,
    required this.permission,
    required this.controller,
    required this.classId, // Now required in the constructor
  }) : super(key: key);

  /// Returns the appropriate color for a status text or its background.
  Color _getStatusColor(String status, {bool isBackground = false}) {
    switch (status.toLowerCase()) {
      // Ensure lowercase comparison
      case "pending":
        return isBackground
            ? AppColors.pendingOrange.withOpacity(0.1)
            : AppColors.pendingOrange;
      case "approved":
        return isBackground
            ? AppColors.successGreen.withOpacity(0.1)
            : AppColors.successGreen;
      case "denied":
        return isBackground
            ? AppColors.declineRed.withOpacity(0.1)
            : AppColors.declineRed;
      default: // Fallback for unknown status
        return isBackground ? AppColors.borderGrey : AppColors.mediumText;
    }
  }

  /// Helper to build a single row for details (e.g., date, reason) with an icon and label-value pair.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mediumText),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
                TextSpan(
                  text: ' $value',
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
              ],
            ),
            maxLines: 3, // Allow multiple lines for reasons to prevent overflow
            overflow:
                TextOverflow.ellipsis, // Truncate if text is still too long
          ),
        ),
      ],
    );
  }

  /// Builds the detailed view (date, reason, action buttons) for an expanded permission card.
  Widget _buildExpandedDetails(PermissionItem permission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
            height: 32,
            thickness: 1,
            color: AppColors.borderGrey), // Divider line
        const Text(
          "Permission Detail",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.darkText,
            fontFamily: AppFonts.fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.calendar_today_rounded, "Date:",
            permission.formattedDateRange), // Use formatted date range
        const SizedBox(height: 8),
        _buildDetailRow(Icons.edit_note_rounded, "Reason:", permission.reason),
        const SizedBox(height: 20),
        // Action Buttons: Deny/Approve (only for Pending status) or status indicator
        Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Align buttons to the right
          children: [
            if (permission.status.toLowerCase() == "pending") ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Call controller method, now correctly passing classId
                    controller.updatePermissionStatus(
                        permission.id, "Denied", classId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.declineRed, // Red for Deny
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0, // No shadow for flat design
                  ),
                  child: const Text("Deny",
                      style: TextStyle(
                          fontFamily: AppFonts.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12), // Spacing between buttons
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Call controller method, now correctly passing classId
                    controller.updatePermissionStatus(
                        permission.id, "Approved", classId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.successGreen, // Green for Approve
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text("Approve",
                      style: TextStyle(
                          fontFamily: AppFonts.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ] else if (permission.status.toLowerCase() == "approved")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successGreen),
                ),
                child: Text(
                  "Already Approved",
                  style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.fontFamily),
                ),
              )
            else if (permission.status.toLowerCase() == "denied")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.declineRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.declineRed),
                ),
                child: Text(
                  "Already Denied",
                  style: TextStyle(
                      color: AppColors.declineRed,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.fontFamily),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine student name and avatar URL from studentDetails, with fallbacks
    final studentName = permission.studentDetails?.name ?? 'Unknown Student';
    final studentGender = permission.studentDetails?.gender ?? 'N/A';
    final studentAvatarUrl = permission.studentDetails?.avatarUrl;

    // Obx here allows StudentPermissionCard to react to changes in permission.isExpanded.value
    return Obx(() => Card(
          elevation: 0, // No default shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
                color: AppColors.borderGrey, width: 1), // Subtle border
          ),
          color: AppColors.cardBackground, // White card background
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Toggle the RxBool value directly on the permission item
              permission.isExpanded.value = !permission.isExpanded.value;
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Student profile picture or initials
                      SuperProfilePicture(
                        imageUrl: studentAvatarUrl,
                        fullName:
                            studentName, // Pass to get initials if no image
                        radius: 24,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        textColor: AppColors.darkText,
                        fontFamily: AppFonts.fontFamily, // Pass font family
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                                fontFamily: AppFonts.fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Gender: $studentGender',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mediumText,
                                fontFamily: AppFonts.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge (e.g., Pending, Approved, Denied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(permission.status,
                              isBackground: true),
                          borderRadius: BorderRadius.circular(20), // Pill shape
                        ),
                        child: Text(
                          permission
                              .formattedStatus, // Use formatted status for display
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(permission.status),
                            fontFamily: AppFonts.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expansion/Collapse Arrow Icon
                      Icon(
                        permission.isExpanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: AppColors.mediumText,
                      ),
                    ],
                  ),
                  // Expanded details section, only shown when `isExpanded` is true
                  if (permission.isExpanded.value)
                    _buildExpandedDetails(permission),
                ],
              ),
            ),
          ),
        ));
  }
}
