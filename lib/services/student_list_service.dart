// lib/services/student_list_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/models/student.dart'; // Import the Student model

/// A service class for fetching a list of all students from the API.
class StudentListService {
  final String _baseUrl = 'https://edtech-academy-management-system-server.onrender.com/api/students';

  /// Fetches all students from the API.
  /// Returns a list of [Student] objects if successful, otherwise throws an [Exception].
  Future<List<Student>> fetchAllStudents() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> rawStudents = jsonData['data'];

        return rawStudents.map((json) => Student.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching students: $e');
    }
  }
}
