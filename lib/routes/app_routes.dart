// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/bindings/student_info_binding.dart';
import 'package:school_management_system_teacher_app/screens/home/check_attendence_screen.dart';
import 'package:school_management_system_teacher_app/onboarding/onboarding_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/forgot_password_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/login_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/class_management_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/edit_profile_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/home_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/my_permission_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/profile_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_list_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_permissions_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_score_input_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_scores_list_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/teacher_management_screen.dart';
import 'package:school_management_system_teacher_app/screens/settings_screen.dart';
import 'package:school_management_system_teacher_app/screens/splash_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_info_screen.dart';
import 'package:school_management_system_teacher_app/controllers/student_list_controller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String notifications = '/notifications';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String classManagement = '/class-management';
  static const String checkAttendance = '/check-attendance';
  static const String teacherManagement = '/teacher-management';
  static const String studentScoreInput = '/student-score-input';
  static const String studentScoresList = '/student-scores-list';
  static const String studentPermission = '/student-permission';
  static const String myPermission = '/my-permission';
  static const String studentList = '/student-list';
  static const String studentInfo = '/student-info';
  static const String settings = '/settings';

  static final List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => SignInScreen()),
    GetPage(
        name: forgotPassword,
        page: () => const ForgotPasswordScreen(email: '')),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: editProfile, page: () => const EditProfileScreen()),
    GetPage(name: classManagement, page: () => const ClassManagementScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(
      name: checkAttendance,
      page: () => CheckAttendanceScreen(
        classId: Get.arguments['classId'],
        className: Get.arguments['className'],
        studentsCount: Get.arguments['studentsCount'],
        subjectName: Get.arguments['subjectName'],
      ),
    ),
    GetPage(
      name: teacherManagement,
      page: () => TeacherManagementScreen(
        classId: Get.arguments['classId'],
        className: Get.arguments['className'],
        studentsCount: Get.arguments['studentsCount'],
        subjectName: Get.arguments['subjectName'],
      ),
    ),
    GetPage(
      name: studentScoreInput,
      page: () => StudentScoreInputScreen(
        student: Get.arguments['student'],
        className: Get.arguments['className'],
        studentsCount: Get.arguments['studentsCount'],
      ),
    ),
    GetPage(
      name: studentScoresList,
      page: () => StudentScoresListScreen(
        classId: Get.arguments['classId'],
        className: Get.arguments['className'],
        studentsCount: Get.arguments['studentsCount'],
      ),
    ),
    GetPage(
      name: studentPermission,
      page: () {
        final args = Get.arguments ?? {};
        return StudentPermissionsScreen(
          classId: args['classId'] ?? '',
          className: args['className'] ?? 'Unknown Class',
          studentsCount: args['studentsCount'] ?? 0,
          subjectName: args['subjectName'] ?? 'N/A',
        );
      },
    ),
    GetPage(name: myPermission, page: () => MyPermissionScreen()),
    GetPage(
      name: studentList,
      page: () => StudentListScreen(
        classId: Get.arguments?['classId'],
        className: Get.arguments?['className'],
        subjectName: Get.arguments['subjectName'],
        studentsCount: Get.arguments['studentsCount'],
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut<StudentListController>(
            () => StudentListController(classId: Get.arguments?['classId']));
      }),
    ),
    GetPage(
      name: studentInfo,
      page: () {
        final String? studentId = Get.arguments['studentId'] as String?;
        if (studentId == null) {
          // You can redirect or show an error here
          Get.snackbar('Error', 'Student ID not provided for student info screen.',
              snackPosition: SnackPosition.BOTTOM);
          return const Scaffold(body: Center(child: Text('Student ID missing!')));
        }
        return StudentInfoScreen(studentId: studentId);
      },
      binding: StudentInfoBinding(), // <--- Use the dedicated binding here
      // No need for a BindingsBuilder directly in GetPage when using a separate class
    ),
  ];
}
