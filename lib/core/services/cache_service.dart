import 'dart:convert'; // استيراد مكتبة لتحويل البيانات من وإلى تنسيق JSON
import 'package:connectivity_plus/connectivity_plus.dart'; // استيراد مكتبة للتحقق من حالة الاتصال بالإنترنت
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الخدمات والحالة
import 'package:shared_preferences/shared_preferences.dart'; // استيراد حزمة التخزين المحلي البسيط على الجهاز

/// شرح عمل الملف:
/// خدمة التخزين المؤقت (CacheService) مسؤولة عن تحسين أداء التطبيق ودعم العمل بدون إنترنت من خلال:
/// 1. حفظ البيانات المجلوبة من السيرفر محلياً على الجهاز.
/// 2. توفير استراتيجية (Cache-First): عرض البيانات المخزنة فوراً للمستخدم ثم تحديثها من السيرفر في الخلفية.
/// 3. تقليل استهلاك البيانات وسرعة استجابة الواجهات.

class CacheService extends GetxService {
  late SharedPreferences _prefs; // تعريف متغير لتخزين نسخة من مكتبة SharedPreferences

  /// دالة تهيئة الخدمة عند تشغيل التطبيق
  Future<CacheService> init() async {
    _prefs = await SharedPreferences.getInstance(); // الحصول على نسخة التخزين المحلي من النظام
    return this; // إرجاع الخدمة بعد اكتمال التهيئة
  }

  /// جلب البيانات من الكاش بناءً على مفتاح (Key) معين
  dynamic getData(String key) {
    try {
      final String? jsonString = _prefs.getString(key); // محاولة جلب النص المخزن المرتبط بالمفتاح
      return jsonString != null ? jsonDecode(jsonString) : null; // تحويل النص من JSON إلى كائن برمجى أو إرجاع null
    } catch (e) {
      return null; // في حال حدوث أي خطأ أثناء الجلب أو التحويل
    }
  }

  /// حفظ البيانات في الكاش بشكل دائم على الجهاز
  Future<bool> saveData(String key, dynamic data) async {
    try {
      final String jsonString = jsonEncode(data); // تحويل البيانات إلى نص بتنسيق JSON للحفظ
      return await _prefs.setString(key, jsonString); // حفظ النص في الذاكرة المحلية وإرجاع حالة النجاح
    } catch (e) {
      return false; // فشل عملية الحفظ
    }
  }

  /// الدالة الرئيسية: جلب البيانات مع دعم التخزين المؤقت (استراتيجية: الكاش أولاً)
  /// [cacheKey]: المفتاح المستخدم لتخزين البيانات محلياً.
  /// [fetchFromServer]: الدالة التي تقوم بجلب البيانات من السيرفر في حال الحاجة.
  /// [onData]: دالة اختيارية تنفذ عند وصول بيانات جديدة من السيرفر لتحديث الواجهة.
  Future<dynamic> fetchWithCache({
    required String cacheKey,
    required Future<dynamic> Function() fetchFromServer,
    Function(dynamic serverData)? onData,
  }) async {
    final localData = getData(cacheKey); // محاولة جلب البيانات الموجودة محلياً أولاً
    bool isConnected = await _hasInternetConnection(); // التحقق من توفر اتصال بالإنترنت

    if (isConnected) {
      if (localData == null) {
        // إذا لم توجد بيانات محلية والإنترنت متوفر، نجلب من السيرفر وننتظر النتيجة
        final serverData = await _doFetchAndSave(cacheKey, fetchFromServer);
        return serverData;
      } else {
        // إذا وجدت بيانات محلية، نعرضها فوراً للمستخدم لسرعة الاستجابة
        // ثم نقوم بتحديث الكاش من السيرفر في الخلفية دون تعطيل المستخدم
        _doFetchAndSave(cacheKey, fetchFromServer).then((serverData) {
          if (serverData != null && onData != null) {
            onData(serverData); // إبلاغ الواجهة بالبيانات الجديدة المحدثة
          }
        });
        return localData; // إرجاع البيانات القديمة مؤقتاً
      }
    } else {
      // في حال عدم وجود إنترنت، نكتفي بإرجاع البيانات المتاحة محلياً فقط
      return localData;
    }
  }

  /// دالة داخلية تقوم بعملية الجلب من السيرفر ثم الحفظ التلقائي في الكاش
  Future<dynamic> _doFetchAndSave(String key, Future<dynamic> Function() fetch) async {
    try {
      final data = await fetch(); // تنفيذ طلب الجلب من السيرفر
      if (data != null) {
        await saveData(key, data); // تحديث الكاش بالبيانات الجديدة في حال نجاح الطلب
      }
      return data; // إرجاع البيانات الجديدة
    } catch (e) {
      return null; // فشل الطلب من السيرفر
    }
  }

  /// دالة للتحقق من وجود اتصال نشط بالإنترنت (واي فاي أو بيانات هاتف)
  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity(); // فحص حالة الشبكة
      return !results.contains(ConnectivityResult.none); // إرجاع true إذا كان هناك أي نوع من الاتصال
    } catch (e) {
      return true; // في حال حدوث خطأ في الفحص، نفترض وجود اتصال لمحاولة الجلب
    }
  }

  /// حذف بيانات معينة من الكاش نهائياً
  Future<bool> removeData(String key) async {
    return await _prefs.remove(key); // حذف المفتاح والبيانات المرتبطة به من الجهاز
  }

  /// إبطال الكاش (اسم بديل لـ removeData)
  Future<bool> invalidate(String key) async {
    return await removeData(key);
  }
}
