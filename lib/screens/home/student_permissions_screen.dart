import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart'; // For skeleton loading
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/models/permission_item.dart'; // Import PermissionItem
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart'; // Assuming SuperProfilePicture is defined and accessible

class StudentPermissionsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final int studentsCount;
  final String subjectName;

  const StudentPermissionsScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.studentsCount,
    this.subjectName = 'N/A',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StudentPermissionController controller =
        Get.find<StudentPermissionController>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(controller), // Pass the controller to the header
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildShimmerList();
              } else if (controller.errorMessage.isNotEmpty) {
                return _buildErrorState(controller.errorMessage.value,
                    () => controller.fetchStudentPermissions());
              } else if (controller.studentPermissions.isEmpty) {
                return _buildEmptyState();
              } else {
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.studentPermissions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final permission = controller.studentPermissions[index];
                    return StudentPermissionCard(
                      permission: permission,
                      controller: controller,
                      classId: classId,
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
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
      centerTitle: true,
    );
  }

  /// Builds the header section displaying permission counts.
  Widget _buildHeader(StudentPermissionController controller) {
    return Container(
      color: AppColors.primaryBlue,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 16),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCountBadge(
                        'Pending',
                        controller.pendingPermissions.value.toString(),
                        AppColors.pendingOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCountBadge(
                        'All',
                        controller.totalPermissions.value.toString(),
                        AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: SvgPicture.asset(
                //     'assets/images/teacher_management/permission.svg',
                //     height: 100,
                //     width: 100,
                //     fit: BoxFit.contain,
                //   ),
                // ),
              ],
            )),
      ),
    );
  }

  /// Helper to build a single count badge with improved styling.
  Widget _buildCountBadge(String title, String count, Color color) {
    return Container(
      // Changed from Card to Container for more control over decoration
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText.withOpacity(0.7),
              fontFamily: AppFonts.fontFamily,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: AppFonts.fontFamily,
            ),
          ),
        ],
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
        itemCount: 4,
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
            const CircleAvatar(radius: 24, backgroundColor: Colors.white),
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
              'assets/images/teacher_management/permission.svg',
              height: 100,
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
              'There are no permission requests from students for you at the moment.',
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

class StudentPermissionCard extends StatelessWidget {
  final PermissionItem permission;
  final StudentPermissionController controller;
  final String classId;

  const StudentPermissionCard({
    Key? key,
    required this.permission,
    required this.controller,
    required this.classId,
  }) : super(key: key);

  Color _getStatusColor(String status, {bool isBackground = false}) {
    switch (status.toLowerCase()) {
      case "pending":
        return isBackground
            ? AppColors.pendingOrange.withOpacity(0.1)
            : AppColors.pendingOrange;
      case "accepted":
        return isBackground
            ? AppColors.successGreen.withOpacity(0.1)
            : AppColors.successGreen;
      case "denied":
      case "rejected":
        return isBackground
            ? AppColors.declineRed.withOpacity(0.1)
            : AppColors.declineRed;
      default:
        return isBackground ? AppColors.borderGrey : AppColors.mediumText;
    }
  }

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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(PermissionItem permission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, thickness: 1, color: AppColors.borderGrey),
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
            permission.formattedDateRange),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.edit_note_rounded, "Reason:", permission.reason),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (permission.status.toLowerCase() == "pending") ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    controller.updatePermissionStatus(
                        permission.id, "denied", classId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.declineRed, // Solid red for Deny
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2, // Add a slight elevation
                  ),
                  child: const Text("Deny",
                      style: TextStyle(
                          fontFamily: AppFonts.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    controller.updatePermissionStatus(
                        permission.id, "Accepted", classId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.successGreen, // Solid green for Approve
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2, // Add a slight elevation
                  ),
                  child: const Text("Accepted",
                      style: TextStyle(
                          fontFamily: AppFonts.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ] else if (permission.status.toLowerCase() == "Accepted")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successGreen),
                ),
                child: Text(
                  "Already Accepted",
                  style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.fontFamily),
                ),
              )
            else if (permission.status.toLowerCase() == "denied" ||
                permission.status.toLowerCase() == "rejected")
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                // decoration: BoxDecoration(
                //   color: AppColors.declineRed.withOpacity(0.1),
                //   borderRadius: BorderRadius.circular(12),
                //   border: Border.all(color: AppColors.declineRed),
                // ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = permission.studentDetails?.engName ?? 'Unknown Student';
    final studentGender = permission.studentDetails?.gender ?? 'N/A';
    final studentAvatarUrl = permission.studentDetails?.avatarUrl;

    return Obx(() => Container(
          // Changed from Card to Container for more custom styling
          margin: const EdgeInsets.symmetric(
              vertical: 4.0), // Add some vertical margin between cards
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.borderGrey.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: AppColors.borderGrey, width: 1), // Subtle border
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              permission.isExpanded.value = !permission.isExpanded.value;
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Align items vertically in the center
                    children: [
                      SuperProfilePicture(
                        imageUrl: studentAvatarUrl,
                        fullName: studentName,
                        radius: 24,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        textColor: AppColors.darkText,
                        fontFamily: AppFonts.fontFamily,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(permission.status,
                              isBackground: true),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          permission.formattedStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(permission.status),
                            fontFamily: AppFonts.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        permission.isExpanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: AppColors.mediumText,
                      ),
                    ],
                  ),
                  if (permission.isExpanded.value)
                    _buildExpandedDetails(permission),
                ],
              ),
            ),
          ),
        ));
  }
}
