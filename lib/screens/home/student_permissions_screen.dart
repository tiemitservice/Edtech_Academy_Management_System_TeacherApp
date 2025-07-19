// lib/screens/student_permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';

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
    // Find the controller instance. Ensure it's already put by a previous screen or in your main binding.
    final StudentPermissionController controller =
        Get.find<StudentPermissionController>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(controller),
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
                return RefreshIndicator(
                  color: AppColors.primaryBlue,
                  onRefresh: () => controller.fetchStudentPermissions(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: controller.studentPermissions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final permission = controller.studentPermissions[index];
                      return StudentPermissionCard(
                        permission: permission,
                        controller: controller,
                      );
                    },
                  ),
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

  Widget _buildHeader(StudentPermissionController controller) {
    return Container(
      color: AppColors.primaryBlue,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Obx(() => Row(
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
                        'Total',
                        controller.totalPermissions.value.toString(),
                        AppColors.primaryBlue,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(String title, String count, Color color) {
    return Container(
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
            const CircleAvatar(radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 150, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(height: 13, width: 100, color: Colors.white),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

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
            Text('Failed to Load Permissions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.fontFamily)),
            const SizedBox(height: 8),
            Text(errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                    fontFamily: AppFonts.fontFamily)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

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
                  fontFamily: AppFonts.fontFamily),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no permission requests from students for you at the moment.',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mediumText,
                  fontFamily: AppFonts.fontFamily),
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

  const StudentPermissionCard({
    Key? key,
    required this.permission,
    required this.controller,
  }) : super(key: key);

  Color _getStatusColor(String status, {bool isBackground = false}) {
    switch (status.toLowerCase()) {
      case "pending":
        return isBackground
            ? AppColors.pendingOrange.withOpacity(0.1)
            : AppColors.pendingOrange;
      case "accepted": // <-- FIX: Was "accepted"
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

  @override
  Widget build(BuildContext context) {
    final studentName = permission.studentDetails?.engName ?? 'Unknown Student';
    final studentGender = permission.studentDetails?.gender ?? 'N/A';
    final studentAvatarUrl = permission.studentDetails?.avatarUrl;

    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey, width: 1),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SuperProfilePicture(
                        imageUrl: studentAvatarUrl,
                        fullName: studentName,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Gender: $studentGender',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.mediumText),
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

  Widget _buildExpandedDetails(PermissionItem permission) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32, thickness: 1, color: AppColors.borderGrey),
          const Text(
            "Permission Detail",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_rounded, "Date:",
              permission.formattedDateRange),
          const SizedBox(height: 8),
          _buildDetailRow(
              Icons.edit_note_rounded, "Reason:", permission.reason),
          const SizedBox(height: 20),
          if (permission.status.toLowerCase() == "pending")
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // UPDATE: Pass the full permission object
                      controller.updatePermissionStatus(permission, "rejected");
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.declineRed,
                        foregroundColor: Colors.white),
                    child: const Text("Rejecte"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // UPDATE: Pass the full permission object
                      controller.updatePermissionStatus(permission, "accepted");
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white),
                    child: const Text("Accepte"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mediumText),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(
                    text: value,
                    style: const TextStyle(color: AppColors.mediumText)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
