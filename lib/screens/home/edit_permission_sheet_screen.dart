import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/scheduler.dart';

// Assuming you have this file and controller.
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

/// A screen to be shown as a modal bottom sheet for editing an existing permission request.
class EditPermissionSheetScreen extends StatefulWidget {
  final Map<String, dynamic> permissionRequest;

  const EditPermissionSheetScreen({
    Key? key,
    required this.permissionRequest,
  }) : super(key: key);

  @override
  State<EditPermissionSheetScreen> createState() =>
      _EditPermissionSheetScreenState();
}

class _EditPermissionSheetScreenState extends State<EditPermissionSheetScreen> {
  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _borderGrey = Color(0xFFE0E6ED);
  static const Color _declineRed = Color(0xFFE74C3C);
  static const Color _lightBlueAccent = Color(0xFF5B9BD5);

  // --- Font Family Constant ---
  static const String _fontFamily =AppFonts.fontFamily;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTimeRange? _selectedDateRange;
  bool _isApplyButtonEnabled = false;
  bool _isLoading = false;

  static const String _apiUrl =
      'http://188.166.242.109:5000/api/staffpermissions';
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    // Use addPostFrameCallback to ensure the UI has been built before initializing controllers.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeFormFields();
      _dateController.addListener(_validateFields);
      _reasonController.addListener(_validateFields);
      _validateFields();
    });
  }

  /// Helper function to determine the font based on the text content.
  /// (Using a static fallback for `NotoSerifKhmer` since we're applying it broadly)
  String _getFontFamily(String text) {
    // If you intend for specific segments to fallback to 'Inter' for Latin text,
    // you could keep the regex logic and adjust it.
    // For now, assuming NotoSerifKhmer for all requested text.
    return _fontFamily;
  }

  /// Pre-fills the form with data from the permission request passed in the constructor.
  void _initializeFormFields() {
    _reasonController.text = widget.permissionRequest['reason'] ?? '';

    final dynamic holdDateRaw = widget.permissionRequest['hold_date'];
    if (holdDateRaw is List && holdDateRaw.isNotEmpty) {
      try {
        final List<String> dateStrings = holdDateRaw.cast<String>();

        DateTime? startDate;
        DateTime? endDate;

        if (dateStrings.isNotEmpty) {
          startDate = DateTime.tryParse(dateStrings[0]);
          if (dateStrings.length > 1) {
            endDate = DateTime.tryParse(dateStrings[1]);
          } else {
            endDate = startDate; // If only one date, it's a single day
          }
        }

        if (startDate != null && endDate != null) {
          _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
          // Format for display consistency with MyPermissionScreen
          if (startDate.isAtSameMomentAs(endDate)) {
            _dateController.text =
                DateFormat('EEEE, dd/MM/yyyy').format(startDate);
          } else {
            _dateController.text =
                '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
          }
        } else {
          // Fallback if parsing fails or dates are null
          debugPrint(
              "Warning: Could not parse dates from hold_date: $holdDateRaw");
          _selectedDateRange =
              DateTimeRange(start: DateTime.now(), end: DateTime.now());
          _dateController.text =
              DateFormat('EEEE, dd/MM/yyyy').format(DateTime.now());
        }
      } catch (e) {
        // Handle any parsing errors gracefully and set a default date.
        debugPrint("Error parsing hold_date in EditPermissionSheetScreen: $e");
        _selectedDateRange =
            DateTimeRange(start: DateTime.now(), end: DateTime.now());
        _dateController.text =
            DateFormat('EEEE, dd/MM/yyyy').format(DateTime.now());
      }
    } else {
      // Fallback if hold_date is null or not a list
      debugPrint("Warning: hold_date is missing or malformed: $holdDateRaw");
      _selectedDateRange =
          DateTimeRange(start: DateTime.now(), end: DateTime.now());
      _dateController.text =
          DateFormat('EEEE, dd/MM/yyyy').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _dateController.removeListener(_validateFields);
    _reasonController.removeListener(_validateFields);
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Validates the form fields to enable/disable the "Update" button.
  void _validateFields() {
    setState(() {
      _isApplyButtonEnabled =
          _dateController.text.isNotEmpty && _reasonController.text.isNotEmpty;
    });
  }

  /// Opens the date range picker and updates the text field with the selected date(s).
  Future<void> _showDateRangePicker() async {
    final DateTime now = DateTime.now();
    // Use the currently selected date as the first selectable date to allow editing past dates.
    final DateTime firstSelectableDate = _selectedDateRange?.start != null &&
            _selectedDateRange!.start.isBefore(now)
        ? _selectedDateRange!.start
        : now;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              brightness: Brightness.light,
              onPrimary: Colors.white,
              onSurface: _darkText,
            ),
            dialogBackgroundColor: _cardBackground,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
                textStyle: const TextStyle(
                    fontFamily: _fontFamily), // Apply NotoSerifKhmer
              ),
            ),
            // Apply theme-wide font for date picker
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
        if (picked.start.isAtSameMomentAs(picked.end)) {
          // Format for single day
          _dateController.text =
              DateFormat('EEEE, dd/MM/yyyy').format(picked.start);
        } else {
          // Format for date range
          _dateController.text =
              '${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}';
        }
      });
      _validateFields();
    }
  }

  /// Submits the edited permission request to the API.
  Future<void> _submitEditRequest() async {
    // Show a confirmation dialog before updating.
    final bool? confirmUpdate = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Update',
            style: TextStyle(
                fontFamily:
                    _getFontFamily('Confirm Update'), // Apply NotoSerifKhmer
                fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to update this permission request?',
            style: TextStyle(
                fontFamily: _getFontFamily(
                    'Are you sure you want to update this permission request?'), // Apply NotoSerifKhmer
                color: _mediumText)),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Get.back(result: false), // Dismiss and return false
            style: TextButton.styleFrom(
              foregroundColor: _declineRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel',
                style: TextStyle(
                    color: _darkText,
                    fontFamily:
                        _getFontFamily('Cancel'))), // Apply NotoSerifKhmer
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true), // Dismiss and return true
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Update',
                style: TextStyle(
                    fontFamily:
                        _getFontFamily('Update'), // Apply NotoSerifKhmer
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmUpdate != true) {
      return; // If the user cancels, do nothing.
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String staffId = await _authController.getUserId();
      if (staffId.isEmpty) {
        throw Exception("Staff ID not found. Please log in again.");
      }
      final String? permissionId = widget.permissionRequest['id'];
      if (permissionId == null) {
        throw Exception("Permission ID is missing. Cannot update.");
      }

      // Format dates to "YYYY-MM-DD" for the API payload
      final String startDateISO =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      final String endDateISO =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

      final List<String> holdDatePayload;
      if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
        holdDatePayload = [startDateISO]; // Single date as a direct string
      } else {
        holdDatePayload = [
          startDateISO,
          endDateISO
        ]; // Date range as direct strings
      }

      final Map<String, dynamic> payload = {
        'staff': staffId,
        'reason': _reasonController.text,
        'hold_date': holdDatePayload,
      };

      final http.Response response = await http.patch(
        Uri.parse('$_apiUrl/$permissionId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Get.snackbar(
          'Success',
          'Permission request updated!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          messageText: Text('Permission request updated!',
              style: TextStyle(
                  fontFamily: _getFontFamily('Permission request updated!'),
                  color: Colors.white)),
          titleText: Text('Success',
              style: TextStyle(
                  fontFamily: _getFontFamily('Success'),
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        );
        Get.back(result: true); // Navigate back with a success result.
      } else {
        String errorMessage =
            'Failed to update request: ${response.statusCode}';
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
          duration: const Duration(seconds: 5),
          messageText: Text(errorMessage,
              style: TextStyle(
                  fontFamily: _getFontFamily(errorMessage),
                  color: Colors.white)),
          titleText: Text('Error',
              style: TextStyle(
                  fontFamily: _getFontFamily('Error'),
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        );
      }
    } catch (e) {
      debugPrint("Error updating form: $e");
      final errorMessage =
          'An error occurred: $e. Please check your internet connection.';
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _declineRed,
        colorText: Colors.white,
        messageText: Text(errorMessage,
            style: TextStyle(
                fontFamily: _getFontFamily(errorMessage), color: Colors.white)),
        titleText: Text('Error',
            style: TextStyle(
                fontFamily: _getFontFamily('Error'),
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Submits a delete request to the API.
  Future<void> _submitDeleteRequest() async {
    final bool? confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Deletion',
            style: TextStyle(
                fontFamily:
                    _getFontFamily('Confirm Deletion'), // Apply NotoSerifKhmer
                fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete this permission request? This action cannot be undone.',
            style: TextStyle(
                fontFamily: _getFontFamily(
                    'Are you sure you want to delete this permission request? This action cannot be undone.'), // Apply NotoSerifKhmer
                color: _mediumText)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: _darkText, // Use dark text for cancel button
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel',
                style: TextStyle(
                    color: _darkText,
                    fontFamily:
                        _getFontFamily('Cancel'))), // Apply NotoSerifKhmer
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _declineRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style: TextStyle(
                    fontFamily:
                        _getFontFamily('Delete'), // Apply NotoSerifKhmer
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? permissionId = widget.permissionRequest['id'];
        if (permissionId == null) {
          throw Exception("Permission ID is missing. Cannot delete.");
        }

        final http.Response response = await http.delete(
          Uri.parse('$_apiUrl/$permissionId'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          Get.snackbar(
            'Success',
            'Permission request deleted!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            messageText: Text('Permission request deleted!',
                style: TextStyle(
                    fontFamily: _getFontFamily('Permission request deleted!'),
                    color: Colors.white)),
            titleText: Text('Success',
                style: TextStyle(
                    fontFamily: _getFontFamily('Success'),
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          );
          Get.back(result: true); // Navigate back with a success result.
        } else {
          String errorMessage =
              'Failed to delete request. Status Code: ${response.statusCode}';
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
                style: TextStyle(
                    fontFamily: _getFontFamily(errorMessage),
                    color: Colors.white)),
            titleText: Text('Error',
                style: TextStyle(
                    fontFamily: _getFontFamily('Error'),
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          );
        }
      } catch (e) {
        debugPrint("Error deleting form: $e");
        final errorMessage =
            'An error occurred during deletion. Please check your internet connection.';
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _declineRed,
          colorText: Colors.white,
          messageText: Text(errorMessage,
              style: TextStyle(
                  fontFamily: _getFontFamily(errorMessage),
                  color: Colors.white)),
          titleText: Text('Error',
              style: TextStyle(
                  fontFamily: _getFontFamily('Error'),
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isLoading, // Prevent interaction while loading
      child: Container(
        decoration: const BoxDecoration(
          color: _lightBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(), // Use ClampingScrollPhysics for a better feel
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            // Dynamic padding to move content above the keyboard
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              // Apply default font family to the entire theme subtree within this screen
              textTheme:
                  Theme.of(context).textTheme.apply(fontFamily: _fontFamily),
              textSelectionTheme: const TextSelectionThemeData(
                selectionColor: _lightBlueAccent,
                cursorColor: _primaryBlue,
                selectionHandleColor: _primaryBlue,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Permission",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _darkText,
                        fontFamily: _getFontFamily(
                            'Edit Permission'), // Applied font family
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: _mediumText, size: 28),
                      onPressed: () => Get.back(),
                      splashRadius: 24, // Add a subtle splash effect
                    ),
                  ],
                ),
                const SizedBox(height: 32), // Consistent vertical spacing
                // Date input field
                _buildInputFieldWithLabel(
                  label: "Choose Date",
                  controller: _dateController,
                  hintText: 'Select a date or date range',
                  icon: Icons.calendar_today_rounded, // Changed icon
                  onTap: _showDateRangePicker,
                  readOnly: true,
                ),
                const SizedBox(height: 24), // Consistent vertical spacing
                // Reason text area
                _buildInputFieldWithLabel(
                  label: "Reason",
                  controller: _reasonController,
                  hintText: 'Ex: Hospital Appointment',
                  icon: Icons.edit_note_rounded,
                  maxLines: 5,
                ),
                const SizedBox(height: 40), // Spacing before buttons
                // Action buttons: Delete and Update
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitDeleteRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _declineRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: _declineRed.withOpacity(0.3),
                          disabledBackgroundColor: _borderGrey,
                          disabledForegroundColor: _mediumText,
                        ),
                        child:
                            _isLoading // Show loading indicator within button
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    "Delete",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _getFontFamily(
                                          'Delete'), // Applied font family
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isApplyButtonEnabled && !_isLoading)
                            ? _submitEditRequest
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: _primaryBlue.withOpacity(0.3),
                          disabledBackgroundColor: _borderGrey,
                          disabledForegroundColor: _mediumText,
                        ),
                        child:
                            _isLoading // Show loading indicator within button
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    "Update",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: _getFontFamily(
                                          'Update'), // Applied font family
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A helper widget to build a styled input field with a label.
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
        // Label with asterisk for required fields
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: label,
                  style: TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w700,
                    fontFamily: _getFontFamily(label), // Applied font family
                  )),
              const TextSpan(text: " *", style: TextStyle(color: _declineRed)),
            ],
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _darkText,
            fontFamily: _getFontFamily(label), // Applied font family
          ),
        ),
        const SizedBox(height: 12),
        // Text field
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines ?? 1,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: _primaryBlue,
                  )
                : null,
            suffixIcon: readOnly
                ? const Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: _mediumText)
                : null,
            hintText: hintText,
            hintStyle: TextStyle(
                color: _mediumText,
                fontFamily:
                    _getFontFamily(hintText ?? '')), // Applied font family
            filled: true,
            fillColor: _cardBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
          ),
          style: TextStyle(
              color: _darkText,
              fontFamily:
                  _getFontFamily(controller.text)), // Applied font family
        ),
      ],
    );
  }
}
