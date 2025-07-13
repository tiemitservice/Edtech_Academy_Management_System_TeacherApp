import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

// ======================================================================
// 1. DATA MODELS
// ======================================================================

/// Represents a single class taught by a teacher.
class TeacherClass {
  final String id;
  final String name;
  final String subjectId;
  final String subjectName;
  final List<String> studentIds;
  final List<String> classDays;
  final String staffId;

  TeacherClass({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subjectName,
    required this.studentIds,
    required this.classDays,
    required this.staffId,
  });

  /// Creates a TeacherClass instance from a JSON map.
  factory TeacherClass.fromJson(
      Map<String, dynamic> json, String resolvedSubjectName) {
    final List<dynamic> studentsRaw = json['students'] as List<dynamic>? ?? [];
    final List<String> studentIds = studentsRaw
        .map((s) => (s as Map<String, dynamic>)['student']['_id'].toString())
        .toList();

    final List<dynamic> daysRaw = json['day_class'] as List<dynamic>? ?? [];
    final List<String> classDays =
        daysRaw.map((day) => day.toString()).toList();

    return TeacherClass(
      id: json['_id'] as String? ?? 'Unknown ID',
      name: json['name'] as String? ?? 'Unnamed Class',
      subjectId: json['subject'] as String? ?? '',
      subjectName: resolvedSubjectName,
      studentIds: studentIds,
      classDays: classDays,
      staffId: json['staff'] as String? ?? '',
    );
  }
}

/// Represents a Subject.
class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['_id'] as String,
      name: json['name'] as String,
    );
  }
}

// ======================================================================
// 2. SERVICE LAYER
// ======================================================================

class ClassService {
  final String _classesBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/classes';
  final String _subjectsBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/subjects';

  /// Fetches all subjects and returns them as a map for easy lookup.
  Future<Map<String, String>> _fetchSubjects() async {
    try {
      final response = await http.get(Uri.parse(_subjectsBaseUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> subjectsApi = jsonData['data'];
        return {
          for (var subjectJson in subjectsApi)
            subjectJson['_id'].toString(): subjectJson['name'].toString()
        };
      } else {
        throw Exception(
            'Failed to load subjects (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching subjects: $e');
    }
  }

  /// Fetches and filters classes for a specific teacher by staff ID.
  Future<List<TeacherClass>> fetchTeacherClasses(String teacherStaffId) async {
    try {
      final Map<String, String> subjectsMap =
          await _fetchSubjects(); // Fetch subjects first

      final response = await http.get(Uri.parse(_classesBaseUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> allClassesApi = jsonData['data'];

        return allClassesApi
            .map((classJson) {
              final String subjectId = classJson['subject'] as String? ?? '';
              final String subjectName = subjectsMap[subjectId] ??
                  'Unknown Subject'; // Resolve subject name
              return TeacherClass.fromJson(
                  classJson as Map<String, dynamic>, subjectName);
            })
            .where((c) => c.staffId == teacherStaffId) // Filter by staffId
            .toList();
      } else {
        throw Exception(
            'Failed to load classes (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching classes: $e');
    }
  }
}

// ======================================================================
// 3. UI SCREEN
// ======================================================================

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

/// Enum to represent the current state of the screen.
enum ScreenState { loading, success, error, empty }

class _ClassManagementScreenState extends State<ClassManagementScreen>
    with SingleTickerProviderStateMixin {
  // --- Dependencies & Services ---
  final AuthController _authController = Get.find<AuthController>();
  final ClassService _classService = ClassService();

  // --- State Management ---
  ScreenState _currentState = ScreenState.loading;
  late TabController _tabController;
  List<TeacherClass> _allClasses = [];
  List<TeacherClass> _todayClasses = [];
  String _errorMessage = '';

  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightGreyBackground = Color(0xFFF8FAFB);
  static const Color _mediumGreyText = Color(0xFF7F8C8D);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _borderColor = Color(0xFFE0E6ED);
  static const Color _successGreen = Color(0xFF28A745);
  static const Color _errorRed = Color(0xFFE74C3C);
  static final Color _skeletonBaseColor = Colors.grey.shade200;
  static final Color _skeletonHighlightColor = Colors.grey.shade100;

  // --- Font Family Constant ---
  static const String _fontFamily = 'NotoSerifKhmer';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Main data loading and processing function.
  Future<void> _loadClassData() async {
    if (!mounted) return;
    setState(() => _currentState = ScreenState.loading);

    try {
      final teacherStaffId = await _authController.getStaffId();
      if (teacherStaffId.isEmpty) {
        throw Exception(
            "Teacher Staff ID not found. Please ensure you are logged in and staff data is available.");
      }

      final fetchedClasses =
          await _classService.fetchTeacherClasses(teacherStaffId);

      if (!mounted) return;

      if (fetchedClasses.isEmpty) {
        setState(() => _currentState = ScreenState.empty);
      } else {
        _allClasses = fetchedClasses;
        _filterTodayClasses();
        setState(() => _currentState = ScreenState.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _currentState = ScreenState.error;
      });
    }
  }

  /// Filters the list of all classes to find which ones are scheduled for today.
  void _filterTodayClasses() {
    final String today = DateFormat('EEEE', 'en_US').format(DateTime.now());
    _todayClasses = _allClasses.where((classItem) {
      return classItem.classDays
          .any((day) => day.toLowerCase() == today.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreyBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // --- BUILDER METHODS: MAIN LAYOUT ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: _borderColor,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _darkText, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'My Classes',
        style: TextStyle(
          color: _darkText,
          fontFamily: _fontFamily, // Apply NotoSerifKhmer
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeaderInfo(),
        Expanded(child: _buildBodyContent()),
      ],
    );
  }

  Widget _buildBodyContent() {
    switch (_currentState) {
      case ScreenState.loading:
        return _buildLoadingSkeleton();
      case ScreenState.error:
        return _buildErrorState();
      case ScreenState.empty:
        return _buildEmptyState();
      case ScreenState.success:
        return _buildSuccessState();
    }
  }

  // --- BUILDER METHODS: UI STATES ---

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _primaryBlue,
            unselectedLabelColor: _mediumGreyText,
            indicatorColor: _primaryBlue,
            indicatorWeight: 3.0,
            labelStyle: const TextStyle(
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                fontWeight: FontWeight.w600,
                fontSize: 15),
            tabs: const [
              Tab(text: 'All Classes'),
              Tab(text: "Schedule's Classes"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClassGrid(classes: _allClasses, isTodayTab: false),
              _buildClassGrid(classes: _todayClasses, isTodayTab: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassGrid(
      {required List<TeacherClass> classes, required bool isTodayTab}) {
    if (classes.isEmpty) {
      return _buildEmptyState(
        message: isTodayTab
            ? "You have no classes scheduled for today."
            : "You are not assigned to any classes.",
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classData = classes[index];
        final isScheduledToday = _todayClasses.any((c) => c.id == classData.id);
        return _buildClassCard(
          classData: classData,
          isScheduledToday: isScheduledToday,
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    // Shimmer effect doesn't render actual text, so no direct font change needed here.
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: _skeletonBaseColor,
        highlightColor: _skeletonHighlightColor,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _errorRed, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Classes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                  fontSize: 14,
                  color: _mediumGreyText,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClassData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry',
                  style: TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/onboarding/teacher_read.svg',
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'No Classes Found',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message == null
                  ? 'It looks like you haven\'t been assigned to any classes yet.'
                  : '',
              style: const TextStyle(
                  fontSize: 14,
                  color: _mediumGreyText,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILDER METHODS: WIDGET COMPONENTS ---

  Widget _buildHeaderInfo() {
    final bool isLoading = _currentState == ScreenState.loading;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildClassCounter(
            'All Classes',
            isLoading ? '-' : _allClasses.length.toString(),
            _primaryBlue,
          ),
          SvgPicture.asset(
            'assets/images/onboarding/teacher_read.svg',
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
          _buildClassCounter(
            'My Schedule',
            isLoading ? '-' : _todayClasses.length.toString(),
            _successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCounter(String title, String count, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: _mediumGreyText,
            fontWeight: FontWeight.w500,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: accentColor,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(
      {required TeacherClass classData, required bool isScheduledToday}) {
    final cardBorderColor = isScheduledToday ? _successGreen : _borderColor;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.teacherManagement,
          arguments: {
            'classId': classData.id,
            'className': classData.name,
            'studentsCount': classData.studentIds.length.toString(),
            'subjectName': classData.subjectName,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: _primaryBlue,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    classData.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classData.subjectName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _mediumGreyText,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classData.studentIds.length} students',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _mediumGreyText,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                ],
              ),
            ),
            if (isScheduledToday) _buildTodayBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBanner() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: _successGreen,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: const Text(
          'SCHEDULE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
          ),
        ),
      ),
    );
  }
}