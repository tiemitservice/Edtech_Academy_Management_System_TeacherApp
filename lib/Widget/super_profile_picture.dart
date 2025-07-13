import 'package:flutter/material.dart';

class SuperProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final String? fullName;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final String? fontFamily; // <--- ADDED: fontFamily parameter

  const SuperProfilePicture({
    super.key,
    this.imageUrl,
    this.fullName,
    this.radius = 24,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.borderColor = Colors.blue,
    this.borderWidth = 2,
    this.fontFamily, // <--- ADDED: Initialize fontFamily
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prioritize displaying the image if imageUrl is provided and not empty.
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    // 2. If no image, try to generate initials from the fullName.
    // Ensure fullName is not null and not just empty spaces
    if (fullName != null && fullName!.trim().isNotEmpty) {
      String initials = '';
      // Split the full name into parts by space and remove any empty strings
      List<String> nameParts =
          fullName!.trim().split(' ').where((s) => s.isNotEmpty).toList();

      if (nameParts.isNotEmpty) {
        // Always take the first initial from the first name part
        initials += nameParts[0][0].toUpperCase();

        // If there's more than one name part, take the first initial of the last name part
        if (nameParts.length > 1) {
          initials += nameParts.last[0].toUpperCase();
        }
      }

      // If we managed to generate any initials, display them
      if (initials.isNotEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor, // Use the provided backgroundColor
          child: Text(
            initials,
            style: TextStyle(
              color: textColor, // Use the provided textColor
              // Adjust font size based on whether it's one or two initials for better fit
              fontSize: radius * (initials.length == 1 ? 1.0 : 0.8),
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily, // <--- APPLIED: Use the passed fontFamily
            ),
          ),
        );
      }
    }

    // 3. Fallback to a generic person icon if no image and no valid name for initials.
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor, // Use the provided backgroundColor
      child: Icon(
        Icons.person,
        color: textColor, // Use the provided textColor for the icon
        size: radius * 0.9, // Icon slightly smaller for better visual
      ),
    );
  }
}
