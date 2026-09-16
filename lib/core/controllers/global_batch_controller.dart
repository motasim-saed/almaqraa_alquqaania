import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:al_maqraa/core/models/shared_models.dart';

class GlobalBatchController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final _storage = GetStorage();
  final String _storageKey = 'selected_batch_filter';

  RxnInt selectedBatch = RxnInt(null);
  RxnInt stagedBatch = RxnInt(null); // الاختيار الحالي في القائمة (قبل التطبيق)
  RxList<int> availableBatches = <int>[].obs;
  RxBool isLoadingBatches = false.obs;

  var selectedGender = Gender.all.obs;
  var stagedGender = Gender.all.obs;

  int systemDefaultBatch = 1;

  final TextEditingController filterController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // البدء بـ "الجميع" (null) كقيمة افتراضية دائماً كما طلب المستخدم
    selectedBatch.value = null;
    stagedBatch.value = null;
    selectedGender.value = Gender.all;
    stagedGender.value = Gender.all;
    filterController.clear();

    fetchAvailableBatches();
  }

  @override
  void onClose() {
    filterController.dispose();
    super.onClose();
  }

  // دالة لتطبيق الفلترة المختارة حالياً
  void applyFilter() {
    selectedBatch.value = stagedBatch.value;
    selectedGender.value = stagedGender.value;
    // تخزين الاختيار في الذاكرة (اختياري، سنبقي عليه للتكامل مع بقية النظام)
    if (selectedBatch.value != null) {
      _storage.write(_storageKey, selectedBatch.value);
    } else {
      _storage.remove(_storageKey);
    }
  }

  // تحديث الاختيار المؤقت (Staged)
  void updateStagedBatch(int? newBatch) {
    if (newBatch == -1) {
      stagedBatch.value = null;
    } else {
      stagedBatch.value = newBatch;
    }
  }

  void updateStagedGender(Gender newGender) {
    stagedGender.value = newGender;
  }

  Future<void> fetchAvailableBatches() async {
    isLoadingBatches.value = true;
    try {
      final Set<int> batches = {};

      // 1. Fetch default batch number
      try {
        final settingsResp = await supabase
            .from('management_systemsetting')
            .select('default_batch_number')
            .limit(1)
            .maybeSingle();

        // تم تعديل الشرط هنا لتجنب التحذيرات غير الضرورية
        if (settingsResp != null) {
          final defaultBatch = settingsResp['default_batch_number'];
          if (defaultBatch != null) {
            systemDefaultBatch = int.parse(defaultBatch.toString());
            batches.add(systemDefaultBatch);
          }
        }
      } catch (e) {
      }

      // 2. اكتشاف الدفعات من الجداول
      final discoveryTables = ['profiles', 'registration_requests', 'circles'];

      for (var table in discoveryTables) {
        try {
          final resp = await supabase.from(table).select('batch_number');

          // تحويل النتيجة بشكل آمن لتجنب تحذيرات Unnecessary cast
          final List data = resp as List;
          for (var row in data) {
            if (row['batch_number'] != null) {
              final val = int.tryParse(row['batch_number'].toString());
              if (val != null) {
                batches.add(val);
              }
            }
          }
        } catch (e) {
        }
      }

      final sortedBatches = batches.toList()..sort();
      availableBatches.assignAll(sortedBatches);
    } catch (e) {
    } finally {
      isLoadingBatches.value = false;
    }
  }

  void changeBatch(int? newBatch) {
    if (newBatch == -1) {
      newBatch = null;
    }

    selectedBatch.value = newBatch;
    if (newBatch != null) {
      filterController.text = newBatch.toString();
      _storage.write(_storageKey, newBatch);
    } else {
      filterController.clear();
      _storage.remove(_storageKey);
    }
  }

  void updateBatchFromText(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      selectedBatch.value = null;
      _storage.remove(_storageKey);
    } else {
      final num = int.tryParse(trimmedText);
      if (num != null) {
        selectedBatch.value = num;
        _storage.write(_storageKey, num);
      }
    }
  }
}
