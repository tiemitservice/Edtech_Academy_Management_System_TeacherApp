// lib/services/student_list_service.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:school_management_system_teacher_app/models/student.dart';

const String _apiBaseUrl =
    'https://edtech-academy-management-system-server.onrender.com/api';

/// A data class to hold the list of students and their total count for a specific class.
class StudentsByClassResult {
  final List<Student> students;
  final int totalStudentsCount;

  StudentsByClassResult(
      {required this.students, required this.totalStudentsCount});
}

class StudentListService extends GetxService {
  /// Fetches a list of students for a specific class, filtered by classId and staffId.
  /// Returns a StudentsByClassResult containing the list of students and their count.
  Future<StudentsByClassResult> fetchStudentsForClass({
    required String classId,
    required String staffId, // This parameter is crucial and correctly used
  }) async {
    try {
      // Fetch from classes API
      final response = await http.get(Uri.parse('$_apiBaseUrl/classes'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> allClassesData =
            responseData['data']; // Access the 'data' array

        // Find the specific class that matches both classId and staffId
        final classJson = allClassesData.firstWhere(
          (c) =>
              c['_id'] == classId &&
              c['staff'] == staffId, // Filtering by both IDs
          orElse: () => throw Exception(
              'Class not found or teacher not assigned to this class.'),
        );

        final List<Student> studentsInClass = [];
        if (classJson['students'] is List) {
          for (var studentEntry in classJson['students']) {
            if (studentEntry['student'] is Map<String, dynamic>) {
              // Parse the nested 'student' object into your Student model
              final Student student = Student.fromJson(studentEntry['student']);
              studentsInClass.add(student);
            }
          }
        }

        // Return the students and their count
        return StudentsByClassResult(
          students: studentsInClass,
          totalStudentsCount: studentsInClass.length,
        );
      } else {
        throw Exception(
            'Failed to load class list: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching students from classes API: $e');
      throw Exception(
          'Failed to load student data: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
