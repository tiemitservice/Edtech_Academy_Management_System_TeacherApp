// lib/models/student.dart

/// Represents a Student's basic details.
class Student {
  final String id;
  final String khName; // Khmer name
  final String engName; // English name
  final String gender;
  final String? avatarUrl; // Nullable to handle missing image
  final String? phoneNumber;
  final String? email;

  Student({
    required this.id,
    required this.khName,
    required this.engName,
    required this.gender,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? '',
      khName: json['kh_name'] as String? ?? 'Unknown Khmer Name',
      engName: json['eng_name'] as String? ?? 'Unknown English Name',
      gender: json['gender'] as String? ?? 'N/A',
      avatarUrl: (json['image'] is String && (json['image'] as String).isNotEmpty)
          ? json['image'] as String
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
    );
  }

  // Getter to provide the most relevant name for display
  String get displayName => engName.isNotEmpty ? engName : khName;
}
