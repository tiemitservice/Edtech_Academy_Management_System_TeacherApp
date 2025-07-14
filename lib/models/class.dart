

/// Represents a Subject.
class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['_id'] as String? ?? 'Unknown Subject ID',
      name: json['name'] as String? ?? 'Unnamed Subject',
    );
  }
}

/// Represents a single class taught by a teacher.
class TeacherClass {
  final String id;
  final String name;
  final String subjectId;
  final String subjectName; // Resolved subject name
  final List<String> studentIds; // Just IDs from the class API
  final List<String> classDays;
  final String staffId;

  TeacherClass({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subjectName,
    required this.studentIds,
    required this.classDays,
    required this.staffId,
  });

  /// Creates a TeacherClass instance from a JSON map.
  factory TeacherClass.fromJson(Map<String, dynamic> json, String resolvedSubjectName) {
    final List<dynamic> studentsRaw = json['students'] as List<dynamic>? ?? [];
    final List<String> studentIds = studentsRaw
        .map((s) {
          // Assuming 's' is a map like {"student": {"_id": "..."}}
          if (s is Map<String, dynamic> && s.containsKey('student') && s['student'] is Map<String, dynamic>) {
            return (s['student'] as Map<String, dynamic>)['_id'].toString();
          }
          return ''; // Return empty string or handle error if structure is unexpected
        })
        .where((id) => id.isNotEmpty) // Filter out any empty IDs
        .toList();

    final List<dynamic> daysRaw = json['day_class'] as List<dynamic>? ?? [];
    final List<String> classDays =
        daysRaw.map((day) => day.toString()).toList();

    return TeacherClass(
      id: json['_id'] as String? ?? 'Unknown ID',
      name: json['name'] as String? ?? 'Unnamed Class',
      subjectId: json['subject'] as String? ?? '',
      subjectName: resolvedSubjectName,
      studentIds: studentIds,
      classDays: classDays,
      staffId: json['staff'] as String? ?? '',
    );
  }
}
