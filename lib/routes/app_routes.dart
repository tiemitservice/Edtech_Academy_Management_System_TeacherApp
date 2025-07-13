import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/screens/home/check_attendence_screen.dart';
import 'package:school_management_system_teacher_app/onboarding/onboarding_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/forgot_password_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/login_screen.dart'; // Assuming this is SignInScreen and the class name is SignInScreen
import 'package:school_management_system_teacher_app/screens/home/class_management_screen.dart'; // Removed 'as class_management'
import 'package:school_management_system_teacher_app/screens/home/edit_profile_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/home_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/my_permission_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/notifications_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/profile_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_permissions_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_score_input_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/student_scores_list_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/teacher_management_screen.dart';
import 'package:school_management_system_teacher_app/screens/splash_screen.dart';

class AppRoutes {
  // Define all route paths as static constants for easy access and typo prevention
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  // static const String permission = '/permission'; // If you have a permission screen, uncomment
  static const String classManagement = '/class-management';
  static const String checkAttendance = '/check-attendance';
  static const String teacherManagement = '/teacher-management';
  static const String studentScoreInput = '/student-score-input';
  static const String studentScoresList = '/student-scores-list';
  static const String studentPermission = '/student-permission';
  static const String myPermission = '/my-permission';
  static const String notification = '/notification';

  // Define the list of GetPage routes
  static final List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login,
      page: () => SignInScreen(), // Assuming SignInScreen is the class name
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(email: ''),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: editProfile,
      page: () => const EditProfileScreen(),
    ),
    GetPage(
      name: classManagement,
      page: () => const ClassManagementScreen(), // Using direct name
    ),
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
      page: () => StudentPermissionsScreen(
        classId: Get.arguments['classId'],
        className: Get.arguments['className'],
        studentsCount: Get.arguments['studentsCount'],
        subjectName: Get.arguments['subjectName'],
      ),
    ),
    GetPage(
      name: myPermission,
      page: () => MyPermissionScreen(), // Assumes no arguments are needed
    ),
    GetPage(
      name: notification,
      page: () => NotificationsScreen(),
    )
  ];
}
