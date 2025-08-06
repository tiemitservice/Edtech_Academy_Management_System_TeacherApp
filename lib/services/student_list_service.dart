// lib/services/student_list_service.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:school_management_system_teacher_app/models/student.dart';

const String _apiBaseUrl = 'http://188.166.242.109:5000/api';

class StudentsByClassResult {
  final List<Student> students;
  final int totalStudentsCount;

  StudentsByClassResult(
      {required this.students, required this.totalStudentsCount});
}

class StudentListService extends GetxService {
  Future<StudentsByClassResult> fetchStudentsForClass({
    required String classId,
    required String staffId,
  }) async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/classes'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> allClassesData = responseData['data'];

        final classJson = allClassesData.firstWhere(
          (c) => c['_id'] == classId && c['staff'] == staffId,
          orElse: () => throw Exception(
              'Class not found or teacher not assigned to this class.'),
        );

        final List<Student> studentsInClass = [];
        if (classJson['students'] is List) {
          for (var studentEntry in classJson['students']) {
            // ✅ FIX: Added a try-catch block to skip invalid student records.
            try {
              if (studentEntry is Map<String, dynamic>) {
                final Student student = Student.fromJson(studentEntry);
                studentsInClass.add(student);
              }
            } catch (e) {
              print(
                  'Skipping invalid student record in class ${classJson['name']}: $e');
            }
          }
        }

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
