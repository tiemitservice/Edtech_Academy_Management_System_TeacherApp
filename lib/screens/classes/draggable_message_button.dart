import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Make sure these import paths are correct for your project structure
import 'package:school_management_system_teacher_app/controllers/notification_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

/// A draggable floating button with a "jiggle" animation for notifications.
class DraggableNotificationButton extends StatefulWidget {
  const DraggableNotificationButton({Key? key}) : super(key: key);

  @override
  State<DraggableNotificationButton> createState() =>
      _DraggableNotificationButtonState();
}

// 1. Add the mixin for the AnimationController
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
  bool _isAtTop = false;
  bool _isInitialized = false;

  // --- UI Constants ---
  static const double _buttonSize = 56.0;
  static const double _badgeHeight = 22.0;
  static const double _padding = 16.0;
  static const Color _primaryBlue = Color(0xFF1468C7);
  static const Color _badgeColor = Color(0xFFE74C3C);
  static const String _fontFamily = AppFonts.fontFamily;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the animation controller and jiggle animation
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
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
    ]).animate(_animationController);

    // Listen to the notification count to start/stop the animation
    _notificationController.pendingPermissionCount.listen((count) {
      if (!mounted) return;
      if (count > 0) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    });

    // Check the initial state
    if (_notificationController.pendingPermissionCount.value > 0) {
      _animationController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
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
        feedback: _buildButton(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            double newX = details.offset.dx.clamp(
              safeArea.left,
              screenSize.width - _buttonSize - safeArea.right,
            );
            double newY = details.offset.dy.clamp(
              safeArea.top,
              screenSize.height - _buttonSize - safeArea.bottom,
            );
            _position = Offset(newX, newY);
            _isAtTop = newY <= (safeArea.top + 100);
          });
        },
        // 3. Apply the jiggle animation to the visible button
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              alignment: Alignment.topCenter,
              child: child,
            );
          },
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
              onTap: () => Get.toNamed(AppRoutes.studentPermission),
              child: SizedBox(
                width: _buttonSize,
                height: _buttonSize,
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
        // Simplified reactive badge
        Obx(() {
          final count = _notificationController.pendingPermissionCount.value;
          if (count > 0) {
            return Positioned.directional(
              textDirection: Directionality.of(context),
              top: (_buttonSize / 2) - (_badgeHeight / 2),
              start: 44,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _badgeColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: _badgeHeight,
                    minHeight: _badgeHeight,
                  ),
                  child: Center(
                    child: Text(
                      _notificationController.formattedPendingCount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
