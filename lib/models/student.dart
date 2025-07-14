// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/models/student.dart
class Student {
  final String id;
  final String khName; // Mapped from kh_name in API
  final String engName; // Mapped from eng_name in API
  final String gender;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl; // Mapped from image in API
  // final String? address; // REMOVED: Address will be constructed from components
  final DateTime? dateOfBirth; // Mapped from date_of_birth
  final String? fatherName;
  final String? motherName;
  final String? fatherPhone;
  final String? motherPhone;
  final int? score; // Overall score
  final int? attendance; // Overall attendance count
  final List<dynamic>? rentalBook; // Assuming it's a list of dynamic items
  final bool? status; // Student status (active/inactive)
  final DateTime? dateEntered; // Mapped from date_intered
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? teacherId; // Mapped from teacher (if it's an ID)
  final DateTime? attendanceDate; // Mapped from attendence_date
  final String?
      attendanceEnum; // Mapped from attendence_enum (e.g., "present", "absence")
  final String? classId; // Mapped from student_type in API
  final int? finalScore;
  final int? midtermScore;
  final int? quizScore;
  final int? totalAttendanceScore;
  final String? scoreStatus;
  final int? oldFinalScore;
  final int? oldMidtermScore;
  final int? oldQuizScore;
  final String? commune; // Keep these for lookup
  final String? district; // Keep these for lookup
  final String? documentNumber;
  final String? documentType;
  final String? familyCommune;
  final String? familyDistrict;
  final String? familyProvince;
  final String? familyVillage;
  final String? province; // Keep these for lookup
  final String? stBirthCommune;
  final String? stBirthDistrict;
  final String? stBirthProvince;
  final String? stBirthVillage;
  final String? village; // Keep these for lookup
  final DateTime? paymentDate;
  final String? paymentType;
  final DateTime? nextPaymentDate;

  Student({
    required this.id,
    required this.khName,
    required this.engName,
    required this.gender,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    // this.address, // REMOVED
    this.dateOfBirth,
    this.fatherName,
    this.motherName,
    this.fatherPhone,
    this.motherPhone,
    this.score,
    this.attendance,
    this.rentalBook,
    this.status,
    this.dateEntered,
    this.createdAt,
    this.updatedAt,
    this.teacherId,
    this.attendanceDate,
    this.attendanceEnum,
    this.classId,
    this.finalScore,
    this.midtermScore,
    this.quizScore,
    this.totalAttendanceScore,
    this.scoreStatus,
    this.oldFinalScore,
    this.oldMidtermScore,
    this.oldQuizScore,
    this.commune,
    this.district,
    this.documentNumber,
    this.documentType,
    this.familyCommune,
    this.familyDistrict,
    this.familyProvince,
    this.familyVillage,
    this.province,
    this.stBirthCommune,
    this.stBirthDistrict,
    this.stBirthProvince,
    this.stBirthVillage,
    this.village,
    this.paymentDate,
    this.paymentType,
    this.nextPaymentDate,
  });

  String get displayName => '$engName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String,
      khName: json['kh_name'] as String,
      engName: json['eng_name'] as String,
      gender: json['gender'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['image'] as String?,
      // address: json['address'] as String?, // REMOVED from parsing
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      fatherPhone: json['father_phone'] as String?,
      motherPhone: json['mother_phone'] as String?,
      score: json['score'] is int
          ? json['score']
          : (json['score'] is double ? json['score'].toInt() : null),
      attendance: json['attendence'] is int
          ? json['attendence']
          : (json['attendence'] is double ? json['attendence'].toInt() : null),
      rentalBook: json['rental_book'] as List<dynamic>?,
      status: json['status'] as bool?,
      dateEntered: json['date_intered'] != null
          ? DateTime.tryParse(json['date_intered'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      teacherId: json['teacher'] as String?,
      attendanceDate: json['attendence_date'] != null
          ? DateTime.tryParse(json['attendence_date'])
          : null,
      attendanceEnum: json['attendence_enum'] as String?,
      classId: json['student_type'] as String?,
      finalScore: json['final_score'] is int
          ? json['final_score']
          : (json['final_score'] is double
              ? json['final_score'].toInt()
              : null),
      midtermScore: json['midterm_score'] is int
          ? json['midterm_score']
          : (json['midterm_score'] is double
              ? json['midterm_score'].toInt()
              : null),
      quizScore: json['quiz_score'] is int
          ? json['quiz_score']
          : (json['quiz_score'] is double ? json['quiz_score'].toInt() : null),
      totalAttendanceScore: json['total_attendance_score'] is int
          ? json['total_attendance_score']
          : (json['total_attendance_score'] is double
              ? json['total_attendance_score'].toInt()
              : null),
      scoreStatus: json['score_status'] as String?,
      oldFinalScore: json['old_final_score'] is int
          ? json['old_final_score']
          : (json['old_final_score'] is double
              ? json['old_final_score'].toInt()
              : null),
      oldMidtermScore: json['old_midterm_score'] is int
          ? json['old_midterm_score']
          : (json['old_midterm_score'] is double
              ? json['old_midterm_score'].toInt()
              : null),
      oldQuizScore: json['old_quiz_score'] is int
          ? json['old_quiz_score']
          : (json['old_quiz_score'] is double
              ? json['old_quiz_score'].toInt()
              : null),
      commune: json['commune'] as String?,
      district: json['district'] as String?,
      documentNumber: json['document_number'] as String?,
      documentType: json['document_type'] as String?,
      familyCommune: json['family_commune'] as String?,
      familyDistrict: json['family_district'] as String?,
      familyProvince: json['family_province'] as String?,
      familyVillage: json['family_village'] as String?,
      province: json['province'] as String?,
      stBirthCommune: json['st_birth_commune'] as String?,
      stBirthDistrict: json['st_birth_district'] as String?,
      stBirthProvince: json['st_birth_province'] as String?,
      stBirthVillage: json['st_birth_village'] as String?,
      village: json['village'] as String?,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'])
          : null,
      paymentType: json['payment_type'] as String?,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.tryParse(json['next_payment_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'kh_name': khName,
      'eng_name': engName,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'email': email,
      'image': avatarUrl,
      // 'address': address, // REMOVED from toJson
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'father_name': fatherName,
      'mother_name': motherName,
      'father_phone': fatherPhone,
      'mother_phone': motherPhone,
      'score': score,
      'attendence': attendance,
      'rental_book': rentalBook,
      'status': status,
      'date_intered': dateEntered?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'teacher': teacherId,
      'attendence_date': attendanceDate?.toIso8601String(),
      'attendence_enum': attendanceEnum,
      'student_type': classId,
      'final_score': finalScore,
      'midterm_score': midtermScore,
      'quiz_score': quizScore,
      'total_attendance_score': totalAttendanceScore,
      'score_status': scoreStatus,
      'old_final_score': oldFinalScore,
      'old_midterm_score': oldMidtermScore,
      'old_quiz_score': oldQuizScore,
      'commune': commune,
      'district': district,
      'document_number': documentNumber,
      'document_type': documentType,
      'family_commune': familyCommune,
      'family_district': familyDistrict,
      'family_province': familyProvince,
      'family_village': familyVillage,
      'province': province,
      'st_birth_commune': stBirthCommune,
      'st_birth_district': stBirthDistrict,
      'st_birth_province': stBirthProvince,
      'st_birth_village': stBirthVillage,
      'village': village,
      'payment_date': paymentDate?.toIso8601String().split('T').first,
      'payment_type': paymentType,
      'next_payment_date': nextPaymentDate?.toIso8601String().split('T').first,
    };
  }
}
