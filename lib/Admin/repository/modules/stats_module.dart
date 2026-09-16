import 'package:al_maqraa/core/models/shared_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dashboard_stats_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/global_batch_controller.dart';

mixin StatsModule {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<DashboardStatsModel> getUnifiedStats(int year) async {
    try {
      int? batchFilter;
      Gender? genderFilter;
      if (Get.isRegistered<GlobalBatchController>()) {
        final gbc = Get.find<GlobalBatchController>();
        batchFilter = gbc.selectedBatch.value;
        genderFilter = gbc.selectedGender.value;
      }

      final adminResponse = await supabase.from('admins').select('id');
      final adminIds = (adminResponse as List).map((a) => a['id'].toString()).toSet();

      var tAppQuery = supabase
          .from('registration_requests')
          .select()
          .eq('status', 'pending')
          .eq('role', 'teacher');
      if (batchFilter != null) {
        tAppQuery = tAppQuery.eq('batch_number', batchFilter);
      }
      final tApplicantsResp = await tAppQuery;
      int tApplicants = 0;
      final tAppFiltered = (tApplicantsResp as List)
          .where((req) => !adminIds.contains(req['id'].toString()));
      
      if (genderFilter != null && genderFilter != Gender.all) {
        tApplicants = tAppFiltered
            .where((req) => req['gender'] == genderFilter!.name)
            .length;
      } else {
        tApplicants = tAppFiltered.length;
      }

      var sAppQuery = supabase
          .from('registration_requests')
          .select()
          .eq('status', 'pending')
          .eq('role', 'student');
      if (batchFilter != null) {
        sAppQuery = sAppQuery.eq('batch_number', batchFilter);
      }
      final sApplicantsResp = await sAppQuery;
      int sApplicants = 0;
      final sAppFiltered = (sApplicantsResp as List)
          .where((req) => !adminIds.contains(req['id'].toString()));

      if (genderFilter != null && genderFilter != Gender.all) {
        sApplicants = sAppFiltered
            .where((req) => req['gender'] == genderFilter!.name)
            .length;
      } else {
        sApplicants = sAppFiltered.length;
      }

      var tAccQuery = supabase
          .from('profiles')
          .select('id')
          .eq('role', 'teacher');
      if (batchFilter != null) {
        tAccQuery = tAccQuery.eq('batch_number', batchFilter);
      }
      if (genderFilter != null && genderFilter != Gender.all) {
        tAccQuery = tAccQuery.eq('gender', genderFilter.name);
      }
      final tAcceptedResp = await tAccQuery;
      final tAccepted = (tAcceptedResp as List)
          .where((data) => !adminIds.contains(data['id'].toString()))
          .length;

      var sAccQuery = supabase
          .from('profiles')
          .select('id')
          .eq('role', 'student');
      if (batchFilter != null)
        sAccQuery = sAccQuery.eq('batch_number', batchFilter);
      if (genderFilter != null && genderFilter != Gender.all)
        sAccQuery = sAccQuery.eq('gender', genderFilter.name);
      final sAcceptedResp = await sAccQuery;
      final sAccepted = (sAcceptedResp as List)
          .where((data) => !adminIds.contains(data['id'].toString()))
          .length;

      var circlesQuery = supabase
          .from('circles')
          .select('id, teacher:profiles!teacher_id(gender)');
      if (batchFilter != null) {
        circlesQuery = circlesQuery.eq('batch_number', batchFilter);
      }

      final circlesResp = await circlesQuery;
      int totalCircles = 0;

      if (genderFilter != null && genderFilter != Gender.all) {
        totalCircles = (circlesResp as List).where((c) {
          final t = c['teacher'];
          if (t != null && t['gender'] == genderFilter!.name) return true;
          if (c['gender'] == genderFilter!.name) return true;
          return false;
        }).length;
      } else {
        totalCircles = (circlesResp as List).length;
      }

      // جلب أحجام النظام
      String dbSize = '0 MB';
      String storageSize = '0 MB';
      try {
         final usage = await getUsageStats();
         dbSize = usage['db'] ?? '0 MB';
         storageSize = usage['storage'] ?? '0 MB';
      } catch(_) {}

      return DashboardStatsModel(
        teacherApplicants: tApplicants,
        studentApplicants: sApplicants,
        acceptedTeachers: tAccepted,
        acceptedStudents: sAccepted,
        unreadTeacherChats: 0,
        unreadStudentChats: 0,
        totalCircles: totalCircles,
        dbSize: dbSize,
        storageSize: storageSize,
      );
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_fetch_stats'.tr, 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
      return DashboardStatsModel.empty();
    }
  }

  Future<Map<String, String>> getUsageStats() async {
    try {
      final res = await supabase.rpc('get_system_usage_stats');
      if (res is List && res.isNotEmpty) {
        final item = res.first as Map<String, dynamic>;
        return {
          'db': item['db_size']?.toString() ?? '0 MB',
          'storage': item['storage_size']?.toString() ?? '0 MB',
        };
      } else if (res is Map) {
        return {
          'db': res['db_size']?.toString() ?? '0 MB',
          'storage': res['storage_size']?.toString() ?? '0 MB',
        };
      }
      return {'db': '0 MB', 'storage': '0 MB'};
    } catch (e) {
      Get.log("Error in getUsageStats: $e");
      return {'db': 'Error', 'storage': 'Error'};
    }
  }

  Future<bool> clearMedia() async {
    try {
      final buckets = await supabase.storage.listBuckets();
      for (final b in buckets) {
        try {
          await supabase.storage.emptyBucket(b.id);
        } catch (err) {
          try {
            final files = await supabase.storage.from(b.id).list();
            if (files.isNotEmpty) {
              final paths = files.map((f) => f.name).toList();
              await supabase.storage.from(b.id).remove(paths);
            }
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      Get.log("Error clearMedia via Storage API: $e");
      return false;
    }
  }

  Future<bool> clearAllPeriodRecords() async {
    try {
      // حذف الجداول بالترتيب لتجنب أي قيود مفاتيح أجنبية (Foreign Keys)
      try {
        await supabase.from('messages').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete messages: $e");
      }

      try {
        await supabase.from('chats').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete chats: $e");
      }

      try {
        await supabase.from('daily_records').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete daily_records: $e");
      }

      try {
        await supabase.from('monthly_exams').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete monthly_exams: $e");
      }

      try {
        await supabase.from('monthly_records').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete monthly_records: $e");
      }

      try {
        await supabase.from('notifications').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        Get.log("Delete notifications: $e");
      }

      return true;
    } catch (e) {
      Get.log("Error in clearAllPeriodRecords: $e");
      return false;
    }
  }

  Future<bool> deleteOldData(String table, int year, {int? month}) async {
    try {
      await supabase.rpc('delete_records_by_date', params: {
        'target_table': table,
        'yr': year,
        'mo': month,
      });
      return true;
    } catch (e) {
      Get.log("RPC delete_records_by_date failed, trying direct date filtering: $e");
      try {
        DateTime startDate;
        DateTime endDate;
        if (month != null) {
          startDate = DateTime(year, month, 1);
          endDate = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
        } else {
          startDate = DateTime(year, 1, 1);
          endDate = DateTime(year + 1, 1, 1);
        }
        await supabase
            .from(table)
            .delete()
            .gte('created_at', startDate.toIso8601String())
            .lt('created_at', endDate.toIso8601String());
        return true;
      } catch (err) {
        Get.log("Direct deleteOldData error: $err");
        return false;
      }
    }
  }
}
