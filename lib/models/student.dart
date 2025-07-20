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
  // Existing score and attendance fields - keep them for now as they might be used elsewhere
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

  // New fields for Academic & Attendance from API
  final int? classPractice;
  final int? homeWork;
  final int? assignmentScore;
  final int? presentation;
  final int? revisionTest;
  final int? finalExam;
  final int? totalOverallScore;
  final int? workBook;
  final String? note;
  final String? exitTime;
  final String? entryTime;
  final String? comments;
  final String? checkingAt;

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
    // Initialize new fields
    this.classPractice,
    this.homeWork,
    this.assignmentScore,
    this.presentation,
    this.revisionTest,
    this.finalExam,
    this.totalOverallScore,
    this.workBook,
    this.note,
    this.exitTime,
    this.entryTime,
    this.comments,
    this.checkingAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // If the API response sometimes nests student data under a 'student' key,
    // this logic handles it. Otherwise, 'studentJson' will simply be the 'json' itself.
    Map<String, dynamic> studentJson = json;
    if (json.containsKey('student') &&
        json['student'] is Map<String, dynamic>) {
      studentJson = json['student'] as Map<String, dynamic>;
    }

    return Student(
      id: studentJson['_id'] as String,
      khName: studentJson['kh_name'] as String,
      engName: studentJson['eng_name'] as String,
      gender: studentJson['gender'] as String,
      phoneNumber: studentJson['phoneNumber'] as String,
      email: studentJson['email'] as String?,
      avatarUrl: studentJson['image'] as String?, // 'image' field in JSON
      address: studentJson['address'] as String?,
      dateOfBirth: studentJson['date_of_birth'] != null
          ? DateTime.tryParse(studentJson['date_of_birth'])
          : null,
      fatherName: studentJson['father_name'] as String?,
      motherName: studentJson['mother_name'] as String?,
      score: (studentJson['score'] as num?)?.toInt(),
      attendance:
          (studentJson['attendence'] as num?)?.toInt(), // 'attendence' field
      attendanceDate: studentJson['attendence_date'] != null
          ? DateTime.tryParse(studentJson['attendence_date'])
          : null,
      attendanceEnum: studentJson['attendence_enum'] as String?,
      studentType: studentJson['student_type'] as String?,
      finalScore: (studentJson['final_score'] as num?)?.toInt(),
      midtermScore: (studentJson['midterm_score'] as num?)?.toInt(),
      quizScore: (studentJson['quiz_score'] as num?)?.toInt(),
      totalAttendanceScore:
          (studentJson['total_attendance_score'] as num?)?.toInt(),
      scoreStatus: studentJson['score_status'] as String?,
      commune: studentJson['commune'] as String?,
      district: studentJson['district'] as String?,
      province: studentJson['province'] as String?,
      village: studentJson['village'] as String?,
      paymentDate: studentJson['payment_date'] != null
          ? DateTime.tryParse(studentJson['payment_date'])
          : null,
      paymentType: studentJson['payment_type'] as String?,
      nextPaymentDate: studentJson['next_payment_date'] != null
          ? DateTime.tryParse(studentJson['next_payment_date'])
          : null,
      fatherPhone: studentJson['father_phone'] as String?,
      motherPhone: studentJson['mother_phone'] as String?,
      documentType: studentJson['document_type'] as String?,
      documentNumber: studentJson['document_number'] as String?,
      status: studentJson['status'] as bool?, // 'status' field

      // Parse new fields from studentJson, assuming they are always part of the student object
      classPractice: (studentJson['class_practice'] as num?)?.toInt(),
      homeWork: (studentJson['home_work'] as num?)?.toInt(),
      assignmentScore: (studentJson['assignment_score'] as num?)?.toInt(),
      presentation: (studentJson['presentation'] as num?)?.toInt(),
      revisionTest: (studentJson['revision_test'] as num?)?.toInt(),
      finalExam: (studentJson['final_exam'] as num?)?.toInt(),
      totalOverallScore: (studentJson['total_score'] as num?)?.toInt(),
      workBook: (studentJson['work_book'] as num?)?.toInt(),
      note: studentJson['note'] as String?,
      exitTime: studentJson['exit_time'] as String?,
      entryTime: studentJson['entry_time'] as String?,
      comments: studentJson['comments'] as String?,
      checkingAt: studentJson['checking_at'] as String?,
    );
  }

  String get displayName {
    return engName.isNotEmpty ? engName : khName;
  }
}
