import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDatabaseService extends GetxService {
  static Database? _database;

  Future<LocalDatabaseService> init() async { 
    if (kIsWeb) return this;
    _database = await _initDatabase();
    return this; 
  }

  Future<Database?> get database async { 
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ذاكرة مؤقتة لأعمدة الجداول لتنقية البيانات قبل الإدخال (تمنع أخطاء الأعمدة غير الموجودة)
  final Map<String, Set<String>> _tableColumnsCache = {};

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'al_maqraa_offline.db');
    return await openDatabase(
      path,
      version: 12, // رفع الإصدار لإضافة عمود created_by و batch_number و gender لجدول الحلقات (circles)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async { 
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        role TEXT,
        avatar_url TEXT,
        email TEXT,
        phone TEXT,
        gender TEXT,
        age INTEGER,
        fcm_token TEXT,
        pledge_file_url TEXT,
        academic_number TEXT,
        private_code TEXT,
        joined_at TEXT,
        academic_qualification TEXT,
        show_profile_info INTEGER,
        batch_number INTEGER,
        created_at TEXT,
        last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE circles (
        id TEXT PRIMARY KEY,
        name TEXT,
        teacher_id TEXT,
        examiner_id TEXT,
        description TEXT,
        teacher_name TEXT,
        examiner_name TEXT,
        student_count INTEGER,
        students_json TEXT,
        created_at TEXT,
        background_url TEXT,
        created_by TEXT,
        batch_number INTEGER,
        gender TEXT,
        last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        id TEXT PRIMARY KEY,
        student_id TEXT,
        date TEXT,
        hifz_content TEXT,
        revision_content TEXT,
        attendance_status TEXT,
        status TEXT,
        teacher_notes TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE plans (
        id TEXT PRIMARY KEY,
        student_id TEXT,
        type TEXT,
        year INTEGER,
        month INTEGER,
        goal_description TEXT,
        created_at TEXT,
        last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT,
        sender_id TEXT,
        receiver_id TEXT,
        text TEXT,
        chat_type TEXT,
        audio_url TEXT,
        image_url TEXT,
        video_url TEXT,
        file_url TEXT,
        is_edited INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        sender_name TEXT,
        help_count INTEGER DEFAULT 0,
        created_at TEXT,
        read_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_reports (
        student_id TEXT,
        year INTEGER,
        month INTEGER,
        attendance_days INTEGER,
        absence_days INTEGER,
        excused_days INTEGER,
        holiday_days INTEGER,
        monthly_grade INTEGER,
        hifz_score REAL,
        tajweed_score REAL,
        tilawah_score REAL,
        student_name TEXT,
        PRIMARY KEY (student_id, year, month)
      )
    ''');

    await db.execute('''
      CREATE TABLE final_exams (
        student_id TEXT PRIMARY KEY,
        hifz_score REAL,
        tajweed_score REAL,
        tilawah_score REAL,
        year INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async { 
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE monthly_reports (
          student_id TEXT,
          year INTEGER,
          month INTEGER,
          attendance_days INTEGER,
          absence_days INTEGER,
          excused_days INTEGER,
          holiday_days INTEGER,
          monthly_grade INTEGER,
          hifz_score REAL,
          tajweed_score REAL,
          tilawah_score REAL,
          student_name TEXT,
          PRIMARY KEY (student_id, year, month)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE final_exams (
          student_id TEXT PRIMARY KEY,
          hifz_score REAL,
          tajweed_score REAL,
          tilawah_score REAL,
          year INTEGER
        )
      ''');
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE circles ADD COLUMN teacher_name TEXT');
        await db.execute('ALTER TABLE circles ADD COLUMN examiner_name TEXT');
        await db.execute('ALTER TABLE circles ADD COLUMN student_count INTEGER');
        await db.execute('ALTER TABLE circles ADD COLUMN students_json TEXT');
      } catch (e) {
        // print('Error upgrading database to version 6: $e');
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN gender TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN age INTEGER');
      } catch (e) {
        // print('Error upgrading database to version 7: $e');
      }
    }
    if (oldVersion < 8) {
      // تحديث جدول الرسائل لمطابقة الصور المرسلة والهيكلية الجديدة
      try {
        // إضافة الأعمدة الجديدة
        await db.execute('ALTER TABLE messages ADD COLUMN audio_url TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN image_url TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN video_url TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN file_url TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN is_edited INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE messages ADD COLUMN is_deleted INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE messages ADD COLUMN sender_name TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN help_count INTEGER DEFAULT 0');
        
        // ملاحظة: SQLite لا يدعم RENAME COLUMN في الإصدارات القديمة بسهولة،
        // ولكننا سنقوم بإضافتها كأعمدة جديدة لضمان التوافق مع الكود الجديد
        await db.execute('ALTER TABLE messages ADD COLUMN text TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN chat_type TEXT');
        
        // نقل البيانات القديمة إذا وجدت
        await db.execute('UPDATE messages SET text = content, chat_type = type');
      } catch (e) {
        // print('Error upgrading database to version 8: $e');
      }
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE plans ADD COLUMN is_synced INTEGER DEFAULT 1');
      } catch (e) {
        // print('Error upgrading database to version 9: $e');
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE profiles ADD COLUMN pledge_file_url TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN academic_number TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN private_code TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN joined_at TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN academic_qualification TEXT');
        await db.execute('ALTER TABLE profiles ADD COLUMN show_profile_info INTEGER');
        await db.execute('ALTER TABLE profiles ADD COLUMN batch_number INTEGER');
      } catch (e) {
        // print('Error upgrading database to version 10: $e');
      }
    }
    if (oldVersion < 11) {
      try {
        await _addColumnIfNotExists(db, 'profiles', 'created_at', 'TEXT');
        await _addColumnIfNotExists(db, 'circles', 'created_at', 'TEXT');
        await _addColumnIfNotExists(db, 'circles', 'background_url', 'TEXT');
      } catch (e) {
        // print('Error upgrading database to version 11: $e');
      }
    }
    if (oldVersion < 12) {
      // إصلاح الخطأ: table circles has no column named created_by
      // الأعمدة الجديدة القادمة من Supabase (created_by, batch_number, gender)
      try {
        await _addColumnIfNotExists(db, 'circles', 'created_by', 'TEXT');
        await _addColumnIfNotExists(db, 'circles', 'batch_number', 'INTEGER');
        await _addColumnIfNotExists(db, 'circles', 'gender', 'TEXT');
        await _addColumnIfNotExists(db, 'circles', 'description', 'TEXT');
      } catch (e) {
        // print('Error upgrading database to version 12: $e');
      }
    }
  }

  /// إضافة عمود فقط إذا لم يكن موجوداً (يمنع التعارض عند الترقية المتكررة)
  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  /// جلب أعمدة الجدول (مع تخزين مؤقت) لتنقية البيانات الدخيلة
  Future<Set<String>> _getTableColumns(Database db, String table) async {
    if (_tableColumnsCache.containsKey(table)) {
      return _tableColumnsCache[table]!;
    }
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final cols = info.map((c) => c['name'].toString()).toSet();
      _tableColumnsCache[table] = cols;
      return cols;
    } catch (_) {
      return {};
    }
  }

  Future<void> insertOrUpdate(String table, Map<String, dynamic> data) async {
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;

      // تنقية البيانات: إسقاط أي مفاتيح غير موجودة كأعمدة في الجدول المحلي
      // (مثل created_by القادم من Supabase قبل الترقية، أو أي حقول مستقبلية)
      // هذا يمنع الخطأ: table circles has no column named xxx
      final validColumns = await _getTableColumns(db, table);
      final processedData = <String, dynamic>{};
      data.forEach((key, value) {
        if (validColumns.isEmpty || validColumns.contains(key)) {
          if (value is bool) {
            processedData[key] = value ? 1 : 0;
          } else if (value is Map || value is List) {
            // الأعمدة المحلية نصية غالباً؛ نخزن الكائنات المعقدة كـ JSON
            // فقط إذا كان العمود المستهدف نصياً معروفاً (students_json) وإلا نتجاوزه
            if (key == 'students_json' || key == 'students') {
              return; // يتم بناؤه محلياً وليس من Supabase مباشرة
            }
            processedData[key] = value.toString();
          } else {
            processedData[key] = value;
          }
        }
      });
      if (processedData.isEmpty) return;

      await db.insert(table, processedData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // print('Error inserting into $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async { 
    if (kIsWeb) return [];
    try {
      final db = await database;
      if (db == null) return [];
      return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy); 
    } catch (e) {
      // print('Error querying $table: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async { 
    if (kIsWeb) return [];
    try {
      final db = await database;
      if (db == null) return [];
      return await db.query(table, where: 'is_synced = 0');
    } catch (e) {
      // print('Error getting unsynced records from $table: $e');
      return [];
    }
  }

  Future<void> markAsSynced(String table, String id) async { 
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      // print('Error marking as synced in $table: $e');
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await insertOrUpdate('profiles', profile);
  }

  Future<void> saveCircle(Map<String, dynamic> circle) async {
    await insertOrUpdate('circles', circle);
  }
}
