// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/controllers/student_info_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_info_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/services/address_service.dart';

class StudentInfoController extends GetxController {
  final StudentInfoService _studentInfoService = Get.find<StudentInfoService>();
  final AddressService _addressService = Get.find<AddressService>();

  final Rx<Student?> student = Rx<Student?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString fullAddress = ''.obs;

  final String studentId;

  StudentInfoController({required this.studentId});

  @override
  void onInit() {
    super.onInit();
    // With Get.putAsync in MainBinding, AddressService is guaranteed to be loaded
    // before this controller is ever initialized. So, no need for `ever` or checks.
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    isLoading.value = true;
    errorMessage.value = '';
    student.value = null;
    fullAddress.value = '';

    try {
      final fetchedStudent =
          await _studentInfoService.fetchStudentById(studentId);
      student.value = fetchedStudent;

      if (student.value != null) {
        print(
            'StudentInfoController: Raw address IDs from student API response:');
        print('  Village ID: ${student.value!.village}');
        print('  Commune ID: ${student.value!.commune}');
        print('  District ID: ${student.value!.district}');
        print('  Province ID: ${student.value!.province}');

        final villageName =
            _addressService.getVillageName(student.value!.village);
        final communeName =
            _addressService.getCommuneName(student.value!.commune);
        final districtName =
            _addressService.getDistrictName(student.value!.district);
        final provinceName =
            _addressService.getProvinceName(student.value!.province);

        List<String> addressParts = [];
        if (villageName != 'N/A') addressParts.add(villageName);
        if (communeName != 'N/A') addressParts.add(communeName);
        if (districtName != 'N/A') addressParts.add(districtName);
        if (provinceName != 'N/A') addressParts.add(provinceName);

        fullAddress.value = addressParts.join(', ');
        if (fullAddress.value.isEmpty) {
          fullAddress.value = 'Address not available';
        }
        print(
            'StudentInfoController: Constructed Full Address: "${fullAddress.value}"');
      } else {
        fullAddress.value = 'Address not available';
      }

      print(
          'StudentInfoController: Fetched student details for ID: $studentId successfully.');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print(
          'StudentInfoController ERROR: Error fetching student details: ${errorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to load student details: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
