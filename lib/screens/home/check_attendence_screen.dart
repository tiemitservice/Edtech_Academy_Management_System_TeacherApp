import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Import the SuperProfilePicture widget
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:shimmer/shimmer.dart';

// --- DATA MODELS ---

class Student {
  final String id;
  String name;
  String gender;
  String? avatarUrl;
  String status;
  bool isSaved;
  final double? quiz_score;
  final double? midterm_score;
  final double? final_score;

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
    this.status = "",
    this.isSaved = false,
    this.quiz_score,
    this.midterm_score,
    this.final_score,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    String formatStatus(String? statusStr) {
      if (statusStr == null || statusStr.isEmpty) return "";
      return statusStr[0].toUpperCase() + statusStr.substring(1);
    }

    return Student(
      id: json['_id'] ?? '',
      name: json['eng_name'] ?? 'Unknown Name',
      gender: json['gender'] ?? 'N/A',
      avatarUrl: json['image'],
      status: formatStatus(json['attendence_enum']),
      isSaved: json['attendence_enum'] != null,
      quiz_score: (json['quiz_score'] ?? 0).toDouble(),
      midterm_score: (json['midterm_score'] ?? 0).toDouble(),
      final_score: (json['final_score'] ?? 0).toDouble(),
    );
  }
}

// --- MAIN WIDGET ---

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
  late Future<List<Student>> _studentListFuture;
  final AuthController _authController = Get.find<AuthController>();
  final Map<String, String> _originalStatuses = {};

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  @override
  void initState() {
    super.initState();
    _studentListFuture = _fetchFilteredClassStudents();
  }

  Future<List<Student>> _fetchFilteredClassStudents() async {
    final uri = Uri.parse(
        'https://edtech-academy-management-system-server.onrender.com/api/classes');
    final staffId = await _authController.getStaffId();

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        final List<dynamic> allClassData = decodedBody['data'];
        final classJson = allClassData.firstWhere(
          (c) => c['_id'] == widget.classId && c['staff'] == staffId,
          orElse: () =>
              throw Exception('Class not found or you do not have permission.'),
        );
        final students = (classJson['students'] as List<dynamic>?)
                ?.map((s) => Student.fromJson(s['student']))
                .toList() ??
            [];

        _originalStatuses.clear();
        for (var student in students) {
          _originalStatuses[student.id] = student.status;
        }
        return students;
      } else {
        throw Exception(
            'Failed to load class list: Status ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No Internet connection. Please check your network.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveAttendanceUpdate(Student student) async {
    final url = Uri.parse(
        'https://edtech-academy-management-system-server.onrender.com/api/classes/${widget.classId}');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      'attendence_enum': student.status.toLowerCase(),
      'attendence_date': DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.patch(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            student.isSaved = true;
            _originalStatuses[student.id] = student.status;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance for ${student.name} saved!',
                  style: const TextStyle(fontFamily: _fontFamily)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save attendance for ${student.name}: Status ${response.statusCode} - ${response.body}',
                style: const TextStyle(fontFamily: _fontFamily)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Network error saving attendance for ${student.name}: $e',
              style: const TextStyle(fontFamily: _fontFamily)),
          backgroundColor: Colors.red,
        ),
      );
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
                fontFamily: _fontFamily)), // Apply NotoSerifKhmer
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Student>>(
              future: _studentListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                                fontFamily:
                                    _fontFamily), // Apply NotoSerifKhmer
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
                if (snapshot.hasData) {
                  final students = snapshot.data!;
                  if (students.isEmpty) {
                    return const Center(
                        child: Text("There are no students in this class.",
                            style: TextStyle(
                                fontFamily:
                                    _fontFamily))); // Apply NotoSerifKhmer
                  }
                  return _buildStudentListView(students);
                }
                return const Center(
                    child: Text("No data available.",
                        style: TextStyle(
                            fontFamily: _fontFamily))); // Apply NotoSerifKhmer
              },
            ),
          ),
        ],
      ),
    );
  }

  // REVISED _buildHeader() to match TeacherManagementScreen style
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the top
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Left-align all text
                children: [
                  Text(
                    '${widget.className}',
                    style: const TextStyle(
                      fontSize: 16, // Larger, more prominent class name
                      fontWeight: FontWeight.bold, // Extra bold for class name
                      color: Colors.black,
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
              'assets/images/teacher_management/atd.svg',
              height: 100, // Fixed height for a distinct visual element
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
        return _StudentAttendanceCard(
          key: ValueKey(students[index].id),
          student: students[index],
          originalStatus: _originalStatuses[students[index].id] ?? '',
          onSave: (updatedStudent) {
            _saveAttendanceUpdate(updatedStudent);
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    // Shimmer itself doesn't render actual text, so no direct font change needed here.
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
    // Shimmer effect doesn't render actual text
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
        ));
  }
}

// --- STUDENT ATTENDANCE CARD WIDGET ---

class _StudentAttendanceCard extends StatefulWidget {
  final Student student;
  final String originalStatus;
  final Function(Student) onSave;

  const _StudentAttendanceCard(
      {Key? key,
      required this.student,
      required this.originalStatus,
      required this.onSave})
      : super(key: key);

  @override
  _StudentAttendanceCardState createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<_StudentAttendanceCard> {
  late String _selectedStatus;

  final List<String> attendanceOptions = [
    "Present",
    "Late",
    "Permission",
    "Absence"
  ];

  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightFillColor = Color(0xFFF4F7F9);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _greyBorder = Color(0xFFE0E6ED);

  // --- Font Family Constant ---
  static const String _fontFamily = 'NotoSerifKhmer';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.student.status;
  }

  @override
  void didUpdateWidget(covariant _StudentAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.status != oldWidget.student.status) {
      setState(() {
        _selectedStatus = widget.student.status;
      });
    }
  }

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

  Widget buildStatusItem(String status) {
    return Row(children: [
      Icon(getStatusIcon(status), size: 20, color: getStatusColor(status)),
      const SizedBox(width: 10),
      Text(status,
          style: TextStyle(
              color: getStatusColor(status),
              fontWeight: FontWeight.w500,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
              fontSize: 15)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    bool hasChanged = _selectedStatus != widget.originalStatus;
    bool isButtonEnabled = _selectedStatus.isNotEmpty && hasChanged;
    bool isDone = widget.student.isSaved && !hasChanged;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: getStatusColor(_selectedStatus),
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
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
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
                            fontFamily: _fontFamily), // Apply NotoSerifKhmer
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Gender: ${widget.student.gender}",
                        style: const TextStyle(
                            color: _mediumText,
                            fontSize: 13,
                            fontFamily: _fontFamily)), // Apply NotoSerifKhmer
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
                          color: getStatusColor(_selectedStatus,
                              isBackground: true),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                              color: _greyBorder, width: 1), // Added border
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
                                    getStatusIcon(_selectedStatus),
                                    size: 20,
                                    color: getStatusColor(_selectedStatus),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedStatus.isNotEmpty
                                          ? _selectedStatus
                                          : "Select Status",
                                      style: TextStyle(
                                          fontFamily:
                                              _fontFamily, // Apply NotoSerifKhmer
                                          fontWeight: FontWeight.w600,
                                          color: _selectedStatus.isNotEmpty
                                              ? getStatusColor(_selectedStatus)
                                              : _mediumText),
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
                    if (isButtonEnabled) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final updatedStudent = widget.student
                            ..status = _selectedStatus;
                          widget.onSave(updatedStudent);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Save",
                            style: TextStyle(
                                fontFamily:
                                    _fontFamily)), // Apply NotoSerifKhmer
                      ),
                    ],
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getStatusColor(_selectedStatus),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          disabledBackgroundColor:
                              getStatusColor(_selectedStatus),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: const Icon(Icons.check, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Helper method to show the PopupMenuButton
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
          child:
              buildStatusItem(option), // buildStatusItem already applies font
        );
      }).toList(),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _greyBorder),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStatus = result;
      });
    }
  }
}
