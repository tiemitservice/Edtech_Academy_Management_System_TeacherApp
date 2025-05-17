import 'package:flutter/material.dart';
class BottomMessageWidget extends StatelessWidget {
  final String message;
  final bool
      isSuccess; // Add a flag to differentiate between error and success messages

  const BottomMessageWidget({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom +
          20, // Adjust position above keyboard
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green
                : Colors.red, // Conditional color
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4), // Shadow position
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.info,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showBottomMessage(BuildContext context, String message,
    {bool isSuccess = false}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => BottomMessageWidget(
      message: message,
      isSuccess: isSuccess,
    ),
  );

  overlay.insert(entry);

  Future.delayed(Duration(seconds: 3), () {
    entry.remove();
  });
}
