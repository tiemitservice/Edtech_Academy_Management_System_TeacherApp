import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/screens/home/check_attendence_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_permissions_screen.dart';
// If you uncommented StudentScoresListScreen before, make sure it's uncommented here too:

class TeacherManagementScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String studentsCount;
  final String subjectName;

  const TeacherManagementScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.studentsCount,
    required this.subjectName,
  }) : super(key: key);

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _borderGrey = Color(0xFFE0E6ED);

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: _primaryBlue,
    ));

    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Teacher Management",
          style: TextStyle(
            color: Colors.white,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          _buildHeader(),
          // Content Section
          Expanded(
            child: Container(
              color: _lightBackground,
              child: _buildContentList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primaryBlue, // Background color for the app bar region
      child: Container(
        decoration: const BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 25), // Increased vertical padding for more space
        child: Row(
          // Use a Row to position text info and SVG
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the top
          children: [
            Expanded(
              // Allow text column to take available space
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Left-align all text
                children: [
                  Text(
                    '${widget.className}',
                    style: const TextStyle(
                      fontSize: 16, // Larger, more prominent class name
                      fontWeight: FontWeight.bold, // Extra bold for class name
                      color: _darkText,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                    maxLines: 2, // Allow wrapping for long names
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                      height: 6), // Spacing between class and subject
                  Text(
                    'Subject: ${widget.subjectName}', // Clear label for subject
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          _mediumText, // Slightly softer color for secondary info
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12), // Spacing before student count

                  Container(
                    // A subtle container for student count
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryBlue
                          .withOpacity(0.1), // Light blue background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'All Students: ${widget.studentsCount}', // Clear label for student count
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                        fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20), // Spacing between text and SVG
            SvgPicture.asset(
              'assets/images/onboarding/teacher_check.svg',
              height: 100, // Fixed height for a distinct visual element
              width: 100,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMainCard(
          image: 'assets/images/teacher_management/atd.svg',
          title: "Check Attendance",
          subtitle: "Manage the students in your classes",
          onTap: () {
            Get.to(() => CheckAttendanceScreen(
                  classId: widget.classId,
                  className: widget.className,
                  studentsCount: widget.studentsCount,
                  subjectName: widget.subjectName,
                ));
          },
        ),
        // // Uncomment this section if you want the "Student's Score" card
        // _buildMainCard(
        //   image: 'assets/images/teacher_management/score.svg',
        //   title: "Student's Score",
        //   subtitle: "Manage the scores in each classes",
        //   onTap: () {
        //     print("Student's Score tapped");
        //     Get.to(() => StudentScoresListScreen(
        //           // Make sure StudentScoresListScreen is imported
        //           classId: widget.classId,
        //           className: widget.className,
        //           studentsCount: widget.studentsCount,
        //         ));
        //   },
        // ),
        _buildMainCard(
          image: 'assets/images/teacher_management/permission.svg',
          title: "Student's Permission",
          subtitle: "Check Student's ask for permission in each classes",
          onTap: () {
            Get.to(() => StudentPermissionsScreen(
                  // Make sure StudentScoresListScreen is imported
                  classId: widget.classId,
                  className: widget.className,
                  studentsCount: int.parse(widget.studentsCount),
                  subjectName: widget.subjectName,
                ));
          },
        ),
        _buildMainCard(
          image: 'assets/images/teacher_management/list.svg',
          title: "Student's List",
          subtitle: "View all my Student's in each classes",
          onTap: () {
            Get.toNamed('/student-list');
          },
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderGrey, width: 1),
      ),
      color: _cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SvgPicture.asset(image, width: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _darkText,
                        fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _mediumText,
                        fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: _mediumText),
            ],
          ),
        ),
      ),
    );
  }
}
