// lib/controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'dart:async'; // For Timer

class NotificationController extends GetxController {
  final StudentPermissionService _permissionService =
      Get.find<StudentPermissionService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxInt pendingPermissionCount = 0.obs;
  Timer? _timer; // Timer for periodic fetching

  @override
  void onInit() {
    super.onInit();
    _fetchPendingPermissions();
    // Fetch pending permissions every 30 seconds (adjust as needed)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchPendingPermissions();
    });
  }

  @override
  void onClose() {
    _timer?.cancel(); // Cancel the timer when the controller is closed
    super.onClose();
  }

  Future<void> _fetchPendingPermissions() async {
    try {
      final teacherStaffId = await _authController.getStaffId();
      if (teacherStaffId.isEmpty) {
        print(
            'NotificationController: Teacher Staff ID not found. Cannot fetch pending permissions.');
        pendingPermissionCount.value = 0; // Reset count if not logged in
        return;
      }

      final allPermissions = await _permissionService.fetchAllPermissions();
      final pendingCount = allPermissions
          .where((p) =>
              p.sentToStaffId == teacherStaffId &&
              p.status.toLowerCase() == 'pending')
          .length;

      pendingPermissionCount.value = pendingCount;
      print(
          'NotificationController: Fetched $pendingCount pending permissions.');
    } catch (e) {
      print('NotificationController: Error fetching pending permissions: $e');
      pendingPermissionCount.value = 0; // Reset count on error
    }
  }

  // Helper getter to format the count for the badge
  String get formattedPendingCount {
    if (pendingPermissionCount.value > 9) {
      return '9+';
    }
    return pendingPermissionCount.value.toString();
  }
}
