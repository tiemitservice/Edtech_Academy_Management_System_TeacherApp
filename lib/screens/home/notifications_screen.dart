import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Make sure you have flutter_svg in your pubspec.yaml

// You might want to define this in a separate file (e.g., models/notification_item.dart)
class NotificationItem {
  final String title;
  final String tag;
  final String description;
  final String date;
  final String iconPath; // Path to your SVG icon

  NotificationItem({
    required this.title,
    required this.tag,
    required this.description,
    required this.date,
    required this.iconPath,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7); // Dominant blue from your previous code
  static const Color _cardBackground = Colors.white; // White for the notification cards
  static const Color _darkText = Color(0xFF2C3E50); // Dark text color
  static const Color _mediumText = Color(0xFF7F8C8D); // Medium grey text
  static const Color _greenTag = Color(0xFF27AE60); // Green for the tag
  static const Color _borderGrey = Color(0xFFE0E6ED); // Subtle border color

  // --- Font Family (Adjust if your font is different) ---
  static const String _fontFamily = 'NotoSerifKhmer'; // Assuming this is still your preferred font

  // --- Mock Data ---
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Student Request for Leave",
      tag: "Pending",
      description: "John Doe has requested a leave for 3 days due to family reasons.",
      date: "Mon, 10/06/2025",
      iconPath: 'assets/images/placeholder_icon_1.svg', // Replace with actual paths
    ),
    NotificationItem(
      title: "New Assignment Graded",
      tag: "Completed",
      description: "Mathematics assignment 'Algebra Basics' has been graded.",
      date: "Tue, 09/06/2025",
      iconPath: 'assets/images/placeholder_icon_2.svg',
    ),
    NotificationItem(
      title: "School Event Reminder",
      tag: "Upcoming",
      description: "Annual Sports Day on 15th July 2025 at school playground.",
      date: "Wed, 08/06/2025",
      iconPath: 'assets/images/placeholder_icon_3.svg',
    ),
    NotificationItem(
      title: "Fee Payment Due",
      tag: "Urgent",
      description: "Second semester fee payment is due by 20th June 2025.",
      date: "Thu, 07/06/2025",
      iconPath: 'assets/images/placeholder_icon_4.svg',
    ),
    NotificationItem(
      title: "Teacher Meeting Scheduled",
      tag: "Important",
      description: "Staff meeting to discuss curriculum changes on Friday, 13th June.",
      date: "Fri, 06/06/2025",
      iconPath: 'assets/images/placeholder_icon_5.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBlue, // Background behind the white content area
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // This expands to fill the remaining space below the AppBar with the rounded white background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: _cardBackground, // White background for the main content
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the custom AppBar for the screen.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryBlue,
      elevation: 0, // Flat app bar
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () {
          // Implement navigation back, e.g., Navigator.pop(context);
        },
      ),
      title: const Text(
        "MRE NOTIFICATIONS", // Or "NOTIFICATIONS"
        style: TextStyle(
          color: Colors.white,
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        // Example: Add more icons if needed based on the blurred image
        IconButton(
          icon: const Icon(Icons.wifi, color: Colors.white, size: 20),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.battery_full, color: Colors.white, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Builds a single notification card.
  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      elevation: 0, // No default shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderGrey, width: 1), // Subtle border
      ),
      color: _cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Handle notification card tap, e.g., navigate to detail screen
          print('Tapped on notification: ${notification.title}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                            fontFamily: _fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        // Green Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _greenTag.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _greenTag,
                              fontFamily: _fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _mediumText,
                        fontFamily: _fontFamily,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _mediumText,
                        fontFamily: _fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon on the right side
              SvgPicture.asset(
                notification.iconPath,
                height: 50, // Adjust size as needed
                width: 50,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the empty state view when there are no notifications.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/empty_notifications.svg', // Replace with a suitable empty state SVG
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'No New Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkText,
                fontFamily: _fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You are all caught up! Check back later for updates.',
              style: TextStyle(
                fontSize: 14,
                color: _mediumText,
                fontFamily: _fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}