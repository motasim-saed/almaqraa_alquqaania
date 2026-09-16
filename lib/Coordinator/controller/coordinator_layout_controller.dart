import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للتعامل مع الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة والتنقل
import '../../Admin/controller/chat_controller.dart'; // استيراد متحكم الدردشة الخاص بالأدمن لاستخدامه هنا
import '../../Admin/repository/admin_repository.dart'; // استيراد الواجهة البرمجية لمستودع بيانات الأدمن
import '../../Admin/repository/supabase_admin_repository.dart'; // استيراد تنفيذ مستودع البيانات باستخدام سوبابيس
import '../../Admin/models/dashboard_stats_model.dart'; // استيراد نموذج بيانات إحصائيات لوحة التحكم
import '../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت
import '../../core/services/connectivity_service.dart'; // استيراد خدمة مراقبة الاتصال
import '../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الفلاتر العالمي

// المتحكم الخاص بتخطيط واجهة المنسق
class CoordinatorLayoutController extends GetxController {
  // تعريف المستودع الخاص ببيانات الأدمن (يستخدمه المنسق أيضاً لجلب الإحصائيات)
  final AdminRepository _repository = SupabaseAdminRepository();
  // الوصول إلى خدمة التخزين المؤقت
  final CacheService _cacheService = Get.find<CacheService>();
  // الوصول إلى خدمة الاتصال بالإنترنت
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();

  static const String _statsCacheKey = 'coordinator_stats_cache';

  // المتغير الخاص برقم الشاشة الحالية المفتوحة في الشريط السفلي (مراقب)
  final currentIndex = 0.obs;

  // متغير منطقي لمتابعة حالة البحث هل هو فعال حالياً أم لا (مراقب)
  var isSearching = false.obs;
  // متحكم نص البحث لإدخال ومراقبة النص المدخل من قبل المستخدم
  final TextEditingController searchController = TextEditingController();

  // نموذج بيانات الإحصائيات (مثل إجمالي الطلاب والمعلمين) بشكل مراقب
  var stats = DashboardStatsModel.empty().obs;
  // متغير لمتابعة حالة تحميل الإحصائيات من السيرفر (مراقب)
  var isStatsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChatControllers();
    loadStatsFromCache();
    
    // إضافة مستمعين لتغيرات الفلتر العالمي (الدفعة والجنس) لتحديث الإحصائيات فوراً
    _setupFilterListeners();

    if (_connectivityService.isConnected.value) {
      fetchStats();
    }
    ever(_connectivityService.isConnected, (bool connected) {
      if (connected) refreshData();
    });
  }

  // إعداد المستمعين للفلاتر العالمية
  void _setupFilterListeners() {
    if (Get.isRegistered<GlobalBatchController>()) {
      final gbc = Get.find<GlobalBatchController>();
      // عند تغيير الدفعة أو الجنس، نقوم بتحديث البيانات فوراً
      ever(gbc.selectedBatch, (_) => refreshData());
      ever(gbc.selectedGender, (_) => refreshData());
    }
  }

  // الحصول على عنوان الشاشة الحالية بناءً على الفهرس
  String get currentTitle {
    switch (currentIndex.value) {
      case 0:
        return 'stats'.tr;
      case 1:
        return 'student_chats'.tr;
      case 2:
        return 'teacher_chats'.tr;
      default:
        return 'coordinator_center'.tr;
    }
  }

  // دالة لتغيير الشاشة المعروضة في الشريط السفلي بناءً على الاختيار
  void changeIndex(int index) {
    // تحديث قيمة المؤشر الحالي
    currentIndex.value = index;
    // عند تغيير الصفحة، نغلق وضع البحث ونمسح النص
    isSearching.value = false;
    searchController.clear();
    
    // عند الانتقال لصفحة الإحصائيات، نتأكد من تحديث البيانات إذا توفر الإنترنت
    if (index == 0 && _connectivityService.isConnected.value) {
      fetchStats();
    }
  }

  // تحميل الإحصائيات من التخزين المحلي (الكاش)
  void loadStatsFromCache() {
    final cachedData = _cacheService.getData(_statsCacheKey);
    if (cachedData != null) {
      stats.value = DashboardStatsModel.fromJson(cachedData);
    }
  }

  // الانتقال المباشر إلى شاشات الدردشة (للطلاب أو المعلمين) من داخل شاشة الإحصائيات
  void navigateToChats(int targetIndex) {
    // تحديث المؤشر للانتقال للشاشة المطلوبة
    currentIndex.value = targetIndex;
  }

  // التبديل بين وضع البحث والعرض العادي في شريط العنوان العلوي
  void toggleSearch() {
    // عكس قيمة حالة البحث الحالية
    isSearching.value = !isSearching.value;
    // إذا تم إغلاق وضع البحث، نقوم بمسح النص وتحديث نتائج البحث لتظهر كاملة
    if (!isSearching.value) {
      // مسح النص من حقل الإدخال
      searchController.clear();
      // تحديث استعلام البحث بقيمة فارغة
      updateSearchQuery('');
    }
  }

  // تحديث استعلام البحث في متحكمات الدردشة (للطلاب والمعلمين) ليتم الفلترة فورياً
  void updateSearchQuery(String query) {
    try {
      // إرسال نص البحث لمتحكم دردشة الطلاب إذا كان مسجلاً في الذاكرة حالياً
      if (Get.isRegistered<AdminChatController>(tag: 'student')) {
        // تحديث قيمة البحث في متحكم الطلاب
        Get.find<AdminChatController>(tag: 'student').searchQuery.value = query;
      }
      // إرسال نص البحث لمتحكم دردشة المعلمين إذا كان مسجلاً في الذاكرة حالياً
      if (Get.isRegistered<AdminChatController>(tag: 'teacher')) {
        // تحديث قيمة البحث في متحكم المعلمين
        Get.find<AdminChatController>(tag: 'teacher').searchQuery.value = query;
      }
    } catch (e) {
      // تجاهل الأخطاء في حال عدم وجود المتحكمات في الذاكرة (مثلاً قبل فتح الشاشات)
    }
  }

  // تهيئة متحكمات الدردشة للطلاب والمعلمين لضمان عمل الإشعارات والعدادات في الخلفية
  void _initializeChatControllers() {
    try {
      if (!Get.isRegistered<AdminChatController>(tag: 'student')) {
        Get.put(AdminChatController(), tag: 'student');
      }
      if (!Get.isRegistered<AdminChatController>(tag: 'teacher')) {
        Get.put(AdminChatController(), tag: 'teacher');
      }
    } catch (e) {}
  }

  // وظيفة تحديث البيانات يدوياً وتلقائياً
  Future<void> refreshData() async {
    if (!_connectivityService.isConnected.value) return;

    if (currentIndex.value == 0) {
      await fetchStats();
    } else {
      try {
        final tag = currentIndex.value == 1 ? 'student' : 'teacher';
        if (Get.isRegistered<AdminChatController>(tag: tag)) {
          await Get.find<AdminChatController>(tag: tag).refreshData();
        }
      } catch (e) {}
    }
  }

  // جلب الإحصائيات الموحدة من قاعدة البيانات باستخدام السنة الحالية وحفظها في الكاش
  Future<void> fetchStats() async {
    if (!_connectivityService.isConnected.value) return;

    // تفعيل مؤشر التحميل فقط إذا لم تكن هناك بيانات معروضة من الكاش
    if (stats.value.totalCircles == 0) isStatsLoading.value = true;
    
    try {
      final result = await _repository.getUnifiedStats(DateTime.now().year);
      // تحديث الواجهة بالبيانات الجديدة
      stats.value = result; 
      // حفظ البيانات الجديدة في الكاش للاستخدام لاحقاً (وضع الأوفلاين)
      await _cacheService.saveData(_statsCacheKey, result.toJson());
    } finally {
      isStatsLoading.value = false; 
    }
  }

  // الحصول على إجمالي الرسائل غير المقروءة للطلاب
  int get studentUnreadCount {
    try {
      if (Get.isRegistered<AdminChatController>(tag: 'student')) {
        return Get.find<AdminChatController>(tag: 'student').unreadStudentMessages;
      }
    } catch (_) {}
    return 0;
  }

  // الحصول على إجمالي الرسائل غير المقروءة للمعلمين
  int get teacherUnreadCount {
    try {
      if (Get.isRegistered<AdminChatController>(tag: 'teacher')) {
        return Get.find<AdminChatController>(tag: 'teacher').unreadTeacherMessages;
      }
    } catch (_) {}
    return 0;
  }

  // تسجيل الخروج من حساب المنسق والعودة لشاشة تسجيل الدخول
  void logout() async {
    Get.offAllNamed('/login');
  }
}
