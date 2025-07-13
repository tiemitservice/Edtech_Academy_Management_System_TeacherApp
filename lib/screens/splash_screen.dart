import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final _storage = const FlutterSecureStorage();

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 3)); // Show splash briefly

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;

    if (!hasConnection) {
      _showNoConnectionDialog();
      return;
    }

    final token = await _storage.read(key: 'token');
    if (token != null) {
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.onboarding);
    }
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('No Internet',
            style: TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
        content: const Text('Please check your internet connection.',
            style: TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initApp(); // Retry
            },
            child: const Text('Retry',
                style:
                    TextStyle(fontFamily: _fontFamily)), // Apply NotoSerifKhmer
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    const textColor = Colors.black;
    const forTeacherColor = Color(0xFF1469C7);

    const logoPath = 'assets/images/logo/secend_logo.svg';
    const fromLogoPath = 'assets/images/logo/tiem_logo.svg';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: SvgPicture.asset(
                        logoPath,
                        height: 120,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 120),
                const Text(
                  "FOR TEACHER",
                  style: TextStyle(
                      fontSize: 25,
                      color: forTeacherColor,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "from",
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.4),
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  ),
                ),
                const SizedBox(height: 5),
                SvgPicture.asset(
                  fromLogoPath,
                  height: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
