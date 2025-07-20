// lib/services/student_info_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class StudentInfoService {
  final String _baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api';

  Future<Student> fetchStudentById(String studentId) async {
    final String url = '$_baseUrl/classes';
    debugPrint('StudentInfoService: Attempting to fetch classes from: $url to find student ID: $studentId');
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(response.body);
        } on FormatException catch (e) {
          debugPrint('StudentInfoService ERROR: Failed to decode JSON: $e');
          throw Exception('Invalid data format received from the server.');
        }

        List<dynamic> classesData = jsonResponse['data'];

        Map<String, dynamic>? foundStudentEntry;

        for (var classItem in classesData) {
          if (classItem is Map<String, dynamic> &&
              classItem.containsKey('students') &&
              classItem['students'] is List) {
            final List<dynamic> studentsInClass = classItem['students'];
            final studentEntry = studentsInClass.firstWhereOrNull(
              (studentDetail) {
                return studentDetail is Map<String, dynamic> &&
                    studentDetail.containsKey('student') &&
                    studentDetail['student'] is Map<String, dynamic> &&
                    (studentDetail['student'] as Map<String, dynamic>)
                        .containsKey('_id') &&
                    (studentDetail['student'] as Map<String, dynamic>)['_id'] ==
                        studentId;
              },
            );

            if (studentEntry != null) {
              foundStudentEntry = studentEntry as Map<String, dynamic>;
              debugPrint('StudentInfoService: Student with ID $studentId found in class: ${classItem['name']}');
              break;
            }
          }
        }

        if (foundStudentEntry != null) {
          // ✅ FIX: Passes the entire entry to fromJson, not just the nested part.
          return Student.fromJson(foundStudentEntry);
        } else {
          debugPrint('StudentInfoService: Student with ID $studentId not found after iterating through all classes.');
          throw Exception('Student with ID $studentId not found.');
        }
      } else {
        debugPrint('StudentInfoService ERROR: Failed to load classes. Status Code: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load student data. Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('StudentInfoService CATCH ERROR: Exception during fetchStudentById: $e');
      if (e is http.ClientException) {
        throw Exception('Network error: Could not connect to the server.');
      } else if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('An unexpected error occurred: ${e.toString().contains("Exception:") ? e.toString().replaceFirst("Exception: ", "") : e.toString()}');
    }
  }
}