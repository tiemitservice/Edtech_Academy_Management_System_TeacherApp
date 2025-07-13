import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

// Import the required screens and the new PermissionController
import 'package:school_management_system_teacher_app/screens/home/add_permission_sheet_screen.dart';
import 'package:school_management_system_teacher_app/screens/home/edit_permission_sheet_screen.dart';
import 'package:school_management_system_teacher_app/controllers/permission_controller.dart'; // Import the PermissionController

/// A screen for a user (student or teacher) to view and manage their own
/// permission requests.
/// This is now a StatelessWidget, as all mutable state is managed by PermissionController.
class MyPermissionScreen extends StatelessWidget {
  const MyPermissionScreen({Key? key}) : super(key: key);

  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _borderGrey = Color(0xFFE0E6ED);
  static const Color _successGreen = Color(0xFF27AE60);
  static const Color _declineRed = Color(0xFFE74C3C);
  static const Color _pendingOrange = Color(0xFFF39C12);
  static const double _cardPadding = 20.0;
  static const double _listPadding = 16.0;
  static const double _bottomButtonPadding = 16.0;

  // --- Font Family Constant ---
  // Define the font family name as a constant for consistent use.
  // This should match the 'family' name in your pubspec.yaml.
  static const String _fontFamily = 'KantumruyPro';

  @override
  Widget build(BuildContext context) {
    final PermissionController permissionController =
        Get.put(PermissionController());

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: _primaryBlue,
    ));

    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: _buildAppBar(permissionController.getFontFamily),
      body: Column(
        children: [
          Obx(() => _buildHeader(
                permissionController.permissionRequests.length,
                permissionController.permissionRequests
                    .where((req) => req['status'] == 'Pending')
                    .length,
                permissionController.isLoading.value,
              )),
          Expanded(
            child: Obx(() {
              if (permissionController.isLoading.value) {
                return _buildSkeletonLoader();
              } else if (permissionController.hasError.value) {
                return _buildErrorState(
                  permissionController.errorMessage.value,
                  permissionController.fetchPermissions,
                  permissionController.getFontFamily,
                );
              } else if (permissionController.permissionRequests.isEmpty) {
                return _buildEmptyState(permissionController.getFontFamily);
              } else {
                return _buildPermissionList(permissionController);
              }
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildAddPermissionButton(permissionController),
    );
  }

  AppBar _buildAppBar(Function(String) getFontFamily) {
    return AppBar(
      backgroundColor: _primaryBlue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () {
          Get.offAllNamed("/home");
        },
      ),
      title: Text(
        "My Permissions",
        style: TextStyle(
          color: Colors.white,
          fontFamily: _fontFamily, // Apply NotoSerifKhmer
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSkeletonLoader() {
    // Shimmer itself doesn't need font changes, but its underlying widgets might.
    // However, for a skeleton loader, text isn't actually rendered.
    return Shimmer.fromColors(
      baseColor: _borderGrey.withOpacity(0.5),
      highlightColor: Colors.white.withOpacity(0.8),
      child: ListView.builder(
        padding: const EdgeInsets.all(_listPadding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: _listPadding),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              side: const BorderSide(color: _borderGrey, width: 1),
            ),
            color: _cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(_cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 150, height: 15),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 200, height: 12),
                        ],
                      ),
                      _buildShimmerBox(width: 70, height: 20, isRounded: true),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerBox(
      {required double width, required double height, bool isRounded = false}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isRounded ? 20 : 4),
      ),
    );
  }

  Widget _buildErrorState(
      String message, VoidCallback onRetry, Function(String) getFontFamily) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              message.contains('Network error')
                  ? Icons.cloud_off_rounded
                  : Icons.error_outline_rounded,
              color: _declineRed.withOpacity(0.8),
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Function(String) getFontFamily) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_outlined, size: 80, color: _mediumText),
          const SizedBox(height: 20),
          Text(
            'No permission requests found.',
            style: TextStyle(
              color: _mediumText,
              fontSize: 16,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(int total, int pending, bool isLoading) {
    final PermissionController controller = Get.find<PermissionController>();
    return Container(
      color: _primaryBlue,
      child: Container(
        decoration: const BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child: _buildStatColumn(
                    "Total", total, isLoading, controller.getFontFamily)),
            SvgPicture.asset(
              'assets/images/teacher_management/permission.svg',
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
            Flexible(
                child: _buildStatColumn(
                    "Pending", pending, isLoading, controller.getFontFamily)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, int value, bool isLoading, Function(String) getFontFamily) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
              color: _mediumText,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
              fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          isLoading ? '...' : '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _darkText,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionList(PermissionController controller) {
    return RefreshIndicator(
      backgroundColor: _lightBackground,
      onRefresh: controller.fetchPermissions,
      color: _primaryBlue,
      child: Obx(
        () => ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: _listPadding, vertical: _listPadding),
          itemCount: controller.permissionRequests.length,
          itemBuilder: (context, index) {
            final request = controller.permissionRequests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: _listPadding),
              child: _buildPermissionCard(
                request: request,
                onTap: () {
                  controller.toggleExpansion(index);
                },
                getFontFamily: controller.getFontFamily,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required Map<String, dynamic> request,
    required VoidCallback onTap,
    required Function(String) getFontFamily,
  }) {
    Color statusColor;
    switch (request['status']) {
      case 'Approved':
        statusColor = _successGreen;
        break;
      case 'Rejected':
        statusColor = _declineRed;
        break;
      case 'Pending':
      default:
        statusColor = _pendingOrange;
        break;
    }

    final String formattedDateDisplay =
        request['formatted_date_display'] as String;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderGrey, width: 1),
      ),
      color: _cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDateDisplay,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _darkText,
                            fontFamily: _fontFamily, // Apply NotoSerifKhmer
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Reason: ${request['reason']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _mediumText,
                            fontFamily: _fontFamily, // Apply NotoSerifKhmer
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            fontFamily: _fontFamily, // Apply NotoSerifKhmer
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        request['isExpanded']
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: _mediumText,
                      ),
                    ],
                  ),
                ],
              ),
              if (request['isExpanded'])
                _buildExpandedDetails(request, getFontFamily),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDetails(
      Map<String, dynamic> request, Function(String) getFontFamily) {
    final PermissionController permissionController =
        Get.find<PermissionController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(color: _borderGrey, height: 1),
        const SizedBox(height: 16),
        Text(
          "Permission Details",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _darkText,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
          ),
        ),
        const SizedBox(height: 16),
        _buildPermissionDetailRow(
          icon: Icons.calendar_month_rounded,
          label: 'Date:',
          value: request['date_full'],
          getFontFamily: getFontFamily,
        ),
        const SizedBox(height: 12),
        _buildPermissionDetailRow(
          icon: Icons.access_time_filled_rounded,
          label: 'Duration:',
          value: request['days_text'],
          getFontFamily: getFontFamily,
        ),
        const SizedBox(height: 12),
        _buildPermissionDetailRow(
          icon: Icons.description_rounded,
          label: 'Reason:',
          value: request['reason'],
          getFontFamily: getFontFamily,
        ),
        if (request['status'] == 'Pending')
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: InkWell(
                onTap: () async {
                  final result = await Get.bottomSheet(
                    EditPermissionSheetScreen(permissionRequest: request),
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  );
                  if (result == true) {
                    permissionController.fetchPermissions();
                  }
                },
                child: Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Function(String) getFontFamily,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _mediumText),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _darkText,
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  ),
                ),
                TextSpan(
                  text: ' $value',
                  style: TextStyle(
                    color: _mediumText,
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAddPermissionButton(PermissionController controller) {
    return Container(
      padding: const EdgeInsets.all(_bottomButtonPadding),
      color: _cardBackground,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Get.bottomSheet(
              const AddPermissionSheetScreen(),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            );
            if (result == true) {
              controller.fetchPermissions();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
          ),
          child: Text(
            "Add Permission",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
            ),
          ),
        ),
      ),
    );
  }
}