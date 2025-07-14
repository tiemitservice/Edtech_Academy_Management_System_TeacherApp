// lib/services/class_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/models/class.dart'; // <--- IMPORTANT: This imports TeacherClass and Subject

/// A service class for fetching class data from the API.
class ClassService {
  final String _classesBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/classes';
  final String _subjectsBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/subjects';

  /// Fetches all subjects and returns them as a map for easy lookup.
  Future<Map<String, String>> _fetchSubjects() async {
    try {
      final response = await http.get(Uri.parse(_subjectsBaseUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> subjectsApi = jsonData['data'];
        return {
          for (var subjectJson in subjectsApi)
            subjectJson['_id'].toString(): subjectJson['name'].toString()
        };
      } else {
        throw Exception(
            'Failed to load subjects (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching subjects: $e');
    }
  }

  /// Fetches and filters classes for a specific teacher by staff ID.
  Future<List<TeacherClass>> fetchTeacherClasses(String teacherStaffId) async {
    try {
      final Map<String, String> subjectsMap =
          await _fetchSubjects(); // Fetch subjects first

      final response = await http.get(Uri.parse(_classesBaseUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> allClassesApi = jsonData['data'];

        return allClassesApi
            .map((classJson) {
              final String subjectId = classJson['subject'] as String? ?? '';
              final String subjectName = subjectsMap[subjectId] ??
                  'Unknown Subject'; // Resolve subject name
              return TeacherClass.fromJson(
                  classJson as Map<String, dynamic>, subjectName);
            })
            .where((c) => c.staffId == teacherStaffId) // Filter by staffId
            .toList();
      } else {
        throw Exception(
            'Failed to load classes (Status code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching classes: $e');
    }
  }
}
