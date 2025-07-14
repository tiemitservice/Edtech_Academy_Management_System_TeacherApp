// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/screens/home/student_info_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/controllers/student_info_controller.dart';
import 'package:shimmer/shimmer.dart'; // For shimmer effect

class StudentInfoScreen extends StatelessWidget {
  final String studentId;

  const StudentInfoScreen({Key? key, required this.studentId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StudentInfoController controller = Get.find<StudentInfoController>();

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
          return _buildStudentDetails(student, controller.fullAddress.value);
        }
      }),
    );
  }

  Widget _buildStudentDetails(Student student, String fullAddress) {
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
                Text(
                  'ID: ${student.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.mediumText,
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
              _buildInfoRow(Icons.phone, 'Phone Number', student.phoneNumber),
              _buildInfoRow(Icons.email, 'Email', student.email),
            ],
          ),

          // Academic & Attendance Details
          _buildInfoCard(
            title: 'Academic & Attendance',
            children: [
              _buildInfoRow(Icons.score_outlined, 'Overall Score',
                  student.score?.toString()),
              _buildInfoRow(Icons.check_circle_outline, 'Total Attendance',
                  student.attendance?.toString()),
              _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Last Attendance Date',
                  student.attendanceDate != null
                      ? DateFormat('dd MMM yyyy')
                          .format(student.attendanceDate!)
                      : 'N/A'),
              _buildInfoRow(Icons.info_outline, 'Attendance Status',
                  student.attendanceEnum),
              _buildInfoRow(Icons.star_half_outlined, 'Quiz Score',
                  student.quizScore?.toString()),
              _buildInfoRow(Icons.star_half_outlined, 'Midterm Score',
                  student.midtermScore?.toString()),
              _buildInfoRow(Icons.star_outlined, 'Final Score',
                  student.finalScore?.toString()),
              _buildInfoRow(Icons.grading_outlined, 'Total Attendance Score',
                  student.totalAttendanceScore?.toString()),
              _buildInfoRow(Icons.track_changes_outlined, 'Score Status',
                  student.scoreStatus),
            ],
          )
        ],
      ),
    );
  }

  // Helper to build a styled information card
  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: AppColors
          .cardBackground, // Use AppColors.cardBackground for consistency
      margin: const EdgeInsets.only(bottom: 16.0),
      // Enhanced shadow for a more "popped" effect and subtle definition
      elevation: 6, // Slightly higher elevation for more depth
      shadowColor:
          AppColors.borderGrey.withOpacity(0.4), // Softer, more diffused shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Consistent border radius
        side: BorderSide(
            color: AppColors.borderGrey.withOpacity(0.5),
            width: 0.5), // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Consistent padding for content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20, // Slightly larger title for prominence
                fontWeight: FontWeight.bold, // Keep bold
                color: AppColors.darkText,
                fontFamily: AppFonts.fontFamily,
              ),
            ),
            const Divider(
                height: 28,
                thickness: 1.5,
                color: AppColors
                    .borderGrey), // Increased height and thickness for divider
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper to build a single information row with icon and text
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 10.0), // Good vertical spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // Add a subtle background for the icon
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 20,
                color: AppColors
                    .primaryBlue), // Icon size adjusted to fit container
          ),
          const SizedBox(width: 16), // Ample spacing between icon and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600, // Make labels slightly bolder
                    color: AppColors.mediumText,
                    fontFamily: AppFonts.fontFamily,
                  ),
                ),
                const SizedBox(height: 6), // Consistent spacing
                Text(
                  value ?? 'N/A', // Display 'N/A' if value is null
                  style: const TextStyle(
                    fontSize: 17, // Larger value text for readability
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

  // Shimmer loading state for StudentInfoScreen
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
                  Container(height: 16, width: 150, color: Colors.white),
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

  // Error state for StudentInfoScreen
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

  // Empty state for StudentInfoScreen (e.g., student not found)
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
