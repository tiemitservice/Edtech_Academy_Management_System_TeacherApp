import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/screens/home/custom_drawer.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

// Extension to capitalize the first letter of a string, useful if API returns lowercase enums
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// --- DATA MODELS ---

class Student {
  final String id;
  String name;
  String gender;
  String? avatarUrl;
  String
      status; // Reflects API data (e.g., "present", "absence", "uncheck", or "Not Set")
  bool isSaved; // True if API had a valid attendance enum, false otherwise
  final double? attendance_score;
  final double? class_practice;
  final double? home_work;
  final double? assignment_score;
  final double? presentation;
  final double? revision_test;
  final double? final_exam_score;
  final double? total_score;
  final double? work_book;
  final String? note;
  final String? comments;

  // Constant for explicitly "Not Set" attendance (frontend display for null/empty API data)
  static const String notSetStatus = "Not Set";

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
    this.status =
        notSetStatus, // Default to "Not Set" for new instances if not specified
    this.isSaved = false,
    this.attendance_score,
    this.class_practice,
    this.home_work,
    this.assignment_score,
    this.presentation,
    this.revision_test,
    this.final_exam_score,
    this.total_score,
    this.work_book,
    this.note,
    this.comments,
  });

  // Factory constructor to create a Student from JSON, requiring validEnums
  factory Student.fromJson(Map<String, dynamic> json, List<String> validEnums) {
    // Helper function to process the raw status string from the backend.
    String? _processRawStatusString(String? statusStr) {
      if (statusStr == null || statusStr.isEmpty) {
        return null;
      }
      for (String validEnum in validEnums) {
        if (statusStr.toLowerCase() == validEnum.toLowerCase()) {
          return validEnum;
        }
      }
      return statusStr;
    }

    String? rawAttendanceStatusFromBackend;
    Map<String, dynamic> studentDetails;

    // Determine if the student data is nested under a 'student' key
    if (json.containsKey('student') && json['student'] is Map) {
      studentDetails = json['student'];
    } else {
      studentDetails = json;
    }

    // Use the `attendance` field at the main JSON level
    if (json.containsKey('attendance')) {
      rawAttendanceStatusFromBackend = json['attendance']?.toString();
    }

    String finalStatusForFrontend;
    bool isStudentSavedInitially = false;

    String? processedStatusFromApi =
        _processRawStatusString(rawAttendanceStatusFromBackend);

    if (processedStatusFromApi == null) {
      finalStatusForFrontend = notSetStatus;
      isStudentSavedInitially = false;
    } else {
      finalStatusForFrontend = processedStatusFromApi;
      isStudentSavedInitially = validEnums.contains(processedStatusFromApi);
    }

    return Student(
      id: studentDetails['_id'] ?? '',
      name: studentDetails['eng_name'] ?? 'Unknown Name',
      gender: studentDetails['gender'] ?? 'N/A',
      avatarUrl: studentDetails['image'],
      status: finalStatusForFrontend,
      isSaved: isStudentSavedInitially,
      attendance_score: (json['attendance_score'] ?? 0).toDouble(),
      class_practice: (json['class_practice'] ?? 0).toDouble(),
      home_work: (json['home_work'] ?? 0).toDouble(),
      assignment_score: (json['assignment_score'] ?? 0).toDouble(),
      presentation: (json['presentation'] ?? 0).toDouble(),
      revision_test: (json['revision_test'] ?? 0).toDouble(),
      final_exam_score: (json['final_exam'] ?? 0).toDouble(),
      total_score: (json['total_score'] ?? 0).toDouble(),
      work_book: (json['work_book'] ?? 0).toDouble(),
      note: json['note'] ?? "",
      comments: json['comments'] ?? null,
    );
  }

  // Converts Student object to JSON format suitable for backend PATCH request
  Map<String, dynamic> toJson(List<String> validEnums) {
    // Determine the status string to send to backend.
    String? statusToSendToBackend;
    if (status == notSetStatus || !validEnums.contains(status)) {
      statusToSendToBackend = null;
    } else {
      statusToSendToBackend = status.toLowerCase();
    }

    return {
      'student': id,
      'attendance': statusToSendToBackend,
      'checking_at': DateTime.now().toIso8601String(),
      'attendance_score': attendance_score ?? 0,
      'class_practice': class_practice ?? 0,
      'home_work': home_work ?? 0,
      'assignment_score': assignment_score ?? 0,
      'presentation': presentation ?? 0,
      'revision_test': revision_test ?? 0,
      'final_exam': final_exam_score ?? 0,
      'total_score': total_score ?? 0,
      'work_book': work_book ?? 0,
      'note': note ?? "",
      'comments': comments ?? null,
    };
  }
}

// --- MAIN WIDGET (CheckAttendanceScreen) ---

class CheckAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String studentsCount;
  final String subjectName;

  const CheckAttendanceScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.studentsCount,
    required this.subjectName,
  }) : super(key: key);

  @override
  State<CheckAttendanceScreen> createState() => _CheckAttendanceScreenState();
}

class _CheckAttendanceScreenState extends State<CheckAttendanceScreen> {
  // State variables for dynamically fetched attendance enums
  List<String> _validAttendanceEnums = [];
  bool _isLoadingEnums = true;
  String _errorMessageEnums = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<Student>> _studentListFuture;
  final AuthController _authController = Get.find<AuthController>();

  // Use a map to track changes more efficiently
  final Map<String, String> _originalStatuses = {};
  final Map<String, String> _pendingStatuses = {};

  List<Student> _students = [];

  bool _isSubmitting = false;

  // New state variables to store class-related IDs for attendance report
  String? _currentSubjectId;
  String? _currentDurationId;
  String? _currentStaffId;

  static const String _fontFamily = AppFonts.fontFamily;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Centralized initialization logic
  Future<void> _initializeData() async {
    // 1. Fetch valid attendance enums first
    await _fetchValidAttendanceEnums();

    // 2. Only if enums are loaded successfully, proceed to fetch students
    if (_errorMessageEnums.isEmpty) {
      _studentListFuture = _fetchFilteredClassStudents();
    } else {
      // If enum fetching failed, set a failed future for students as well
      _studentListFuture = Future.error(_errorMessageEnums);
    }
    setState(() {}); // Trigger initial build with loading/error states
  }

  Future<void> _fetchValidAttendanceEnums() async {
    setState(() {
      _isLoadingEnums = true;
      _errorMessageEnums = '';
    });
    try {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay
      _validAttendanceEnums = ["Present", "Absent", "Late", "Permission"];
    } catch (e) {
      _errorMessageEnums = 'Error fetching attendance options: ${e.toString()}';
    } finally {
      setState(() {
        _isLoadingEnums = false;
      });
    }
  }

  void _onStatusChanged(String studentId, String newStatus) {
    if (mounted) {
      setState(() {
        _pendingStatuses[studentId] = newStatus;
      });
    }
  }

  bool get _hasChanges {
    if (_pendingStatuses.length != _originalStatuses.length) {
      return true;
    }
    for (var entry in _pendingStatuses.entries) {
      if (_originalStatuses[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }

  Future<List<Student>> _fetchFilteredClassStudents() async {
    final uri = Uri.parse('http://188.166.242.109:5000/api/classes');
    final staffId = await _authController.getStaffId();
    final token = await _authController.getToken();

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        final List<dynamic> allClassData = decodedBody['data'];

        final classJson = allClassData.firstWhere(
          (c) => c['_id'] == widget.classId && c['staff'] == staffId,
          orElse: () => throw Exception(
              'Class with ID "${widget.classId}" not found or you do not have permission to access it.'),
        );

        _currentSubjectId = classJson['subject'];
        _currentDurationId = classJson['duration'];
        _currentStaffId = classJson['staff'];

        final fetchedStudents = (classJson['students'] as List<dynamic>?)
                ?.map((s) => Student.fromJson(s, _validAttendanceEnums))
                .toList() ??
            [];

        _originalStatuses.clear();
        _pendingStatuses.clear();
        for (var student in fetchedStudents) {
          _originalStatuses[student.id] = student.status;
          _pendingStatuses[student.id] = student.status;
        }

        setState(() {
          _students = fetchedStudents;
        });

        return fetchedStudents;
      } else {
        String errorMessage = 'Failed to load class list.';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage += ' ${errorBody['message']}';
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage += ' ${errorBody['error']}';
          } else {
            errorMessage += ' Status: ${response.statusCode}.';
          }
        } catch (_) {
          errorMessage +=
              ' Status: ${response.statusCode}. Body (unparseable): ${response.body}.';
        }
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No Internet connection. Please check your network.');
    } on FormatException {
      throw Exception(
          'Received unexpected data format from server. (JSON parsing error)');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred during class fetching: ${e.toString()}');
    }
  }

  Future<void> _submitAllAttendance() async {
    if (_isSubmitting) return;

    final unselectedStudents = _pendingStatuses.entries
        .where((entry) => entry.value == Student.notSetStatus)
        .toList();

    if (unselectedStudents.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an attendance status for all students. ${unselectedStudents.length} students are "Not Set".',
            style: const TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentSubjectId == null ||
        _currentDurationId == null ||
        _currentStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Missing class details (subject, duration, or staff ID). Please try reloading the screen.',
            style: const TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final token = await _authController.getToken();
    final headers = {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final List<Map<String, dynamic>> studentsUpdateData =
        _students.map((student) {
      final newStatus = _pendingStatuses[student.id] ?? student.status;
      final tempStudent = Student(
        id: student.id,
        name: student.name,
        gender: student.gender,
        avatarUrl: student.avatarUrl,
        status: newStatus,
        attendance_score: student.attendance_score,
        class_practice: student.class_practice,
        home_work: student.home_work,
        assignment_score: student.assignment_score,
        presentation: student.presentation,
        revision_test: student.revision_test,
        final_exam_score: student.final_exam_score,
        total_score: student.total_score,
        work_book: student.work_book,
        note: student.note,
        comments: student.comments,
      );
      return tempStudent.toJson(_validAttendanceEnums);
    }).toList();

    final List<Map<String, dynamic>> studentsReportData =
        _students.map((student) {
      final newStatus = _pendingStatuses[student.id] ?? student.status;
      return {
        'student': student.id,
        'attendance': newStatus.toLowerCase(),
        'checking_at': DateTime.now().toIso8601String(),
        'note': student.note,
      };
    }).toList();

    final updateClassUrl =
        Uri.parse('http://188.166.242.109:5000/api/classes/${widget.classId}');
    final updateClassBody = jsonEncode({'students': studentsUpdateData});
    final createReportUrl =
        Uri.parse('http://188.166.242.109:5000/api/attendancereports');
    final createReportBody = jsonEncode({
      'class_id': widget.classId,
      'subject_id': _currentSubjectId,
      'duration': _currentDurationId,
      'staff_id': _currentStaffId,
      'students': studentsReportData,
    });

    try {
      final patchFuture =
          http.patch(updateClassUrl, headers: headers, body: updateClassBody);
      final postFuture =
          http.post(createReportUrl, headers: headers, body: createReportBody);
      final responses = await Future.wait([patchFuture, postFuture]);
      final patchResponse = responses[0];
      final postResponse = responses[1];

      bool allSucceeded = true;
      String errorMessage = '';

      if (patchResponse.statusCode != 200) {
        allSucceeded = false;
        errorMessage +=
            'Failed to update class: ${patchResponse.statusCode} - ${patchResponse.body}\n';
      }

      if (postResponse.statusCode != 201) {
        allSucceeded = false;
        errorMessage +=
            'Failed to create attendance report: ${postResponse.statusCode} - ${postResponse.body}\n';
      }

      if (mounted) {
        if (allSucceeded) {
          setState(() {
            _originalStatuses.addAll(_pendingStatuses);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All attendance changes submitted successfully!',
                  style: const TextStyle(fontFamily: _fontFamily)),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission completed with errors:\n$errorMessage',
                  style: const TextStyle(fontFamily: _fontFamily)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No Internet connection. Please check your network and retry submission.',
              style: const TextStyle(fontFamily: _fontFamily)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'An unexpected error occurred during attendance submission: ${e.toString()}',
              style: const TextStyle(fontFamily: _fontFamily)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF8FAFB);
  static const Color _cardBackground = Colors.white;
  static const Color _skeletonColor = Color(0xFFE0E0E0);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _skeletonHighlightColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: _primaryBlue,
    ));

    return Scaffold(
      backgroundColor: _lightBackground,
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text("Check Attendance",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 19,
                fontFamily: _fontFamily)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: CustomDrawer(
        onLogout: () {
          _authController.logout();
          Get.offAllNamed(AppRoutes.login);
        },
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingEnums
                ? _buildShimmerList()
                : _errorMessageEnums.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade400, size: 50),
                              const SizedBox(height: 10),
                              Text(
                                'Error loading attendance options: $_errorMessageEnums',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontFamily: _fontFamily),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _initializeData,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry",
                                    style: TextStyle(fontFamily: _fontFamily)),
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
                      )
                    : FutureBuilder<List<Student>>(
                        future: _studentListFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildShimmerList();
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade400, size: 50),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontFamily: _fontFamily),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _studentListFuture =
                                              _fetchFilteredClassStudents();
                                        });
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Retry",
                                          style: TextStyle(
                                              fontFamily: _fontFamily)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            final students = snapshot.data!;
                            if (students.isEmpty) {
                              return const Center(
                                  child: Text(
                                      "There are no students in this class.",
                                      style:
                                          TextStyle(fontFamily: _fontFamily)));
                            }
                            return _buildStudentListView(_students);
                          }
                          return const Center(
                              child: Text("No data available.",
                                  style: TextStyle(fontFamily: _fontFamily)));
                        },
                      ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _hasChanges && !_isSubmitting ? _submitAllAttendance : null,
        label: Text(
          _isSubmitting ? "Submitting..." : "Submit All Attendance",
          style: const TextStyle(fontFamily: _fontFamily, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          disabledBackgroundColor: _primaryBlue.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
        ),
      ),
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
                    '${widget.className}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: _fontFamily,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subject: ${widget.subjectName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _mediumText,
                      fontFamily: _fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'All Students: ${widget.studentsCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SvgPicture.asset(
              'assets/images/teacher_management/atd.svg',
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListView(List<Student> students) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentAttendanceCard(
          key: ValueKey(student.id),
          student: student,
          selectedStatus: _pendingStatuses[student.id]!,
          originalStatus: _originalStatuses[student.id]!,
          onStatusChanged: (newStatus) {
            _onStatusChanged(student.id, newStatus);
          },
          validAttendanceEnums: _validAttendanceEnums,
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: _skeletonColor,
      highlightColor: _skeletonHighlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildStudentSkeletonLoader(),
      ),
    );
  }

  Widget _buildStudentSkeletonLoader() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4))),
                  ])),
            ]),
            const SizedBox(height: 18),
            Container(
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)))
          ],
        ),
      ),
    );
  }
}

class _StudentAttendanceCard extends StatefulWidget {
  final Student student;
  final String selectedStatus;
  final String originalStatus;
  final ValueChanged<String> onStatusChanged;
  final List<String> validAttendanceEnums;

  const _StudentAttendanceCard({
    Key? key,
    required this.student,
    required this.selectedStatus,
    required this.originalStatus,
    required this.onStatusChanged,
    required this.validAttendanceEnums,
  }) : super(key: key);

  @override
  _StudentAttendanceCardState createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<_StudentAttendanceCard> {
  List<String> get attendanceOptions => widget.validAttendanceEnums;

  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightFillColor = Color(0xFFF4F7F9);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _greyBorder = Color(0xFFE0E6ED);
  static const Color _notSetColor = Color(0xFF95A5A6);
  static const Color _unrecognizedStatusColor = Color(0xFF8D6E63);
  static const String _fontFamily = AppFonts.fontFamily;

  Color getStatusColor(String status, {bool isBackground = false}) {
    final List<String> validEnums = widget.validAttendanceEnums;
    for (String validEnum in validEnums) {
      if (status.toLowerCase() == validEnum.toLowerCase()) {
        switch (validEnum) {
          case "Permission":
            return isBackground
                ? const Color(0xFFE7F0FE)
                : const Color(0xFF0D6EFD);
          case "Late":
            return isBackground
                ? const Color(0xFFFFF8E1)
                : const Color(0xFFFFC107);
          case "Absent":
            return isBackground
                ? const Color(0xFFFBE9EA)
                : const Color(0xFFDC3545);
          case "Present":
            return isBackground
                ? const Color(0xFFEAF6EB)
                : const Color(0xFF28A745);
        }
      }
    }
    if (status == Student.notSetStatus) {
      return isBackground ? const Color(0xFFF0F3F4) : _notSetColor;
    }
    return isBackground ? const Color(0xFFF5EFEA) : _unrecognizedStatusColor;
  }

  IconData getStatusIcon(String status) {
    final List<String> validEnums = widget.validAttendanceEnums;
    for (String validEnum in validEnums) {
      if (status.toLowerCase() == validEnum.toLowerCase()) {
        switch (validEnum) {
          case "Permission":
            return Icons.insert_drive_file_outlined;
          case "Late":
            return Icons.watch_later_outlined;
          case "Absent":
            return Icons.highlight_off_outlined;
          case "Present":
            return Icons.check_circle_outline;
        }
      }
    }
    if (status == Student.notSetStatus) {
      return Icons.info_outline;
    }
    return Icons.help_outline;
  }

  Widget buildStatusItem(String status) {
    return Row(children: [
      Icon(getStatusIcon(status), size: 20, color: getStatusColor(status)),
      const SizedBox(width: 10),
      Text(status,
          style: TextStyle(
              color: getStatusColor(status),
              fontWeight: FontWeight.w500,
              fontFamily: _fontFamily,
              fontSize: 15)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = widget.selectedStatus == widget.originalStatus &&
        widget.selectedStatus != Student.notSetStatus;
    bool hasPendingLocalChange = widget.selectedStatus != widget.originalStatus;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: hasPendingLocalChange
                ? _primaryBlue
                : getStatusColor(widget.selectedStatus),
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SuperProfilePicture(
                imageUrl: widget.student.avatarUrl,
                fullName: widget.student.name,
                radius: 26,
                backgroundColor: _lightFillColor,
                textColor: _darkText,
                fontFamily: _fontFamily,
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.student.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                            fontFamily: _fontFamily),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Gender: ${widget.student.gender}",
                        style: const TextStyle(
                            color: _mediumText,
                            fontSize: 13,
                            fontFamily: _fontFamily)),
                  ])),
            ]),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: getStatusColor(widget.selectedStatus,
                              isBackground: true),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: _greyBorder, width: 1),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            onTap: () {
                              _showPopupMenu(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 10.0),
                              child: Row(
                                children: [
                                  Icon(
                                    getStatusIcon(widget.selectedStatus),
                                    size: 20,
                                    color:
                                        getStatusColor(widget.selectedStatus),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.selectedStatus,
                                      style: TextStyle(
                                          fontFamily: _fontFamily,
                                          fontWeight: FontWeight.w600,
                                          color: getStatusColor(
                                              widget.selectedStatus)),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle,
                          color: getStatusColor(widget.selectedStatus),
                          size: 28),
                    ],
                    if (hasPendingLocalChange && !isDone) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.edit_note_rounded,
                          color: _primaryBlue, size: 28),
                    ]
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final String? result = await showMenu<String>(
      context: context,
      position: position,
      items: attendanceOptions.map((String option) {
        return PopupMenuItem<String>(
          value: option,
          child: buildStatusItem(option),
        );
      }).toList(),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _greyBorder),
      ),
    );

    if (result != null && result != widget.selectedStatus) {
      widget.onStatusChanged(result);
    }
  }
}
