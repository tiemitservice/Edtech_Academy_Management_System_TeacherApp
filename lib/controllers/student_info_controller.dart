// lib/controllers/student_info_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_info_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/services/address_service.dart';
import 'package:flutter/foundation.dart';

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
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    isLoading.value = true;
    errorMessage.value = '';
    student.value = null;
    fullAddress.value = '';

    debugPrint(
        'StudentInfoController: Attempting to fetch student details for ID: $studentId');

    try {
      final fetchedStudent =
          await _studentInfoService.fetchStudentById(studentId);
      student.value = fetchedStudent;

      if (student.value != null) {
        List<String> parts = [];
        final rawAddress = student.value!.address;
        if (rawAddress != null &&
            rawAddress.isNotEmpty &&
            !rawAddress.toLowerCase().contains('undefined')) {
          fullAddress.value = rawAddress;
        } else {
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

        if (fullAddress.value.isEmpty) {
          fullAddress.value = 'Address not available';
        }
      } else {
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
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
