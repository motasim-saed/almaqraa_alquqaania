import 'dart:convert'; // استيراد مكتبة التحويل لتحويل البيانات من وإلى تنسيق JSON
import 'package:http/http.dart'
    as http; // استيراد حزمة http للقيام بطلبات الـ API من الخادم
import '../../models/system_setting_model.dart'; // استيراد نموذج بيانات إعدادات النظام
import '../../../core/utils/app_constants.dart'; // استيراد الثوابت الخاصة بالتطبيق مثل روابط الـ API والمفاتيح

mixin SettingsModule {
  // تعريف "ميكسين" (وحدة برمجية) لإدارة إعدادات النظام
  final String _settingsUrl = // تعريف رابط الـ API الخاص بجلب وتحديث الإعدادات
      "${AppConstants.djangoApiBaseUrl}/management/api/settings/"; // دمج الرابط الأساسي مع مسار الإعدادات
  final Map<String, String> _headers = {
    // تعريف الترويسات (Headers) المطلوبة لطلبات الـ API
    'Accept':
        'application/json', // إخبار الخادم أننا نتوقع استلام بيانات بصيغة JSON
    'Content-Type':
        'application/json', // إخبار الخادم أن البيانات المرسلة هي بصيغة JSON
    'X-API-KEY':
        AppConstants.djangoApiKey, // إرسال مفتاح الـ API للتحقق من الصلاحية
  }; // نهاية تعريف الترويسات

  Future<SystemSettingModel?> getSystemSettings() async {
    // دالة لجلب إعدادات النظام من الخادم بشكل غير متزامن
    try {
      // بدء كتلة محاولة التنفيذ لمعالجة الأخطاء المحتملة
      final response = await http.get(
        // إرسال طلب من نوع GET لجلب البيانات
        Uri.parse(_settingsUrl), // تحويل الرابط النصي إلى كائن Uri
        headers: _headers, // تضمين الترويسات المعرفة مسبقاً في الطلب
      ); // انتظار استجابة الخادم
      if (response.statusCode == 200) {
        // التحقق مما إذا كانت الاستجابة ناجحة (كود 200)
        final data = json.decode(
          response.body,
        ); // تحويل نص الاستجابة من JSON إلى خريطة بيانات (Map)
        if (data['status'] == 'success') {
          // التحقق من نجاح العملية بناءً على حقل الحالة المستلم
          return SystemSettingModel.fromJson(
            data['data'],
          ); // تحويل البيانات المستلمة إلى كائن SystemSettingModel وإرجاعه
        } // نهاية التحقق من حالة النجاح
      } // نهاية التحقق من كود الحالة
      // ignore: empty_catches
    } catch (e) {} // نهاية كتلة معالجة الخطأ
    return null; // إرجاع قيمة فارغة في حال فشل العملية أو حدوث خطأ
  } // نهاية دالة getSystemSettings

  Future<bool> updateSystemSettings(SystemSettingModel settings) async {
    // دالة لتحديث إعدادات النظام على الخادم
    try {
      // بدء كتلة محاولة التنفيذ
      final response = await http.post(
        // إرسال طلب من نوع POST لتحديث البيانات
        Uri.parse(_settingsUrl), // تحديد رابط الإعدادات
        headers: _headers, // تضمين ترويسات التحقق والنوع
        body: json.encode(
          settings.toJson(),
        ), // تحويل كائن الإعدادات إلى نص JSON لإرساله في جسم الطلب
      ); // انتظار استجابة الخادم
      if (response.statusCode == 200) {
        // التحقق من نجاح استلام الطلب ومعالجته
        final data = json.decode(response.body); // تحليل بيانات الاستجابة
        return data['status'] ==
            'success'; // إرجاع قيمة منطقية (صح/خطأ) بناءً على نجاح التحديث في الخادم
      } // نهاية التحقق من كود الاستجابة
    } catch (e) {} // نهاية كتلة معالجة الخطأ
    return false; // إرجاع فشل العملية في حال عدم الوصول لنتيجة نجاح
  } // نهاية دالة updateSystemSettings
} // نهاية تعريف الميكسين SettingsModule
