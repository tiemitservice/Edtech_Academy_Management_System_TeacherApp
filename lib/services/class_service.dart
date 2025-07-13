// lib/services/class_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/models/student.dart'; // Import Student model

// Define a simple Class model if you don't have one
class TeacherClass {
  final String id;
  final String name;
  final String subjectId;
  final String subjectName;
  final List<Student> students; // List of actual Student objects
  final String staffId; // Added staffId as it's in your class API response

  TeacherClass({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subjectName,
    required this.students,
    required this.staffId, // Added to constructor
  });

  factory TeacherClass.fromJson(
      Map<String, dynamic> json, String resolvedSubjectName) {
    final List<dynamic> studentsRaw = json['students'] as List<dynamic>? ?? [];
    final List<Student> students = studentsRaw.map((s) {
      // Ensure 'student' key exists and is a Map before parsing
      if (s is Map<String, dynamic> &&
          s.containsKey('student') &&
          s['student'] is Map<String, dynamic>) {
        return Student.fromJson(s['student'] as Map<String, dynamic>);
      }
      print('Warning: Invalid student data structure in class API: $s');
      // Return a dummy student or handle error as appropriate
      return Student(
          id: 'unknown',
          name: 'Invalid Student',
          gender: 'N/A',
          avatarUrl: null);
    }).toList();

    return TeacherClass(
      id: json['_id'] as String? ?? 'Unknown ID',
      name: json['name'] as String? ?? 'Unnamed Class',
      subjectId: json['subject'] as String? ?? '',
      subjectName: resolvedSubjectName,
      students: students,
      staffId: json['staff'] as String? ?? '', // Parse staffId
    );
  }
}

/// Represents a Subject.
class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['_id'] as String,
      name: json['name'] as String,
    );
  }
}

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
