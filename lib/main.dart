// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart'; // Import NotificationController
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/services/student_info_service.dart';
import 'package:school_management_system_teacher_app/services/address_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // For AppFonts and other colors

// Main binding to initialize all necessary controllers and services
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Services should be put() or lazyPut() based on their usage.
    // Order matters if a service is a dependency of another.
    // AddressService is a dependency for StudentInfoService and StudentPermissionService.
    Get.put(AddressService(), permanent: true); // Often needed globally
    Get.lazyPut(() => StudentRepository()); // May be used by services below

    // StudentPermissionService needs AuthController to get Staff ID,
    // and potentially AddressService for data mapping in permissions.
    // So, AuthController should be put/lazyPut before NotificationController.
    Get.lazyPut(() => StudentPermissionService());

    // StudentListService often depends on StudentRepository.
    Get.put(StudentListService(),
        permanent: true); // Ensure immediate availability

    Get.put(StudentInfoService(),
        permanent: true); // Ensured immediate instantiation

    // AuthController is fundamental and typically made available permanently
    Get.put(AuthController(), permanent: true);

    // StudentPermissionController might depend on StudentPermissionService and AuthController
    Get.put(StudentPermissionController(),
        permanent: true); // Or lazyPut if only used on specific screens

    // FIX: Change NotificationController to Get.put for immediate instantiation
    //      This ensures it's found when needed, especially by global widgets.
    //      Make it permanent: true as it's a global listener.
    Get.put(NotificationController(), permanent: true);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EdTech Teacher App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: AppFonts
            .fontFamily, // Ensure this font is correctly configured in pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: MainBinding(), // Initialize all dependencies
      initialRoute:
          AppRoutes.splash, // Set to home or your desired starting screen
      getPages: AppRoutes.routes, // Your defined routes
    );
  }
}
