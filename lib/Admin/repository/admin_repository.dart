import '../models/admin_models.dart';
import '../models/dashboard_stats_model.dart';
import '../../Student/models/student_models.dart';
import '../../core/models/notification_model.dart';
import '../../Teacher/models/daily_attendance_record_model.dart';
import '../../Teacher/models/monthly_exam_model.dart';
import '../../Teacher/models/monthly_record_model.dart';
import '../models/yearly_record_model.dart';
import '../models/system_setting_model.dart';

abstract class AdminRepository {
  Future<SystemSettingModel?> getSystemSettings();
  Future<bool> updateSystemSettings(SystemSettingModel settings);
  Future<DashboardStatsModel> getUnifiedStats(int year);
  
  // Storage & Maintenance
  Future<Map<String, String>> getUsageStats();
  Future<bool> clearMedia();
  Future<bool> clearAllPeriodRecords();
  Future<bool> deleteOldData(String table, int year, {int? month});

  Future<List<TeacherModel>> getTeachers({required String status});
  Future<List<StudentModel>> getStudents({required String status});
  Future<bool> deleteTeacher(String id);
  Future<bool> deleteStudent(String id);
  Future<void> setStudentsDistributed(List<String> ids, bool isDistributed);
  Future<bool> updateTeacherSponsorship(String id, bool canCover, {double? amount, String? package});
  Future<bool> updateUserBatch(String id, int batchNumber);
  Future<bool> transferStudent(String studentId, String newCircleId);
  Future<List<QuranCircleModel>> getQuranCircles();
  Future<void> updateCircleExaminer(String circleId, String? examinerId);
  Future<List<ChatModel>> getChats();
  Future<List<MessageModel>> getMessages(String chatId);
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  Future<void> deleteMessageFromServer(String messageId);
  Future<void> markMessagesAsRead(String chatId);
  Future<bool> sendMessage(String chatId, String senderId, String text, {String? audioUrl, String? imageUrl, String? videoUrl});
  Future<String> uploadFile(String bucket, String path, String filePath);
  Future<List<ChatUserModel>> getAllUserProfiles();
  Future<bool> updateChatStatus(String chatId, String status);
  Future<List<AnnualPlanModel>> getStudentAnnualPlans(String studentId);
  Future<List<MonthlyPlanModel>> getStudentMonthlyPlans(String studentId);
  Future<void> deleteAnnualPlan(String planId);
  Future<void> deleteMonthlyPlan(String planId);
  Future<List<DailyRecordModel>> getStudentDailyRecords(String studentId);
  Future<String?> getOrCreateChat(String userId, String? type);
  Future<bool> sendNotification(String title, String body, String targetRole);
  Future<List<NotificationModel>> getSentNotifications();
  Future<bool> updateNotification(String id, String title, String body, String targetRole);
  Future<bool> deleteNotification(String id);
  Future<List<DailyAttendanceRecord>> getCircleAttendance(String circleId, {int? month, int? year, Function(List<DailyAttendanceRecord>)? onRefresh, bool forceRefresh = false});
  Future<List<MonthlyExamRecord>> getCircleExams(String circleId, {int? month, int? year});
  Future<List<MonthlyRecord>> getCircleMonthlyGrades(String circleId, {int? month, int? year, Function(List<MonthlyRecord>)? onRefresh});
  Future<List<YearlyRecord>> getCircleYearlyGrades(String circleId, {int? year});
  Future<List<HolidayModel>> getHolidays();
  Future<bool> addHoliday(HolidayModel holiday);
  Future<bool> deleteHoliday(String id);
  Future<bool> assignStudentLeave({String? studentId, required DateTime startDate, required DateTime endDate, required String reason});
  Future<List<AdminUserModel>> getUsersByRoles(List<String> roles);
  Future<bool> createManagementUser({required String name, required String email, required String password, required String role, required String gender});
}
