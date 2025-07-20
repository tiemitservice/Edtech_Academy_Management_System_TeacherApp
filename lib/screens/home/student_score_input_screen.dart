import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/screens/home/check_attendence_screen.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Assuming Student model is here

// It's assumed the Student model from `check_attendence_screen.dart` is updated
// to include score fields. The provided Student class already has these.

class StudentScoreInputScreen extends StatefulWidget {
  final Student student;
  final String className;
  final String studentsCount;

  const StudentScoreInputScreen({
    Key? key,
    required this.student,
    required this.className,
    required this.studentsCount,
  }) : super(key: key);

  @override
  State<StudentScoreInputScreen> createState() =>
      _StudentScoreInputScreenState();
}

class _StudentScoreInputScreenState extends State<StudentScoreInputScreen> {
  // Define UI colors for consistency
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF8FAFB);
  static const Color _cardBackground = Colors.white;
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _borderColor = Color(0xFFDCDCDC);
  static const Color _lightFillColor = Color(0xFFF4F7F9);

  // --- Font Family Constant ---
  static const String _fontFamily = AppFonts.fontFamily;

  // Controllers for score input fields
  final TextEditingController _quizScoreController = TextEditingController();
  final TextEditingController _midtermScoreController = TextEditingController();
  final TextEditingController _finalScoreController = TextEditingController();

  // State variables
  String _selectedAttendanceStatus = 'Present';
  double _totalScore = 0.0;
  bool _isLoading = false;

  final List<String> _attendanceOptions = [
    "Present",
    "Late",
    "Permission",
    "Absence"
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to controllers to auto-calculate total score
    _quizScoreController.addListener(_calculateTotalScore);
    _midtermScoreController.addListener(_calculateTotalScore);
    _finalScoreController.addListener(_calculateTotalScore);

    // Load existing student data into the form fields
    final studentData = widget.student;
    // _quizScoreController.text = (studentData.quiz_score ?? 0).toString();
    // _midtermScoreController.text = (studentData.midterm_score ?? 0).toString();
    // _finalScoreController.text = (studentData.final_score ?? 0).toString();

    // Capitalize the status from the API (e.g., "present" -> "Present")
    String status = studentData.status;
    if (status.isNotEmpty) {
      _selectedAttendanceStatus = status[0].toUpperCase() + status.substring(1);
    }

    _calculateTotalScore(); // Calculate initial total score
  }

  @override
  void dispose() {
    _quizScoreController.dispose();
    _midtermScoreController.dispose();
    _finalScoreController.dispose();
    super.dispose();
  }

  /// Calculates the total score from the input fields and updates the state.
  void _calculateTotalScore() {
    final quiz = double.tryParse(_quizScoreController.text) ?? 0.0;
    final midterm = double.tryParse(_midtermScoreController.text) ?? 0.0;
    final finalScore = double.tryParse(_finalScoreController.text) ?? 0.0;
    if (mounted) {
      setState(() {
        _totalScore = quiz + midterm + finalScore;
      });
    }
  }

  /// Resets all input fields to their default values.
  void _resetScores() {
    setState(() {
      _quizScoreController.clear();
      _midtermScoreController.clear();
      _finalScoreController.clear();
      _selectedAttendanceStatus = 'Present';
      _totalScore = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Scores have been reset.',
              style: const TextStyle(
                  fontFamily: _fontFamily))), // Apply NotoSerifKhmer
    );
  }

  /// Saves the updated scores and attendance to the backend API.
  Future<void> _saveScores() async {
    if (_isLoading) return; // Prevent multiple submissions

    setState(() {
      _isLoading = true;
    });

    // The API endpoint to update a student's score and attendance.
    // This uses the student's unique ID.
    final url = Uri.parse(
        'http://188.166.242.109:5000/api/students/${widget.student.id}');

    try {
      final body = json.encode({
        'quiz_score': double.tryParse(_quizScoreController.text) ?? 0,
        'midterm_score': double.tryParse(_midtermScoreController.text) ?? 0,
        'final_score': double.tryParse(_finalScoreController.text) ?? 0,
        // The API expects a lowercase string for attendance
        'attendence_enum': _selectedAttendanceStatus.toLowerCase(),
      });

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Scores for ${widget.student.name} saved successfully!',
                  style: const TextStyle(
                      fontFamily: _fontFamily)), // Apply NotoSerifKhmer
              backgroundColor: Colors.green),
        );
        Get.back(result: true); // Go back and indicate success
      } else {
        // Handle server errors
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'An unknown error occurred.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save scores: $errorMessage',
                  style: const TextStyle(
                      fontFamily: _fontFamily)), // Apply NotoSerifKhmer
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Handle network or other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred: $e',
                style: const TextStyle(
                    fontFamily: _fontFamily)), // Apply NotoSerifKhmer
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Helper Methods ---

  Color getStatusColor(String status, {bool isBackground = false}) {
    switch (status) {
      case "Permission":
        return isBackground ? const Color(0xFFE7F0FE) : const Color(0xFF0D6EFD);
      case "Late":
        return isBackground ? const Color(0xFFFFF8E1) : const Color(0xFFFFC107);
      case "Absence":
        return isBackground ? const Color(0xFFFBE9EA) : const Color(0xFFDC3545);
      case "Present":
        return isBackground ? const Color(0xFFEAF6EB) : const Color(0xFF28A745);
      default:
        return isBackground ? _lightFillColor : _mediumText;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case "Permission":
        return Icons.insert_drive_file_outlined;
      case "Late":
        return Icons.watch_later_outlined;
      case "Absence":
        return Icons.highlight_off_outlined;
      case "Present":
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

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

  ImageProvider _getAvatarImage(Student student) {
    final avatarUrl = student.avatarUrl;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        (Uri.tryParse(avatarUrl)?.hasAbsolutePath ?? false)) {
      return NetworkImage(avatarUrl);
    }
    return const AssetImage('assets/images/no_profile_image_w.png');
  }

  Widget _buildScoreInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: _mediumText,
              fontFamily: _fontFamily), // Apply NotoSerifKhmer
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: _primaryBlue, width: 2.0),
          ),
          filled: true,
          fillColor: _lightBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(
            color: _darkText,
            fontSize: 16,
            fontFamily: _fontFamily), // Apply NotoSerifKhmer
      ),
    );
  }

  // --- Main Build Method ---

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Theme(
                // Wrap with Theme to apply default font family
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context)
                      .textTheme
                      .apply(fontFamily: _fontFamily),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Info
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    _getAvatarImage(widget.student),
                                radius: 30,
                                backgroundColor: _lightFillColor,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _darkText,
                                      fontFamily:
                                          _fontFamily, // Apply NotoSerifKhmer
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Gender: ${widget.student.gender}",
                                    style: const TextStyle(
                                      color: _mediumText,
                                      fontSize: 14,
                                      fontFamily:
                                          _fontFamily, // Apply NotoSerifKhmer
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(
                              height: 30, thickness: 1, color: _borderColor),

                          // Attendance Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(_selectedAttendanceStatus,
                                  isBackground: true),
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: _borderColor, width: 1.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedAttendanceStatus,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.grey),
                                style: TextStyle(
                                  color:
                                      getStatusColor(_selectedAttendanceStatus),
                                  fontWeight: FontWeight.w600,
                                  fontFamily:
                                      _fontFamily, // Apply NotoSerifKhmer
                                  fontSize: 15,
                                ),
                                onChanged: _isLoading
                                    ? null
                                    : (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedAttendanceStatus =
                                                newValue;
                                          });
                                        }
                                      },
                                items: _attendanceOptions
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(getStatusIcon(value),
                                            size: 20,
                                            color: getStatusColor(value)),
                                        const SizedBox(width: 10),
                                        Text(value,
                                            style: const TextStyle(
                                                fontFamily:
                                                    _fontFamily)), // Apply NotoSerifKhmer
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Score Input Fields
                          _buildScoreInputField(
                              "Quiz Score", _quizScoreController),
                          _buildScoreInputField(
                              "Midterm Score", _midtermScoreController),
                          _buildScoreInputField(
                              "Final Score", _finalScoreController),
                          const SizedBox(height: 16),

                          // Total Score Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _primaryBlue),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Score:",
                                  style: TextStyle(
                                    color: _darkText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    fontFamily:
                                        _fontFamily, // Apply NotoSerifKhmer
                                  ),
                                ),
                                Text(
                                  _totalScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily:
                                        _fontFamily, // Apply NotoSerifKhmer
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _resetScores,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryBlue,
                              side: const BorderSide(color: _primaryBlue),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Reset",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily:
                                        _fontFamily)), // Apply NotoSerifKhmer
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveScores,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text("Save",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily:
                                            _fontFamily)), // Apply NotoSerifKhmer
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
