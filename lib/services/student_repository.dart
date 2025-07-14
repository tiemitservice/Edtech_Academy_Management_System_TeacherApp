// lib/services/student_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; // For GetxService
import 'package:school_management_system_teacher_app/models/student.dart';

/// A repository to fetch and cache student data.
/// This helps avoid multiple API calls for the same student.
class StudentRepository extends GetxService {
  final String _baseUrl = 'https://edtech-academy-management-system-server.onrender.com/api/students';
  final Map<String, Student> _studentsCache = {}; // Cache student data by ID
  final RxBool _isFetchingAllStudents = false.obs; // To prevent multiple simultaneous fetches

  /// Fetches all students from the API and populates the cache.
  Future<void> fetchAllStudents() async {
    if (_isFetchingAllStudents.value) {
      print('Already fetching all students. Skipping duplicate call.');
      return;
    }
    _isFetchingAllStudents.value = true;
    print('Fetching all students from API...');

    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> rawStudents = jsonData['data'];

        _studentsCache.clear(); // Clear old cache
        for (var rawStudent in rawStudents) {
          final student = Student.fromJson(rawStudent);
          _studentsCache[student.id] = student;
        }
        print('Successfully fetched and cached ${_studentsCache.length} students.');
      } else {
        print('Failed to load all students: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load all students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all students: $e');
      throw Exception('An error occurred while fetching all students: $e');
    } finally {
      _isFetchingAllStudents.value = false;
    }
  }

  /// Retrieves a student by ID from the cache or fetches all students if not found.
  Future<Student?> getStudentById(String studentId) async {
    if (_studentsCache.containsKey(studentId)) {
      return _studentsCache[studentId];
    } else {
      // If not in cache, try to fetch all students again (in case it was missed or cache was empty)
      await fetchAllStudents();
      return _studentsCache[studentId]; // Try to get it after fetching all
    }
  }
}
