// lib/models/student.dart

/// Represents a Student's basic details.
class Student {
  final String id;
  final String name; // e.g., 'eng_name' from API
  final String gender;
  final String? avatarUrl; // Nullable to handle missing image

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? '',
      name: json['eng_name'] as String? ?? 'Unknown Student', // Use eng_name
      gender: json['gender'] as String? ?? 'N/A',
      avatarUrl: (json['image'] is String &&
              (json['image'] as String).isNotEmpty)
          ? json['image'] as String // Only assign if it's a non-empty string
          : null, // Set to null if image is not a valid URL or is empty
    );
  }
}
