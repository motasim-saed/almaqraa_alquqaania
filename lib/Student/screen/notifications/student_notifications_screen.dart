import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/controllers/notification_controller.dart';
import '../../../core/models/notification_model.dart';
import '../../../Teacher/models/monthly_rating_model.dart';
import 'package:intl/intl.dart';

/// شاشة إشعارات الطالب بتصميم الدردشة الموحد
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // جلب أحدث الإشعارات من السيرفر فور فتح الشاشة (لتحديث الكاش)
      // ثم تعليمها كمقروءة
      controller.fetchNotifications().then((_) {
        controller.markNotificationsAsSeen();
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'no_notifications_currently'.tr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              final dateStr = DateFormat('hh:mm a yyyy/MM/dd', Get.locale?.languageCode ?? 'ar').format(notification.createdAt);

              // رسالة التقييم: بطاقة مميزة حسب تقييم الطالب الفعلي، ومحفوظة ضمن القائمة
              if (notification.isRatingMessage) {
                return _StudentRatingCard(
                  notification: notification,
                  dateStr: dateStr,
                  isDarkMode: isDarkMode,
                );
              }

              return Align(
              alignment: Alignment.centerLeft, // الإشعارات تأتي من الإدارة
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                  minWidth: 140, // ضمان ظهور الوقت والتاريخ حتى لو الرسالة قصيرة
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDarkMode ? Colors.grey[200] : const Color(0xFF334155),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.done_all, size: 14, color: Colors.blue.shade400),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        );
      }),
    );
  }
}

/// بطاقة رسالة التقييم: تعرض مستوى الطالب الفعلي
/// - إن حمل الإشعار مفتاح تقييم صالح يُستخدم مباشرة
/// - وإلا يُجلب آخر تقييم شهري للطالب من جدول monthly_ratings
///   (يصلح مشكلة ظهور "جيد" الافتراضي لرسالة "ممتاز" عند غياب عمود rating)
class _StudentRatingCard extends StatefulWidget {
  final NotificationModel notification;
  final String dateStr;
  final bool isDarkMode;

  const _StudentRatingCard({
    required this.notification,
    required this.dateStr,
    required this.isDarkMode,
  });

  @override
  State<_StudentRatingCard> createState() => _StudentRatingCardState();
}

class _StudentRatingCardState extends State<_StudentRatingCard> {
  late final Future<MonthlyRatingLevel?> _levelFuture;

  @override
  void initState() {
    super.initState();
    _levelFuture = _resolveLevel();
  }

  Future<MonthlyRatingLevel?> _resolveLevel() async {
    // 1) مفتاح صالح مرفق بالإشعار (عند وجود عمود rating)
    final direct =
        MonthlyRatingLevel.tryFromKey(widget.notification.rating);
    if (direct != null) return direct;
    // 2) جلب تقييم الطالب الفعلي (الأحدث) من السيرفر
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await Supabase.instance.client
          .from('monthly_ratings')
          .select('rating')
          .eq('student_id', userId)
          .order('year', ascending: false)
          .order('month', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null) {
        final lv =
            MonthlyRatingLevel.tryFromKey(res['rating']?.toString());
        if (lv != null) return lv;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyRatingLevel?>(
      future: _levelFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shell(
            context,
            accent: Colors.amber,
            icon: Icons.star_rate_rounded,
            levelTitle: '…',
            stars: 0,
            showStars: false,
            loading: true,
          );
        }
        final lv = snap.data;
        if (lv == null) {
          // لا توجد معلومة تقييم: بطاقة مميزة عامة بدون نجوم مضللة
          return _shell(
            context,
            accent: Colors.amber,
            icon: Icons.star_rate_rounded,
            levelTitle: '',
            stars: 0,
            showStars: false,
            loading: false,
          );
        }
        final isArabic = Get.locale?.languageCode != 'en';
        return _shell(
          context,
          accent: lv.color,
          icon: lv.icon,
          levelTitle: isArabic ? lv.titleAr : lv.titleEn,
          stars: lv.stars,
          showStars: true,
          loading: false,
        );
      },
    );
  }

  /// هيكل البطاقة المميزة لرسالة التقييم الشهري: شارة ذهبية + لون المستوى
  Widget _shell(
    BuildContext context, {
    required Color accent,
    required IconData icon,
    required String levelTitle,
    required int stars,
    required bool showStars,
    required bool loading,
  }) {
    final n = widget.notification;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: 140,
        ),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rate_rounded,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'monthly_rating_badge'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accent,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                n.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: widget.isDarkMode ? Colors.grey[200] : const Color(0xFF334155),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (showStars)
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      levelTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.done_all, size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 4),
                  Text(
                    widget.dateStr,
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
