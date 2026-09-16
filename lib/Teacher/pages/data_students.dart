import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال الخاصة بواجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة فتح الروابط الخارجية
import '../controller/student_monitoring_controller.dart'; // استيراد متحكم مراقبة الطلاب
import 'student_detail_progress_screen.dart'; // استيراد شاشة تفاصيل تقدم الطالب

/// شاشة عرض قائمة الطلاب التابعين للمعلم لمراقبة تقدمهم (الجداول)
/// تم تصميمها لتظهر داخل الواجهة الرئيسية للمعلم بدون Scaffold مستقل
class DataStudents extends StatelessWidget {
  // تعريف الفئة كودجت بدون حالة (Stateless)
  const DataStudents({super.key}); // منشئ الفئة الثابت

  @override // إعادة تعريف دالة البناء الأساسية
  Widget build(BuildContext context) {
    // دالة بناء واجهة المستخدم
    // تهيئة واسترجاع متحكم مراقبة بيانات الطلاب ووضعه في الذاكرة
    final StudentMonitoringController controller = Get.put(
      StudentMonitoringController(),
    );

    return RefreshIndicator(
      onRefresh: () => controller.fetchStudents(), // إضافة خاصية السحب للتحديث
      child: Column(
        // تنظيم الواجهة في عمود رأسي
        children: [
          // قائمة العناصر داخل العمود
          // إضافة مساحة علوية (Padding) تحتوي على صف للإجراءات

          // استخدام Expanded لجعل قائمة الطلاب تأخذ المساحة المتبقية من الشاشة
          Expanded(
            child: Obx(() {
              // استخدام Obx لإعادة بناء القائمة تلقائياً عند تغير البيانات
              if (controller.isLoading.value && controller.students.isEmpty) {
                // التحقق من حالة التحميل في المتحكم
                return const Center(
                  child: CircularProgressIndicator(),
                ); // عرض مؤشر تحميل دائري
              }
              if (controller.students.isEmpty) {
                // التحقق مما إذا كانت قائمة الطلاب فارغة
                // استخدام ListView لتمكين السحب للتحديث حتى لو كانت القائمة فارغة
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text('no_students_currently'.tr),
                    ),
                  ],
                ); // عرض رسالة "لا يوجد طلاب حالياً" مترجمة
              }
              return ListView.builder(
                // بناء قائمة قابلة للتمرير بكفاءة
                physics: const AlwaysScrollableScrollPhysics(), // التأكد من قابلية التمرير للسحب
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ), // هوامش جانبية للقائمة
                itemCount: controller
                    .students
                    .length, // عدد العناصر بناءً على عدد الطلاب
                itemBuilder: (context, index) {
                  // دالة بناء كل عنصر (بطاقة طالب)
                  final student = controller
                      .students[index]; // الحصول على بيانات الطالب الحالي
                  return Card(
                    // عرض بيانات الطالب داخل بطاقة
                    elevation: 2, // شدة الظل تحت البطاقة
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                    ), // مسافة عمودية بين البطاقات
                    shape: RoundedRectangleBorder(
                      // تحديد شكل زوايا البطاقة
                      borderRadius: BorderRadius.circular(12), // زوايا دائرية
                    ),
                    child: ListTile(
                      // عنصر قائمة قياسي لتنظيم محتوى البطاقة
                      leading: CircleAvatar(
                        // أيقونة دائرية في بداية السطر
                        backgroundColor: student.isSupervisor
                            ? Colors.amber.shade100
                            : Colors.blue.shade100, // لون خلفية الأيقونة
                        child: student.isSupervisor
                            ? const Icon(Icons.star_rounded, color: Colors.amber, size: 24)
                            : Text(
                                // عرض الحرف الأول من اسم الطالب
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : '?', // التأكد من وجود اسم
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ), // نص عريض
                              ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              // عرض اسم الطالب كعنوان
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ), // نص عريض للعنوان
                            ),
                          ),
                          if (student.isSupervisor)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.shade700,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'مشرف الحلقة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${'level'.tr}: ${student.level}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ), // عرض مستوى الطالب مترجماً
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            tooltip: 'خيارات',
                            onSelected: (value) async {
                              if (value == 'toggle_supervisor') {
                                controller.toggleCircleSupervisor(student);
                              } else if (value == 'view_details') {
                                controller.fetchStudentDetails(student.id);
                                Get.to(
                                  () => StudentDetailProgressScreen(student: student),
                                );
                              } else if (value == 'whatsapp') {
                                // فتح واتساب مع الطالب مباشرةً
                                final rawPhone = student.phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                                final whatsappUri = Uri.parse('https://wa.me/$rawPhone');
                                if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
                                  Get.snackbar(
                                    'تنبيه',
                                    'تعذّر فتح واتساب، تأكد من تسجيل رقم الهاتف للطالب',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'view_details',
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text('عرض الإنجازات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                                  ],
                                ),
                              ),
                              // خيار واتساب - يظهر فقط إذا كان للطالب رقم هاتف مسجّل
                              if (student.phone.isNotEmpty)
                                PopupMenuItem(
                                  value: 'whatsapp',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF25D366),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chat_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'تواصل بالواتساب',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: Color(0xFF25D366),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'toggle_supervisor',
                                child: Row(
                                  children: [
                                    Icon(
                                      student.isSupervisor
                                          ? Icons.star_border_rounded
                                          : Icons.star_rounded,
                                      size: 18,
                                      color: student.isSupervisor ? Colors.red : Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      student.isSupervisor
                                          ? 'سحب صلاحية الإشراف'
                                          : 'تعيين كمشرف للحلقة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: student.isSupervisor ? Colors.red : Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ), // أيقونة سهم للنقر
                      onTap: () {
                        // وظيفة تُنفذ عند النقر على بطاقة الطالب
                        // جلب تفاصيل الطالب (السجلات والخطط) قبل الانتقال
                        controller.fetchStudentDetails(student.id);
                        // الانتقال إلى شاشة عرض تقدم الطالب المحددة
                        Get.to(
                          () => StudentDetailProgressScreen(student: student),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
