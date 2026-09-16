// import 'dart:io'; // استيراد مكتبة التعامل مع نظام الملفات
import 'dart:convert'; // استيراد مكتبة تحويل البيانات (JSON)
import 'package:sqflite/sqflite.dart'; // استيراد مكتبة SQLite لإدارة قواعد البيانات المحلية
import 'package:path/path.dart'; // استيراد مكتبة التعامل مع مسارات الملفات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الخدمات والحالة

/// شرح عمل الملف:
/// هذا الملف يمثل خدمة "LocalDbService" وهي المسؤولة عن إدارة قاعدة البيانات المحلية (SQLite) للتطبيق.
/// يقوم بتوفير آلية لتخزين البيانات بشكل دائم على جهاز المستخدم لضمان سرعة الوصول إليها ودعم العمل بدون إنترنت (Offline Mode).
///
/// أين يستخدم:
/// 1. في `main.dart`: يتم حقنه كخدمة دائمة عند تشغيل التطبيق (Get.putAsync).
/// 2. في الـ Repositories و Controllers: لاسترجاع البيانات المخزنة محلياً (مثل بيانات المستخدم أو الرسائل) بدلاً من طلبها من السيرفر في كل مرة.
/// 3. في المحادثات: لتخزين الرسائل الواردة والصادرة وعرضها فوراً للمستخدم.
/// 4. في نظام الكاش (Caching): لتخزين استجابات الـ API المعقدة على شكل نصوص JSON.

class LocalDbService extends GetxService {
  // تعريف الفئة كخدمة تابعة لإطار عمل GetX
  static Database? _db; // متغير خاص لتخزين كائن قاعدة البيانات (Singleton)

  // تعريف أسماء الجداول كمجلدات ثابتة لتجنب الأخطاء الإملائية
  static const String cacheTable = 'offline_cache'; // جدول التخزين المؤقت العام
  static const String usersTable = 'users'; // جدول بيانات المستخدمين
  static const String messagesTable = 'messages'; // جدول الرسائل
  static const String sessionsTable = 'sessions'; // جدول الجلسات التعليمية
  //
  // /// دالة تهيئة الخدمة عند تشغيل التطبيق (تستدعى مرة واحدة)
  // Future<LocalDbService> init() async {
  //   await db; // استدعاء خاصية get db لضمان إنشاء قاعدة البيانات
  //   return this; // إرجاع نسخة الخدمة بعد التهيئة
  // }

  /// خاصية جلب قاعدة البيانات (تقوم بالإنشاء إذا لم تكن موجودة)
  Future<Database> get db async {
    if (_db != null) return _db!; // إذا كانت مهيأة مسبقاً، يتم إرجاعها فوراً
    _db = await _initDb(); // إذا لم تكن مهيأة، يتم استدعاء دالة الإنشاء
    return _db!; // إرجاع نسخة قاعدة البيانات
  }

  /// دالة خاصة لتهيئة وفتح ملف قاعدة البيانات
  Future<Database> _initDb() async {
    final dbPath =
        await getDatabasesPath(); // الحصول على المسار الافتراضي لقواعد البيانات في النظام
    final path = join(
      dbPath,
      'al_maqraa_cache.db',
    ); // دمج المسار مع اسم ملف قاعدة البيانات

    return await openDatabase(
      // فتح قاعدة البيانات أو إنشاؤها
      path, // مسار الملف
      version: 2, // رقم الإصدار (يُستخدم للتحكم في تحديثات الجداول مستقبلاً)
      onCreate: (db, version) async {
        // دالة تُنفذ عند إنشاء القاعدة لأول مرة
        await _createTables(db); // استدعاء دالة إنشاء الجداول
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // دالة تُنفذ عند تحديث إصدار التطبيق ببيانات جديدة
        if (oldVersion < 2) {
          // التحقق من الإصدار القديم
          await _createNewTables(
            db,
          ); // إنشاء الجداول الجديدة التي لم تكن موجودة في الإصدار 1
        }
      },
    );
  }

  /// دالة إنشاء الجداول الأساسية
  Future<void> _createTables(Database db) async {
    // إنشاء جدول الكاش العام (مفتاح وقيمة) لتخزين أي نوع من البيانات
    await db.execute(
      'CREATE TABLE $cacheTable (key TEXT PRIMARY KEY, value TEXT)',
    );
    await _createNewTables(db); // استدعاء دالة إنشاء الجداول التفصيلية الأخرى
  }

  /// دالة إنشاء جداول البيانات المخصصة (المستخدمين، الرسائل، الجلسات)
  Future<void> _createNewTables(Database db) async {
    // إنشاء جدول المستخدمين لحفظ الملف الشخصي للمستخدم وأي مستخدمين آخرين مرتبطين
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
        id TEXT PRIMARY KEY, -- المعرف الفريد للمستخدم
        name TEXT, -- اسم المستخدم
        email TEXT, -- البريد الإلكتروني
        role TEXT, -- الدور (طالب، معلم، إلخ)
        avatar_url TEXT, -- رابط الصورة الشخصية
        updated_at TEXT -- تاريخ آخر تحديث للبيانات
      )
    ''');

    // إنشاء جدول الرسائل لدعم نظام المحادثات الفوري والأوفلاين
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $messagesTable (
        id TEXT PRIMARY KEY, -- معرف الرسالة
        sender_id TEXT, -- معرف المرسل
        receiver_id TEXT, -- معرف المستقبل
        content TEXT, -- محتوى الرسالة النصي
        type TEXT, -- نوع الرسالة (نص، صورة، صوت)
        media_url TEXT, -- رابط الوسائط إن وجد
        local_path TEXT, -- المسار المحلي للملف في الهاتف (في حال التحميل)
        created_at TEXT, -- وقت الإرسال
        is_read INTEGER, -- هل قُرئت الرسالة (0 أو 1)
        is_delivered INTEGER -- هل وصلت الرسالة للسيرفر (0 أو 1)
      )
    ''');

    // إنشاء جدول الجلسات لحفظ بيانات الحلقات التعليمية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $sessionsTable (
        id TEXT PRIMARY KEY, -- معرف الجلسة
        teacher_id TEXT, -- معرف المعلم المسؤول
        title TEXT, -- عنوان الجلسة
        description TEXT, -- وصف الجلسة
        created_at TEXT -- تاريخ الإنشاء
      )
    ''');
  }

  // ============== دالات الحفظ المخبأ العام (Key-Value) ==============

  /// دالة لحفظ أي بيانات (Map أو List) عن طريق تحويلها لنص JSON
  Future<void> saveData(String key, dynamic data) async {
    final database = await db; // الحصول على نسخة قاعدة البيانات
    String jsonValue = jsonEncode(data); // تحويل الكائن إلى نص JSON
    await database.insert(
      // إدخال أو تحديث البيانات
      cacheTable,
      {'key': key, 'value': jsonValue}, // البيانات المراد حفظها
      conflictAlgorithm: ConflictAlgorithm
          .replace, // استبدال البيانات إذا كان المفتاح موجوداً مسبقاً
    );
  }

  /// دالة لاسترجاع البيانات المحفوظة وتحويلها من JSON لشكلها الأصلي
  Future<dynamic> getData(String key) async {
    final database = await db; // الحصول على نسخة قاعدة البيانات
    final List<Map<String, dynamic>> maps = await database.query(
      // الاستعلام عن المفتاح المطلوب
      cacheTable,
      where: 'key = ?', // شرط البحث
      whereArgs: [key], // قيمة المفتاح
    );
    if (maps.isNotEmpty) {
      // إذا وجدت نتائج
      return jsonDecode(
        maps.first['value'],
      ); // تحويل النص من JSON إلى كائن وإرجاعه
    }
    return null; // إرجاع فارغ في حال عدم وجود المفتاح
  }

  /// دالة لمسح جدول الكاش العام بالكامل
  Future<void> clearCache() async {
    final database = await db; // الحصول على نسخة قاعدة البيانات
    await database.delete(cacheTable); // حذف جميع السجلات من جدول الكاش
  }
}
