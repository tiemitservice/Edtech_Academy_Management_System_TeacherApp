import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Profile',
            style: TextStyle(color: Colors.black, fontFamily: 'Inter')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                      'assets/images/no_profile_image.png'), // replace with your image path
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.edit, size: 16, color: Color(0xFF1469C7)),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'SOR SI EY',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFE1ECF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'mr.sor.siey@gmail.com',
              style: TextStyle(color: Color(0xFF1469C7), fontFamily: 'Inter'),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Inter',
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: Colors.red),
            title: Text('Logout',
                style: TextStyle(color: Colors.red, fontFamily: 'Inter')),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Are you sure you want to log out from your account?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.black87),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (shouldLogout == true) {
                await authController.deleteToken();
                Get.offAllNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
