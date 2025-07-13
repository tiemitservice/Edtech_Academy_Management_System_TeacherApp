import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/class_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart'; // <--- NEW IMPORT

// Main binding to initialize all necessary controllers and services
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => StudentPermissionService());
    Get.lazyPut(() => ClassService());
    Get.lazyPut(() => StudentRepository()); // <--- NEW BINDING

    // Controllers
    Get.put(AuthController()); // AuthController should be available for staffId
    Get.put(StudentPermissionController()); // StudentPermissionController
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
        fontFamily:
            'NotoSerifKhmer', // Ensure this font is correctly configured in pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: MainBinding(), // Initialize all dependencies
      initialRoute: AppRoutes
          .splash, // Set StudentPermissionsScreen as the initial route for testing
      getPages: AppRoutes.routes, // Your defined routes
    );
  }
}
