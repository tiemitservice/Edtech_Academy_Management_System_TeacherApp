import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';

void main() async {
  Get.put(AuthController()); // Register the AuthController
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EdTech Academy Teacher App',
      themeMode: ThemeMode.system, // Auto switch based on device
      initialRoute: AppRoutes.splash, // Where the app starts
      getPages: AppRoutes.routes, // <- Use `getPages` for GetX routing
    );
  }
}
