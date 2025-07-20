import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_management_system_teacher_app/Widget/super_profile_picture.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/screens/classes/draggable_message_button.dart';

// Import your CustomDrawer widget
import 'package:school_management_system_teacher_app/screens/home/custom_drawer.dart'; // Make sure this path is correct!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // AuthController is still needed here to fetch user data and perform logout
  final AuthController authController = Get.find<AuthController>();

  // --- GlobalKey for ScaffoldState ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- State Variables ---
  String? imageUrl; // For header profile picture
  String? fullName; // For header full name
  String? userEmail; // For drawer email (fetched from AuthController)

  bool isLoading = true; // Controls the main profile/content loader
  bool isExpanded = false; // Controls the "My Schedule" card expansion
  late AnimationController _arrowController;
  List<Map<String, dynamic>> _teacherClassesToday = [];
  bool _isLoadingClasses = true; // Controls the "My Schedule" class list loader
  String? _currentUserEmail;
  String? _currentStaffId;
  Map<String, String> _subjectsMap = {};

  // --- UI Constants ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _cardBackground = Colors.white;
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _mediumText = Color(0xFF7F8C8D);
  static const Color _borderGrey = Color(0xFFE0E6ED);
  static const Color _skeletonBaseColor = Color(0xFFE0E0E0);
  static const Color _skeletonHighlightColor = Color(0xFFF5F5F5);

  // --- Font Family Constant ---
  static const String _fontFamily =
      AppFonts.fontFamily; // Assuming AppFonts.fontFamily maps to this

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  // --- Data Fetching Logic ---

  Future<void> _loadInitialData() async {
    // isLoading is set to true at the start of fetchUserProfile
    await fetchUserProfile();
    if (_currentStaffId != null && _currentStaffId!.isNotEmpty) {
      await _fetchSubjects(); // Fetch subjects first
      await _fetchAndFilterTeacherClasses();
    } else {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      // Get user email and staff ID from AuthController
      _currentUserEmail = await authController.getUserEmail();
      _currentStaffId = await authController.getStaffId();

      // Retrieve display name, email, and image URL directly from AuthController's
      // observable properties. These properties are expected to be updated by
      // your AuthController's login/data fetching logic.
      setState(() {
        // Use setState here to ensure UI updates with current AuthController values
        fullName = authController.userName.value;
        userEmail = authController.userEmail.value;
        imageUrl = authController.userImageUrl.value;
      });

      if (_currentUserEmail == null ||
          _currentUserEmail!.isEmpty ||
          _currentStaffId == null ||
          _currentStaffId!.isEmpty) {
        print("User email or Staff ID is empty, cannot fetch profile.");
        if (mounted) {
          setState(() {
            isLoading = false;
            _isLoadingClasses = false;
          });
        }
        return;
      }

      // You can still perform an API call here if you need to fetch additional
      // or more up-to-date user details specifically for the HomeScreen,
      // but ensure it doesn't conflict with AuthController's primary role.
      // For this scenario, we'll assume AuthController is the source of truth
      // for the basic profile info (name, email, image URL) that goes to the drawer.

      // Example of an API call if needed (otherwise, remove this block):
      final response =
          await http.get(Uri.parse('http://188.166.242.109:5000/api/staffs'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> staffList = jsonData['data'];

        final user = staffList.firstWhereOrNull(
          (staff) => staff['email'] == _currentUserEmail,
        );

        if (user != null) {
          if (mounted) {
            setState(() {
              // Update state variables with potentially more recent data from this API call
              // or ensure AuthController's values are synchronized with this.
              imageUrl = user['image'] as String? ??
                  imageUrl; // Prefer API data, fallback to existing
              fullName = user['en_name'] as String? ??
                  fullName; // Prefer API data, fallback to existing
              // userEmail = user['email'] as String? ?? userEmail; // If you want to update email from this API call too
              isLoading = false; // Set to false after successful data load
            });
          }
        } else {
          print("User not found with email: $_currentUserEmail");
          if (mounted) {
            setState(() {
              isLoading = false; // Set to false if user not found
              _isLoadingClasses = false;
            });
          }
        }
      } else {
        print('Failed to load staff data: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false; // Set to false on API error
            _isLoadingClasses = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // Set to false on network/other errors
          _isLoadingClasses = false;
        });
      }
    }
  }

  // New method to fetch subjects
  Future<void> _fetchSubjects() async {
    try {
      final response =
          await http.get(Uri.parse('http://188.166.242.109:5000/api/subjects'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> subjectsApi = jsonData['data'];
        if (mounted) {
          setState(() {
            _subjectsMap = {
              for (var subjectJson in subjectsApi)
                subjectJson['_id'].toString(): subjectJson['name'].toString()
            };
          });
        }
      } else {
        print('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _fetchAndFilterTeacherClasses() async {
    if (_currentStaffId == null || _currentStaffId!.isEmpty) {
      if (mounted) setState(() => _isLoadingClasses = false);
      return;
    }

    if (mounted) setState(() => _isLoadingClasses = true);

    try {
      final response =
          await http.get(Uri.parse('http://188.166.242.109:5000/api/classes'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> allClasses = jsonData['data'];

        final String today = DateFormat('EEEE', 'en_US').format(DateTime.now());

        final List<Map<String, dynamic>> filteredClasses = [];
        for (var classItem in allClasses) {
          final classStaffId =
              classItem['staff'] as String?; // Directly access staff ID

          final classDays = classItem['day_class'];

          if (classStaffId == _currentStaffId && classDays is List) {
            if (classDays.any(
                (day) => day.toString().toLowerCase() == today.toLowerCase())) {
              if (classItem is Map<String, dynamic>) {
                classItem['students'] =
                    classItem['students'] is List ? classItem['students'] : [];
                filteredClasses.add(classItem);
              }
            }
          }
        }

        setState(() {
          _teacherClassesToday = filteredClasses;
          _isLoadingClasses = false;
        });
      } else {
        print('Failed to load classes: ${response.statusCode}');
        setState(() {
          _isLoadingClasses = false;
          _teacherClassesToday = [];
        });
      }
    } catch (e) {
      print('Error fetching or filtering classes: $e');
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
          _teacherClassesToday = [];
        });
      }
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: _primaryBlue,
    ));

    return Scaffold(
      backgroundColor: _primaryBlue,
      key: _scaffoldKey, // Assign the GlobalKey here
      // Pass data to CustomDrawer using the HomeScreen's State variables
      drawer: CustomDrawer(
        userDisplayName: fullName ?? 'Guest', // Pass fetched full name
        // userDisplayEmail: , // Pass fetched email
        userDisplayImageUrl: imageUrl ?? '', // Pass fetched image URL
        onLogout: () {
          // This callback will trigger the logout action in AuthController
          authController.logout();
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _lightBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: isLoading
                      ? _buildSkeletonLoader()
                      : _buildContentListView(),
                ),
              ),
            ],
          ),
          DraggableNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildContentListView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        _buildMainCard(
          image: 'assets/images/home/teacher_check.svg',
          title: 'Students Management',
          subtitle:
              'Manage students in my classes: attendance, and Student\'s Permission.',
          onTap: () {
            Get.toNamed(AppRoutes.classManagement);
          },
        ),
        _buildMainCard(
          image: 'assets/images/home/permission.svg',
          title: 'Ask for Permission',
          subtitle: 'Submit permission requests and receive admin approval.',
          onTap: () {
            Get.toNamed(AppRoutes.myPermission);
          },
        ),
        _buildExpandableCard(), // This is the card we are focusing on
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Modified IconButton to open the drawer
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer(); // Open the drawer
              },
            ),
            SvgPicture.asset(
              'assets/images/logo/leading_logo.svg',
              width: 180,
            ),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.profile),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isLoading
                    ? Shimmer.fromColors(
                        baseColor: _skeletonBaseColor,
                        highlightColor: _skeletonHighlightColor,
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                        ),
                      )
                    : SuperProfilePicture(
                        imageUrl: imageUrl, // Use the state variable here
                        fullName: fullName, // Use the state variable here
                        radius: 24,
                        backgroundColor: Colors.white,
                        textColor: _primaryBlue,
                        fontFamily: _fontFamily,
                      ),
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
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderGrey, width: 1),
      ),
      color: _cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SvgPicture.asset(image, width: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _darkText,
                        fontFamily: _fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _mediumText,
                        fontFamily: _fontFamily,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: _mediumText),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildExpandableCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderGrey, width: 1),
      ),
      color: _cardBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SvgPicture.asset('assets/images/home/calendar.svg',
                      width: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Schedule',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: _darkText,
                              fontFamily: _fontFamily),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "View classes you're scheduled to teach today.",
                          style: const TextStyle(
                              fontSize: 13,
                              color: _mediumText,
                              fontFamily: _fontFamily),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns:
                        Tween(begin: 0.0, end: 0.25).animate(_arrowController),
                    child: Icon(
                      isExpanded
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: _mediumText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            child:
                isExpanded ? _buildExpandedContent() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _borderGrey,
            width: isExpanded ? 1.0 : 0.0,
          ),
        ),
      ),
      child: _isLoadingClasses
          ? _buildExpandedContentSkeleton()
          : _teacherClassesToday.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: Text(
                    'No classes scheduled for you today.',
                    style: TextStyle(
                        color: _mediumText,
                        fontSize: 14,
                        fontFamily: _fontFamily),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: List.generate(_teacherClassesToday.length, (index) {
                    final classData = _teacherClassesToday[index];
                    final String subjectId =
                        classData['subject'] as String? ?? '';
                    final String subjectName =
                        _subjectsMap[subjectId] ?? 'Unknown Subject';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildClassTile(classData, subjectName),
                        if (index < _teacherClassesToday.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(color: _borderGrey, height: 1),
                          ),
                      ],
                    );
                  }),
                ),
    );
  }

  Widget _buildClassTile(Map<String, dynamic> classData, String subjectName) {
    String className = classData['name'] as String? ?? 'Unknown Class';
    int studentCount = (classData['students'] as List?)?.length ?? 0;
    String? classId = classData['_id'] as String?;

    return InkWell(
      onTap: () {
        if (classId != null) {
          Get.toNamed(
            AppRoutes.teacherManagement,
            arguments: {
              'classId': classId,
              'className': className,
              'studentsCount': studentCount.toString(),
              'subjectName': subjectName,
            },
          );
        } else {
          Get.snackbar(
            'Error',
            'Could not open class details. Class ID is missing.',
            snackPosition: SnackPosition.BOTTOM,
            messageText: Text(
                'Could not open class details. Class ID is missing.',
                style: const TextStyle(
                    color: Colors.white, fontFamily: _fontFamily)),
            titleText: Text('Error',
                style: const TextStyle(
                    color: Colors.white, fontFamily: _fontFamily)),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded,
                  color: _primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _darkText,
                        fontFamily: _fontFamily),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subjectName,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _mediumText,
                        fontFamily: _fontFamily),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$studentCount Students',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _mediumText,
                        fontFamily: _fontFamily),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: _mediumText),
          ],
        ),
      ),
    );
  }

  // --- SKELETON LOADER WIDGETS (No font changes needed here) ---

  Widget _buildExpandedContentSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        children: List.generate(2, (index) => _buildClassTileSkeleton()),
      ),
    );
  }

  Widget _buildClassTileSkeleton() {
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(3, (index) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: _skeletonBaseColor,
        highlightColor: _skeletonHighlightColor,
        child: SizedBox(
          height: 90,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
