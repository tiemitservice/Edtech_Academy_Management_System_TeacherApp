import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/controllers/permission_controller.dart';

class AddPermissionSheetScreen extends StatefulWidget {
  const AddPermissionSheetScreen({Key? key}) : super(key: key);

  @override
  State<AddPermissionSheetScreen> createState() =>
      _AddPermissionSheetScreenState();
}

class _AddPermissionSheetScreenState extends State<AddPermissionSheetScreen> {
  // --- UI Constants - Use AppColors for consistency ---
  static const Color _primaryBlue = AppColors.primaryBlue;
  static const Color _lightBackground = AppColors.lightBackground;
  static const Color _cardBackground = AppColors.cardBackground;
  static const Color _darkText = AppColors.darkText;
  static const Color _mediumText = AppColors.mediumText;
  static const Color _borderGrey = AppColors.borderGrey;
  static const Color _declineRed = AppColors.declineRed;
  static const Color _lightBlueAccent = AppColors.primaryBlue;

  // --- Font Family Constant - Use AppFonts for consistency ---
  static const String _fontFamily = AppFonts.fontFamily;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTimeRange? _selectedDateRange;
  bool _isApplyButtonEnabled = false;
  bool _isLoading = false;

  static const String _apiUrl =
      'http://188.166.242.109:5000/api/staffpermissions';
  late final AuthController _authController;
  late final PermissionController _permissionController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _permissionController = Get.find<PermissionController>();
    _dateController.addListener(_validateFields);
    _reasonController.addListener(_validateFields);
    _validateFields();
  }

  @override
  void dispose() {
    _dateController.removeListener(_validateFields);
    _reasonController.removeListener(_validateFields);
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      _isApplyButtonEnabled =
          _dateController.text.isNotEmpty && _reasonController.text.isNotEmpty;
    });
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              onSurface: _darkText,
            ),
            dialogBackgroundColor: _cardBackground,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
                textStyle: const TextStyle(fontFamily: _fontFamily),
              ),
            ),
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: _fontFamily),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        final String startDate =
            DateFormat('EEEE, dd/MM/yyyy').format(picked.start);
        final String endDate =
            DateFormat('EEEE, dd/MM/yyyy').format(picked.end);

        if (picked.start.isAtSameMomentAs(picked.end)) {
          _dateController.text = startDate;
        } else {
          _dateController.text = '$startDate - $endDate';
        }
      });
      _validateFields();
    }
  }

  Future<void> _submitPermissionRequest() async {
    final bool? confirm = await _showConfirmationDialog();
    if (confirm != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String staffId = await _authController.getUserId();
      if (staffId.isEmpty) {
        throw Exception("Staff ID not found. Please log in again.");
      }

      if (_selectedDateRange == null) {
        throw Exception("Please select a date or date range.");
      }

      final String startDateISO =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      final String endDateISO =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

      final List<String> holdDatePayload;
      if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
        holdDatePayload = [startDateISO];
      } else {
        holdDatePayload = [startDateISO, endDateISO];
      }

      final Map<String, dynamic> payload = {
        'staff': staffId,
        'reason': _reasonController.text,
        'hold_date': holdDatePayload,
      };

      final http.Response response = await http.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Get.snackbar(
          'Success',
          'Permission request submitted!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successGreen,
          colorText: Colors.white,
          messageText: Text('Permission request submitted!',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
          titleText: Text('Success',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
        );
        _permissionController.fetchPermissions(); // Trigger data refresh
        Get.back(result: true);
        Get.offAndToNamed('/my-permission'); // Close the sheet
      } else {
        String errorMessage =
            'Failed to submit request: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage =
              'Status Code: ${response.statusCode}, Body: ${response.body}';
        }
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _declineRed,
          colorText: Colors.white,
          messageText: Text(errorMessage,
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
          titleText: Text('Error',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
        );
      }
    } catch (e) {
      debugPrint("Error submitting form: $e");
      Get.snackbar(
        'Error',
        'An error occurred. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _declineRed,
        colorText: Colors.white,
        messageText: Text(
            'An error occurred. Please check your internet connection.',
            style:
                const TextStyle(color: Colors.white, fontFamily: _fontFamily)),
        titleText: Text('Error',
            style:
                const TextStyle(color: Colors.white, fontFamily: _fontFamily)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Confirm Submission",
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: _fontFamily,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to submit this permission request?",
              style: TextStyle(
                color: _mediumText,
                fontSize: 15,
                fontFamily: _fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Dates: ",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: _fontFamily),
                  ),
                  TextSpan(
                    text: _dateController.text,
                    style:
                        TextStyle(color: _mediumText, fontFamily: _fontFamily),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Reason: ",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: _fontFamily),
                  ),
                  TextSpan(
                    text: _reasonController.text,
                    style:
                        TextStyle(color: _mediumText, fontFamily: _fontFamily),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: _declineRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontFamily: _fontFamily),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontFamily: _fontFamily),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _lightBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: const TextSelectionThemeData(
                selectionColor: _lightBlueAccent,
                cursorColor: _primaryBlue,
                selectionHandleColor: _primaryBlue,
              ),
              textTheme:
                  Theme.of(context).textTheme.apply(fontFamily: _fontFamily),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _darkText, size: 24),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Add Permission",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInputFieldWithLabel(
                  label: "Choose Date",
                  controller: _dateController,
                  hintText: 'Select a date or date range',
                  icon: Icons.calendar_month,
                  onTap: _showDateRangePicker,
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                _buildInputFieldWithLabel(
                  label: "Reason",
                  controller: _reasonController,
                  hintText: 'Ex: Hospital Appointment',
                  maxLines: 5,
                  icon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isApplyButtonEnabled && !_isLoading)
                        ? _submitPermissionRequest
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      disabledBackgroundColor: _borderGrey,
                      disabledForegroundColor: _mediumText,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "Apply",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: _fontFamily,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a labeled text input field.
  Widget _buildInputFieldWithLabel({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? icon,
    int? maxLines,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: label,
                  style: const TextStyle(
                      color: _darkText, fontFamily: _fontFamily)),
              const TextSpan(
                  text: "*",
                  style:
                      TextStyle(color: _declineRed, fontFamily: _fontFamily)),
            ],
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _darkText,
            fontFamily: _fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines ?? 1,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: _primaryBlue) : null,
            suffixIcon: readOnly
                ? const Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: _mediumText)
                : null,
            hintText: hintText,
            hintStyle:
                const TextStyle(color: _mediumText, fontFamily: _fontFamily),
            filled: true,
            fillColor: _cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryBlue, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          style: const TextStyle(color: _darkText, fontFamily: _fontFamily),
        ),
      ],
    );
  }
}
