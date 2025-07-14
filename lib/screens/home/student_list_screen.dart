// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/screens/home/student_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/models/student.dart'; // Correctly import Student model
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/controllers/student_list_controller.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart'; // Import AppRoutes

class StudentListScreen extends StatelessWidget {
  final String? classId;
  final String? className;

  const StudentListScreen({Key? key, this.classId, this.className})
      : super(key: key); // NEW: Accept classId and className

  @override
  Widget build(BuildContext context) {
    final StudentListController controller =
        Get.find<StudentListController>(); //

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(className), // Pass className to AppBar
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerList();
          } else if (controller.errorMessage.isNotEmpty) {
            return _buildErrorState(
                controller.errorMessage.value,
                () => controller.fetchStudents(
                    classId: classId)); // Pass classId on retry
          } else if (controller.students.isEmpty) {
            //
            return _buildEmptyState(
                className); // Pass className to empty state message
          } else {
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: controller.students.length, //
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = controller.students[index]; //
                return _buildStudentCard(student);
              },
            );
          }
        }),
      ),
    );
  }

  AppBar _buildAppBar(String? className) {
    // Modified to accept className
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text(
        className != null
            ? "STUDENTS IN ${className.toUpperCase()}"
            : "ALL STUDENTS", // Dynamic title
        style: const TextStyle(
          color: Colors.white,
          fontFamily: AppFonts.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStudentCard(Student student) {
    final String displayName =
        student.displayName; // Correctly access displayName getter

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
          // Navigate to StudentInfoScreen, passing student.id as argument
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
                      'Gender: ${student.gender}', //
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumText,
                        fontFamily: AppFonts.fontFamily,
                      ),
                    ),
                    if (student.phoneNumber != null &&
                        student.phoneNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Phone: ${student.phoneNumber!}', //
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumText,
                            fontFamily: AppFonts.fontFamily,
                          ),
                        ),
                      ),
                    if (student.email != null && student.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Email: ${student.email!}', //
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

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBaseColor,
      highlightColor: AppColors.skeletonHighlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildStudentCardSkeleton(),
      ),
    );
  }

  Widget _buildStudentCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 18, width: double.infinity, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 14, width: 150, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 14, width: 100, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(height: 20, width: 20, color: Colors.white),
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
            Text(
              'Failed to Load Students',
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

  Widget _buildEmptyState(String? className) {
    // Modified to accept className
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
              className != null
                  ? 'No Students Found in $className'
                  : 'No Students Found', // Dynamic empty state message
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
              className != null
                  ? 'There are no student records available for $className at the moment.'
                  : 'There are no student records available at the moment.',
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
