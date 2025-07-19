import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Make sure these import paths are correct for your project structure
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';

/// A draggable floating button that also functions as a real-time notification indicator.
///
/// This widget connects to a `NotificationController` to display a badge with the
/// number of pending notifications. It can be dragged freely around the screen,
/// animates its position smoothly, and changes color when moved to the top.
/// Tapping the button navigates to the student permission screen.
class DraggableNotificationButton extends StatefulWidget {
  const DraggableNotificationButton({Key? key}) : super(key: key);

  @override
  State<DraggableNotificationButton> createState() =>
      _DraggableNotificationButtonState();
}

class _DraggableNotificationButtonState
    extends State<DraggableNotificationButton> {
  // --- Dependencies ---
  // Find the existing instance of NotificationController provided by GetX.
  // Ensure a controller is put() in a parent widget before this is used.
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  // --- State for Draggable Logic ---
  Offset _position = Offset.zero;
  bool _isAtTop = false;
  bool _isInitialized = false;

  // --- UI Constants ---
  static const double _buttonSize = 56.0;
  static const double _padding = 16.0;
  static const Color _primaryBlue = Color(0xFF1468C7);
  static const Color _badgeColor = Color(0xFFE74C3C); // Red for the badge

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the button's starting position once the context is available.
    if (!_isInitialized) {
      final Size screenSize = MediaQuery.of(context).size;
      final EdgeInsets safeArea = MediaQuery.of(context).padding;

      setState(() {
        // Set initial position to the bottom-right, respecting the safe area.
        _position = Offset(
          screenSize.width - _buttonSize - _padding,
          screenSize.height - _buttonSize - safeArea.bottom - _padding,
        );
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;

    // AnimatedPositioned provides smooth movement when the button is released.
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildButton(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            // Clamp the final position to stay within the screen's safe boundaries.
            double newX = details.offset.dx.clamp(
              safeArea.left,
              screenSize.width - _buttonSize - safeArea.right,
            );
            double newY = details.offset.dy.clamp(
              safeArea.top,
              screenSize.height - _buttonSize - safeArea.bottom,
            );
            _position = Offset(newX, newY);

            // Check if the button is in the top area to trigger color change.
            _isAtTop = newY <= (safeArea.top + 100);
          });
        },
        child: _buildButton(),
      ),
    );
  }

  /// Builds the button, now integrated with notification logic.
  Widget _buildButton() {
    return Stack(
      clipBehavior: Clip.none, // Allows the badge to render outside the Stack
      children: [
        // The main button body, which animates color changes.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: _isAtTop ? Colors.white : _primaryBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              // **BEHAVIOR CHANGE**: Navigate on tap.
              onTap: () => Get.toNamed(AppRoutes.studentPermission),
              child: SizedBox(
                width: _buttonSize,
                height: _buttonSize,
                // **REACTIVE ICON**: Wrapped in Obx to listen for changes.
                child: Obx(() {
                  return Icon(
                    _notificationController.pendingPermissionCount.value > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _isAtTop ? _primaryBlue : Colors.white,
                  );
                }),
              ),
            ),
          ),
        ),
        // **REACTIVE BADGE**: Also wrapped in Obx.
        Obx(() {
          final count = _notificationController.pendingPermissionCount.value;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            // **FIXED**: The transitionBuilder now correctly wraps the badge content
            // with the ScaleTransition, leaving the Positioned widget outside.
            transitionBuilder: (Widget child, Animation<double> animation) {
              // The child from AnimatedSwitcher is either the Positioned badge or a SizedBox.
              // We apply the scale animation to whatever child is currently active.
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            // Show badge only if count > 0.
            child: count > 0
                ? Positioned(
                    // Using a ValueKey ensures AnimatedSwitcher correctly identifies the widget.
                    key: const ValueKey('badge'),
                    top: -4,
                    right: -4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _badgeColor,
                          shape: BoxShape.circle,
                          // border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Center(
                          child: Text(
                            _notificationController.formattedPendingCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                // When count is 0, switch to this empty widget.
                : const SizedBox.shrink(key: ValueKey('empty')),
          );
        }),
      ],
    );
  }
}
