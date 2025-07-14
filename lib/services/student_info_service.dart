// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/services/student_info_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:school_management_system_teacher_app/models/student.dart';

class StudentInfoService {
  final String _baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api';

  Future<Student> fetchStudentById(String studentId) async {
    final String url = '$_baseUrl/students'; // Fetch all students

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        List<dynamic> studentData = jsonResponse['data'];

        // Find the specific student by ID from the fetched list
        final studentJson = studentData.firstWhere(
          (item) => item['_id'] == studentId,
          orElse: () => null, // Return null if not found
        );

        if (studentJson != null) {
          return Student.fromJson(studentJson);
        } else {
          throw Exception('Student with ID $studentId not found.');
        }
      } else {
        throw Exception(
            'Failed to load students: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the student API: $e');
    }
  }
}
