// lib/services/address_service.dart
import 'package:flutter/material.dart'; // For SnackBar
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AddressService extends GetxService {
  Map<String, String> _villages = {};
  Map<String, String> _communes = {};
  Map<String, String> _districts = {};
  Map<String, String> _provinces = {};

  // Raw lists to support filtering by parent ID
  List<Map<String, dynamic>> _rawProvinces = [];
  List<Map<String, dynamic>> _rawDistricts = [];
  List<Map<String, dynamic>> _rawCommunes = [];
  List<Map<String, dynamic>> _rawVillages = [];

  @override
  void onInit() {
    super.onInit();
    // Load data as soon as the service is initialized
    loadAddressData();
  }

  Future<void> loadAddressData() async {
    try {
      debugPrint('AddressService: Starting to load address data...');

      // --- Load Province data ---
      String provinceJsonString =
          await rootBundle.loadString('assets/data/province.json');
      _rawProvinces = List<Map<String, dynamic>>.from(
          json.decode(provinceJsonString) as List);
      for (var item in _rawProvinces) {
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          final adminId = properties['ADMIN_ID1']?.toString();
          final nameEng = properties['NAME_ENG1']?.toString();
          if (adminId != null && nameEng != null) {
            _provinces[adminId] = nameEng;
          }
        }
      }
      debugPrint('AddressService: Loaded ${_provinces.length} provinces.');

      // --- Load District data ---
      String districtJsonString =
          await rootBundle.loadString('assets/data/district.json');
      _rawDistricts = List<Map<String, dynamic>>.from(
          json.decode(districtJsonString) as List);
      for (var item in _rawDistricts) {
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          final adminId = properties['ADMIN_ID2']?.toString();
          final nameEng = properties['NAME_ENG2']?.toString();
          if (adminId != null && nameEng != null) {
            _districts[adminId] = nameEng;
          }
        }
      }
      debugPrint('AddressService: Loaded ${_districts.length} districts.');

      // --- Load Commune data ---
      String communeJsonString =
          await rootBundle.loadString('assets/data/commune.json');
      _rawCommunes = List<Map<String, dynamic>>.from(
          json.decode(communeJsonString) as List);
      for (var item in _rawCommunes) {
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          final adminId = properties['ADMIN_ID']?.toString();
          final nameEng = properties['NAME_ENG3']?.toString();
          if (adminId != null && nameEng != null) {
            _communes[adminId] = nameEng;
          }
        }
      }
      debugPrint('AddressService: Loaded ${_communes.length} communes.');

      // --- Load Village data ---
      String villageJsonString =
          await rootBundle.loadString('assets/data/village.json');
      _rawVillages = List<Map<String, dynamic>>.from(
          json.decode(villageJsonString) as List);
      for (var item in _rawVillages) {
        final properties = item['properties'] as Map<String, dynamic>?;
        if (properties != null) {
          final adminId = properties['ADMIN_ID']?.toString();
          final nameEng = properties['NAME_ENG']?.toString();
          if (adminId != null && nameEng != null) {
            _villages[adminId] = nameEng;
          }
        }
      }
      debugPrint('AddressService: Loaded ${_villages.length} villages.');

      debugPrint('AddressService: All address data loading complete.');
    } on FormatException catch (e) {
      debugPrint('AddressService ERROR: Failed to decode address JSON: $e');
      Get.snackbar(
        'Data Error',
        'Address data files are corrupted. Please contact support. Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      rethrow;
    } catch (e) {
      debugPrint('AddressService ERROR: Error loading address data: $e');
      Get.snackbar(
        'Error Loading Data',
        'Failed to load geographical data. Address information may be incomplete. Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      rethrow;
    }
  }

  // Ensure these methods handle null or empty IDs gracefully
  String getVillageName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _villages[id] ?? 'N/A';
    // debugPrint('AddressService Lookup: Village ID "$id" -> Name: "$name"');
    return name;
  }

  String getCommuneName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _communes[id] ?? 'N/A';
    // debugPrint('AddressService Lookup: Commune ID "$id" -> Name: "$name"');
    return name;
  }

  String getDistrictName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _districts[id] ?? 'N/A';
    // debugPrint('AddressService Lookup: District ID "$id" -> Name: "$name"');
    return name;
  }

  String getProvinceName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _provinces[id] ?? 'N/A';
    // debugPrint('AddressService Lookup: Province ID "$id" -> Name: "$name"');
    return name;
  }

  // Methods to get lists of children by parent ID with robust null/type checks
  List<Map<String, String>> getAllProvinces() {
    return _rawProvinces.map((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final id = properties?['ADMIN_ID1']?.toString();
      final name = properties?['NAME_ENG1']?.toString();
      return {
        'id': id ?? '',
        'name': name ?? '',
      };
    }).toList();
  }

  List<Map<String, String>> getDistrictsByProvinceId(String provinceId) {
    return _rawDistricts.where((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final adminId2 = properties?['ADMIN_ID2']?.toString();
      return properties != null &&
          adminId2 != null &&
          adminId2.startsWith(provinceId);
    }).map((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final id = properties?['ADMIN_ID2']?.toString();
      final name = properties?['NAME_ENG2']?.toString();
      return {
        'id': id ?? '',
        'name': name ?? '',
      };
    }).toList();
  }

  List<Map<String, String>> getCommunesByDistrictId(String districtId) {
    return _rawCommunes.where((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final adminId = properties?['ADMIN_ID']?.toString();
      return properties != null &&
          adminId != null &&
          adminId.startsWith(districtId);
    }).map((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final id = properties?['ADMIN_ID']?.toString();
      final name = properties?['NAME_ENG3']?.toString();
      return {
        'id': id ?? '',
        'name': name ?? '',
      };
    }).toList();
  }

  List<Map<String, String>> getVillagesByCommuneId(String communeId) {
    return _rawVillages.where((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final adminId = properties?['ADMIN_ID']?.toString();
      return properties != null &&
          adminId != null &&
          adminId.startsWith(communeId);
    }).map((item) {
      final properties = item['properties'] as Map<String, dynamic>?;
      final id = properties?['ADMIN_ID']?.toString();
      final name = properties?['NAME_ENG']?.toString();
      return {
        'id': id ?? '',
        'name': name ?? '',
      };
    }).toList();
  }
}
