import 'package:flutter/material.dart';

class DraggableMessageButton extends StatefulWidget {
  final Function()? onPressed;

  const DraggableMessageButton({Key? key, this.onPressed}) : super(key: key);

  @override
  State<DraggableMessageButton> createState() => _DraggableMessageButtonState();
}

class _DraggableMessageButtonState extends State<DraggableMessageButton> {
  Offset? position;
  bool isAtTop = false;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    const double buttonSize = 56;

    position ??= Offset(
      screenSize.width - buttonSize - 10,
      screenSize.height - buttonSize - 10,
    );

    return Positioned(
      left: position!.dx,
      top: position!.dy,
      child: Draggable(
        feedback: _buildButton(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            double newX =
                details.offset.dx.clamp(0.0, screenSize.width - buttonSize);
            double newY = details.offset.dy
                .clamp(0.0, screenSize.height - buttonSize - 50);
            position = Offset(newX, newY);

            // Change color if dragged to top
            isAtTop = newY <= 100;
          });
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    return FloatingActionButton(
      elevation: 0,
      highlightElevation: 0,
      onPressed: widget.onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Message Sent!")),
            );
          },
      backgroundColor: isAtTop
          ? const Color.fromARGB(255, 255, 255, 255) // White when at top
          : const Color(0xFF1468C7), // Default color
      child: Icon(
        Icons.notifications_none_rounded,
        color: isAtTop
            ? const Color(0xFF1468C7) // Blue icon when at top
            : const Color(0xFFFFFFFF), // White icon normally
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
