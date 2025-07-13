import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/routes/app_routes.dart';
import 'package:school_management_system_teacher_app/screens/auth/forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isFormValid = false;

  // --- Font Family Constant ---
  static const String _fontFamily = 'KantumruyPro';

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    setState(() {
      _rememberMe = rememberMe;
    });

    if (rememberMe && savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final confirm = await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          isScrollControlled: true,
          backgroundColor:
              Colors.transparent, // Important to allow custom shape
          builder: (context) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 30,
                  left: 30,
                  right: 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle,
                        color: Color(0xFF1469C7), size: 60),
                    const SizedBox(height: 10),
                    const Text(
                      'Continue with',
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                    ),
                    const SizedBox(height: 5),
                    Text(
                      savedEmail,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1469C7),
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(9, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1469C7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _emailController.text = savedEmail;
                              _passwordController.text = savedPassword;
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1469C7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                  fontFamily: _fontFamily,
                                  color: Colors.white), // Apply NotoSerifKhmer
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1469C7)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Switch Account',
                              style: TextStyle(
                                  color: Color(0xFF1469C7),
                                  fontFamily:
                                      _fontFamily), // Apply NotoSerifKhmer
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );

        if (confirm == false) {
          setState(() {
            _emailController.clear();
            _passwordController.clear();
            _rememberMe = false;
          });
        }
      });
    }
  }

  Future<void> _saveCredentialsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('savedEmail', _emailController.text.trim());
      await prefs.setString('savedPassword', _passwordController.text.trim());
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    final loginUrl = Uri.parse(
      'https://edtech-academy-management-system-server.onrender.com/api/login',
    );
    final staffUrl = Uri.parse(
        'https://edtech-academy-management-system-server.onrender.com/api/staffs');
    final data = {'email': email, 'password': password};
    final AuthController _authController = AuthController();

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('userId', responseData['user']['id']);
        await prefs.setString('token', responseData['token']);
        await prefs.setString('email', email);
        await prefs.setString('username', responseData['user']['name']);

        await _authController.saveUserId(responseData['user']['id']);
        await _authController.saveUserEmail(email);
        await _authController.saveUserName(responseData['user']['name']);
        await _authController.saveToken(responseData['token']);

        final staffResponse = await http.get(staffUrl);

        if (staffResponse.statusCode == 200) {
          final staffData = json.decode(staffResponse.body);
          final List<dynamic> staffs = staffData['data'];

          final matchingStaff = staffs.firstWhereOrNull(
            (staff) => staff['email'] == email,
          );

          if (matchingStaff != null) {
            await _authController.saveStaffId(matchingStaff['_id']);
            print("Staff ID saved: ${matchingStaff['_id']}");
          } else {
            print("No staff found with email: $email");
          }
        } else {
          print(
              "Failed to load staff data: ${staffResponse.statusCode} ${staffResponse.body}");
        }

        await _saveCredentialsIfNeeded();
        Get.offNamed(AppRoutes.home);
      } else {
        final responseData = json.decode(response.body);
        _showMessage(responseData['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      _showMessage('Connection error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: const TextStyle(
                  fontFamily: _fontFamily))), // Apply NotoSerifKhmer
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Theme(
            data: Theme.of(context).copyWith(
              // Apply default font family to the entire theme subtree within this screen
              textTheme:
                  Theme.of(context).textTheme.apply(fontFamily: _fontFamily),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Color(0xFF1469C7),
                selectionColor: Color(0xFF90CAF9),
                selectionHandleColor: Color(0xFF1469C7),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logo/secend_logo.svg',
                    height: screenWidth * 0.3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    cursorColor: const Color(0xFF1469C7),
                    style: const TextStyle(
                        fontFamily: _fontFamily,
                        color: Colors.black), // Apply NotoSerifKhmer
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      floatingLabelStyle: const TextStyle(
                          color: Color(0xFF1469C7),
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF1469C7), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'email@example.com',
                      hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                      suffixIcon: const Icon(Icons.email_rounded,
                          color: Color(0xFF1469C7)),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Email is required' // Validation message will inherit theme font or fallback
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    cursorColor: const Color(0xFF1469C7),
                    style: const TextStyle(
                        fontFamily: _fontFamily,
                        color: Colors.black), // Apply NotoSerifKhmer
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      floatingLabelStyle: const TextStyle(
                          color: Color(0xFF1469C7),
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF1469C7), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: _fontFamily), // Apply NotoSerifKhmer
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: const Color(0xFF1469C7),
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Password is required' // Validation message will inherit theme font or fallback
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            value: _rememberMe,
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? false),
                            activeColor: const Color(0xFF1469C7),
                          ),
                          const Text(
                            'Remember Me',
                            style: TextStyle(
                                fontFamily: _fontFamily,
                                color: Colors.black), // Apply NotoSerifKhmer
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                  email: _emailController.text),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              fontFamily: _fontFamily,
                              color: Color(0xFF1469C7)), // Apply NotoSerifKhmer
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isFormValid && !_isLoading) ? _signIn : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1469C7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
