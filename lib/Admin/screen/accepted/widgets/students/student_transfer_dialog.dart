import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import '../../../../controller/quran_circles_controller.dart'; // استيراد متحكم الحلقات القرآنية

// حوار توزيع ونقل الطلاب - StudentTransferDialog
// يتيح للمسؤول اختيار حلقة قرآنية لتوزيع طالب جديد عليها أو نقل طالب موجود من حلقة لأخرى
class StudentTransferDialog {
  // دالة ستاتيكية لعرض الحوار
  static void show(
    BuildContext context, // سياق التطبيق
    StudentModel student, // نموذج بيانات الطالب
    AcceptedStudentsController controller, // متحكم الطلاب المقبولين
  ) {
    // الوصول لمتحكم الحلقات لجلب القائمة الحالية من الذاكرة أو الخادم
    final circlesController = Get.find<QuranCirclesController>();
    circlesController.fetchQuranCircles(); // تحديث بيانات الحلقات

    Get.dialog( // فتح نافذة الحوار باستخدام GetX
      AlertDialog( // استخدام نافذة تنبيه تقليدية
        title: Text( // عنوان النافذة يتغير حسب حالة الطالب (نقل أو توزيع)
          '${student.isDistributed ? 'transfer_student'.tr : 'distribute_student'.tr}: ${student.name}',
        ),
        content: SizedBox( // تحديد حجم محتوى النافذة
          width: double.maxFinite, // أقصى عرض متاح
          child: Obx(() { // مراقبة التغييرات في متحكم الحلقات وتحديث الواجهة
            if (circlesController.isLoading.value) { // عرض مؤشر تحميل إذا كانت البيانات قيد الجلب
              return const Center(child: CircularProgressIndicator());
            }

            // تصفية الحلقات حسب جنس الطالب (بنين للبنين وبنات للبنات) لضمان الفصل
            final circles = circlesController.quranCircles
                .where((c) => c.gender == student.gender)
                .toList();

            if (circles.isEmpty) { // عرض رسالة في حال عدم وجود حلقات متاحة لهذا الجنس
              return Center(child: Text('no_circles_available'.tr));
            }

            return ListView.separated( // عرض قائمة الحلقات المتاحة مع فواصل
              shrinkWrap: true, // جعل القائمة تأخذ مساحة المحتوى فقط
              itemCount: circles.length, // عدد الحلقات المتاحة
              separatorBuilder: (context, index) => const Divider(), // خط فاصل بين كل حلقة
              itemBuilder: (context, index) { // بناء عناصر القائمة
                final circle = circles[index]; // الحلقة الحالية في التكرار
                return ListTile( // عنصر قائمة لكل حلقة
                  title: Text( // عرض اسم الحلقة
                    circle.name,
                    style: const TextStyle(fontWeight: FontWeight.bold), // نص عريض لاسم الحلقة
                  ),
                  subtitle: Column( // تفاصيل الحلقة في عمود تحت الاسم
                    crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النص للبداية
                    children: [
                      // عرض اسم معلم الحلقة الحالي
                      Text('${'teacher'.tr}: ${circle.teacherName}'),
                      const SizedBox(height: 3), // مسافة صغيرة
                      // عرض عدد الطلاب الحالي في الحلقة مع أيقونة
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey[600]), // أيقونة المستخدمين
                          const SizedBox(width: 4), // مسافة أفقية
                          Text( // نص يوضح عدد الطلاب
                            '${circle.studentCount} ${'students'.tr}',
                            style: TextStyle(color: Colors.grey[600]), // لون رمادي للنص الفرعي
                          ),
                        ],
                      ),
                      // عرض أسماء الطلاب الموجودين في الحلقة (للتأكد قبل النقل أو التوزيع)
                      if (circle.studentNames.isNotEmpty) // التحقق من وجود طلاب أولاً
                        Padding(
                          padding: const EdgeInsets.only(top: 4), // مسافة علوية
                          child: Text( // نص يسرد أسماء الطلاب
                            '${'students'.tr}: ${circle.studentNames.join('، ')}',
                            style: TextStyle(
                              fontSize: 13, // حجم خط صغير للأسماء
                              color: Colors.grey[500], // لون باهت

                            ),
                            maxLines: 2, // حد أقصى سطرين
                            overflow: TextOverflow.ellipsis, // نقاط في حال كان النص طويلاً جداً
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: circle.studentNames.isNotEmpty, // تحسين المظهر إذا كانت التفاصيل كثيرة
                  onTap: () { // عند اختيار حلقة معينة
                    Get.back(); // إغلاق نافذة الحوار
                    // تنفيذ عملية النقل أو التوزيع في متحكم الطلاب
                    controller.transferStudent(student.id, circle.id);
                  },
                );
              },
            );
          }),
        ),
        actions: [ // أزرار العمليات في أسفل النافذة
          // زر الإلغاء لإغلاق النافذة دون إجراء أي تغيير
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }
}
