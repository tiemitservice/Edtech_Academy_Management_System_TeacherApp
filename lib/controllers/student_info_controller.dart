import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Added for Colors in SnackBar
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_info_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/services/address_service.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class StudentInfoController extends GetxController {
  // Ensure these services are correctly registered with Get.put or Get.lazyPut
  // For example, in your AppBindings or main.dart
  final StudentInfoService _studentInfoService = Get.find<StudentInfoService>();
  final AddressService _addressService = Get.find<AddressService>();

  final Rx<Student?> student = Rx<Student?>(null);
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString fullAddress = ''.obs;

  final String studentId;

  // Constructor now requires studentId as before
  StudentInfoController({required this.studentId});

  @override
  void onInit() {
    super.onInit();
    // Fetch student details when the controller is initialized
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    isLoading.value = true;
    errorMessage.value = '';
    student.value = null;
    fullAddress.value = ''; // Clear previous address

    debugPrint(
        'StudentInfoController: Attempting to fetch student details for ID: $studentId');

    try {
      final fetchedStudent =
          await _studentInfoService.fetchStudentById(studentId);
      student.value = fetchedStudent;

      if (student.value != null) {
        debugPrint(
            'StudentInfoController: Raw address IDs from student API response:');
        debugPrint('   Village ID: ${student.value!.village}');
        debugPrint('   Commune ID: ${student.value!.commune}');
        debugPrint('   District ID: ${student.value!.district}');
        debugPrint('   Province ID: ${student.value!.province}');

        List<String> parts = [];

        // --- Refined Address Construction Logic ---
        // 1. Prioritize the direct 'address' string from the student model
        final rawAddress = student.value!.address;
        if (rawAddress != null &&
            rawAddress.isNotEmpty &&
            !rawAddress.toLowerCase().contains('undefined')) {
          fullAddress.value = rawAddress;
        } else {
          // 2. If raw address is not good, try building from geographical IDs
          final villageName =
              _addressService.getVillageName(student.value!.village);
          final communeName =
              _addressService.getCommuneName(student.value!.commune);
          final districtName =
              _addressService.getDistrictName(student.value!.district);
          final provinceName =
              _addressService.getProvinceName(student.value!.province);

          if (villageName != 'N/A' && villageName.isNotEmpty)
            parts.add(villageName);
          if (communeName != 'N/A' && communeName.isNotEmpty)
            parts.add(communeName);
          if (districtName != 'N/A' && districtName.isNotEmpty)
            parts.add(districtName);
          if (provinceName != 'N/A' && provinceName.isNotEmpty)
            parts.add(provinceName);

          fullAddress.value = parts.join(', ');
        }

        // 3. If after all attempts, address is still empty, set default message
        if (fullAddress.value.isEmpty) {
          fullAddress.value = 'Address not available';
        }

        debugPrint(
            'StudentInfoController: Constructed Full Address: "${fullAddress.value}"');
      } else {
        // If student.value is null, address is definitively not available from the detailed fetch
        fullAddress.value = 'Address not available';
      }

      debugPrint(
          'StudentInfoController: Fetched student details for ID: $studentId successfully.');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      debugPrint(
          'StudentInfoController ERROR: Error fetching student details: ${errorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to load student details: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
        margin:
            const EdgeInsets.all(10), // Add some margin for better appearance
        borderRadius: 8, // Add border radius
      );
    } finally {
      isLoading.value = false;
    }
  }
}
