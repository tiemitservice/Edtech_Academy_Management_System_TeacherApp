import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
// Note: You may need to adjust the import path for app_colors.dart
// import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';

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

class ClassService {
  final String _classesBaseUrl =
      'http://188.166.242.109:5000/api/classes';
  final String _subjectsBaseUrl =
      'http://188.166.242.109:5000/api/subjects';

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

  Future<List<TeacherClass>> fetchTeacherClasses(String teacherStaffId) async {
    try {
      final Map<String, String> subjectsMap = await _fetchSubjects();
      final response = await http.get(Uri.parse(_classesBaseUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> allClassesApi = jsonData['data'];

        return allClassesApi
            .map((classJson) {
              final String subjectId = classJson['subject'] as String? ?? '';
              final String subjectName =
                  subjectsMap[subjectId] ?? 'Unknown Subject';
              return TeacherClass.fromJson(
                  classJson as Map<String, dynamic>, subjectName);
            })
            .where((c) => c.staffId == teacherStaffId)
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

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

enum ScreenState { loading, success, error, empty }

class _ClassManagementScreenState extends State<ClassManagementScreen>
    with SingleTickerProviderStateMixin {
  // --- Dependencies & Services ---
  final AuthController _authController = Get.find<AuthController>();
  final NotificationController _notificationController =
      Get.put(NotificationController());
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
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        // **MODIFICATION**: Using the new, modern-styled badge
        ModernNotificationBadge(controller: _notificationController),
        const SizedBox(width: 8),
      ],
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
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: _mediumGreyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClassData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
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
              ),
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
              ),
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
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: accentColor,
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
                  const Icon(
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
                        color: _darkText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classData.subjectName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mediumGreyText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classData.studentIds.length} students',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _mediumGreyText),
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
              letterSpacing: 0.5),
        ),
      ),
    );
  }
}
// --- NOTIFICATION WIDGET (ANIMATING THE ENTIRE BELL ICON) ---

class ModernNotificationBadge extends StatefulWidget {
  final NotificationController controller;

  const ModernNotificationBadge({Key? key, required this.controller})
      : super(key: key);

  @override
  State<ModernNotificationBadge> createState() =>
      _ModernNotificationBadgeState();
}

class _ModernNotificationBadgeState extends State<ModernNotificationBadge>
    with SingleTickerProviderStateMixin {
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _badgeColor = Color(0xFFE74C3C);

  late final AnimationController _animationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: -0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.12, end: 0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
    ]).animate(_animationController);

    widget.controller.pendingPermissionCount.listen((count) {
      if (!mounted) return;
      if (count > 0) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    });

    if (widget.controller.pendingPermissionCount.value > 0) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // The AnimatedBuilder wraps everything that needs to animate.
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            alignment: Alignment.topCenter,
            child: child,
          );
        },
        // The child is the entire Stack.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // This IconButton contains the Icon, so it will be animated.
            IconButton(
              icon: Obx(() {
                return Icon(
                  widget.controller.pendingPermissionCount.value > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: _darkText,
                  size: 28,
                );
              }),
              onPressed: () {
                Get.toNamed(AppRoutes.studentPermission);
              },
            ),
            // The Positioned badge also gets animated as part of the Stack.
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 6.0,
              end: 4.0,
              child: Obx(() {
                if (widget.controller.pendingPermissionCount.value == 0) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.controller.formattedPendingCount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
