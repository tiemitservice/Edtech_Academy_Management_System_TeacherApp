import 'package:flutter/material.dart';

class BottomMessageWidget extends StatelessWidget {
  final String message;
  final bool
      isSuccess; // Add a flag to differentiate between error and success messages

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  const BottomMessageWidget(
      {super.key, required this.message, required this.isSuccess});

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green
                : Colors.red, // Conditional color based on message type
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4), // Shadow position
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.info, // Conditional icon
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
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

// Function to display the custom bottom message
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

  // Automatically remove the message after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    entry.remove();
  });
}
