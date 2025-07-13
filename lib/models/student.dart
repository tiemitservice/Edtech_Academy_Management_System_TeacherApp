// lib/models/student.dart

/// Represents a Student's basic details.
class Student {
  final String id;
  final String name; // e.g., 'eng_name' from API
  final String gender;
  final String? avatarUrl;

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? '',
      name: json['eng_name'] as String? ?? 'Unknown Student',
      gender: json['gender'] as String? ?? 'N/A',
      avatarUrl: json['image'] as String?,
    );
  }
}