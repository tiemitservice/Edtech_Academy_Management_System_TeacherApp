// lib/bindings/student_info_binding.dart
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/controllers/student_info_controller.dart';

class StudentInfoBinding extends Bindings {
  @override
  void dependencies() {
    // These services should ideally be in MainBinding if they are global singletons.
    // However, if they are only used by StudentInfoController, putting them here is fine.
    // Given your main.dart, they are already in MainBinding.
    // So, we don't strictly need to put them again here, but it doesn't hurt.
    // Get.lazyPut(() => StudentInfoService());
    // Get.lazyPut(() => AddressService());

    // Get the studentId from the arguments
    final String? studentId = Get.arguments['studentId'] as String?;

    if (studentId != null) {
      // Put the StudentInfoController with a tag matching the studentId
      Get.put<StudentInfoController>(
        StudentInfoController(studentId: studentId),
        tag: studentId, // This is crucial for Get.find(tag: studentId) to work
      );
    } else {
      // Handle the case where studentId is not provided (e.g., show error or log)
      Get.log('Error: Student ID is null in StudentInfoBinding.');
      // You might want to navigate back or show a specific error screen here.
      // For now, it will just proceed with a null student, which your UI handles.
    }
  }
}