import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// External dependencies (assumed to be defined in your project elsewhere)
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

// Shimmer is a direct dependency for loading states
import 'package:shimmer/shimmer.dart';

// ======================================================================
// CONSTANTS & UTILITIES
// ======================================================================

// Unified AppColors for consistency
class AppColors {
  static const Color primaryBlue = Color(0xFF1469C7);
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color cardBackground = Colors.white;
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF7F8C8D);
  static const Color borderGrey = Color(0xFFE0E6ED);
  static const Color declineRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color pendingOrange = Color(0xFFF39C12);
  static const Color skeletonBaseColor = Color(0xFFE0E0E0);
  static const Color skeletonHighlightColor = Color(0xFFF0F0F0);
}

// Unified AppFonts for consistency
class AppFonts {
  static const String fontFamily = 'KantumruyPro'; // Ensure this font is correctly set up in pubspec.yaml
}

// Unified AppDurations for consistency
class AppDurations {
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration apiTimeout = Duration(seconds: 15); // Added a general API timeout
}

// Unified AppAssets for consistency
class AppAssets {
  static const String teacherCheckSvg = 'assets/images/onboarding/teacher_check.svg';
  static const String teacherReadSvg = 'assets/images/onboarding/teacher_read.svg';
  static const String emptyStateIllustration = 'assets/images/illustrations/empty_state.svg'; // Placeholder for a generic empty state SVG
  static const String networkErrorIllustration = 'assets/images/illustrations/network_error.svg'; // Placeholder for network error SVG
}

// Unified AppApi for consistency
class AppApi {
  static const String baseUrl = 'https://edtech-academy-management-system-server.onrender.com/api';
  static const String permissionsEndpoint = '$baseUrl/student_permissions';
  static const String studentsEndpoint = '$baseUrl/students';
  static const String classesEndpoint = '$baseUrl/classes';
  static const String subjectsEndpoint = '$baseUrl/subjects';
}

// ======================================================================
// DATA MODELS
// ======================================================================

/// Represents a Student's basic details.
class Student {
  final String id;
  final String name; // e.g., 'eng_name' from API
  final String gender;
  final String? avatarUrl;

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? '',
      name: json['eng_name'] as String? ?? 'Unknown Student',
      gender: json['gender'] as String? ?? 'N/A',
      avatarUrl: json['image'] as String?,
    );
  }
}

/// Represents a single student permission request.
class PermissionItem {
  final String id; // The _id of the permission request
  final String studentId; // ID of the student
  final String sentToStaffId; // ID of the teacher it was sent to ('sent_to' field)
  final String reason;
  final List<DateTime> holdDates; // Parsed dates for the permission period
  String status; // e.g., "pending", "approved", "denied" (from 'permissent_status')
  final DateTime createdAt;

  // UI-specific and reactive state:
  // This is where the RxBool is defined.
  final RxBool isExpanded; // Changed to 'final' as it's initialized in the constructor

  PermissionItem({
    required this.id,
    required this.studentId,
    required this.sentToStaffId,
    required this.reason,
    required this.holdDates,
    required this.status,
    required this.createdAt,
    this.studentDetails,
    RxBool? isExpanded, // Make it nullable in constructor for copyWith
  }) : this.isExpanded = isExpanded ?? false.obs; // Initialize if null

  Student? studentDetails; // To hold the fetched Student object


  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> holdDateStrings = json['hold_date'] as List<dynamic>? ?? [];
    final List<DateTime> parsedHoldDates = holdDateStrings
        .map((dateStr) => DateTime.tryParse(dateStr.toString()))
        .where((date) => date != null)
        .toList()
        .cast<DateTime>();

    return PermissionItem(
      id: json['_id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      sentToStaffId: json['sent_to'] as String? ?? '',
      reason: json['reason'] as String? ?? 'No reason provided',
      holdDates: parsedHoldDates,
      status: json['permissent_status'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      // When creating from JSON, it's typically not expanded by default
      isExpanded: false.obs,
    );
  }

  // Helper getter to format status for display (e.g., "pending" -> "Pending")
  String get formattedStatus {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Helper getter to format the date range for display
  String get formattedDateRange {
    if (holdDates.isEmpty) return 'N/A';
    // Sort dates to ensure start and end are correct if the API doesn't guarantee order
    final sortedDates = List<DateTime>.from(holdDates)..sort();

    final startDate = sortedDates.first;
    final endDate = sortedDates.length > 1 ? sortedDates.last : sortedDates.first;

    final dateFormat = DateFormat('EEE, dd/MM/yyyy');

    if (startDate.isAtSameMomentAs(endDate)) {
      return dateFormat.format(startDate);
    } else {
      return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }
  }

  // copyWith method for immutable updates of PermissionItem instances
  PermissionItem copyWith({
    String? status,
    Student? studentDetails,
    bool? isExpandedValue, // <--- CHANGE: Accept a boolean value here
  }) {
    return PermissionItem(
      id: id,
      studentId: studentId,
      sentToStaffId: sentToStaffId,
      reason: reason,
      holdDates: holdDates,
      status: status ?? this.status,
      createdAt: createdAt,
      studentDetails: studentDetails ?? this.studentDetails,
      // <--- CHANGE: Create a new RxBool instance based on the provided value
      isExpanded: RxBool(isExpandedValue ?? this.isExpanded.value),
    );
  }
}

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
  factory TeacherClass.fromJson(Map<String, dynamic> json, String resolvedSubjectName) {
    final List<dynamic> studentsRaw = json['students'] as List<dynamic>? ?? [];
    // Ensure that 'student' and '_id' exist before accessing
    final List<String> studentIds = studentsRaw
        .map((s) => (s as Map<String, dynamic>)['student']?['_id']?.toString())
        .whereType<String>() // Filters out nulls
        .toList();

    final List<dynamic> daysRaw = json['day_class'] as List<dynamic>? ?? [];
    final List<String> classDays = daysRaw.map((day) => day.toString()).toList();

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
// SERVICE LAYER
// ======================================================================

class ClassService {
  final http.Client _httpClient;

  ClassService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Fetches all subjects and returns them as a map for easy lookup.
  Future<Map<String, String>> _fetchSubjects() async {
    try {
      final response = await _httpClient.get(Uri.parse(AppApi.subjectsEndpoint)).timeout(AppDurations.apiTimeout);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> subjectsApi = jsonData['data'];
        return {
          for (var subjectJson in subjectsApi)
            subjectJson['_id'].toString(): subjectJson['name'].toString()
        };
      } else {
        throw http.ClientException(
            'Failed to load subjects (Status code: ${response.statusCode})');
      }
    } on TimeoutException {
      throw http.ClientException('Subjects API request timed out.');
    } catch (e) {
      throw http.ClientException('An error occurred while fetching subjects: $e');
    }
  }

  /// Fetches and filters classes for a specific teacher by staff ID.
  Future<List<TeacherClass>> fetchTeacherClasses(String teacherStaffId) async {
    try {
      final Map<String, String> subjectsMap = await _fetchSubjects(); // Fetch subjects first

      final response = await _httpClient.get(Uri.parse(AppApi.classesEndpoint)).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> allClassesApi = jsonData['data'];

        return allClassesApi
            .map((classJson) {
              final String subjectId = classJson['subject'] as String? ?? '';
              final String subjectName = subjectsMap[subjectId] ?? 'Unknown Subject'; // Resolve subject name
              return TeacherClass.fromJson(classJson as Map<String, dynamic>, subjectName);
            })
            .where((c) => c.staffId == teacherStaffId) // Filter by staffId
            .toList();
      } else {
        throw http.ClientException(
            'Failed to load classes (Status code: ${response.statusCode})');
      }
    } on TimeoutException {
      throw http.ClientException('Classes API request timed out.');
    } on http.ClientException catch (e) {
      throw e; // Re-throw client exceptions directly
    } catch (e) {
      throw http.ClientException('An unexpected error occurred while fetching classes: $e');
    }
  }
}

// ======================================================================
// STUDENT PERMISSION CONTROLLER (GetX Controller)
// ======================================================================

/// Manages state and logic for fetching and updating student permission requests.
class StudentPermissionController extends GetxController {
  // Reactive state variables that trigger UI updates
  final RxList<PermissionItem> studentPermissions = <PermissionItem>[].obs;
  final RxBool isLoadingPermissions = true.obs; // Separate loading state for permissions
  final RxString permissionErrorMessage = ''.obs; // Stores error messages from API calls

  // Cache for student details to avoid redundant API calls for the same student
  final RxMap<String, Student> studentDetailsMap = <String, Student>{}.obs;

  late final AuthController _authController; // Dependency for authenticated user's ID
  final http.Client _httpClient;

  StudentPermissionController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>(); // AuthController must be initialized globally
    fetchStudentPermissions(); // Fetch data when the controller is initialized
  }

  /// Fetches student permission requests for the authenticated teacher.
  /// It also fetches and caches student details required for displaying names/avatars.
  Future<void> fetchStudentPermissions() async {
    isLoadingPermissions.value = true; // Activate loading indicator
    permissionErrorMessage.value = ''; // Clear any previous errors
    studentPermissions.clear(); // Clear existing list items

    try {
      final String staffId = await _authController.getUserId(); // Use getUserId() for staff ID
      if (staffId.isEmpty) {
        throw Exception("Staff ID not found. Please log in again.");
      }

      // 1. Fetch all student permission requests sent to this teacher
      final permissionsResponse = await _httpClient
          .get(Uri.parse('${AppApi.permissionsEndpoint}?sent_to=$staffId'))
          .timeout(AppDurations.apiTimeout);

      if (permissionsResponse.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(permissionsResponse.body);
        final List<dynamic> permissionsJson = decodedData['data'] ?? [];

        // Collect all unique student IDs from the fetched permissions
        final Set<String> uniqueStudentIds = permissionsJson
            .map((p) => (p['studentId'] as String? ?? '')) // Safely cast and handle null
            .where((id) => id.isNotEmpty)
            .toSet();

        // 2. Fetch details for all unique students involved in these permissions and cache them
        await _fetchStudentDetailsForPermissions(uniqueStudentIds.toList());

        // 3. Process each raw permission JSON into a PermissionItem object
        // and attach the corresponding student details from the cache.
        final List<PermissionItem> fetchedPermissions = permissionsJson.map((pJson) {
          final permission = PermissionItem.fromJson(pJson);
          permission.studentDetails = studentDetailsMap[permission.studentId]; // Attach student details
          return permission;
        }).toList();

        studentPermissions.assignAll(fetchedPermissions); // Update the reactive list, triggering UI rebuild
      } else {
        throw http.ClientException(
            "Failed to load permissions: Server responded with status ${permissionsResponse.statusCode}.");
      }
    } on TimeoutException {
      permissionErrorMessage.value = "Permissions API request timed out. Please try again.";
      _showSnackbar('Network Error', 'Permissions data could not be loaded due to a timeout.', isSuccess: false);
    } on http.ClientException catch (e) {
      permissionErrorMessage.value = "Network Error: ${e.message}";
      _showSnackbar('Network Error', 'Could not connect to the server. Please check your internet connection.', isSuccess: false);
    } catch (e) {
      permissionErrorMessage.value = "An unexpected error occurred: ${e.toString()}";
      _showSnackbar('Error', 'An unexpected error occurred while fetching permissions.', isSuccess: false);
      debugPrint("Error fetching student permissions: $e"); // Use debugPrint for logging
    } finally {
      isLoadingPermissions.value = false; // Deactivate loading indicator
    }
  }

  /// Fetches details for a list of student IDs and populates the `studentDetailsMap` cache.
  Future<void> _fetchStudentDetailsForPermissions(List<String> studentIds) async {
    if (studentIds.isEmpty) return;

    try {
      final response = await _httpClient.get(Uri.parse(AppApi.studentsEndpoint)).timeout(AppDurations.apiTimeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> studentsJson = decodedData['data'] ?? [];

        studentDetailsMap.clear(); // Clear existing cache
        for (var sJson in studentsJson) {
          final student = Student.fromJson(sJson);
          studentDetailsMap[student.id] = student; // Cache student by ID
        }
      } else {
        debugPrint("Warning: Failed to fetch student details: Status ${response.statusCode}");
      }
    } on TimeoutException {
      debugPrint("Warning: Student details API request timed out.");
    } catch (e) {
      debugPrint("Warning: Error fetching student details: $e");
    }
  }

  /// Updates the status of a specific student permission request via a PATCH API call.
  /// After successful update, it refreshes the UI.
  Future<void> updatePermissionStatus(String permissionId, String newStatus) async {
    // Show a loading indicator during update or block UI
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      barrierDismissible: false,
    );

    try {
      final response = await _httpClient.patch(
        Uri.parse('${AppApi.permissionsEndpoint}/$permissionId'), // Target specific permission
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'permissent_status': newStatus.toLowerCase()}), // Send the new status
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        // Find the index of the permission in the list
        final index = studentPermissions.indexWhere((p) => p.id == permissionId);
        if (index != -1) {
          // Create a new PermissionItem instance with updated status and replace it
          final updatedPermission = studentPermissions[index].copyWith(
            status: newStatus.toLowerCase(),
            isExpandedValue: false, // Collapse the card after action
          );
          studentPermissions[index] = updatedPermission;
          // studentPermissions.refresh(); // Removed: Not strictly needed if item itself is replaced.
                                        // Keeping it if GetX sometimes misses the update.
                                        // You can test without it.
        }

        _showSnackbar('Success', 'Permission status updated to ${newStatus.capitalizeFirst!}.', isSuccess: true);
      } else {
        final errorBody = jsonDecode(response.body);
        final msg = errorBody['message'] ?? 'Failed to update status.';
        _showSnackbar('Error', 'Failed to update permission: $msg', isSuccess: false);
      }
    } on TimeoutException {
      _showSnackbar('Network Error', 'Updating permission timed out. Please try again.', isSuccess: false);
    } on http.ClientException catch (e) {
      _showSnackbar('Network Error', 'Could not connect to update status: ${e.message}', isSuccess: false);
    } catch (e) {
      _showSnackbar('Error', 'An unexpected error occurred: ${e.toString()}', isSuccess: false);
      debugPrint("Error updating permission status: $e"); // Debugging
    } finally {
      Get.back(); // Dismiss the loading dialog
    }
  }

  /// Displays a GetX snackbar for notifications (success or error).
  void _showSnackbar(String title, String message, {bool isSuccess = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? AppColors.successGreen : AppColors.declineRed,
      colorText: Colors.white,
      messageText: Text(message, style: const TextStyle(fontFamily: AppFonts.fontFamily, color: Colors.white)),
      titleText: Text(title, style: const TextStyle(fontFamily: AppFonts.fontFamily, color: Colors.white, fontWeight: FontWeight.bold)),
      duration: AppDurations.snackbarDuration,
    );
  }
}

// ======================================================================
// UI SCREEN: ClassManagementScreen
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
  final StudentPermissionController _permissionController = Get.find<StudentPermissionController>();

  // --- State Management ---
  ScreenState _currentState = ScreenState.loading;
  late TabController _tabController;
  List<TeacherClass> _allClasses = [];
  List<TeacherClass> _todayClasses = [];
  String _errorMessage = '';

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
      final teacherStaffId = await _authController.getUserId();
      if (teacherStaffId.isEmpty) {
        throw Exception("Teacher Staff ID not found. Please ensure you are logged in and staff data is available.");
      }

      final fetchedClasses = await _classService.fetchTeacherClasses(teacherStaffId);

      if (!mounted) return;

      if (fetchedClasses.isEmpty) {
        setState(() => _currentState = ScreenState.empty);
      } else {
        _allClasses = fetchedClasses;
        _filterTodayClasses();
        setState(() => _currentState = ScreenState.success);
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _currentState = ScreenState.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _currentState = ScreenState.error;
      });
      debugPrint("Error loading class data: $e");
    }
  }

  /// Filters the list of all classes to find which ones are scheduled for today.
  void _filterTodayClasses() {
    final String today = DateFormat('EEEE', 'en_US').format(DateTime.now());
    _todayClasses = _allClasses.where((classItem) {
      return classItem.classDays.any((day) => day.toLowerCase() == today.toLowerCase());
    }).toList();
  }

  /// Handles tapping the notification button.
  void _onNotificationPressed() {
    Get.toNamed(AppRoutes.studentPermission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeaderInfo(),
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  // --- BUILDER METHODS: MAIN LAYOUT ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: AppColors.borderGrey,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkText, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'My Classes',
        style: TextStyle(
          color: AppColors.darkText,
          fontFamily: AppFonts.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Obx(() {
              // Calculate pending permissions dynamically
              final pendingCount = _permissionController.studentPermissions
                  .where((p) => p.status.toLowerCase() == 'pending')
                  .length;
              return Badge(
                label: pendingCount > 0 ? Text(pendingCount.toString()) : null,
                isLabelVisible: pendingCount > 0,
                backgroundColor: AppColors.pendingOrange, // Consistent pending color
                child: const Icon(Icons.notifications_none_rounded),
              );
            }),
            color: AppColors.darkText,
            iconSize: 24,
            onPressed: _onNotificationPressed,
          ),
        ),
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
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.mediumText,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3.0,
            labelStyle: const TextStyle(
                fontFamily: AppFonts.fontFamily,
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

  Widget _buildClassGrid({required List<TeacherClass> classes, required bool isTodayTab}) {
    if (classes.isEmpty) {
      return _buildEmptyState(
        message: isTodayTab
            ? "You have no classes scheduled for today."
            : "You are not assigned to any classes.",
        assetPath: AppAssets.emptyStateIllustration, // Generic empty state SVG
        title: isTodayTab ? 'No Classes Today' : 'No Classes Assigned',
        showDescription: false, // Don't show generic description if specific message is provided
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
      physics: const NeverScrollableScrollPhysics(), // Prevent scrolling while loading
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Display 6 skeleton cards
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppColors.skeletonBaseColor,
        highlightColor: AppColors.skeletonHighlightColor,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          // You can add more complex skeleton shapes inside if needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 40, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Container(width: 100, height: 16, color: Colors.grey[300]),
              const SizedBox(height: 4),
              Container(width: 80, height: 14, color: Colors.grey[300]),
              const SizedBox(height: 4),
              Container(width: 70, height: 14, color: Colors.grey[300]),
            ],
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
            SvgPicture.asset(AppAssets.networkErrorIllustration, height: 150), // Use a specific error SVG
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Classes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  fontFamily: AppFonts.fontFamily),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mediumText,
                  fontFamily: AppFonts.fontFamily),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClassData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry', style: TextStyle(fontFamily: AppFonts.fontFamily)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message, String? assetPath, String? title, bool showDescription = true}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              assetPath ?? AppAssets.teacherReadSvg, // Default to teacherReadSvg or custom
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              title ?? 'No Classes Found',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  fontFamily: AppFonts.fontFamily),
              textAlign: TextAlign.center,
            ),
            if (showDescription) ...[
              const SizedBox(height: 8),
              Text(
                message ?? 'It looks like you haven\'t been assigned to any classes yet.',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mediumText,
                    fontFamily: AppFonts.fontFamily),
                textAlign: TextAlign.center,
              ),
            ],
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
            AppColors.primaryBlue,
          ),
          SvgPicture.asset(
            AppAssets.teacherReadSvg, // This SVG should be appropriate for header
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
          _buildClassCounter(
            'My Schedule',
            isLoading ? '-' : _todayClasses.length.toString(),
            AppColors.successGreen,
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
            color: AppColors.mediumText,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: accentColor,
            fontFamily: AppFonts.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard({required TeacherClass classData, required bool isScheduledToday}) {
    final cardBorderColor = isScheduledToday ? AppColors.successGreen : AppColors.borderGrey;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.teacherManagement,
          arguments: {
            'classId': classData.id,
            'className': classData.name,
            'studentsCount': classData.studentIds.length, // Pass int directly
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
                    color: AppColors.primaryBlue,
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
                      color: AppColors.darkText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classData.subjectName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classData.studentIds.length} students',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mediumText,
                      fontFamily: AppFonts.fontFamily,
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
          color: AppColors.successGreen,
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
            fontFamily: AppFonts.fontFamily,
          ),
        ),
      ),
    );
  }
}