// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/services/student_info_service.dart';
import 'package:school_management_system_teacher_app/services/address_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // NEW IMPORT

// Main binding to initialize all necessary controllers and services
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StudentPermissionService());
    Get.lazyPut(() => StudentRepository());
    Get.put(StudentListService()); // Ensure immediate availability
    Get.lazyPut(() =>
        StudentInfoService()); // Keep as lazyPut here, as it's found by route-bound controller

    // NEW: Register AddressService globally and ensure it's initialized
    Get.put(AddressService());

    Get.put(AuthController());
    Get.put(StudentPermissionController());
    Get.lazyPut(() => NotificationController());
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
          AppRoutes.home, // Set to home or your desired starting screen
      getPages: AppRoutes.routes, // Your defined routes
    );
  }
}
