import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'package:al_maqraa/Admin/models/admin_models.dart';

class ChatCacheService extends GetxService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<ChatCacheService> init() async {
    if (kIsWeb) return this;
    await database;
    return this;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_cache.db');
    return await openDatabase(
      path,
      version: 10, // تحديث النسخة لإضافة عمود unread_count و audio_duration
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          try {
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages (chat_id)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages (created_at)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_pending_chat_id ON pending_messages (chat_id)',
            );
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN file_url TEXT');
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute('ALTER TABLE contacts ADD COLUMN avatar_url TEXT');
          } catch (_) {}
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN chat_type TEXT');
            await db.execute(
              'ALTER TABLE pending_messages ADD COLUMN chat_type TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 8) {
          // إضافة أعمدة المزامنة الكاملة مع Supabase كما طلب المستخدم
          try {
            // 1. تحديث جدول الرسائل
            await db.execute(
              'ALTER TABLE messages ADD COLUMN receiver_id TEXT',
            );
            await db.execute('ALTER TABLE messages ADD COLUMN read_at TEXT');

            // 2. تحديث جدول الرسائل المعلقة ( pending_messages )
            await db.execute(
              'ALTER TABLE pending_messages ADD COLUMN receiver_id TEXT',
            );

            // 3. تحديث جدول المحادثات
            await db.execute('ALTER TABLE chats ADD COLUMN student_id TEXT');
            await db.execute('ALTER TABLE chats ADD COLUMN teacher_id TEXT');
            await db.execute('ALTER TABLE chats ADD COLUMN circle_id TEXT');
            await db.execute(
              'ALTER TABLE chats ADD COLUMN unread_count INTEGER',
            );
            await db.execute('ALTER TABLE chats ADD COLUMN avatar_url TEXT');
          } catch (_) {}
        }
        if (oldVersion < 9) {
          // إضافة عمود العداد إلى جدول جهات الاتصال
          try {
            await db.execute(
              'ALTER TABLE contacts ADD COLUMN unread_count INTEGER DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE contacts ADD COLUMN last_message TEXT',
            );
            await db.execute('ALTER TABLE contacts ADD COLUMN updated_at TEXT');
          } catch (_) {}
        }
        if (oldVersion < 10) {
          try {
            await db.execute(
              'ALTER TABLE messages ADD COLUMN audio_duration INTEGER',
            );
            await db.execute(
              'ALTER TABLE pending_messages ADD COLUMN audio_duration INTEGER',
            );
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            user_name TEXT,
            last_message TEXT,
            updated_at TEXT,
            type TEXT,
            user_role TEXT,
            last_sender_id TEXT,
            gender TEXT,
            student_id TEXT,
            teacher_id TEXT,
            circle_id TEXT,
            unread_count INTEGER,
            avatar_url TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            chat_id TEXT,
            sender_id TEXT,
            receiver_id TEXT,
            text TEXT,
            audio_url TEXT,
            image_url TEXT,
            video_url TEXT,
            file_url TEXT,
            chat_type TEXT,
            local_audio_path TEXT,
            local_image_path TEXT,
            local_video_path TEXT,
            local_file_path TEXT,
            is_edited INTEGER,
            is_deleted INTEGER,
            created_at TEXT,
            read_at TEXT,
            sender_name TEXT,
            audio_duration INTEGER,
            help_count INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_id TEXT,
            sender_id TEXT,
            receiver_id TEXT,
            text TEXT,
            local_audio_path TEXT,
            local_image_path TEXT,
            local_video_path TEXT,
            local_file_path TEXT,
            file_url TEXT,
            chat_type TEXT,
            audio_duration INTEGER,
            help_count INTEGER,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE contacts (
            id TEXT PRIMARY KEY,
            name TEXT,
            role TEXT,
            avatar_url TEXT,
            unread_count INTEGER DEFAULT 0,
            last_message TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  // --- Chats Methods ---

  Future<void> saveChats(dynamic chatsData) async {
    final db = await database;
    final batch = db.batch();

    if (chatsData is List) {
      for (var item in chatsData) {
        if (item is ChatModel) {
          batch.insert('chats', {
            'id': item.id,
            'user_id': item.userId,
            'user_name': item.userName,
            'last_message': item.lastMessage,
            'updated_at': item.updatedAt.toIso8601String(),
            'type': item.type,
            'user_role': item.userRole,
            'last_sender_id': item.lastSenderId,
            'gender': item.gender == Gender.female ? 'female' : 'male',
            'student_id': item.userId,
            'teacher_id': item.userRole == 'teacher' ? item.userId : null,
            'circle_id': item.type == 'circle_group' ? item.userId : null,
            'unread_count': item.unreadCount,
            'avatar_url': item.userAvatar,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } else if (item is Map<String, dynamic>) {
          batch.insert(
            'chats',
            item,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChatModel>> getCachedChats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) {
      return ChatModel.fromJson(maps[i]);
    });
  }

  // --- Messages Methods ---

  Future<void> saveMessages(List<MessageModel> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var msg in messages) {
      batch.execute(
        '''INSERT OR IGNORE INTO messages (id, chat_id, sender_id, receiver_id, text, created_at, read_at, chat_type, audio_duration) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          msg.id,
          msg.chatID,
          msg.senderId,
          msg.receiverId,
          msg.text,
          msg.createdAt.toIso8601String(),
          msg.readAt?.toIso8601String(),
          msg.chatType,
          msg.audioDuration,
        ],
      );

      batch.execute(
        '''
        UPDATE messages SET 
          chat_id = ?, sender_id = ?, receiver_id = ?, text = ?, audio_url = ?, image_url = ?, video_url = ?, file_url = ?,
          local_audio_path = COALESCE(?, local_audio_path), local_image_path = COALESCE(?, local_image_path),
          local_video_path = COALESCE(?, local_video_path), local_file_path = COALESCE(?, local_file_path),
          is_edited = ?, is_deleted = ?, created_at = ?, read_at = ?, sender_name = ?, help_count = ?, chat_type = ?, audio_duration = ?
        WHERE id = ?
      ''',
        [
          msg.chatID,
          msg.senderId,
          msg.receiverId,
          msg.text,
          msg.audioUrl,
          msg.imageUrl,
          msg.videoUrl,
          msg.fileUrl,
          msg.localAudioPath,
          msg.localImagePath,
          msg.localVideoPath,
          msg.localFilePath,
          msg.isEdited ? 1 : 0,
          msg.isDeleted ? 1 : 0,
          msg.createdAt.toIso8601String(),
          msg.readAt?.toIso8601String(),
          msg.senderName,
          msg.helpCount,
          msg.chatType,
          msg.audioDuration,
          msg.id,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<MessageModel>> getCachedMessages(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return MessageModel(
        id: maps[i]['id'],
        chatID: maps[i]['chat_id'],
        senderId: maps[i]['sender_id'],
        receiverId: maps[i]['receiver_id'],
        text: maps[i]['text'],
        audioUrl: maps[i]['audio_url'],
        imageUrl: maps[i]['image_url'],
        videoUrl: maps[i]['video_url'],
        fileUrl: maps[i]['file_url'],
        localAudioPath: maps[i]['local_audio_path'],
        localImagePath: maps[i]['local_image_path'],
        localVideoPath: maps[i]['local_video_path'],
        localFilePath: maps[i]['local_file_path'],
        chatType: maps[i]['chat_type'],
        audioDuration: maps[i]['audio_duration'],
        isEdited: maps[i]['is_edited'] == 1,
        isDeleted: maps[i]['is_deleted'] == 1,
        createdAt: DateTime.parse(maps[i]['created_at']),
        readAt: maps[i]['read_at'] != null
            ? DateTime.parse(maps[i]['read_at'])
            : null,
        senderName: maps[i]['sender_name'],
        helpCount: maps[i]['help_count'] ?? 0,
      );
    });
  }

  // --- Pending Messages Methods ---

  Future<int> savePendingMessage(Map<String, dynamic> messageData) async {
    final db = await database;
    return await db.insert('pending_messages', messageData);
  }

  Future<List<Map<String, dynamic>>> getPendingMessages(String chatId) async {
    final db = await database;
    return await db.query(
      'pending_messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> deletePendingMessage(int id) async {
    final db = await database;
    await db.delete('pending_messages', where: 'id = ?', whereArgs: [id]);
  }

  // --- Contacts Methods ---

  Future<void> saveContacts(dynamic contactsData) async {
    final db = await database;
    final batch = db.batch();

    if (contactsData is List) {
      for (var contact in contactsData) {
        if (contact is Map<String, dynamic>) {
          batch.insert('contacts', {
            'id': contact['id'],
            'name': contact['name'],
            'role': contact['role'],
            'avatar_url': contact['avatar_url'],
            'unread_count': contact['unread_count'] ?? 0,
            'last_message': contact['last_message'],
            'updated_at': contact['updated_at'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          // ChatUserModel
          try {
            final c = contact as dynamic;
            batch.insert('contacts', {
              'id': c.id,
              'name': c.name,
              'role': c.role,
              'avatar_url': c.avatarUrl,
              'unread_count': (c.unreadCount as int?) ?? 0,
              'last_message': c.lastMessage,
              'updated_at': c.updatedAt?.toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (_) {}
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedContacts() async {
    final db = await database;
    // جلب كافة الأعمدة بما فيها unread_count
    return await db.query('contacts', orderBy: 'updated_at DESC');
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final db = await database;
    await db.update(
      'messages',
      {'read_at': DateTime.now().toIso8601String()},
      where: 'chat_id = ? AND read_at IS NULL',
      whereArgs: [chatId],
    );
  }

  // --- Maintenance ---

  Future<void> deleteMessageLocal(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
