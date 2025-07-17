// lib/models/student.dart
class Student {
  final String id;
  final String khName;
  final String engName;
  final String gender;
  final String phoneNumber;
  final String? email; // email can be null
  final String? avatarUrl; // assuming 'image' maps to avatarUrl
  final String? address;
  final DateTime? dateOfBirth;
  final String? fatherName;
  final String? motherName;
  final int? score;
  final int? attendance; // Assuming 'attendence' is total attendance
  final DateTime? attendanceDate; // Assuming 'attendence_date'
  final String? attendanceEnum; // Assuming 'attendence_enum'
  final String? studentType;
  final int? finalScore;
  final int? midtermScore;
  final int? quizScore;
  final int? totalAttendanceScore;
  final String? scoreStatus;
  final String? commune;
  final String? district;
  final String? province;
  final String? village;
  final DateTime? paymentDate;
  final String? paymentType;
  final DateTime? nextPaymentDate;
  final String? fatherPhone;
  final String? motherPhone;
  final String? documentType;
  final String? documentNumber;
  final bool? status; // Add status field

  Student({
    required this.id,
    required this.khName,
    required this.engName,
    required this.gender,
    required this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.address,
    this.dateOfBirth,
    this.fatherName,
    this.motherName,
    this.score,
    this.attendance,
    this.attendanceDate,
    this.attendanceEnum,
    this.studentType,
    this.finalScore,
    this.midtermScore,
    this.quizScore,
    this.totalAttendanceScore,
    this.scoreStatus,
    this.commune,
    this.district,
    this.province,
    this.village,
    this.paymentDate,
    this.paymentType,
    this.nextPaymentDate,
    this.fatherPhone,
    this.motherPhone,
    this.documentType,
    this.documentNumber,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String,
      khName: json['kh_name'] as String,
      engName: json['eng_name'] as String,
      gender: json['gender'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      avatarUrl: json['image'] as String?, // 'image' field in JSON
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      score: (json['score'] as num?)?.toInt(),
      attendance: (json['attendence'] as num?)?.toInt(), // 'attendence' field
      attendanceDate: json['attendence_date'] != null
          ? DateTime.tryParse(json['attendence_date'])
          : null,
      attendanceEnum: json['attendence_enum'] as String?,
      studentType: json['student_type'] as String?,
      finalScore: (json['final_score'] as num?)?.toInt(),
      midtermScore: (json['midterm_score'] as num?)?.toInt(),
      quizScore: (json['quiz_score'] as num?)?.toInt(),
      totalAttendanceScore: (json['total_attendance_score'] as num?)?.toInt(),
      scoreStatus: json['score_status'] as String?,
      commune: json['commune'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      village: json['village'] as String?,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'])
          : null,
      paymentType: json['payment_type'] as String?,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.tryParse(json['next_payment_date'])
          : null,
      fatherPhone: json['father_phone'] as String?,
      motherPhone: json['mother_phone'] as String?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      status: json['status'] as bool?, // 'status' field
    );
  }

  String get displayName {
    return engName.isNotEmpty ? engName : khName;
  }
}
