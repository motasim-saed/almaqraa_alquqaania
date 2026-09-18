import 'dart:io' show Platform, Directory, File; // استيراد مكتبة التعامل مع الملفات والنظام
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart'; // استيراد مكتبة Dio للقيام بطلبات الشبكة (تحميل ورفع)
import 'package:get/get.dart'; // استيراد GetX لإدارة الخدمات والحالة التفاعلية
import 'package:path_provider/path_provider.dart'; // استيراد مكتبة للحصول على مسارات المجلدات في الجهاز
import 'package:path/path.dart'
    as p; // استيراد مكتبة للتعامل مع مسارات الملفات وتعديلها
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة Supabase للتعامل مع التخزين السحابي
import 'package:flutter_dotenv/flutter_dotenv.dart'; // استيراد مكتبة لقراءة متغيرات البيئة (مثل رابط السيرفر)
import 'package:permission_handler/permission_handler.dart'; // استيراد مكتبة لإدارة طلب تصاريح الوصول للهاتف

/// شرح عمل الملف:
/// هذا الملف يمثل "خدمة إدارة الوسائط والتخزين المؤقت" (MediaCacheService).
/// وظيفتها الأساسية هي إدارة كل ما يتعلق بالملفات (صور، صوت، فيديو) في التطبيق من حيث:
/// 1. التحميل من الإنترنت مع حفظ نسخة محلية (Caching) لتوفير البيانات.
/// 2. رفع الملفات إلى سيرفر Supabase مع متابعة نسبة التقدم.
/// 3. إدارة وتنظيم المجلدات داخل ذاكرة الهاتف (AlMaqraa Media).
/// 4. توفير ميزة إلغاء التحميل أو الرفع في أي وقت.
///
/// أين يستخدم:
/// 1. في شاشات الدردشة (Chat): لرفع الصور والرسائل الصوتية وتحميل الوسائط المرسلة.
/// 2. في مشغل الصوت والفيديو: للتأكد من تشغيل الملف من الذاكرة المحلية إذا كان محملًا مسبقًا.
/// 3. في عرض الصور الشخصية: لحفظ صور البروفايل محليًا لسرعة العرض.

class MediaCacheService extends GetxService {
  // تعريف الفئة كخدمة GetX لتبقى متاحة طوال فترة تشغيل التطبيق
  final Dio _dio = Dio(); // إنشاء نسخة من مكتبة Dio للتعامل مع الروابط
  SupabaseClient get _supabase =>
      Supabase.instance.client; // الحصول على نسخة عميل Supabase بشكل كسول

  // خريطة لربط أنواع المجلدات الفرعية بأسماء عربية/إنجليزية واضحة في الذاكرة
  static const Map<String, String> _subFolderToName = {
    'images': 'AlMaqraa Images', // مجلد الصور
    'videos': 'AlMaqraa Videos', // مجلد الفيديو
    'audio': 'AlMaqraa Audio', // مجلد الصوتيات
    'documents': 'AlMaqraa Documents', // مجلد المستندات
  };

  static const String _defaultFolderName =
      'AlMaqraa Media'; // الاسم الافتراضي للمجلد إذا لم يحدد نوع

  // متغيرات تفاعلية لمتابعة نسبة تقدم التحميل (مفتاح: معرف الملف، قيمة: النسبة من 0 إلى 1)
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  // مخزن لرموز الإلغاء للتحميلات الجارية
  final RxMap<String, CancelToken> _downloadTokens =
      <String, CancelToken>{}.obs;

  // متغيرات تفاعلية لمتابعة نسبة تقدم الرفع
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;
  // مخزن لرموز الإلغاء لعمليات الرفع الجارية
  final RxMap<String, CancelToken> _uploadTokens = <String, CancelToken>{}.obs;

  late Directory
  _appDocDir; // متغير لتخزين مسار المجلد الرئيسي للتطبيق في الجهاز

  /// دالة تهيئة الخدمة عند بدء تشغيل التطبيق
  /// ملاحظة: لا نطلب أي إذن هنا بشكل إلزامي عند الإقلاع (يمنع تجميد الخيط الرئيسي
  /// ويمنع تحذير permission_handler: No permissions found in manifest).
  /// تُطلب الأذونات عند الحاجة فقط عبر [ensureStoragePermission].
  Future<MediaCacheService> init() async {
    if (kIsWeb) return this;

    if (Platform.isAndroid) {

      final externalDir =
          await getExternalStorageDirectory(); // محاولة الحصول على مسار التخزين الخارجي
      if (externalDir != null) {
        _appDocDir = Directory(
          p.join(externalDir.path, 'AlMaqraa'),
        ); // إنشاء مسار المجلد الخاص بالتطبيق
      } else {
        _appDocDir = Directory(
          '/storage/emulated/0/AlMaqraa',
        ); // مسار احتياطي في حال فشل الحصول على المسار الرسمي
      }
    } else {
      // لنظام iOS والأنظمة الأخرى، نستخدم مجلد المستندات الخاص بالتطبيق
      final docDir = await getApplicationDocumentsDirectory();
      _appDocDir = Directory(p.join(docDir.path, 'AlMaqraa'));
    }

    // إنشاء المجلد الرئيسي في ذاكرة الجهاز إذا لم يكن موجودًا
    if (!await _appDocDir.exists()) {
      try {
        await _appDocDir.create(
          recursive: true,
        ); // إنشاء المجلد مع كافة المجلدات الأب
      } catch (e) {
        // في حال حدوث خطأ في الصلاحيات، نستخدم مجلد التطبيق الخاص
        _appDocDir = await getApplicationDocumentsDirectory();
        _appDocDir = Directory(p.join(_appDocDir.path, 'AlMaqraa'));
        if (!await _appDocDir.exists()) {
          await _appDocDir.create(recursive: true);
        }
      }
    }
    return this; // إرجاع الخدمة بعد اكتمال التهيئة
  }

  /// طلب إذن التخزين/الوسائط عند الحاجة فقط (وليس عند الإقلاع).
  /// يختار الأذونات الصحيحة حسب إصدار أندرويد لتجنب تحذير:
  /// "No permissions found in manifest" الذي يظهر عند طلب
  /// Permission.storage / manageExternalStorage على Android 13+.
  Future<bool> ensureStoragePermission() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return true;
    try {
      if (Platform.isIOS) {
        final photos = await Permission.photos.status;
        if (photos.isDenied) {
          final res = await Permission.photos.request();
          return res.isGranted || res.isLimited;
        }
        return true;
      }
      // أندرويد: نحاول الأذونات الحديثة أولاً (READ_MEDIA_*) ثم نتراجع للقديمة.
      // permission_handler يرمي/يحذر إذا كان الإذن غير معلن في Manifest، لذا نغلف كل طلب بـ try/catch.
      final List<Permission> candidates = [
        Permission.photos,
        Permission.audio,
        Permission.videos,
        Permission.storage,
      ];
      bool anyGranted = false;
      for (final p in candidates) {
        try {
          final status = await p.status;
          if (status.isGranted || status.isLimited) {
            anyGranted = true;
            continue;
          }
          if (status.isDenied) {
            final res = await p.request();
            if (res.isGranted || res.isLimited) anyGranted = true;
          } else if (status.isPermanentlyDenied) {
            // لا نفتح الإعدادات تلقائياً؛ نكتفي بالمجلد الخاص بالتطبيق الذي لا يحتاج إذناً
            continue;
          } else {
            anyGranted = true;
          }
        } catch (_) {
          // إذن غير مدعوم على هذا الإصدار (مثل storage على Android 14) -> تجاهله
          continue;
        }
      }
      return anyGranted;
    } catch (_) {
      return true; // لا نمنع التحميل/الحفظ في المجلد الخاص عند فشل الطلب
    }
  }

  /// دالة تحميل الوسائط من رابط وحفظها في المجلد المناسب
  Future<String?> downloadMedia(
    String url, {
    String? subFolder,
    String? messageId,
  }) async {
    if (kIsWeb || url.isEmpty) return null; // إذا كان الرابط فارغاً، نخرج
    final mId =
        messageId ?? url; // استخدام معرف الرسالة أو الرابط لتمييز عملية التحميل

    File? downloadedFile;
    try {
      final uri = Uri.parse(url); // تحليل الرابط
      // تنظيف اسم الملف من الرموز الخاصة واستخراج الاسم الأساسي
      final String fullPath =
          uri.path + (uri.query.isNotEmpty ? '_q_${uri.query.hashCode}' : '');
      final fileName = p.basename(fullPath);

      // تحديد المجلد الفرعي بناءً على النوع (صور، صوت...)
      final folderName = _subFolderToName[subFolder] ?? _defaultFolderName;
      final folderPath = p.join(_appDocDir.path, folderName);

      final subDir = Directory(folderPath);
      if (!await subDir.exists()) {
        // إنشاء المجلد الفرعي إذا لم يكن موجوداً
        try {
          await subDir.create(recursive: true);
        } catch (e) {
          Get.log('Error creating folder: $e'); // تسجيل الخطأ في السجل
        }
      }

      final localPath = p.join(
        folderPath,
        fileName,
      ); // المسار الكامل للملف محلياً
      final file = File(localPath);
      downloadedFile = file;

      // ميزة التخزين المؤقت (Caching): إذا كان الملف موجوداً مسبقاً، نرجعه مباشرة ولا نحمله ثانية
      if (await file.exists()) {
        return localPath;
      }

      final cancelToken = CancelToken(); // إنشاء رمز لإمكانية إلغاء التحميل
      _downloadTokens[mId] = cancelToken; // حفظ الرمز في القائمة
      downloadProgress[mId] = 0.0; // بدء عداد التقدم من الصفر

      // تنفيذ عملية التحميل باستخدام Dio
      await _dio.download(
        url, // رابط التحميل
        localPath, // مكان الحفظ
        cancelToken: cancelToken, // ربط رمز الإلغاء
        onReceiveProgress: (received, total) {
          // متابعة نسبة التحميل لحظة بلحظة
          if (total != -1) {
            downloadProgress[mId] = received / total; // تحديث النسبة المئوية
          }
        },
      );

      downloadProgress.remove(mId); // حذف عداد التقدم بعد الانتهاء
      _downloadTokens.remove(mId); // حذف رمز الإلغاء
      return localPath; // إرجاع مسار الملف المحلي بعد نجاح التحميل
    } on DioException catch (e) {
      if (downloadedFile != null && await downloadedFile.exists()) {
        try {
          await downloadedFile.delete();
        } catch (_) {}
      }
      if (CancelToken.isCancel(e)) {
        Get.log(
          "${"download_cancelled".tr}: $mId",
        ); // استخدام الترجمة عند الإلغاء
      }
      downloadProgress.remove(mId);
      _downloadTokens.remove(mId);
      return null;
    } catch (e) {
      if (downloadedFile != null && await downloadedFile.exists()) {
        try {
          await downloadedFile.delete();
        } catch (_) {}
      }
      downloadProgress.remove(mId);
      _downloadTokens.remove(mId);
      return null;
    }
  }

  /// دالة لإيقاف عملية تحميل معينة بواسطة معرفها
  void cancelDownload(String id) {
    if (_downloadTokens.containsKey(id)) {
      _downloadTokens[id]?.cancel(
        "download_cancelled".tr,
      ); // إرسال طلب إلغاء مترجم
      _downloadTokens.remove(id); // تنظيف البيانات المرتبطة
      downloadProgress.remove(id);
    }
  }

  /// دالة رفع ملف من الجهاز إلى سحابة Supabase
  Future<String?> uploadMedia({
    required String filePath, // مسار الملف في الجهاز
    required String folder, // المجلد المستهدف في السحاب (مثلاً: audio, images)
    required String chatId, // معرف المحادثة المرتبطة
    required String messageId, // معرف الرسالة لتمييز الرفع
  }) async {
    if (kIsWeb) return null; // الرفع عبر الملفات المحلية غير مدعوم بهذا الشكل على الويب
    final file = File(filePath); // الوصول للملف المحلي
    if (!await file.exists()) {
      Get.snackbar(
        "error".tr,
        "file_not_found".tr,
      ); // تنبيه المستخدم بفقدان الملف
      return null;
    }

    final ext = filePath.split('.').last; // استخراج امتداد الملف (jpg, mp3...)
    final fileName =
        '${folder}_${DateTime.now().millisecondsSinceEpoch}.$ext'; // توليد اسم فريد للملف
    final storagePath =
        '$folder/$chatId/$fileName'; // المسار داخل Storage في Supabase

    try {
      final session =
          _supabase.auth.currentSession; // الحصول على جلسة المستخدم الحالية
      if (session == null) {
        throw Exception(
          "user_not_logged_in".tr,
        ); // التحقق من المصادقة برسالة مترجمة
      }

      final supabaseUrl =
          dotenv.env['SUPABASE_URL'] ?? ''; // جلب رابط السيرفر من ملف .env
      final url =
          '$supabaseUrl/storage/v1/object/chat_attachments/$storagePath'; // الرابط الكامل لرفع الملف

      final cancelToken = CancelToken(); // رمز لإمكانية إلغاء الرفع
      _uploadTokens[messageId] = cancelToken;
      uploadProgress[messageId] = 0.0;

      final fileLength = await file.length(); // حساب حجم الملف

      // الرفع باستخدام طلب POST مع إرسال البيانات كتيار (Stream) لتقليل استهلاك الرام
      await _dio.post(
        url,
        data: file.openRead(), // قراءة الملف كتدفق بيانات
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${session.accessToken}', // إرسال توكن المصادقة
            'Content-Type': 'application/octet-stream', // تحديد نوع البيانات
            'Content-Length': fileLength.toString(), // إرسال حجم الملف للسيرفر
          },
        ),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          // متابعة نسبة الرفع لحظياً
          if (total != -1) {
            uploadProgress[messageId] = sent / total; // تحديث عداد التقدم
          }
        },
      );

      uploadProgress.remove(messageId);
      _uploadTokens.remove(messageId);
      // بعد نجاح الرفع، يتم جلب الرابط العام للملف لمشاركته في الدردشة
      return _supabase.storage
          .from('chat_attachments')
          .getPublicUrl(storagePath);
    } on DioException {
      uploadProgress.remove(messageId);
      _uploadTokens.remove(messageId);
      rethrow; // استخدام rethrow للحفاظ على تفاصيل الخطأ الأصلية
    } catch (e) {
      uploadProgress.remove(messageId);
      _uploadTokens.remove(messageId);
      rethrow;
    }
  }

  /// دالة لإيقاف عملية رفع معينة بواسطة معرف الرسالة
  void cancelUpload(String messageId) {
    if (_uploadTokens.containsKey(messageId)) {
      _uploadTokens[messageId]?.cancel(
        "upload_cancelled".tr,
      ); // إلغاء مع رسالة مترجمة
      _uploadTokens.remove(messageId);
      uploadProgress.remove(messageId);
    }
  }

  bool isFileCached(String? path) {
    if (kIsWeb || path == null || path.isEmpty) return false;
    return File(
      path,
    ).existsSync(); // تعيد true إذا وجد الملف، و false إذا لم يوجد
  }

  /// دالة لتوليد المسار المحلي المتوقع لملف معين بناءً على رابطه (دون تحميله)
  String getCachePath(String url, {String? subFolder}) {
    if (kIsWeb || url.isEmpty) return "";
    final uri = Uri.parse(url);
    final String fullPath =
        uri.path + (uri.query.isNotEmpty ? '_q_${uri.query.hashCode}' : '');
    final fileName = p.basename(fullPath);

    final folderName = _subFolderToName[subFolder] ?? _defaultFolderName;
    return p.join(
      _appDocDir.path,
      folderName,
      fileName,
    ); // إرجاع المسار الكامل الذي يفترض أن يكون فيه الملف
  }
}
