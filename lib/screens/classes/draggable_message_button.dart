import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Ensure these import paths are correct for your project structure
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Assuming AppFonts is here

/// A draggable floating button for notifications with a subtle jiggle animation.
class DraggableNotificationButton extends StatefulWidget {
  const DraggableNotificationButton({Key? key}) : super(key: key);

  @override
  State<DraggableNotificationButton> createState() =>
      _DraggableNotificationButtonState();
}

class _DraggableNotificationButtonState
    extends State<DraggableNotificationButton>
    with SingleTickerProviderStateMixin {
  // --- Dependencies ---
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  // --- Animation State ---
  late final AnimationController _animationController;
  late final Animation<double> _rotationAnimation;

  // --- Draggable Logic State ---
  Offset _position = Offset.zero;
  bool _isInitialized = false;

  // --- UI Constants ---
  static const double _buttonSize = 56.0;
  static const double _badgeHeight = 20.0; // Slightly smaller badge
  static const double _padding = 20.0; // Increased padding from edges
  static const Color _primaryButtonColor = Color(0xFF1468C7); // Consistent blue
  static const Color _badgeColor = Color(0xFFE74C3C);
  static const String _fontFamily =
      AppFonts.fontFamily; // Access font family from AppFonts

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _setupNotificationListener();
  }

  /// Initializes the animation controller and rotation animation for the jiggle effect.
  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: -0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.12, end: 0.12), weight: 10),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.12, end: 0.0), weight: 10),
      TweenSequenceItem(
          tween: ConstantTween<double>(0.0), weight: 60), // Longer pause
    ]).animate(_animationController);
  }

  /// Sets up a listener for notification count changes to control the animation.
  void _setupNotificationListener() {
    _notificationController.pendingPermissionCount.listen((count) {
      if (!mounted) return;
      if (count > 0) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    });

    if (_notificationController.pendingPermissionCount.value > 0) {
      _animationController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializePosition();
    }
  }

  /// Initializes the button's position to the bottom-right corner.
  void _initializePosition() {
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;
    setState(() {
      _position = Offset(
        screenSize.width - _buttonSize - _padding,
        screenSize.height - _buttonSize - safeArea.bottom - _padding,
      );
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildAnimatedButton(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            // Clamp the new position to stay within screen bounds
            final double newX = details.offset.dx.clamp(
              safeArea.left,
              screenSize.width - _buttonSize - safeArea.right,
            );
            final double newY = details.offset.dy.clamp(
              safeArea.top,
              screenSize.height - _buttonSize - safeArea.bottom,
            );
            _position = Offset(newX, newY);
            // No _isAtTop logic needed now, simplifies state.
          });
        },
        child: _buildAnimatedButton(),
      ),
    );
  }

  /// Builds the animated button with the rotation effect.
  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: _NotificationButtonContent(
        notificationController: _notificationController,
        buttonSize: _buttonSize,
        badgeHeight: _badgeHeight,
        primaryButtonColor: _primaryButtonColor,
        badgeColor: _badgeColor,
        fontFamily: _fontFamily,
      ),
    );
  }
}

/// A private widget to encapsulate the button's visual content, including the icon and badge.
class _NotificationButtonContent extends StatelessWidget {
  const _NotificationButtonContent({
    Key? key,
    required NotificationController notificationController,
    required double buttonSize,
    required double badgeHeight,
    required Color primaryButtonColor,
    required Color badgeColor,
    required String fontFamily,
  })  : _notificationController = notificationController,
        _buttonSize = buttonSize,
        _badgeHeight = badgeHeight,
        _primaryButtonColor = primaryButtonColor,
        _badgeColor = badgeColor,
        _fontFamily = fontFamily,
        super(key: key);

  final NotificationController _notificationController;
  final double _buttonSize;
  final double _badgeHeight;
  final Color _primaryButtonColor;
  final Color _badgeColor;
  final String _fontFamily;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          // Changed from AnimatedContainer as color animation is removed
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: _primaryButtonColor, // Consistent primary color
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // More subtle shadow
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => Get.toNamed(AppRoutes.studentPermission),
              child: Obx(() {
                return Icon(
                  _notificationController.pendingPermissionCount.value > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: Colors.white, // Icon color is always white
                  size: _buttonSize * 0.5, // Make icon size proportional
                );
              }),
            ),
          ),
        ),
        // Notification Badge
        Obx(() {
          final count = _notificationController.pendingPermissionCount.value;
          if (count > 0) {
            return Positioned.directional(
              textDirection: Directionality.of(context),
              top: (_buttonSize / 2) -
                  (_badgeHeight / 2) -
                  10, // Adjust badge position
              start: 40, // Adjust badge position
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2), // Horizontal padding for better fit
                  decoration: BoxDecoration(
                    color: _badgeColor,
                    borderRadius: BorderRadius.circular(
                        _badgeHeight / 2), // Fully rounded corners
                  ),
                  constraints: BoxConstraints(
                    minWidth: _badgeHeight,
                    minHeight: _badgeHeight,
                  ),
                  child: Center(
                    child: Text(
                      _notificationController.formattedPendingCount,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10, // Slightly smaller font for badge
                        fontWeight: FontWeight.bold,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),
      ],
    );
  }
}
