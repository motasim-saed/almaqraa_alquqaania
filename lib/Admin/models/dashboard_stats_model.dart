class DashboardStatsModel {
  final int teacherApplicants;
  final int studentApplicants;
  final int acceptedTeachers;
  final int acceptedStudents;
  final int unreadTeacherChats;
  final int unreadStudentChats;
  final int totalCircles;
  
  // الحقول الجديدة للإحصائيات التقنية
  final String dbSize;
  final String storageSize;
  final String bandwidth; // إضافة الباندويث

  DashboardStatsModel({
    required this.teacherApplicants,
    required this.studentApplicants,
    required this.acceptedTeachers,
    required this.acceptedStudents,
    required this.unreadTeacherChats,
    required this.unreadStudentChats,
    required this.totalCircles,
    this.dbSize = '0 MB',
    this.storageSize = '0 MB',
    this.bandwidth = '0 MB',
  });

  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      teacherApplicants: 0,
      studentApplicants: 0,
      acceptedTeachers: 0,
      acceptedStudents: 0,
      unreadTeacherChats: 0,
      unreadStudentChats: 0,
      totalCircles: 0,
      dbSize: '0 MB',
      storageSize: '0 MB',
      bandwidth: '0 MB',
    );
  }

  int get totalPending => teacherApplicants + studentApplicants;
  int get totalUnreadMessages => unreadTeacherChats + unreadStudentChats;

  Map<String, dynamic> toJson() {
    return {
      'teacherApplicants': teacherApplicants,
      'studentApplicants': studentApplicants,
      'acceptedTeachers': acceptedTeachers,
      'acceptedStudents': acceptedStudents,
      'unreadTeacherChats': unreadTeacherChats,
      'unreadStudentChats': unreadStudentChats,
      'totalCircles': totalCircles,
      'dbSize': dbSize,
      'storageSize': storageSize,
      'bandwidth': bandwidth,
    };
  }

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      teacherApplicants: json['teacherApplicants'] ?? 0,
      studentApplicants: json['studentApplicants'] ?? 0,
      acceptedTeachers: json['acceptedTeachers'] ?? 0,
      acceptedStudents: json['acceptedStudents'] ?? 0,
      unreadTeacherChats: json['unreadTeacherChats'] ?? 0,
      unreadStudentChats: json['unreadStudentChats'] ?? 0,
      totalCircles: json['totalCircles'] ?? 0,
      dbSize: json['dbSize'] ?? '0 MB',
      storageSize: json['storageSize'] ?? '0 MB',
      bandwidth: json['bandwidth'] ?? '0 MB',
    );
  }
}
