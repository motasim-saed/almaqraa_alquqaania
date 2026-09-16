// استيراد حزمة Supabase للتعامل مع قاعدة البيانات السحابية
import 'package:supabase_flutter/supabase_flutter.dart';
// استيراد حزمة GetX لإدارة الحالة والاعتماديات
import 'package:get/get.dart';
// استيراد خدمة قاعدة البيانات المحلية للتخزين دون اتصال
import '../../core/services/local_database_service.dart';
// استيراد النماذج الخاصة بالطالب
import '../models/student_models.dart';
// استيراد الواجهة الأساسية لمستودع بيانات الطالب
import 'student_repository.dart';

/// فئة تنفذ عمليات مستودع بيانات الطالب باستخدام Supabase (قاعدة بيانات سحابية)
class SupabaseStudentRepository implements StudentRepository {
  // إنشاء نسخة من عميل Supabase للاتصال بقاعدة البيانات
  final SupabaseClient _supabase = Supabase.instance.client;
  // جلب خدمة قاعدة البيانات المحلية عبر GetX
  final _localDb = Get.find<LocalDatabaseService>();

  /// جلب الخطط السنوية الخاصة بالطالب
  @override
  Future<List<AnnualPlanModel>> getAnnualPlans(String studentId) async {
    if (studentId.isEmpty || studentId.length < 5) {
      return []; // الحماية من UUID غير صالح
    }
    try {
      final response = await _supabase
          .from('annual_plans')
          .select()
          .eq('student_id', studentId);

      final plans = (response as List)
          .map((data) => AnnualPlanModel.fromJson(data))
          .toList();

      for (var plan in plans) {
        await _localDb.insertOrUpdate('plans', {
          ...plan.toJson(),
          'type': 'annual',
        });
      }

      return plans;
    } catch (e) {
      final localData = await _localDb.query(
        'plans',
        where: 'student_id = ? AND type = ?',
        whereArgs: [studentId, 'annual'],
        orderBy: 'year DESC',
      );
      return localData.map((data) => AnnualPlanModel.fromJson(data)).toList();
    }
  }

  @override
  Future<void> saveAnnualPlan(AnnualPlanModel plan) async {
    try {
      await _supabase
          .from('annual_plans')
          .upsert(plan.toJson(), onConflict: 'student_id,year');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<MonthlyPlanModel>> getMonthlyPlans(String studentId) async {
    if (studentId.isEmpty || studentId.length < 5) return [];
    try {
      final response = await _supabase
          .from('monthly_plans')
          .select()
          .eq('student_id', studentId);

      final plans = (response as List)
          .map((data) => MonthlyPlanModel.fromJson(data))
          .toList();

      for (var plan in plans) {
        await _localDb.insertOrUpdate('plans', {
          ...plan.toJson(),
          'type': 'monthly',
        });
      }

      return plans;
    } catch (e) {
      final localData = await _localDb.query(
        'plans',
        where: 'student_id = ? AND type = ?',
        whereArgs: [studentId, 'monthly'],
        orderBy: 'year DESC, month DESC',
      );
      return localData.map((data) => MonthlyPlanModel.fromJson(data)).toList();
    }
  }

  @override
  Future<void> saveMonthlyPlan(MonthlyPlanModel plan) async {
    try {
      await _supabase
          .from('monthly_plans')
          .upsert(plan.toJson(), onConflict: 'student_id,year,month');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<DailyRecordModel>> getDailyRecords(String studentId) async {
    if (studentId.isEmpty || studentId.length < 5) return [];
    try {
      final response = await _supabase
          .from('daily_records')
          .select()
          .eq('student_id', studentId)
          .order('date', ascending: false);

      final records = (response as List)
          .map((data) => DailyRecordModel.fromJson(data))
          .toList();

      for (var record in records) {
        await _localDb.insertOrUpdate('daily_records', record.toJson());
      }

      return records;
    } catch (e) {
      final localData = await _localDb.query(
        'daily_records',
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'date DESC',
      );
      return localData.map((data) => DailyRecordModel.fromJson(data)).toList();
    }
  }

  /// حفظ تسجيل يومي جديد - تم تحسينه لضمان الرفع
  @override
  Future<void> saveDailyRecord(DailyRecordModel record) async {
    try {
      // إزالة المعرف 'id' إذا كان فارغاً ليقوم Supabase بتوليده تلقائياً
      final recordData = record.toJson();
      if (record.id.isEmpty) {
        recordData.remove('id');
      }

      // محاولة إضافة السجل في الخادم
      // نستخدم insert بدلاً من upsert لضمان عملية إضافة نظيفة ما لم يكن هناك منطق تكرار محدد
      await _supabase.from('daily_records').insert(recordData);

      // حفظ في القاعدة المحلية وتحديد أنه متزامن (is_synced = 1)
      await _localDb.insertOrUpdate('daily_records', {
        ...record.toJson(),
        'is_synced': 1,
      });
    } catch (e) {
      // في حالة الخطأ (مثل انقطاع الإنترنت)، احفظ السجل محلياً وحدده كغير متزامن (is_synced = 0)
      await _localDb.insertOrUpdate('daily_records', {
        ...record.toJson(),
        'is_synced': 0,
      });
      // إذا كان الخطأ ليس بسبب الشبكة، نقوم برميه لمعرفته
      if (!e.toString().contains('SocketException') &&
          !e.toString().contains('network')) {
        rethrow;
      }
    }
  }

  @override
  Future<void> updateDailyRecord(DailyRecordModel record) async {
    try {
      await _supabase
          .from('daily_records')
          .update(record.toJson())
          .eq('id', record.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatContacts(
    String studentId,
    String role,
  ) async {
    try {
      Set<String> personIds = {};

      if (role == 'teacher') {
        final circlesResponse = await _supabase
            .from('circles')
            .select('id, examiner_id')
            .eq('teacher_id', studentId);

        final List circles = circlesResponse as List;
        final circleIds = circles
            .map((e) => e['id']?.toString())
            .whereType<String>()
            .toList();

        for (var c in circles) {
          if (c['examiner_id'] != null) {
            personIds.add(c['examiner_id'].toString());
          }
        }

        if (circleIds.isNotEmpty) {
          final membersResponse = await _supabase
              .from('circle_members')
              .select('student_id')
              .filter('circle_id', 'in', circleIds);

          for (var row in membersResponse as List) {
            if (row['student_id'] != null) {
              personIds.add(row['student_id'].toString());
            }
          }
        }
      } else if (role == 'examiner') {
        final circlesResponse = await _supabase
            .from('circles')
            .select('id, teacher_id')
            .eq('examiner_id', studentId);

        final List circles = circlesResponse as List;
        final circleIds = circles
            .map((e) => e['id']?.toString())
            .whereType<String>()
            .toList();

        for (var c in circles) {
          if (c['teacher_id'] != null) {
            personIds.add(c['teacher_id'].toString());
          }
        }

        if (circleIds.isNotEmpty) {
          final membersResponse = await _supabase
              .from('circle_members')
              .select('student_id')
              .filter('circle_id', 'in', circleIds);

          for (var row in membersResponse as List) {
            if (row['student_id'] != null) {
              personIds.add(row['student_id'].toString());
            }
          }
        }
      } else {
        final memberships = await _supabase
            .from('circle_members')
            .select('circle_id')
            .eq('student_id', studentId);

        final circleIds = (memberships as List)
            .map((e) => e['circle_id']?.toString())
            .whereType<String>()
            .toList();

        if (circleIds.isNotEmpty) {
          final circles = await _supabase
              .from('circles')
              .select('teacher_id, examiner_id')
              .filter('id', 'in', circleIds);

          for (var row in circles as List) {
            if (row['teacher_id'] != null) {
              personIds.add(row['teacher_id'].toString());
            }
            if (row['examiner_id'] != null) {
              personIds.add(row['examiner_id'].toString());
            }
          }

          final peers = await _supabase
              .from('circle_members')
              .select('student_id')
              .filter('circle_id', 'in', circleIds);

          for (var row in peers as List) {
            if (row['student_id'] != null && row['student_id'] != studentId) {
              personIds.add(row['student_id'].toString());
            }
          }
        }
      }

      if (personIds.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, role, avatar_url')
          .filter('id', 'in', personIds.toList());

      final chatsResponse = await _supabase
          .from('chats')
          .select()
          .or('student_id.eq.$studentId,teacher_id.eq.$studentId');

      Map<String, Map<String, dynamic>> chatDataMap = {};
      for (var chat in chatsResponse as List) {
        if (chat['type'] == 'circle_group') continue;

        final sId = chat['student_id']?.toString();
        final tId = chat['teacher_id']?.toString();
        final otherId = sId == studentId ? tId : sId;

        if (otherId != null) {
          final dateStr = chat['updated_at'];
          final chatDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
          final existingDate = chatDataMap[otherId]?['date'] as DateTime?;

          if (chatDate != null &&
              (existingDate == null || chatDate.isAfter(existingDate))) {
            chatDataMap[otherId] = {
              'msg': null,
              'date': chatDate,
            };
          }
        }
      }

      final unreadResponse = await _supabase
          .from('messages')
          .select('sender_id')
          .neq('sender_id', studentId)
          .eq('receiver_id', studentId)
          .filter('read_at', 'is', null);

      Map<String, int> unreadCounts = {};
      for (var row in unreadResponse as List) {
        final sid = row['sender_id'].toString();
        unreadCounts[sid] = (unreadCounts[sid] ?? 0) + 1;
      }

      final contacts = (profilesResponse as List)
          .where(
            (row) => row['id'].toString() != studentId,
          ) // استثناء الطالب من قائمته الشخصية
          .map((row) {
            final pid = row['id'].toString();
            return {
              'id': pid,
              'name': row['full_name'],
              'role': row['role'],
              'avatar_url': row['avatar_url'],
              'last_message': null,
              'updated_at': chatDataMap[pid]?['date']?.toIso8601String(),
              'unread_count': unreadCounts[pid] ?? 0,
            };
          })
          .toList();

      for (var row in profilesResponse) {
        await _localDb.insertOrUpdate('profiles', {
          'id': row['id'].toString(),
          'full_name': row['full_name'],
          'role': row['role'],
          'avatar_url': row['avatar_url'],
        });
      }

      return contacts;
    } catch (e) {
      final localProfiles = await _localDb.query('profiles');
      return localProfiles
          .map(
            (row) => {
              'id': row['id'],
              'name': row['full_name'],
              'role': row['role'],
              'avatar_url': row['avatar_url'],
              'last_message': null,
              'updated_at': null,
              'unread_count': 0,
            },
          )
          .toList();
    }
  }

  static Map<String, dynamic>? _cachedAdmin;

  @override
  Future<Map<String, dynamic>?> getFirstAdmin() async {
    // 1. استخدام الذاكرة السريعة إن وُجدت
    if (_cachedAdmin != null) {
      _refreshAdminInBackground();
      return _cachedAdmin;
    }

    // 2. فحص قاعدة البيانات المحلية فوراً (0ms)
    try {
      final localAdmin = await _localDb.query(
        'profiles',
        where: 'role = ? OR role = ?',
        whereArgs: ['coordinator', 'admin'],
        orderBy: 'role DESC',
      );
      if (localAdmin.isNotEmpty) {
        _cachedAdmin = localAdmin.first;
        _refreshAdminInBackground();
        return _cachedAdmin;
      }
    } catch (_) {}

    // 3. جلب البيانات عبر استعلام واحد سريع من Supabase في حال عدم وجودها محلياً
    try {
      final res = await _supabase
          .from('profiles')
          .select('id, full_name, role, avatar_url')
          .filter('role', 'in', ['coordinator', 'admin'])
          .order('role', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        _cachedAdmin = res;
        await _localDb.insertOrUpdate('profiles', res);
        return res;
      }
    } catch (e) {
      // في حال الخطأ نرجع النتيجة المحلية إن توفرت
      try {
        final localAdmin = await _localDb.query(
          'profiles',
          where: 'role = ? OR role = ?',
          whereArgs: ['coordinator', 'admin'],
          orderBy: 'role DESC',
        );
        if (localAdmin.isNotEmpty) return localAdmin.first;
      } catch (_) {}
    }
    return null;
  }

  void _refreshAdminInBackground() {
    _supabase
        .from('profiles')
        .select('id, full_name, role, avatar_url')
        .filter('role', 'in', ['coordinator', 'admin'])
        .order('role', ascending: false)
        .limit(1)
        .maybeSingle()
        .then((freshAdmin) {
      if (freshAdmin != null) {
        _cachedAdmin = freshAdmin;
        _localDb.insertOrUpdate('profiles', freshAdmin);
      }
    }).catchError((_) {});
  }

  @override
  Future<Map<String, dynamic>?> getStudentDetailedInfo(String studentId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(
            '*, circle_members(circles(name, teacher:profiles!circles_teacher_id_fkey(full_name)))',
          )
          .eq('id', studentId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
