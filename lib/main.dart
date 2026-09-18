import 'package:al_maqraa/core/navigation/app_router.dart'; // استيراد موجه التطبيق للتنقل بين الصفحات
import 'package:al_maqraa/core/localization/app_translations.dart'; // استيراد ملف الترجمات الخاص بالتطبيق
import 'package:al_maqraa/Auth/routing/auth_route.dart'; // استيراد مسارات المصادقة (تسجيل الدخول)
import 'package:al_maqraa/core/services/background_sync_service.dart'; // استيراد خدمة المزامنة في الخلفية
import 'package:al_maqraa/core/bindings/initial_binding.dart'; // استيراد الروابط الأولية (Dependency Injection)
import "package:al_maqraa/core/theme/app_theme.dart"; // استيراد سمات التطبيق (الألوان والخطوط)
import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import "package:get/get.dart"; // استيراد مكتبة GetX لإدارة الحالة والتنقل
import 'package:flutter_dotenv/flutter_dotenv.dart'; // استيراد مكتبة التعامل مع ملفات البيئة .env
import 'package:flutter_native_splash/flutter_native_splash.dart'; // استيراد مكتبة Splash Screen
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة Supabase لقواعد البيانات
import 'package:flutter_quran/flutter_quran.dart'; // استيراد مكتبة عرض القرآن الكريم
import 'package:al_maqraa/core/services/cache_service.dart'; // استيراد خدمة التخزين المؤقت
import 'package:al_maqraa/core/services/local_database_service.dart'; // استيراد خدمة قاعدة البيانات المحلية
import 'package:al_maqraa/core/services/notification_service.dart'; // استيراد خدمة التنبيهات
import 'package:al_maqraa/core/services/firebase_service.dart'; // استيراد خدمة فايربيس
import 'package:firebase_core/firebase_core.dart'; // استيراد المكتبة الأساسية لفايربيس
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
// استيراد مكتبة رسائل فايربيس
import 'package:al_maqraa/core/services/chat_cache_service.dart'; // استيراد خدمة التخزين المؤقت للمحادثات
import 'package:al_maqraa/core/services/media_cache_service.dart'; // استيراد خدمة التخزين المؤقت للوسائط
import 'package:al_maqraa/core/services/showcase_service.dart'; // استيراد خدمة الإرشاد والتوجيه
import 'package:al_maqraa/core/services/connectivity_service.dart'; // استيراد خدمة مراقبة الاتصال بالإنترنت
import 'package:intl/date_symbol_data_local.dart'; // استيراد مكتبة تهيئة تنسيق التاريخ محلياً
import 'package:intl/intl.dart'; // استيراد مكتبة تنسيق التاريخ واللغة
import 'dart:io' show Platform; // استيراد مكتبة النظام للتعامل مع المنصات والملفات
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // استيراد مكتبة قاعدة البيانات للأنظمة المكتبية
import 'package:get_storage/get_storage.dart'; // استيراد مكتبة التخزين المحلي السريع
import 'package:shared_preferences/shared_preferences.dart'; // استيراد مكتبة حفظ التفضيلات
import 'package:window_manager/window_manager.dart'; // استيراد مكتبة إدارة نافذة التطبيق على سطح المكتب
import 'package:flutter/foundation.dart' show kIsWeb; // استيراد فحص الويب

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. تهيئة فايربيس في الخلفية
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  // 2. تهيئة خدمة الإشعارات المحلية لضمان قدرتها على إظهار التنبيه
  await NotificationService().init();
  
  // 3. معالجة الرسالة
  FirebaseService.handleIncomingMessage(message);
}

Future<void> main() async {
  WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized(); // التأكد من تهيئة أدوات فلاتر قبل البدء
  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  ); // الحفاظ على شاشة البداية أثناء تهيئة التطبيق

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    // التحقق إذا كان التطبيق يعمل على ويندوز أو لينكس
    sqfliteFfiInit(); // تهيئة قاعدة بيانات sqflite للأنظمة المكتبية
    databaseFactory =
        databaseFactoryFfi; // ضبط مصنع قاعدة البيانات للعمل على الحاسوب
  }

  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      center: true,
      backgroundColor:
          Colors.transparent, // تغييرها لشفاف يقلل من ومضة اللون الأبيض
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // ننتظر حتى تصبح النافذة جاهزة للعرض
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager
          .maximize(); // تكبير الشاشة لتملأ الشاشة بالكامل مع بقاء شريط المهام
      await windowManager.setResizable(
        false,
      ); // قفل إمكانية تصغير أو تغيير حجم النافذة (إغلاق وتصغير فقط)
      await windowManager.show(); // إظهار النافذة
      await windowManager.focus(); // التركيز عليها
    });
  }

  await initializeDateFormatting(
    'ar',
    null,
  ); // تهيئة تنسيق التاريخ للغة العربية

  final prefs =
      await SharedPreferences.getInstance(); // الوصول إلى التفضيلات المشتركة
  String? savedLang = prefs.getString('selectedLanguage'); // جلب اللغة المحفوظة
  Locale initialLocale = savedLang != null
      ? Locale(
          savedLang,
          savedLang == 'ar' ? 'SA' : 'US',
        ) // تحديد اللغة المحفوظة
      : const Locale('ar', 'SA'); // أو استخدام العربية كافتراضية

  Intl.defaultLocale =
      initialLocale.languageCode; // ضبط اللغة الافتراضية للمكتبة الدولية

  try {
    await dotenv.load(fileName: ".env"); // محاولة تحميل ملف الإعدادات .env
  } catch (e) {
    // debugPrint("⚠️ تحذير: لم يتم العثور على ملف .env أو فشل تحميله: $e");
  }

  final url =
      dotenv.env['SUPABASE_URL'] ?? ''; // جلب رابط سوبابيز من ملف الإعدادات
  final anonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      ''; // جلب مفتاح سوبابيز من ملف الإعدادات
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    // التأكد من توفر البيانات
    try {
      await Supabase.initialize(url: url, anonKey: anonKey); // تهيئة سوبابيز
    } catch (e) {
      // debugPrint("❌ خطأ في تهيئة Supabase: $e");
    }
  }

  await GetStorage.init(); // تهيئة مكتبة GetStorage للتخزين المحلي (خفيفة ولازمة قبل runApp)
  // تأجيل تهيئة مكتبة القرآن الثقيلة لما بعد أول إطار لتجنب Skipped frames
  // سيتم استكمال تهيئتها في الخلفية بعد تشغيل التطبيق
  final flutterQuranInit = FlutterQuran().init(); // تهيئة غير محجوبة للخيط الرئيسي

  try {
    await NotificationService().init(); // تهيئة خدمة التنبيهات
  } catch (e) {}

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // التحقق إذا كان النظام موبايل
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      ); // ضبط معالج التنبيهات في الخلفية
      await FirebaseService().init(); // تهيئة خدمة فايربيس المخصصة
    // ignore: empty_catches
    } catch (e) {}
  }

  // تهيئة وحقن الخدمات المختلفة في ذاكرة التطبيق
  // تحسين أداء الخيط الرئيسي: الخدمات المستقلة تُهيأ بالتوازي عبر Future.wait
  // بدل التسلسل الذي كان يجمد البداية ويسبب Skipped frames.
  // ملاحظة: BackgroundSyncService يعتمد على Connectivity + LocalDatabase لذا يبقى بعدهما.
  try {
    await Get.putAsync(() => ConnectivityService().init());
    await Get.putAsync(() => LocalDatabaseService().init());
    await Future.wait([
      Get.putAsync(() => CacheService().init()),
      Get.putAsync(() => ChatCacheService().init()),
      Get.putAsync(() => MediaCacheService().init()),
      Get.putAsync(() => ShowcaseService().init()),
    ]);
    await Get.putAsync(() => BackgroundSyncService().init());
  } catch (e) {
    // Get.log("⚠️ Error initializing services: $e");
  }
  // انتظار تهيئة القرآن في الخلفية دون حجب الإقلاع (مع مهلة أمان)
  try {
    await flutterQuranInit.timeout(const Duration(seconds: 15));
  } catch (_) {}

  // جعل التطبيق يفتح دائماً على شاشة تسجيل الدخول بناءً على طلبك لضمان الأمان
  // بحيث لا يمكن تجاوز هذه الشاشة إلا بإدخال البيانات الصحيحة (سواء أونلاين أو أوفلاين)
  String startRoute = AuthRoutes.login;

  runApp(
    MyApp(initialLocale: initialLocale, initialRoute: startRoute),
  ); // تشغيل التطبيق مع تمرير اللغة الأولية والمسار
  FlutterNativeSplash.remove(); // إزالة شاشة البداية بعد اكتمال التشغيل
}

class MyApp extends StatelessWidget {
  final Locale initialLocale; // متغير لحفظ اللغة الأولية
  final String initialRoute; // متغير لحفظ مسار البداية

  const MyApp({
    super.key,
    required this.initialLocale,
    required this.initialRoute,
  }); // المشيد لاستقبال اللغة والمسار

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // استخدام تطبيق GetX
      debugShowCheckedModeBanner: false, // إخفاء علامة التصحيح المزعجة
      title: 'Al Maqraa', // عنوان التطبيق
      translations: AppTranslations(), // تحديد ملف الترجمات
      locale: initialLocale, // تحديد اللغة الحالية
      fallbackLocale: const Locale(
        'ar',
        'SA',
      ), // اللغة الاحتياطية في حال تعذر الحصول على الحالية
      initialBinding: InitialBinding(), // تحديد الروابط الأولية (الاعتمادات)
      themeMode: ThemeMode.system, // استخدام سمة النظام (فاتح/داكن)
      theme: AppTheme.buildTheme(Brightness.light), // ضبط السمة الفاتحة
      darkTheme: AppTheme.buildTheme(Brightness.dark), // ضبط السمة الداكنة
      initialRoute:
          initialRoute, // تحديد صفحة البداية ديناميكياً لتجاوز تسجيل الدخول إن أمكن
      getPages: AppRouter.routes, // تحديد كافة صفحات التطبيق
    );
  }
}
