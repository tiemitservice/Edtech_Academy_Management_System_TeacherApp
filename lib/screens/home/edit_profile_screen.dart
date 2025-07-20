import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mime/mime.dart'; // Import for MIME type lookup
import 'package:http_parser/http_parser.dart'; // Import for MediaType

import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

// --- Address Data Models ---
class Province {
  final String id;
  final String code;
  final String name; // This will now prioritize English name

  Province({required this.id, required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      print("Warning: Province JSON missing 'properties' key: $json");
      return Province(id: '', code: '', name: 'Invalid Province Data');
    }
    return Province(
      id: properties['ADMIN_ID1'] as String? ?? '',
      code: properties['ADMIN_ID1'] as String? ?? '',
      name: properties['NAME_ENG1'] as String? ?? // Prioritize English name
          properties['NAME1'] as String? ??
          'Unknown Province',
    );
  }
}

class District {
  final String id;
  final String code;
  final String name; // This will now prioritize English name
  final String provinceCode;

  District(
      {required this.id,
      required this.code,
      required this.name,
      required this.provinceCode});

  factory District.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      print("Warning: District JSON missing 'properties' key: $json");
      return District(
          id: '', code: '', name: 'Invalid District Data', provinceCode: '');
    }
    return District(
      id: properties['ADMIN_ID2'] as String? ?? '',
      code: properties['ADMIN_ID2'] as String? ?? '',
      name: properties['NAME_ENG2'] as String? ?? // Prioritize English name
          properties['NAME2'] as String? ??
          'Unknown District',
      provinceCode: properties['ADMIN_ID1'] as String? ?? '',
    );
  }
}

class Commune {
  final String id;
  final String code;
  final String name; // This will now prioritize English name
  final String districtCode;

  Commune(
      {required this.id,
      required this.code,
      required this.name,
      required this.districtCode});

  factory Commune.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      print("Warning: Commune JSON missing 'properties' key: $json");
      return Commune(
          id: '', code: '', name: 'Invalid Commune Data', districtCode: '');
    }
    return Commune(
      id: properties['ADMIN_ID3'] as String? ?? '',
      code: properties['ADMIN_ID3'] as String? ?? '',
      name: properties['NAME_ENG3'] as String? ?? // Prioritize English name
          properties['NAME3'] as String? ??
          'Unknown Commune',
      districtCode: properties['ADMIN_ID2'] as String? ?? '',
    );
  }
}

class Village {
  final String id;
  final String code;
  final String name; // This will now prioritize English name
  final String communeCode;

  Village(
      {required this.id,
      required this.code,
      required this.name,
      required this.communeCode});

  factory Village.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      print("Warning: Village JSON missing 'properties' key: $json");
      return Village(
          id: '', code: '', name: 'Invalid Village Data', communeCode: '');
    }
    return Village(
      id: properties['ADMIN_ID'] as String? ?? '',
      code: properties['ADMIN_ID'] as String? ?? '',
      name: properties['NAME_ENG'] as String? ?? // Prioritize English name
          properties['NAME'] as String? ??
          'Unknown Village',
      communeCode: properties['ADMIN_ID3'] as String? ?? '',
    );
  }
}

// --- Data Model for Position ---
class Position {
  final String id;
  final String name;

  Position({required this.id, required this.name});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Position',
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- Controllers for form fields ---
  late final AuthController authController;

  final TextEditingController _khmerNameController = TextEditingController();
  final TextEditingController _englishNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _positionController =
      TextEditingController(); // Re-added for read-only display

  // --- Address Selection State Variables ---
  List<Province> _allProvinces = [];
  List<District> _allDistricts = [];
  List<Commune> _allCommunes = [];
  List<Village> _allVillages = [];

  List<District> _filteredDistricts = [];
  List<Commune> _filteredCommunes = [];
  List<Village> _filteredVillages = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Commune? _selectedCommune;
  Village? _selectedVillage;

  // --- Profile, Loading, and Saving States ---
  String? _profileImageUrl;
  File? _profileImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading =
      false; // Controls shimmer loading for initial user data fetch
  bool _isSaving = false; // Controls progress indicator for profile update

  String? _userId;
  String? _selectedGender;

  // --- State for positions data ---
  List<Position> _allPositions = [];
  String?
      _currentPositionId; // Stores the position ID from loaded user data (for sending to backend)
  bool _isLoadingPositions = false;
  bool _isLoadingAddressData = false; // New loading state for address JSONs

  // --- Color Palette ---
  static const Color _primaryBlue = Color(0xFF1469C7);
  static const Color _lightGreyBackground = Color(0xFFF8FAFB);
  static const Color _mediumGreyText = Color(0xFF7F8C8D);
  static const Color _darkText = Color(0xFF2C3E50);
  static const Color _borderColor = Color(0xFFE0E6ED);
  static const Color _shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color _shimmerHighlightColor = Color(0xFFF0F0F0);
  static const Color _errorRed = Color(0xFFDC3545);

  // --- Font Family Constant ---
  static const String _fontFamily = AppFonts.fontFamily;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        authController = Get.find<AuthController>();
        _loadAllData(); // Combined loading for user, positions, and address data
      } catch (e) {
        print("ERROR: AuthController not found or other init error: $e");
        Get.snackbar('Initialization Error',
            'Could not load user session. Please ensure you are logged in.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _errorRed,
            colorText: Colors.white,
            // Apply font to snackbar
            messageText: const Text(
                'Could not load user session. Please ensure you are logged in.',
                style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
            titleText: const Text('Initialization Error',
                style:
                    TextStyle(color: Colors.white, fontFamily: _fontFamily)));
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _khmerNameController.dispose();
    _englishNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  // --- Combined Data Loading Function ---
  Future<void> _loadAllData() async {
    if (mounted) {
      setState(() => _isLoading = true); // Start general screen loading
    }
    await _loadAddressJsonData();
    await _fetchPositions();
    await _loadUserData();
    if (mounted) {
      setState(() => _isLoading = false); // End general screen loading
    }
  }

  // --- Load Address JSON Data from Assets ---
  Future<void> _loadAddressJsonData() async {
    if (mounted) {
      setState(() => _isLoadingAddressData = true);
    }
    try {
      final String provincesJson =
          await rootBundle.loadString('assets/data/province.json');
      final String districtsJson =
          await rootBundle.loadString('assets/data/district.json');
      final String communesJson =
          await rootBundle.loadString('assets/data/commune.json');
      final String villagesJson =
          await rootBundle.loadString('assets/data/village.json');

      final List<dynamic> provincesList = json.decode(provincesJson);
      final List<dynamic> districtsList = json.decode(districtsJson);
      final List<dynamic> communesList = json.decode(communesJson);
      final List<dynamic> villagesList = json.decode(villagesJson);

      if (mounted) {
        setState(() {
          _allProvinces =
              provincesList.map((e) => Province.fromJson(e)).toList();
          _allDistricts =
              districtsList.map((e) => District.fromJson(e)).toList();
          _allCommunes = communesList.map((e) => Commune.fromJson(e)).toList();
          _allVillages = villagesList.map((e) => Village.fromJson(e)).toList();
        });
      }
      print("DEBUG: Loaded address data.");
    } catch (e) {
      print("ERROR: Failed to load address JSON data: $e");
      Get.snackbar('Error',
          'Failed to load address data. Please ensure JSON files are correctly added to assets.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text(
              'Failed to load address data. Please ensure JSON files are correctly added to assets.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddressData = false);
      }
    }
  }

  // --- Fetch Positions Function ---
  Future<void> _fetchPositions() async {
    print("DEBUG: _fetchPositions: Attempting to load positions data...");
    if (mounted) {
      setState(() => _isLoadingPositions = true);
    }

    try {
      final uri = Uri.parse(
          'http://188.166.242.109:5000/api/positions');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        if (mounted) {
          setState(() {
            _allPositions =
                data.map((item) => Position.fromJson(item)).toList();
          });
        }
        print(
            "DEBUG: _fetchPositions: Loaded ${_allPositions.length} positions.");
      } else {
        print(
            'ERROR: _fetchPositions: Failed to load positions: Status ${response.statusCode}');
        Get.snackbar('Error',
            'Failed to load positions data. Server responded with status ${response.statusCode}.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _errorRed,
            colorText: Colors.white,
            // Apply font to snackbar
            messageText: Text(
                'Failed to load positions data. Server responded with status ${response.statusCode}.',
                style: const TextStyle(
                    color: Colors.white, fontFamily: _fontFamily)),
            titleText: const Text('Error',
                style:
                    TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      }
    } on SocketException {
      print('ERROR: _fetchPositions: No internet connection.');
      Get.snackbar(
          'Network Error', 'No internet connection to fetch positions.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text('No internet connection to fetch positions.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Network Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } catch (e) {
      print('ERROR: _fetchPositions: Exception caught: $e');
      Get.snackbar(
          'Error', 'An unexpected error occurred while fetching positions: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: Text(
              'An unexpected error occurred while fetching positions: $e',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPositions = false);
      }
    }
  }

  /// Fetches user data from the backend and populates the form fields.
  Future<void> _loadUserData() async {
    print("DEBUG: _loadUserData: Attempting to load user data...");

    try {
      final email = await authController.getUserEmail();
      print("DEBUG: _loadUserData: User email from AuthController: $email");
      if (email.isEmpty) {
        throw Exception("User email not available.");
      }

      final uri = Uri.parse(
          'http://188.166.242.109:5000/api/staffs?email=$email');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];

        if (data.isNotEmpty) {
          final user = data.first;

          _userId = user['_id'];
          _khmerNameController.text = user['kh_name'] ?? '';
          _englishNameController.text = user['en_name'] ?? '';
          _phoneController.text = user['phoneNumber'] ?? '';
          _emailController.text = user['email'] ?? '';
          _selectedGender = user['gender'];

          _currentPositionId =
              user['position'] as String?; // Store the ID for submission
          _positionController.text =
              _formatPositionById(_currentPositionId ?? '');

          _profileImageUrl = user['image'];
          _profileImageFile = null;

          final String userProvinceCode = user['province'] as String? ?? '';
          final String userDistrictCode = user['district'] as String? ?? '';
          final String userCommuneCode = user['commune'] as String? ?? '';
          final String userVillageCode = user['village'] as String? ?? '';

          if (mounted) {
            setState(() {
              _selectedProvince = _allProvinces
                  .firstWhereOrNull((p) => p.code == userProvinceCode);

              _filteredDistricts = _selectedProvince != null
                  ? _allDistricts
                      .where((d) => d.provinceCode == _selectedProvince!.code)
                      .toList()
                  : [];
              _selectedDistrict = _filteredDistricts
                  .firstWhereOrNull((d) => d.code == userDistrictCode);

              _filteredCommunes = _selectedDistrict != null
                  ? _allCommunes
                      .where((c) => c.districtCode == _selectedDistrict!.code)
                      .toList()
                  : [];
              _selectedCommune = _filteredCommunes
                  .firstWhereOrNull((c) => c.code == userCommuneCode);

              _filteredVillages = _selectedCommune != null
                  ? _allVillages
                      .where((v) => v.communeCode == _selectedCommune!.code)
                      .toList()
                  : [];
              _selectedVillage = _filteredVillages
                  .firstWhereOrNull((v) => v.code == userVillageCode);
            });
          }

          print(
              "DEBUG: _loadUserData: Data populated. Current Image URL: $_profileImageUrl");
        } else {
          Get.snackbar('Warning', 'No user data found for this email.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              // Apply font to snackbar
              messageText: const Text('No user data found for this email.',
                  style:
                      TextStyle(color: Colors.white, fontFamily: _fontFamily)),
              titleText: const Text('Warning',
                  style:
                      TextStyle(color: Colors.white, fontFamily: _fontFamily)));
          print(
              "WARNING: _loadUserData: Data array is empty for email: $email");
        }
      } else {
        Get.snackbar(
            'Error', 'Failed to load profile. Status: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _errorRed,
            colorText: Colors.white,
            // Apply font to snackbar
            messageText: Text(
                'Failed to load profile. Status: ${response.statusCode}',
                style: const TextStyle(
                    color: Colors.white, fontFamily: _fontFamily)),
            titleText: const Text('Error',
                style:
                    TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      }
    } on SocketException {
      Get.snackbar(
          'Network Error', 'No internet connection. Please check your network.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text(
              'No internet connection. Please check your network.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Network Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } catch (e) {
      Get.snackbar('Error', 'Error loading profile: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: Text('Error loading profile: $e',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      print("ERROR: _loadUserData: Exception caught: $e");
    } finally {
      // _isLoading is handled by _loadAllData
    }
  }

  // --- Utility Functions for Cascading Address Dropdowns ---
  void _updateFilteredDistricts(String? provinceCode) {
    if (mounted) {
      setState(() {
        _filteredDistricts = provinceCode != null
            ? _allDistricts
                .where((d) => d.provinceCode == provinceCode)
                .toList()
            : [];
        _selectedDistrict = null; // Reset child selection
        _filteredCommunes = []; // Reset grandchild
        _selectedCommune = null;
        _filteredVillages = []; // Reset great-grandchild
        _selectedVillage = null;
      });
    }
  }

  void _updateFilteredCommunes(String? districtCode) {
    if (mounted) {
      setState(() {
        _filteredCommunes = districtCode != null
            ? _allCommunes.where((c) => c.districtCode == districtCode).toList()
            : [];
        _selectedCommune = null; // Reset child selection
        _filteredVillages = []; // Reset grandchild
        _selectedVillage = null;
      });
    }
  }

  void _updateFilteredVillages(String? communeCode) {
    if (mounted) {
      setState(() {
        _filteredVillages = communeCode != null
            ? _allVillages.where((v) => v.communeCode == communeCode).toList()
            : [];
        _selectedVillage = null; // Reset child selection
      });
    }
  }

  // --- Utility Function to format position by ID (now used for display) ---
  String _formatPositionById(String id) {
    final position = _allPositions.firstWhereOrNull((item) => item.id == id);
    return position?.name ?? 'N/A';
  }

  Future<void> _pickImage() async {
    print("DEBUG: _pickImage: Showing image source bottom sheet.");
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Profile Photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  fontFamily: _fontFamily, // Apply NotoSerifKhmer
                ),
              ),
              const SizedBox(height: 20),
              _buildImageOption(
                icon: Icons.photo_library,
                text: 'Pick from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageSource(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _buildImageOption(
                icon: Icons.camera_alt,
                text: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageSource(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _borderColor),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkText,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily, // Apply NotoSerifKhmer
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: _lightGreyBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryBlue, size: 24),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: _darkText,
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageSource(ImageSource source) async {
    print("DEBUG: _pickImageSource: Attempting to pick image from $source.");
    try {
      final pickedFile =
          await _picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        print(
            "DEBUG: _pickImageSource: Image selected. Path: ${pickedFile.path}");
        if (mounted) {
          setState(() {
            _profileImageFile = File(pickedFile.path);
            _profileImageUrl = null; // Clear URL if a new file is picked
          });
        }
        print("DEBUG: _profileImageFile updated for preview.");
      } else {
        print("DEBUG: _pickImageSource: Image picking cancelled by user.");
      }
    } on PlatformException catch (e) {
      print("ERROR: _pickImageSource: PlatformException during image pick: $e");
      Get.snackbar('Permission Denied',
          'Please grant permission to access photos/camera.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text(
              'Please grant permission to access photos/camera.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Permission Denied',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } catch (e) {
      print("ERROR: _pickImageSource: General error during image pick: $e");
      Get.snackbar('Error', 'Could not pick image. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text('Could not pick image. Please try again.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    }
  }

  Future<void> _updateProfile() async {
    print("DEBUG: _updateProfile: Initiating profile update.");
    // --- Validation ---
    if (_khmerNameController.text.trim().isEmpty ||
        _englishNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedGender == null ||
        _currentPositionId ==
            null || // Validate that a position ID is available
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedCommune == null ||
        _selectedVillage == null) {
      Get.snackbar('Missing Fields', 'Please fill in all required fields.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text('Please fill in all required fields.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Missing Fields',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      print("ERROR: _updateProfile: Missing required fields.");
      return;
    }

    final userId = _userId;
    if (userId == null) {
      Get.snackbar('Error', 'User ID is missing. Cannot update profile.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text('User ID is missing. Cannot update profile.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      print("ERROR: _updateProfile: User ID is null.");
      return;
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }
    print("DEBUG: _updateProfile: _isSaving set to true.");

    try {
      final uri = Uri.parse(
          'http://188.166.242.109:5000/api/staffs/$userId');
      print("DEBUG: _updateProfile: Target URI: $uri");

      var request = http.MultipartRequest('PATCH', uri);

      request.fields['kh_name'] = _khmerNameController.text.trim();
      request.fields['en_name'] = _englishNameController.text.trim();
      request.fields['phoneNumber'] = _phoneController.text.trim();
      request.fields['gender'] = _selectedGender!;

      request.fields['position'] = _currentPositionId!; // Use the stored ID

      request.fields['province'] = _selectedProvince!.code;
      request.fields['district'] = _selectedDistrict!.code;
      request.fields['commune'] = _selectedCommune!.code;
      request.fields['village'] = _selectedVillage!.code;

      request.fields['address'] = [
        _selectedVillage!.name,
        _selectedCommune!.name,
        _selectedDistrict!.name,
        _selectedProvince!.name,
      ].where((s) => s.isNotEmpty).join(', ');

      print(
          "DEBUG: _updateProfile: Text fields prepared for MultipartRequest: ${request.fields}");

      if (_profileImageFile != null) {
        print(
            "DEBUG: _updateProfile: New image file detected. Adding to MultipartRequest.");

        final mimeTypeData =
            lookupMimeType(_profileImageFile!.path, headerBytes: [0xFF, 0xD8])
                ?.split('/');
        MediaType? contentType;
        if (mimeTypeData != null && mimeTypeData.length == 2) {
          contentType = MediaType(mimeTypeData[0], mimeTypeData[1]);
        } else {
          contentType = MediaType('image', 'jpeg'); // Fallback
          print(
              "WARNING: Could not determine exact MIME type, defaulting to image/jpeg.");
        }

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _profileImageFile!.path,
          filename: _profileImageFile!.path.split('/').last,
          contentType: contentType, // Apply the determined content type
        ));
        print(
            "DEBUG: _updateProfile: MultipartFile 'image' added from path: ${_profileImageFile!.path} with Content-Type: ${contentType}");
      } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        print(
            "DEBUG: _updateProfile: No new image. Sending existing image URL as a form field.");
        request.fields['image'] = _profileImageUrl!;
      } else {
        print(
            "DEBUG: _updateProfile: No image (new or existing). Sending empty string for image field.");
        request.fields['image'] = '';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(
          "DEBUG: _updateProfile: MultipartRequest sent. Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Profile updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _primaryBlue,
            colorText: Colors.white,
            // Apply font to snackbar
            messageText: const Text('Profile updated successfully!',
                style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
            titleText: const Text('Success',
                style:
                    TextStyle(color: Colors.white, fontFamily: _fontFamily)));
        print(
            "DEBUG: _updateProfile: Profile updated successfully. Reloading data...");
        await _loadUserData();
      } else {
        String errorMessage =
            'Failed to update profile. Status: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['message'] != null) {
            errorMessage += '\nDetails: ${errorJson['message']}';
          } else if (errorJson['error'] != null) {
            errorMessage += '\nDetails: ${errorJson['error']}';
          }
        } catch (e) {
          errorMessage += '\nDetails: ${response.body}';
        }
        Get.snackbar('Update Failed', errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: _errorRed,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            // Apply font to snackbar
            messageText: Text(errorMessage,
                style: const TextStyle(
                    color: Colors.white, fontFamily: _fontFamily)),
            titleText: const Text('Update Failed',
                style:
                    TextStyle(color: Colors.white, fontFamily: _fontFamily)));
        print(
            "ERROR: _updateProfile: Update failed. Full response: $errorMessage");
      }
    } on SocketException {
      Get.snackbar('Network Error',
          'No internet connection during update. Please check your network.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: const Text(
              'No internet connection during update. Please check your network.',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Network Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
    } catch (e) {
      Get.snackbar('Network Error', 'An error occurred during update: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _errorRed,
          colorText: Colors.white,
          // Apply font to snackbar
          messageText: Text('An error occurred during update: $e',
              style: const TextStyle(
                  color: Colors.white, fontFamily: _fontFamily)),
          titleText: const Text('Network Error',
              style: TextStyle(color: Colors.white, fontFamily: _fontFamily)));
      print("ERROR: _updateProfile: Exception caught during update: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        print(
            "DEBUG: _updateProfile: _isSaving set to false in finally block.");
      }
    }
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: _darkText,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                  color: _errorRed,
                  fontSize: 15,
                  fontFamily: _fontFamily), // Apply NotoSerifKhmer
            ),
        ],
      ),
    );
  }

  // Generic TextField builder (used for Name, Phone, Email, Position)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(labelText, required: isRequired),
        TextField(
          controller: controller,
          cursorColor: _primaryBlue,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 16,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
            fontWeight: FontWeight.w500,
            color: readOnly ? _mediumGreyText : _darkText,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? _lightGreyBackground : Colors.white,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon,
                    color: readOnly ? _mediumGreyText : _primaryBlue)
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: readOnly ? _borderColor : _primaryBlue,
                  width: readOnly ? 1 : 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _errorRed, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _errorRed, width: 2),
            ),
            hintText: 'Enter $labelText',
            hintStyle: TextStyle(
              color: _mediumGreyText.withOpacity(0.7),
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Gender', required: true),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            icon: const Icon(Icons.arrow_drop_down, color: _primaryBlue),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: 'Select Gender',
              hintStyle: TextStyle(
                color: _mediumGreyText.withOpacity(0.7),
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
              fontWeight: FontWeight.w500,
              color: _darkText,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male',
                      style: TextStyle(
                          fontFamily: _fontFamily))), // Apply NotoSerifKhmer
              DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female',
                      style: TextStyle(
                          fontFamily: _fontFamily))), // Apply NotoSerifKhmer
              DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other',
                      style: TextStyle(
                          fontFamily: _fontFamily))), // Apply NotoSerifKhmer
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your gender'; // Validation message will use default theme font
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddressDropdown<T>({
    required String labelText,
    required T? selectedValue,
    required List<T> items,
    required String Function(T) itemLabelBuilder,
    required ValueChanged<T?> onChanged,
    required bool isRequired,
    required bool isLoading,
    String hint = 'Select',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(labelText, required: isRequired),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<T>(
            value: selectedValue,
            icon: const Icon(Icons.arrow_drop_down, color: _primaryBlue),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: isLoading ? 'Loading...' : hint,
              hintStyle: TextStyle(
                color: _mediumGreyText.withOpacity(0.7),
                fontFamily: _fontFamily, // Apply NotoSerifKhmer
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: _fontFamily, // Apply NotoSerifKhmer
              fontWeight: FontWeight.w500,
              color: _darkText,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            isExpanded: true,
            items: isLoading || items.isEmpty
                ? null
                : items.map<DropdownMenuItem<T>>((T item) {
                    return DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabelBuilder(item),
                          style: const TextStyle(
                              fontFamily: _fontFamily)), // Apply NotoSerifKhmer
                    );
                  }).toList(),
            onChanged: isLoading || items.isEmpty ? null : onChanged,
            validator: (value) {
              if (isRequired && value == null) {
                return 'Please select your $labelText'; // Validation message will use default theme font
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    // Shimmer effect doesn't render actual text, so no direct font change needed here.
    // The placeholder boxes just shimmer.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: _shimmerBaseColor,
            highlightColor: _shimmerHighlightColor,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(10, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 18,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
    ));

    final bool overallLoading =
        _isLoading || _isLoadingPositions || _isLoadingAddressData;

    return Scaffold(
      backgroundColor: _lightGreyBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _darkText,
            fontFamily: _fontFamily, // Apply NotoSerifKhmer
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkText),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          _isSaving || overallLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: overallLoading ? null : _updateProfile,
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: _fontFamily, // Apply NotoSerifKhmer
                    ),
                  ),
                ),
        ],
      ),
      body: overallLoading
          ? _buildShimmerLoader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Theme(
                data: Theme.of(context).copyWith(
                  // Apply default font family to the entire theme subtree within this screen
                  textTheme: Theme.of(context)
                      .textTheme
                      .apply(fontFamily: _fontFamily),
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Color(0xFF1469C7),
                    selectionColor: Color(0xFF90CAF9),
                    selectionHandleColor: Color(0xFF1469C7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _borderColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _borderColor,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                                child: _profileImageFile != null
                                    ? Image.file(
                                        _profileImageFile!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : (_profileImageUrl != null &&
                                            _profileImageUrl!.isNotEmpty
                                        ? Image.network(
                                            _profileImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2));
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 60,
                                                        color: _mediumGreyText),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: _mediumGreyText,
                                          ))),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: _primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Form Fields ---
                    _buildTextField(
                      controller: _khmerNameController,
                      labelText: 'Khmer Name',
                      suffixIcon: Icons.person_outline,
                    ),
                    _buildTextField(
                      controller: _englishNameController,
                      labelText: 'English Name',
                      suffixIcon: Icons.person_outline,
                    ),
                    _buildGenderDropdown(),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      suffixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        suffixIcon: Icons.email_outlined,
                        readOnly: true,
                        isRequired: false),
                    _buildTextField(
                        controller: _positionController,
                        labelText: 'Position',
                        suffixIcon: Icons.work_outline,
                        readOnly: true,
                        isRequired: false),

                    // --- Address Selection Dropdowns ---
                    _buildAddressDropdown<Province>(
                      labelText: 'Province',
                      selectedValue: _selectedProvince,
                      items: _allProvinces,
                      itemLabelBuilder: (province) => province.name,
                      onChanged: (province) {
                        if (mounted) {
                          setState(() {
                            _selectedProvince = province;
                            _updateFilteredDistricts(province?.code);
                          });
                        }
                      },
                      isRequired: true,
                      isLoading: _isLoadingAddressData,
                      hint: 'Select Province',
                    ),
                    _buildAddressDropdown<District>(
                      labelText: 'District',
                      selectedValue: _selectedDistrict,
                      items: _filteredDistricts,
                      itemLabelBuilder: (district) => district.name,
                      onChanged: (district) {
                        if (mounted) {
                          setState(() {
                            _selectedDistrict = district;
                            _updateFilteredCommunes(district?.code);
                          });
                        }
                      },
                      isRequired: true,
                      hint: _selectedProvince == null || _isLoadingAddressData
                          ? 'Select Province first'
                          : 'Select District',
                      isLoading: _isLoadingAddressData ||
                          _selectedProvince == null ||
                          _filteredDistricts.isEmpty,
                    ),
                    _buildAddressDropdown<Commune>(
                      labelText: 'Commune',
                      selectedValue: _selectedCommune,
                      items: _filteredCommunes,
                      itemLabelBuilder: (commune) => commune.name,
                      onChanged: (commune) {
                        if (mounted) {
                          setState(() {
                            _selectedCommune = commune;
                            _updateFilteredVillages(commune?.code);
                          });
                        }
                      },
                      isRequired: true,
                      hint: _selectedDistrict == null || _isLoadingAddressData
                          ? 'Select District first'
                          : 'Select Commune',
                      isLoading: _isLoadingAddressData ||
                          _selectedDistrict == null ||
                          _filteredCommunes.isEmpty,
                    ),
                    _buildAddressDropdown<Village>(
                      labelText: 'Village',
                      selectedValue: _selectedVillage,
                      items: _filteredVillages,
                      itemLabelBuilder: (village) => village.name,
                      onChanged: (village) {
                        if (mounted) {
                          setState(() {
                            _selectedVillage = village;
                          });
                        }
                      },
                      isRequired: true,
                      hint: _selectedCommune == null || _isLoadingAddressData
                          ? 'Select Commune first'
                          : 'Select Village',
                      isLoading: _isLoadingAddressData ||
                          _selectedCommune == null ||
                          _filteredVillages.isEmpty,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
