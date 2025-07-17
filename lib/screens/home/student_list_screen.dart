import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Required for SvgPicture
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/controllers/student_list_controller.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';

class StudentListScreen extends StatelessWidget {
  // Make essential parameters required
  final String classId;
  final String className;
  final String subjectName;
  final String?
      studentsCount; // This can remain nullable, as it's often a string from navigation args

  const StudentListScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.subjectName,
    this.studentsCount, // Optional, initial count from previous screen
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize and put the controller with the required classId.
    // Get.put is typically called once per controller instance.
    final StudentListController controller =
        Get.put(StudentListController(classId: classId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(className),
      body: Column(
        children: [
          // Header section displaying class info and dynamic student count
          _buildHeader(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildShimmerList();
              } else if (controller.errorMessage.isNotEmpty) {
                // Correct retry callback
                return _buildErrorState(controller.errorMessage.value,
                    () => controller.fetchStudents());
              } else if (controller.students.isEmpty) {
                return _buildEmptyState(className);
              } else {
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.students.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = controller.students[index];
                    return _buildStudentCard(student);
                  },
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  /// Builds the AppBar for the Student List screen.
  AppBar _buildAppBar(String className) {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        "STUDENT LIST",
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

  /// Header widget to display class name, subject, and reactive student count.
  Widget _buildHeader(StudentListController controller) {
    return Container(
      color: AppColors.primaryBlue, // Top section background
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground, // Content background
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24)), // Rounded top corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className, // Class name from constructor
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subject: $subjectName', // Subject name from constructor
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Container(
                        // Use Obx to react to totalStudentsCount changes
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'All Students: ${controller.totalStudentsCount.value}', // Reactive student count
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                            fontFamily: AppFonts.fontFamily,
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SvgPicture.asset(
              'assets/images/teacher_management/list.svg',
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single student card in the list.
  Widget _buildStudentCard(Student student) {
    final String displayName = student.displayName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderGrey.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          print('Tapped on student: $displayName (ID: ${student.id})');
          Get.toNamed(AppRoutes.studentInfo,
              arguments: {'studentId': student.id});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SuperProfilePicture(
                imageUrl: student.avatarUrl,
                fullName: displayName,
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                textColor: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                        fontFamily: AppFonts.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gender: ${student.gender}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumText,
                        fontFamily: AppFonts.fontFamily,
                      ),
                    ),
                    // FIX: Correctly check if phoneNumber is not null and not empty
                    if (student.phoneNumber !=
                        student.phoneNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Phone: ${student.phoneNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumText,
                            fontFamily: AppFonts.fontFamily,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.mediumText, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a shimmer loading list for student cards.
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBaseColor,
      highlightColor: AppColors.skeletonHighlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Show a reasonable number of skeletons
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildStudentCardSkeleton(),
      ),
    );
  }

  /// Builds a single skeleton card for shimmer effect.
  Widget _buildStudentCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderGrey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Skeleton for the profile picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor
                  .withOpacity(0.5), // Use skeleton color for consistency
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton for student name
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Skeleton for gender
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Skeleton for phone number
                Container(
                  height: 14,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Skeleton for email
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBaseColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Skeleton for the arrow icon
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: AppColors.skeletonBaseColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error state widget.
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
            const Text(
              'Failed to Load Students',
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

  /// Builds the empty state widget when no students are found.
  Widget _buildEmptyState(String className) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded,
                size: 150, color: AppColors.mediumText.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'No Students Found in $className', // Use the provided className
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
              'There are no student records available for $className at the moment.', // Use the provided className
              style: const TextStyle(
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
