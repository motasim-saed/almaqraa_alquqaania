import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج بيانات الأدمن
import '../../../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import 'teacher_details_dialog.dart'; // استيراد نافذة تفاصيل المعلم

// بطاقة المعلم - TeacherCard تعرض ملخص بيانات المعلم في القائمة
class TeacherCard extends StatelessWidget {
  final TeacherModel item; // نموذج بيانات المعلم
  final AcceptedTeachersController controller; // نسخة من المتحكم لإدارة العمليات

  // بناء الكلاس مع المعاملات المطلوبة
  const TeacherCard({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    // التحقق من حالة الثيم (غامق أم فاتح)
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // التحقق مما إذا كان المعلم قد تم توزيعه على حلقة أم لا
    final bool isDistributed = controller.isTeacherDistributed(item.id);
    
    // تحديد لون الثيم بناءً على جنس المعلم مع دعم الوضع الغامق بألوان أكثر سطوعاً
    final Color themeColor = item.gender == Gender.male 
        ? (isDarkMode ? Colors.indigoAccent : Theme.of(context).primaryColor)
        : (isDarkMode ? Colors.pinkAccent : Colors.pink);

    return Container( // الحاوية الرئيسية للبطاقة
      decoration: BoxDecoration( // تنسيق الحاوية
        color: Theme.of(context).cardColor, // لون الخلفية متفاعل مع الثيم
        borderRadius: BorderRadius.circular(16), // حواف دائرية
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.2) // حواف أوضح في الوضع الغامق
              : Colors.indigo.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black45 : Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => TeacherDetailsDialog.show(context, item, controller),
            child: Stack(
              children: [
                PositionRectangle(color: themeColor.withValues(alpha: 0.07)),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(context, themeColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Colors.black87, // لون الاسم
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.academicNumber,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(), 
                      Divider(
                        height: 24, 
                        thickness: 1.0,
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)
                      ), 
                      
                      // تفاصيل التخصص والحالة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'specialization'.tr,
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: isDarkMode ? Colors.white70 : Theme.of(context).hintColor, // لون التسمية
                                  ),
                                ),
                                // تم تحسين لون النص هنا ليكون واضحاً جداً في الثيم الغامق
                                Text(
                                  item.specialization,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor, // استخدام اللون الساطع المتكيف
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(isDistributed),
                        ],
                      ),
                      
                      const SizedBox(height: 12), 
                      
                      Row(
                        children: [
                          if (!item.canCoverBalance)
                            _buildSponsorshipInfo(context)
                          else
                            const Spacer(),
                          
                          IconButton(
                            onPressed: () => _confirmDelete(context, item, controller),
                            icon: Icon(
                              Icons.delete_outline_rounded, 
                              color: isDarkMode ? Colors.redAccent.shade100 : Theme.of(context).colorScheme.error, 
                              size: 20
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            tooltip: 'delete'.tr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ودجت لبناء الصورة الرمزية (الأفاتار)
  Widget _buildAvatar(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Icon(
        item.gender == Gender.male ? Icons.person_rounded : Icons.person_3_rounded,
        color: color,
        size: 24,
      ),
    );
  }

  // ودجت لبناء شارة حالة التوزيع (موزع أو غير موزع)
  Widget _buildStatusBadge(bool isDistributed) {
    final Color statusColor = isDistributed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        isDistributed ? 'distributed'.tr : 'not_distributed'.tr,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  // ودجت لعرض معلومات الحاجة للكفالة
  Widget _buildSponsorshipInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism, size: 12, color: isDarkMode ? Colors.white70 : Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'needs_sponsorship'.tr,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: isDarkMode ? Colors.white70 : Theme.of(context).hintColor
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لعرض نافذة تأكيد حذف المعلم
  void _confirmDelete(BuildContext context, TeacherModel teacher, AcceptedTeachersController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'confirm_delete'.tr, 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)
        ),
        content: Text(
          '${'delete_confirm_msg'.tr} ${teacher.name}؟',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), 
            child: Text('cancel'.tr, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeUser(teacher.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error, 
              foregroundColor: Theme.of(context).colorScheme.onError
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}

// ودجت تزييني لرسم دائرة في خلفية البطاقة
class PositionRectangle extends StatelessWidget {
  final Color color;
  const PositionRectangle({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -25,
      right: -25,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
