import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Get.snackbar, Colors
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart'; // Import AuthController

// Assuming StudentFetchResult is the return type from StudentListService.
// If this class does not exist, you might need to define it in your models or services.
// Example:
// class StudentFetchResult {
//   final List<Student> students;
//   final int totalStudentsCount;
//   StudentFetchResult({required this.students, required this.totalStudentsCount});
// }

class StudentListController extends GetxController {
  final StudentListService _studentListService = Get.find<StudentListService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Student> students = <Student>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt totalStudentsCount = 0.obs;

  // Make classId a required parameter since the controller cannot function without it.
  final String classId;

  StudentListController({required this.classId}); // classId is now required

  @override
  void onInit() {
    super.onInit();
    // No need to pass classId here, it's already a property of the controller
    fetchStudents();
  }

  /// Fetches the list of students for the class associated with this controller's classId,
  /// and the currently authenticated staffId.
  Future<void> fetchStudents() async {
    // The check for classId being null or empty is now handled by the constructor.
    // If you ever need to manually trigger this with a different classId,
    // consider a separate method like `loadStudentsForNewClass(String newClassId)`.

    isLoading.value = true;
    errorMessage.value = ''; // Clear previous error
    totalStudentsCount.value = 0; // Reset count
    students.clear(); // Clear existing student list before fetching

    try {
      final staffId = await _authController.getStaffId(); // Get the staffId

      if (staffId.isEmpty) {
        errorMessage.value = "Teacher Staff ID not found. Please log in again.";
        // Show a snackbar for immediate user feedback
        Get.snackbar(
          'Authentication Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.declineRed,
          colorText: Colors.white,
        );
        return; // Exit function if staffId is missing
      }

      // Call the service with both classId (from controller property) and staffId
      final result = await _studentListService.fetchStudentsForClass(
        classId: this.classId, // Use the controller's classId
        staffId: staffId,
      );

      // Ensure result.students is not null, default to empty list if it could be
      students.assignAll(result.students);
      // Ensure totalStudentsCount is not null, default to 0 if it could be
      totalStudentsCount.value = result.totalStudentsCount;

      print(
          'Fetched ${students.length} students successfully for class ${this.classId}. Total items: ${totalStudentsCount.value}');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching students: ${errorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to load students: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
