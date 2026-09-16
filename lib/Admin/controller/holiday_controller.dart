import 'package:al_maqraa/core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات العالمي
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import '../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../repository/admin_repository.dart'; // استيراد الواجهة البرمجية لمستودع الأدمن
import '../repository/supabase_admin_repository.dart'; // استيراد تنفيذ مستودع الأدمن باستخدام Supabase
import '../../../core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت للبيانات

/// متحكم الإجازات والعطلات (HolidayController)
/// يدير جلب، إضافة، تعديل، وحذف الإجازات مع دعم التخزين المؤقت والفلترة.
class HolidayController extends GetxController { // تعريف فئة المتحكم وربطها بـ GetX
  final AdminRepository repository = SupabaseAdminRepository(); // تهيئة المستودع باستخدام Supabase
  final CacheService _cacheService = Get.find<CacheService>(); // الوصول إلى خدمة التخزين المؤقت المسجلة

  // قائمة الإجازات المسجلة بشكل مراقب لتحديث الواجهة تلقائياً
  final RxList<HolidayModel> holidays = <HolidayModel>[].obs; 
  // متغير منطقي مراقب لمتابعة حالة التحميل
  final RxBool isLoading = false.obs; 
  // متغير مراقب لتحديد الجنس المختار في الفلترة (ذكر/أنثى/الكل)
  final Rx<Gender> selectedGender = Gender.all.obs; 

  @override
  void onInit() { // دالة تُستدعى عند تهيئة المتحكم
    super.onInit(); // استدعاء دالة التهيئة للأب
    fetchHolidays(); // جلب بيانات الإجازات عند بدء التشغيل
  }

  // دالة لتحديث البيانات يدوياً عن طريق إعادة جلبها
  Future<void> refreshData() => fetchHolidays(); 

  /// جلب قائمة الإجازات من السيرفر مع دعم التخزين المحلي
  Future<void> fetchHolidays() async { 
    _loadFromCache(); // تحميل البيانات من الكاش لعرضها فوراً للمستخدم

    try { // محاولة جلب البيانات من السيرفر
      if (holidays.isEmpty) {
        isLoading.value = true; // تعيين حالة التحميل إلى "جاري"
      }
      final list = await repository.getHolidays(); // طلب قائمة الإجازات من المستودع
      holidays.assignAll(list); // تحديث قائمة الإجازات في الذاكرة
      _saveToCache(list); // حفظ القائمة الجديدة في التخزين المؤقت
    } catch (e) { // في حالة حدوث خطأ أثناء الجلب
      // يتم الاكتفاء بالبيانات المحملة من الكاش سابقاً
    } finally { // في نهاية العملية سواء نجحت أو فشلت
      isLoading.value = false; // إنهاء حالة التحميل
    }
  }

  // دالة لجلب البيانات المخزنة محلياً
  void _loadFromCache() { 
    final cachedData = _cacheService.getData('admin_holidays'); // الحصول على البيانات من مفتاح معين
    if (cachedData != null) { // إذا كانت هناك بيانات مخزنة
      holidays.assignAll( // تحويل البيانات من JSON إلى قائمة كائنات وإضافتها
        (cachedData as List).map((e) => HolidayModel.fromJson(e)).toList(),
      );
    }
  }

  // دالة لحفظ القائمة الحالية في التخزين المؤقت
  void _saveToCache(List<HolidayModel> list) { 
    _cacheService.saveData( // حفظ البيانات في الذاكرة الدائمة بصيغة JSON
      'admin_holidays',
      list.map((e) => e.toJson()).toList(),
    );
  }

  // دالة لإضافة إجازة جديدة
  Future<void> addHoliday(HolidayModel holiday) async { 
    isLoading.value = true; // بدء حالة التحميل
    try { 
      // الحصول على رقم الدفعة المختار حالياً لإلحاقه بالإجازة الجديدة
      int? currentBatch; 
      if (Get.isRegistered<GlobalBatchController>()) { // التحقق من وجود متحكم الدفعات
        currentBatch = Get.find<GlobalBatchController>().selectedBatch.value; // جلب الدفعة المختارة
      }

      // إنشاء كائن إجازة جديد يحتوي على رقم الدفعة المختار
      final newHoliday = HolidayModel( 
        id: holiday.id, // معرف الإجازة
        date: holiday.date, // تاريخ البداية
        endDate: holiday.endDate, // تاريخ النهاية
        dayOfWeek: holiday.dayOfWeek, // اليوم من الأسبوع
        reason: holiday.reason, // سبب الإجازة
        batchNumber: currentBatch, // رقم الدفعة المرتبط
      );

      final success = await repository.addHoliday(newHoliday); // إرسال طلب الإضافة للمستودع
      if (success) { // في حال نجاح الإضافة
        await fetchHolidays(); // إعادة جلب البيانات لتحديث القائمة
        Get.back(); // العودة للشاشة السابقة
      }
    } finally { // في كل الأحوال
      isLoading.value = false; // إيقاف حالة التحميل
    }
  }

  // دالة لتعديل إجازة موجودة
  Future<void> updateHoliday(HolidayModel holiday) async { 
    if (holiday.id == null) return; // التأكد من وجود معرف للإجازة قبل التعديل
    isLoading.value = true; // بدء التحميل
    try { 
      await (repository as SupabaseAdminRepository).supabase // الوصول المباشر لـ Supabase للتعديل
          .from('holidays') // تحديد جدول الإجازات
          .update(holiday.toJson()) // تحديث البيانات المرسلة بصيغة JSON
          .eq('id', holiday.id!); // مطابقة المعرف المحدد
      await fetchHolidays(); // تحديث القائمة المحلية
      Get.back(); // العودة
    } finally { 
      isLoading.value = false; // إيقاف التحميل
    }
  }

  // دالة لحذف إجازة
  Future<void> deleteHoliday(String id) async { 
    final success = await repository.deleteHoliday(id); // طلب حذف الإجازة بالمعرف
    if (success) fetchHolidays(); // إذا نجح الحذف، يتم تحديث القائمة
  }


} // نهاية كلاس متحكم الإجازات
