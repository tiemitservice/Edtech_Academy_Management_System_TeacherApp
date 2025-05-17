import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _arrowController.forward();
      } else {
        _arrowController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: const Color(0xFF1469C7),
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF1469C7),
      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMainCard(
                    image: 'assets/images/home/teacher_check.svg',
                    title: 'Students Management',
                    subtitle:
                        'Manage students in my classes: scores, attendance, and permissions.',
                  ),
                  _buildMainCard(
                    image: 'assets/images/home/check_atd.svg',
                    title: 'Teacher Permission',
                    subtitle:
                        'Submit permission requests and receive admin approval.',
                  ),
                  _buildExpandableCard(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.menu, color: Colors.white),
            SvgPicture.asset(
              'assets/images/logo/leading_logo.svg',
              width: 230,
            ),
            GestureDetector(
              onTap: () {
                Get.toNamed(AppRoutes.profile);
              },
              child: const CircleAvatar(
                radius: 24,
                backgroundImage:
                    AssetImage('assets/images/no_profile_image_w.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Card(
      shadowColor: const Color.fromARGB(100, 0, 0, 0),
      surfaceTintColor: Colors.white,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SvgPicture.asset(image, width: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard() {
    return Card(
      shadowColor: const Color.fromARGB(100, 0, 0, 0),
      surfaceTintColor: Colors.white,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _toggleExpand,
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/home/calendar.svg',
                    width: 60,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Teacher Classes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'Inter')),
                        SizedBox(height: 4),
                        Text("View the classes I'm scheduled to teach.",
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns:
                        Tween(begin: 0.0, end: 0.25).animate(_arrowController),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: isExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        const Divider(color: Colors.black26),
                        _buildClassTile('English 1', 27),
                        const Divider(color: Colors.black26),
                        _buildClassTile('English 2', 25),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassTile(String className, int studentCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF1469C7), size: 24),
        ),
        title: Text(
          className,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Text(
          '$studentCount Students',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontFamily: 'Inter',
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.black45,
        ),
        onTap: () {
          // TODO: Add your navigation logic here
          print('object');
        },
      ),
    );
  }
}
