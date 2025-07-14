// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/services/address_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

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


  Future<void> loadAddressData() async {
    try {
      print('AddressService: Starting to load address data...');
      // Load Province data
      String provinceJsonString = await rootBundle.loadString('assets/data/province.json');
      _rawProvinces = List<Map<String, dynamic>>.from(json.decode(provinceJsonString));
      for (var item in _rawProvinces) {
        if (item['properties'] != null && item['properties']['ADMIN_ID1'] != null && item['properties']['NAME_ENG1'] != null) {
          _provinces[item['properties']['ADMIN_ID1']] = item['properties']['NAME_ENG1'];
        }
      }
      print('AddressService: Loaded ${_provinces.length} provinces.');

      // Load District data
      String districtJsonString = await rootBundle.loadString('assets/data/district.json');
      _rawDistricts = List<Map<String, dynamic>>.from(json.decode(districtJsonString));
      for (var item in _rawDistricts) {
        if (item['properties'] != null && item['properties']['ADMIN_ID2'] != null && item['properties']['NAME_ENG2'] != null) {
          _districts[item['properties']['ADMIN_ID2']] = item['properties']['NAME_ENG2'];
        }
      }
      print('AddressService: Loaded ${_districts.length} districts.');

      // Load Commune data
      String communeJsonString = await rootBundle.loadString('assets/data/commune.json');
      _rawCommunes = List<Map<String, dynamic>>.from(json.decode(communeJsonString));
      for (var item in _rawCommunes) {
        if (item['properties'] != null && item['properties']['ADMIN_ID'] != null && item['properties']['NAME_ENG3'] != null) {
          _communes[item['properties']['ADMIN_ID']] = item['properties']['NAME_ENG3'];
        }
      }
      print('AddressService: Loaded ${_communes.length} communes.');

      // Load Village data
      String villageJsonString = await rootBundle.loadString('assets/data/village.json');
      _rawVillages = List<Map<String, dynamic>>.from(json.decode(villageJsonString));
      for (var item in _rawVillages) {
        if (item['properties'] != null && item['properties']['ADMIN_ID'] != null && item['properties']['NAME_ENG'] != null) {
          _villages[item['properties']['ADMIN_ID']] = item['properties']['NAME_ENG'];
        }
      }
      print('AddressService: Loaded ${_villages.length} villages.');

      print('AddressService: All address data loading complete.');
    } catch (e) {
      print('AddressService ERROR: Error loading address data: $e');
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

  String getVillageName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _villages[id] ?? 'N/A';
    // print('AddressService Lookup: Village ID "$id" -> Name: "$name"'); // Keep for debugging if needed
    return name;
  }

  String getCommuneName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _communes[id] ?? 'N/A';
    // print('AddressService Lookup: Commune ID "$id" -> Name: "$name"');
    return name;
  }

  String getDistrictName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _districts[id] ?? 'N/A';
    // print('AddressService Lookup: District ID "$id" -> Name: "$name"');
    return name;
  }

  String getProvinceName(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    String name = _provinces[id] ?? 'N/A';
    // print('AddressService Lookup: Province ID "$id" -> Name: "$name"');
    return name;
  }

  // NEW: Methods to get lists of children by parent ID
  List<Map<String, String>> getAllProvinces() {
    return _rawProvinces.map((item) {
      return {
        'id': item['properties']['ADMIN_ID1'].toString(),
        'name': item['properties']['NAME_ENG1'].toString(),
      };
    }).toList();
  }

  List<Map<String, String>> getDistrictsByProvinceId(String provinceId) {
    return _rawDistricts.where((item) =>
        item['properties'] != null &&
        item['properties']['ADMIN_ID2'] != null &&
        item['properties']['ADMIN_ID2'].toString().startsWith(provinceId)
    ).map((item) {
      return {
        'id': item['properties']['ADMIN_ID2'].toString(),
        'name': item['properties']['NAME_ENG2'].toString(),
      };
    }).toList();
  }

  List<Map<String, String>> getCommunesByDistrictId(String districtId) {
    return _rawCommunes.where((item) =>
        item['properties'] != null &&
        item['properties']['ADMIN_ID'] != null &&
        item['properties']['ADMIN_ID'].toString().startsWith(districtId)
    ).map((item) {
      return {
        'id': item['properties']['ADMIN_ID'].toString(),
        'name': item['properties']['NAME_ENG3'].toString(),
      };
    }).toList();
  }

  List<Map<String, String>> getVillagesByCommuneId(String communeId) {
    return _rawVillages.where((item) =>
        item['properties'] != null &&
        item['properties']['ADMIN_ID'] != null &&
        item['properties']['ADMIN_ID'].toString().startsWith(communeId)
    ).map((item) {
      return {
        'id': item['properties']['ADMIN_ID'].toString(),
        'name': item['properties']['NAME_ENG'].toString(),
      };
    }).toList();
  }
}