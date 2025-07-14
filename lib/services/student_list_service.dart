// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/services/student_list_service.dart
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For json.decode
import 'package:school_management_system_teacher_app/models/student.dart';

class StudentListService {
  // Set the base URL for your API
  final String _baseUrl = 'https://edtech-academy-management-system-server.onrender.com/api';

  /// Fetches the list of students from the API.
  /// If classId is provided, it filters the students client-side based on their 'student_type'.
  Future<List<Student>> fetchAllStudents({String? classId}) async {
    final String url = '$_baseUrl/students'; // The API endpoint for all students

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        // The actual student data is inside the 'data' key of the JSON response
        List<dynamic> studentData = jsonResponse['data'];

        // Convert the list of JSON objects into a list of Student objects
        List<Student> allFetchedStudents = studentData.map((json) => Student.fromJson(json)).toList();

        // If a classId is provided, filter the students on the client-side
        if (classId != null && classId.isNotEmpty) {
          return allFetchedStudents.where((student) => student.classId == classId).toList();
        } else {
          // If no classId, return all students
          return allFetchedStudents;
        }
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception('Failed to load students: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Catch any network-related errors
      throw Exception('Failed to connect to the student API: $e');
    }
  }
}