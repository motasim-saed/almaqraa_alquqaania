import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../Student/repository/supabase_student_repository.dart';

/// شاشة الطلبات والاستئذان والشكاوى الرسمية
/// تتيح للمعلم والطالب التواصل النصي الحصري مع الإدارة بدون أي وسائط أو مرفقات
class OfficialRequestsScreen extends StatefulWidget {
  final String userRole; // 'student' أو 'teacher'

  const OfficialRequestsScreen({super.key, required this.userRole});

  @override
  State<OfficialRequestsScreen> createState() => _OfficialRequestsScreenState();
}

class _OfficialRequestsScreenState extends State<OfficialRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  // حقول نموذج تقديم الطلب
  String _selectedType = 'leave_request'; // 'leave_request', 'complaint', 'inquiry'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _messagesHistory = [];
  String? _chatId;
  String? _adminId;
  String? _adminName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminAndHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _detailsController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  /// جلب بيانات المسؤول وسجل المراسلات السابقة
  Future<void> _loadAdminAndHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 1. جلب بيانات الإدارة
      final adminData = await SupabaseStudentRepository().getFirstAdmin();
      if (adminData != null) {
        _adminId = adminData['id']?.toString();
        _adminName = adminData['full_name'] ??
            (adminData['role'] == 'coordinator'
                ? 'coordinator_label'.tr
                : 'admin_label'.tr);
      }

      if (_adminId == null) {
        setState(() => _isLoadingHistory = false);
        return;
      }

      // 2. البحث عن الشات المشترك بين المستخدم والإدارة
      final isTeacher = widget.userRole == 'teacher';
      var query = _supabase.from('chats').select('id');

      if (isTeacher) {
        query = query.or(
          'and(teacher_id.eq.$currentUserId,student_id.eq.$_adminId),and(teacher_id.eq.$_adminId,student_id.eq.$currentUserId)',
        );
      } else {
        query = query.or(
          'and(student_id.eq.$currentUserId,teacher_id.eq.$_adminId),and(student_id.eq.$_adminId,teacher_id.eq.$currentUserId)',
        );
      }

      final chatData = await query.maybeSingle();

      if (chatData != null) {
        _chatId = chatData['id'].toString();
        // 3. جلب الرسائل النصية
        final msgs = await _supabase
            .from('messages')
            .select('id, text, sender_id, created_at, status')
            .eq('chat_id', _chatId!)
            .order('created_at', ascending: true);

        setState(() {
          _messagesHistory = List<Map<String, dynamic>>.from(msgs);
        });
      }
    } catch (e) {
      debugPrint('Error loading official requests history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  /// إرسال طلب جديد للإدارة
  Future<void> _submitRequest() async {
    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();

    if (subject.isEmpty) {
      Get.snackbar(
        'alert'.tr,
        'يرجى إدخال موضوع أو عنوان للطلب',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (details.isEmpty) {
      Get.snackbar(
        'alert'.tr,
        'يرجى كتابة تفاصيل الطلب بشكل واضح',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    if (_adminId == null) {
      Get.snackbar('error'.tr, 'no_admin_found'.tr);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. ضمان وجود سجل Chat مع الإدارة
      if (_chatId == null) {
        final isTeacher = widget.userRole == 'teacher';
        final newChat = await _supabase
            .from('chats')
            .insert({
              'student_id': isTeacher ? _adminId : currentUserId,
              'teacher_id': isTeacher ? currentUserId : _adminId,
              'type': 'private',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        _chatId = newChat['id'].toString();
      }

      // 2. صياغة النص الرسمي للطلب
      String typeTitle;
      if (_selectedType == 'leave_request') {
        typeTitle = 'طلب استئذان / إجازة';
      } else if (_selectedType == 'complaint') {
        typeTitle = 'تقديم شكوى أو بلاغ';
      } else {
        typeTitle = 'استفسار أو مقترح';
      }

      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final StringBuffer messageBuffer = StringBuffer();
      messageBuffer.writeln('📋 [$typeTitle]');
      messageBuffer.writeln('📌 الموضوع: $subject');
      if (_selectedType == 'leave_request') {
        messageBuffer.writeln('📅 الفترة: من $startStr إلى $endStr');
      }
      messageBuffer.writeln('📝 التفاصيل:');
      messageBuffer.write(details);

      final fullMessageText = messageBuffer.toString();

      // 3. إدراج الرسالة النصية في جدول messages
      await _supabase.from('messages').insert({
        'chat_id': _chatId,
        'sender_id': currentUserId,
        'text': fullMessageText,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. تحديث تاريخ الدردشة
      await _supabase.from('chats').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _chatId!);

      // تنظيف الحقول
      _subjectController.clear();
      _detailsController.clear();

      Get.snackbar(
        'success'.tr,
        'تم إرسال طلبك بنجاح إلى الإدارة وسيتم مراجعته',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // إعادة تحميل السجل والتبديل لتبويب المتابعة
      await _loadAdminAndHistory();
      _tabController.animateTo(1);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'فشل في إرسال الطلب، يرجى المحاولة لاحقاً',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// إرسال تعقيب أو رد نصي إضافي
  Future<void> _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty || _chatId == null) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase.from('messages').insert({
        'chat_id': _chatId,
        'sender_id': currentUserId,
        'text': replyText,
        'created_at': DateTime.now().toIso8601String(),
      });

      _replyController.clear();
      await _loadAdminAndHistory();
    } catch (e) {
      Get.snackbar('error'.tr, 'فشل إرسال الرد');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الطلبات والمراسلات الرسمية',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.note_add_outlined), text: 'تقديم طلب جديد'),
            Tab(icon: Icon(Icons.history_outlined), text: 'سجل الطلبات والردود'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  /// تبويب تقديم طلب جديد
  Widget _buildNewRequestTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة توجيهية
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'هذه القناة مخصصة للطلبات والاستئذان والشكاوى الرسمية النصية فقط مع إدارة المقرأة.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // اختيار نوع الطلب
          const Text(
            'نوع الطلب:',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'leave_request',
                    child: Row(
                      children: [
                        Icon(Icons.event_busy, color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Text('طلب استئذان / إجازة', style: TextStyle(fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'complaint',
                    child: Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Text('تقديم شكوى أو ملاحظة', style: TextStyle(fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'inquiry',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.teal, size: 20),
                        SizedBox(width: 10),
                        Text('استفسار أو مقترح', style: TextStyle(fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // إذا كان طلب استئذان، يظهر تحديد التواريخ
          if (_selectedType == 'leave_request') ...[
            const Text(
              'فترة الاستئذان:',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'من: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'إلى: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],

          // موضوع الطلب
          const Text(
            'موضوع الطلب:',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'اكتب عنواناً مختصراً للطلب...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.title),
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 18),

          // تفاصيل الطلب (نص فقط)
          const Text(
            'تفاصيل الطلب أو الشكوى:',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'اكتب التفاصيل والأسباب هنا بوضوح (نص كتابي فقط)...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 24),

          // زر الإرسال
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting ? 'جاري الإرسال...' : 'إرسال الطلب إلى الإدارة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تبويب سجل الطلبات والردود
  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messagesHistory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAdminAndHistory,
        child: ListView(
          padding: const EdgeInsets.all(40),
          children: const [
            SizedBox(height: 60),
            Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'لا توجد طلبات أو مراسلات سابقة مع الإدارة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAdminAndHistory,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messagesHistory.length,
              itemBuilder: (context, index) {
                final msg = _messagesHistory[index];
                final isMe = msg['sender_id'] == currentUserId;
                final text = msg['text'] ?? '';
                final createdAt = msg['created_at'];

                String timeStr = '';
                if (createdAt != null) {
                  try {
                    final dt = DateTime.parse(createdAt).toLocal();
                    timeStr = DateFormat('yyyy/MM/dd hh:mm a').format(dt);
                  } catch (_) {}
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF2C323D) : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isMe
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMe ? Icons.account_circle : Icons.admin_panel_settings,
                              size: 16,
                              color: isMe ? theme.colorScheme.primary : Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isMe ? 'أنت (الطلب المرسل)' : (_adminName ?? 'إدارة المقرأة'),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isMe ? theme.colorScheme.primary : Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          text,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // شريط إضافة تعقيب نصي سريع
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'كتابة رد أو تعقيب نصي إضافي...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF262C36) : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendReply,
                  icon: const Icon(Icons.send_rounded),
                  color: theme.colorScheme.primary,
                  tooltip: 'إرسال التعقيب',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
