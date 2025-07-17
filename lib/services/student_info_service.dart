// lib/services/student_info_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:flutter/foundation.dart'; // For debugPrint

class StudentInfoService {
  final String _baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api';

  Future<Student> fetchStudentById(String studentId) async {
    final String url = '$_baseUrl/classes';

    debugPrint(
        'StudentInfoService: Attempting to fetch classes from: $url to find student ID: $studentId');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        debugPrint(
            'StudentInfoService: Successfully fetched classes. Status Code: ${response.statusCode}');
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(response.body);
        } on FormatException catch (e) {
          debugPrint('StudentInfoService ERROR: Failed to decode JSON: $e');
          throw Exception('Invalid data format received from the server.');
        }

        List<dynamic> classesData = jsonResponse['data'];

        Map<String, dynamic>? foundStudentJson; // Changed to nullable Map
        for (var classItem in classesData) {
          // Ensure classItem is a Map and has a 'students' key that is a List
          if (classItem is Map<String, dynamic> &&
              classItem.containsKey('students') &&
              classItem['students'] is List) {
            final List<dynamic> studentsInClass = classItem['students'];

            final studentEntry = studentsInClass.firstWhereOrNull(
              (studentDetail) {
                // Ensure studentDetail is a Map and has a 'student' key that is a Map
                // Also check if _id key exists before comparing
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
              foundStudentJson = studentEntry['student']
                  as Map<String, dynamic>; // Cast for safety
              debugPrint(
                  'StudentInfoService: Student with ID $studentId found in class: ${classItem['name']}');
              break; // Student found, exit the loop
            }
          }
        }

        if (foundStudentJson != null) {
          return Student.fromJson(foundStudentJson);
        } else {
          debugPrint(
              'StudentInfoService: Student with ID $studentId not found after iterating through all classes.');
          throw Exception('Student with ID $studentId not found.');
        }
      } else {
        debugPrint(
            'StudentInfoService ERROR: Failed to load classes. Status Code: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load student data. Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          'StudentInfoService CATCH ERROR: Exception during fetchStudentById: $e');
      // Re-throw with a more user-friendly message
      if (e is http.ClientException) {
        throw Exception('Network error: Could not connect to the server.');
      } else if (e is Exception && e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception(
          'An unexpected error occurred: ${e.toString().contains("Exception:") ? e.toString().replaceFirst("Exception: ", "") : e.toString()}');
    }
  }
}
