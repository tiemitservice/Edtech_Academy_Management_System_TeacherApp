import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/controllers/student_permission_controller.dart';
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';
import 'package:school_management_system_teacher_app/controllers/student_list_controller.dart'; // <--- NEW IMPORT
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
// import 'package:school_management_system_teacher_app/services/class_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/services/student_list_service.dart'; // <--- NEW IMPORT

// Main binding to initialize all necessary controllers and services
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StudentPermissionService());
    Get.lazyPut(() => StudentRepository());
    Get.lazyPut(() => StudentListService());

    Get.put(AuthController());
    Get.put(StudentPermissionController());
    Get.lazyPut(() => NotificationController());
    Get.lazyPut(() => StudentListController());
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
            'KantumruyPro', // Ensure this font is correctly configured in pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: MainBinding(), // Initialize all dependencies
      initialRoute:
          AppRoutes.home, // Set to home or your desired starting screen
      getPages: AppRoutes.routes, // Your defined routes
    );
  }
}
