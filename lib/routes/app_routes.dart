import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/onboarding/onboarding_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/forgot_password_screen.dart';
import 'package:school_management_system_teacher_app/screens/auth/login_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/home_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/profile_screen.dart';
import 'package:school_management_system_teacher_app/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String classes = '/classes';
  static const String attendance = '/attendance';
  static const String permission = '/permission';

  static final List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login,
      page: () => SignInScreen(),
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
    ),GetPage(
      name: profile,
      page: () => ProfileScreen(),
    ),
  ];
}
