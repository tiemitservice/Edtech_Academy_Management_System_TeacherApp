import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/screens/home/check_attendence_screen.dart'; // Assuming Student model is here
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

// Assuming StudentScoreInputScreen is correctly implemented
import 'student_score_input_screen.dart';

// This data model is used to structure the data specifically for this list screen.
class StudentScoreSummary {
  final Student student;
  final String attendanceStatus;
  final double totalScore;

  StudentScoreSummary({
    required this.student,
    required this.attendanceStatus,
    required this.totalScore,
  });
}

class StudentScoresListScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String studentsCount;

  const StudentScoresListScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.studentsCount,
  }) : super(key: key);

  @override
  State<StudentScoresListScreen> createState() =>
      _StudentScoresListScreenState();
}

class _StudentScoresListScreenState extends State<StudentScoresListScreen> {
  // Define colors for consistent UI theming
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF8FAFB);
  static const Color _cardBackground = Colors.white;
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _skeletonColor = Color(0xFFE0E0E0);
  static const Color _skeletonHighlightColor = Color(0xFFF0F0F0);
  static const Color _lightFillColor = Color(0xFFF4F7F9);
  static const Color _errorRed =
      Color(0xFFDC3545); // Added for consistency with other screens

  // --- Font Family Constant ---
  static const String _fontFamily = AppFonts.fontFamily;

  late Future<List<StudentScoreSummary>> _studentScoresFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future to fetch student scores from the API using the classId
    _studentScoresFuture = _fetchStudentScores(widget.classId);
  }

  /// Fetches student scores from the remote API for a specific class.
  ///
  /// This function sends a GET request to the classes API, finds the class
  /// matching [classId], and then processes its student list.
  Future<List<StudentScoreSummary>> _fetchStudentScores(String classId) async {
    // The API endpoint fetches all classes. We need to find the one with the matching classId.
    // A more efficient API would be `/api/classes/{classId}`
    final Uri url = Uri.parse(
        'http://188.166.242.109:5000/api/classes');

    try {
      final response =
          await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> allClasses = decodedData['data'];

        // Find the specific class by its ID from the list of all classes
        final classData = allClasses.firstWhere(
          (c) => c['_id'] == classId,
          orElse: () => null, // Return null if no class is found
        );

        if (classData == null) {
          throw Exception('Class with ID $classId not found.');
        }

        final List<dynamic> studentsData = classData['students'] ?? [];

        if (studentsData.isEmpty) {
          return []; // Return an empty list if there are no students in the class
        }

        // Map the student data from the API to the local StudentScoreSummary model
        return studentsData.map((studentJson) {
          // Create the Student object required by StudentScoreSummary
          final student = Student(
            id: studentJson['_id'] ?? '',
            name: studentJson['eng_name'] ?? 'No Name',
            gender: studentJson['gender'] ?? 'N/A',
            avatarUrl: studentJson['image'],
            status: studentJson['attendence_enum'] ?? 'N/A',
            // Ensure these are parsed correctly from the API to match the Student model
            // quiz_score: (studentJson['quiz_score'] ?? 0).toDouble(),
            // midterm_score: (studentJson['midterm_score'] ?? 0).toDouble(),
            // final_score: (studentJson['final_score'] ?? 0).toDouble(),
          );

          // Calculate total score by summing up the different score fields from the API
          double finalScore = (studentJson['final_score'] ?? 0).toDouble();
          double midtermScore = (studentJson['midterm_score'] ?? 0).toDouble();
          double quizScore = (studentJson['quiz_score'] ?? 0).toDouble();
          double totalScore = finalScore + midtermScore + quizScore;

          // The API's `attendence_enum` (e.g., "present") needs to be capitalized
          // to match the expected format for `getStatusColor` (e.g., "Present").
          String attendanceStatus = studentJson['attendence_enum'] ?? 'N/A';
          if (attendanceStatus.isNotEmpty && attendanceStatus != 'N/A') {
            attendanceStatus = attendanceStatus[0].toUpperCase() +
                attendanceStatus.substring(1);
          }

          return StudentScoreSummary(
            student: student,
            attendanceStatus: attendanceStatus,
            totalScore: totalScore,
          );
        }).toList();
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any other exceptions during the process (e.g., network error)
      throw Exception('Failed to fetch student scores: $e');
    }
  }

  /// Returns a color based on the student's attendance status.
  Color getStatusColor(String status) {
    switch (status) {
      case "Permission":
        return const Color(0xFF0D6EFD);
      case "Late":
        return const Color(0xFFFFC107);
      case "Absence":
        return const Color(0xFFDC3545);
      case "Present":
        return const Color(0xFF28A745);
      default:
        return _mediumText;
    }
  }

  /// Builds a UI column for the header section.
  Widget _buildHeaderColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: const TextStyle(
                color: _mediumText,
                fontFamily: _fontFamily)), // Apply NotoSerifKhmer
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
                fontFamily: _fontFamily)), // Apply NotoSerifKhmer
      ],
    );
  }

  /// Builds the header section of the screen.
  Widget _buildHeader() {
    return Container(
      color: _primaryBlue,
      child: Container(
        decoration: const BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderColumn("Class", widget.className),
            SvgPicture.asset('assets/images/onboarding/teacher_check.svg',
                height: 80),
            _buildHeaderColumn("Students", widget.studentsCount),
          ],
        ),
      ),
    );
  }

  /// Provides an image for the student's avatar, with a fallback.
  ImageProvider _getAvatarImage(Student student) {
    final avatarUrl = student.avatarUrl;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        (Uri.tryParse(avatarUrl)?.hasAbsolutePath ?? false)) {
      return NetworkImage(avatarUrl);
    }
    // Provide a local fallback image
    return const AssetImage('assets/images/no_profile_image_w.png');
  }

  /// Builds a card widget for displaying a single student's score summary.
  Widget _buildStudentScoreCard(StudentScoreSummary scoreSummary) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to the score input screen for the selected student
          // and then refresh the list when returning.
          Get.to(() => StudentScoreInputScreen(
                student: scoreSummary.student,
                className: widget.className,
                studentsCount: widget.studentsCount,
              ))?.then((result) {
            if (result == true) {
              // Assuming result 'true' means data was updated
              setState(() {
                _studentScoresFuture =
                    _fetchStudentScores(widget.classId); // Re-fetch data
              });
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _getAvatarImage(scoreSummary.student),
                radius: 26,
                backgroundColor: _lightFillColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreSummary.student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Gender: ${scoreSummary.student.gender}",
                      style: const TextStyle(
                        color: _mediumText,
                        fontSize: 13,
                        fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Attendance: ${scoreSummary.attendanceStatus}",
                    style: TextStyle(
                      color: getStatusColor(scoreSummary.attendanceStatus),
                      fontSize: 13,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total Score: ${scoreSummary.totalScore.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a list of shimmering skeleton loaders for the loading state.
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: _skeletonColor,
      highlightColor: _skeletonHighlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8, // Number of shimmer items
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildStudentSkeletonLoader(),
      ),
    );
  }

  /// Builds a single skeleton loader item.
  Widget _buildStudentSkeletonLoader() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const CircleAvatar(radius: 26, backgroundColor: Colors.white),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ])),
      ]),
    );
  }

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
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text("STUDENT'S SCORE",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 19,
                fontFamily: _fontFamily)), // Apply NotoSerifKhmer
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<StudentScoreSummary>>(
              future: _studentScoresFuture,
              builder: (context, snapshot) {
                // Wrap the entire builder content with Theme to set default font
                return Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context)
                        .textTheme
                        .apply(fontFamily: _fontFamily),
                  ),
                  child: Builder(
                      // Use Builder to ensure context is aware of the new Theme
                      builder: (innerContext) {
                    // Show a shimmer loading effect while data is being fetched
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerList();
                    }
                    // Show an error message if fetching fails
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: _errorRed,
                                  size: 50), // Using _errorRed constant
                              const SizedBox(height: 10),
                              Text('Error: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontFamily:
                                          _fontFamily)), // Apply NotoSerifKhmer
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _studentScoresFuture = _fetchStudentScores(
                                        widget.classId); // Re-fetch on retry
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry",
                                    style: TextStyle(
                                        fontFamily:
                                            _fontFamily)), // Apply NotoSerifKhmer
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // If data is fetched successfully, display it
                    if (snapshot.hasData) {
                      final studentScores = snapshot.data!;
                      if (studentScores.isEmpty) {
                        return const Center(
                            child: Text("No students found in this class.",
                                style: TextStyle(
                                    fontFamily:
                                        _fontFamily))); // Apply NotoSerifKhmer
                      }
                      // Build the list of student score cards
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: studentScores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildStudentScoreCard(studentScores[index]);
                        },
                      );
                    }
                    // A fallback message if no data is available
                    return const Center(
                        child: Text("No data available.",
                            style: TextStyle(
                                fontFamily:
                                    _fontFamily))); // Apply NotoSerifKhmer
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
