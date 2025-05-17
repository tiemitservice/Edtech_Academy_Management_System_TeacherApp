import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 4;

  late final List<OnboardingPage> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    const svgImage1 = 'assets/images/logo/main_logo.svg';
    const svgImage2 = 'assets/images/onboarding/teacher_check.svg';
    const svgImage3 = 'assets/images/onboarding/teacher_read.svg';
    const svgImage4 = 'assets/images/onboarding/teacher.svg';

    _pages = [
      OnboardingPage(
        image: svgImage1,
        title: 'Welcome to EdTech Academy',
        description:
            'The all-in-one platform for teachers and staff to manage their daily tasks efficiently.',
      ),
      OnboardingPage(
        image: svgImage2,
        title: 'Manage Your Classes',
        description:
            'View your class schedule, student lists, and course materials all in one place.',
      ),
      OnboardingPage(
        image: svgImage3,
        title: 'Track Attendance',
        description:
            'Easily mark and monitor student attendance with just a few taps.',
      ),
      OnboardingPage(
        image: svgImage4,
        title: 'Request Permissions',
        description:
            'Submit and track leave requests and other administrative permissions seamlessly.',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light mode
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Light mode overlay
        actions: [
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF1469C7), // Light mode blue
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _numPages,
                itemBuilder: (context, index) {
                  return _buildPage(index);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_numPages, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Color(0xFF1469C7)
                          : Color(0xFF1469C7).withOpacity(0.2),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _numPages - 1) {
                      _navigateToLogin();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1469C7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _currentPage == _numPages - 1 ? 'Continue' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Always white text
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: _pages[index].image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SvgPicture.asset(
                      _pages[index].image,
                      fit: BoxFit.contain,
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(height: 40),
          Text(
            _pages[index].title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1469C7), // Keep your branded color
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _pages[index].description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Light mode text
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}
