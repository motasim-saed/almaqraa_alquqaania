import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../controller/quran_circles_controller.dart'; // استيراد متحكم الحلقات القرآنية
import '../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import 'widgets/assign_examiner_dialog.dart'; // استيراد حوار تعيين المختبر

// شاشة لجنة الاختبارات - ExamCommitteeScreen
// تتيح للمسؤول تعيين معلمين كمختبرين للحلقات للإشراف على جودة التسميع والاختبارات
class ExamCommitteeScreen extends StatelessWidget { // تعريف ودجت لا تحتوي على حالة (Stateless)
  const ExamCommitteeScreen({super.key}); // منشئ الصف مع تمرير مفتاح فريد

  @override
  Widget build(BuildContext context) { // دالة بناء واجهة المستخدم للشاشة
    // تهيئة وجلب المتحكمات اللازمة
    Get.put(AcceptedTeachersController()); // التأكد من توفر متحكم المعلمين المقبولين لاختيار المختبرين
    final circlesController = Get.find<QuranCirclesController>(); // العثور على متحكم الحلقات المسجل مسبقاً
    final theme = Theme.of(context); // الحصول على بيانات الثيم الحالي

    return Scaffold( // إرجاع هيكل الشاشة الأساسي
      backgroundColor: theme.scaffoldBackgroundColor, // استخدام لون خلفية الثيم ليدعم الوضعين
      // ملاحظة: تم إزالة الهيدر الداخلي وحقل البحث بناءً على طلب المستخدم
      // حيث يتم الاعتماد على أزرار البحث والتحديث الموجودة في الـ AppBar الرئيسي للتطبيق
      body: Padding( // إضافة هوامش حول محتوى الشاشة
        padding: const EdgeInsets.all(24.0), // هامش بمقدار 24 بكسل من جميع الجهات
        child: Column( // ترتيب العناصر بشكل عمودي
          crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر للبداية أفقياً
          children: [ // قائمة العناصر داخل العمود
            // تم حذف قسم العنوان وزر التحديث من هنا للاعتماد على الـ AppBar العلوي
            // تم حذف حقل البحث اليدوي من هنا للاعتماد على بحث الـ AppBar العلوي

            // قائمة الحلقات مع تفاصيل المختبرين وتحديثها تلقائياً عند البحث أو التغيير
            Expanded( // توسيع القائمة لتأخذ المساحة المتبقية
              child: Obx(() { // استخدام Obx لمراقبة التغييرات في بيانات المتحكم
                // التحقق من حالة التحميل
                if (circlesController.isLoading.value) { // إذا كان جاري التحميل
                  return const Center(child: CircularProgressIndicator()); // عرض مؤشر تقدم في المنتصف
                }

                // تطبيق فلتر البحث على قائمة الحلقات (البحث يتم عبر circlesController.searchQuery المحدث من الـ AppBar)
                final filteredCircles = circlesController.quranCircles.where((circle) { // تصفية القائمة
                  final query = circlesController.searchQuery.value.toLowerCase(); // تحويل نص البحث لحروف صغيرة
                  return circle.name.toLowerCase().contains(query) || // التحقق من مطابقة اسم الحلقة
                         circle.teacherName.toLowerCase().contains(query) || // التحقق من مطابقة اسم المعلم
                         (circle.examinerName?.toLowerCase().contains(query) ?? false); // التحقق من مطابقة اسم المختبر
                }).toList(); // تحويل النتائج لقائمة

                // عرض رسالة في حال كانت القائمة فارغة (سواء الأصلية أو المفلترة)
                if (filteredCircles.isEmpty) { // إذا لم توجد نتائج
                  return Center(
                    child: Text(
                      'no_matching_circles'.tr,
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ); // عرض نص "لا توجد نتائج مطابقة" بلون متناسق
                }

                // بناء القائمة الفعلية للعناصر المفلترة باستخدام ListView
                return ListView.builder( // بناء قائمة بشكل كفؤ
                  itemCount: filteredCircles.length, // عدد العناصر المفلترة
                  itemBuilder: (context, index) { // دالة بناء كل عنصر
                    final circle = filteredCircles[index]; // الحصول على الحلقة الحالية
                    return _buildCircleExaminerCard( // استدعاء دالة بناء بطاقة الحلقة
                      context,
                      circle,
                      circlesController,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة الحلقة - _buildCircleExaminerCard
  // تحتوي على معلومات الحلقة، المعلم الأساسي، والمختبر المعين مع أزرار التحكم
  Widget _buildCircleExaminerCard( // دالة ترجع ودجت البطاقة
    BuildContext context, // سياق بناء الواجهة
    QuranCircleModel circle, // بيانات الحلقة الحالية
    QuranCirclesController controller, // نسخة من متحكم الحلقات
  ) {
    final theme = Theme.of(context); // الحصول على بيانات الثيم
    final colorScheme = theme.colorScheme; // الحصول على مخطط الألوان
    final isDark = theme.brightness == Brightness.dark; // التحقق إذا كان الوضع غامقاً

    return Card( // ودجت البطاقة لإعطاء ظل وشكل بارز
      margin: const EdgeInsets.only(bottom: 16), // مسافة سفلية بين كل بطاقة وأخرى
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // حواف دائرية للبطاقة بنسبة 16
      elevation: isDark ? 0 : 2, // إلغاء الظل في الوضع الغامق لتصميم أنظف
      color: theme.cardColor, // استخدام لون البطاقة من الثيم
      child: Padding( // هوامش داخلية لمحتوى البطاقة
        padding: const EdgeInsets.all(20), // هامش بمقدار 20 بكسل
        child: Row( // ترتيب محتوى البطاقة بشكل أفقي
          children: [ // قائمة العناصر داخل الصف
            // أيقونة تمثل الحلقة
            Container( // حاوية للأيقونة مع خلفية ملونة
              padding: const EdgeInsets.all(12), // هوامش داخلية للأيقونة
              decoration: BoxDecoration( // تنسيق الخلفية
                color: colorScheme.primary.withValues(
                  alpha: 0.1), // لون مشتق من اللون الرئيسي للثيم
                borderRadius: BorderRadius.circular(12), // حواف دائرية بنسبة 12
              ),
              child: Icon(Icons.group, color: colorScheme.primary, size: 32), // أيقونة مجموعة باللون الرئيسي
            ),
            const SizedBox(width: 20), // مسافة أفقية بمقدار 20 بكسل
            
            // قسم معلومات الحلقة والمعلم الأساسي
            Expanded( // جعل هذا القسم يأخذ أقصى مساحة متاحة في الصف
              child: Column( // ترتيب النصوص بشكل عمودي
                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النصوص للبداية
                children: [ // قائمة النصوص
                  Text( // عرض اسم الحلقة
                    circle.name, // اسم الحلقة من النموذج
                    style: TextStyle( // تنسيق الاسم
                      fontSize: 18, // حجم الخط 18 بكسل
                      fontWeight: FontWeight.bold, // خط عريض
                      color: theme.textTheme.bodyLarge?.color, // لون النص من الثيم
                    ),
                  ),
                  const SizedBox(height: 4), // مسافة عمودية بسيطة
                  Text( // عرض اسم المعلم الأساسي
                    '${'main_teacher'.tr}: ${circle.teacherName}', // دمج كلمة "المعلم الأساسي" مع الاسم
                    style: TextStyle(color: theme.hintColor, fontSize: 14), // لون التلميح وحجم خط 14
                  ),
                ],
              ),
            ),
            
            // فاصل عمودي متناسق مع الثيم
            Container(height: 40, width: 1, color: theme.dividerColor),
            const SizedBox(width: 20),
            
            // قسم معلومات المختبر المعين (أو حالة عدم التعيين)
            Expanded( // جعل هذا القسم يأخذ مساحة مساوية لقسم معلومات الحلقة
              child: Column( // ترتيب المعلومات عمودياً
                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النصوص للبداية
                children: [ // قائمة النصوص والأيقونات
                  Text( // تسمية القسم
                    'assigned_examiner'.tr, // نص "المختبر المعين" المترجم
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ), // تنسيق عريض وصغير متوافق مع الثيم
                  ),
                  const SizedBox(height: 4), // مسافة عمودية بسيطة
                  Row( // ترتيب أيقونة الحالة واسم المختبر أفقياً
                    children: [ // قائمة العناصر
                      Icon( // أيقونة توضح حالة التعيين
                        circle.examinerId != null // إذا كان هناك مختبر معين
                            ? Icons.check_circle // عرض أيقونة "تم"
                            : Icons.help_outline, // وإلا عرض أيقونة "استفهام/غير محدد"
                        size: 16, // حجم الأيقونة 16 بكسل
                        color: circle.examinerId != null // تحديد اللون بناءً على الحالة
                            ? Colors.green // أخضر إذا كان معيناً
                            : Colors.orange, // برتقالي إذا لم يكن معيناً
                      ),
                      const SizedBox(width: 8), // مسافة أفقية بسيطة
                      Expanded(
                        child: Text( // عرض اسم المختبر أو نص يفيد بعدم التعيين
                          circle.examinerName ?? 'not_assigned_yet'.tr, // جلب الاسم أو نص "لم يتم التعيين"
                          style: TextStyle( // تنسيق الخط بناءً على الحالة
                            color: circle.examinerId != null // تغيير اللون
                                ? theme.textTheme.bodyMedium?.color // لون النص من الثيم
                                : theme.hintColor, // لون التلميح إذا لم يوجد
                            fontWeight: circle.examinerId != null // تغيير سمك الخط
                                ? FontWeight.w500 // متوسط إذا وجد
                                : FontWeight.normal, // عادي إذا لم يوجد
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20), // مسافة أفقية بمقدار 20 بكسل قبل الأزرار
            
            // زر التعيين أو تغيير المختبر
            ElevatedButton( // زر بارز للتفاعل
              onPressed: () { // الوظيفة المنفذة عند الضغط
                // فتح نافذة حوار اختيار وتعيين المختبر وتمرير بيانات الحلقة الحالية لها
                Get.dialog(AssignExaminerDialog(circle: circle));
              },
              style: ElevatedButton.styleFrom( // تحديد نمط الزر بناءً على الحالة والثيم
                backgroundColor: circle.examinerId != null // تغيير لون الخلفية
                    ? (isDark ? theme.highlightColor : Colors.grey[100]) // لون محايد إذا وجد مختبر
                    : colorScheme.primary, // اللون الرئيسي إذا لم يوجد مختبر
                foregroundColor: circle.examinerId != null // تغيير لون النص
                    ? (isDark ? Colors.white : colorScheme.primary) 
                    : colorScheme.onPrimary, // لون النص المتوافق مع الخلفية
                elevation: 0, // إلغاء الظل الخاص بالزر
                padding: const EdgeInsets.symmetric( // هوامش داخلية للزر
                  horizontal: 16, // 16 أفقي
                  vertical: 12, // 12 عمودي
                ),
                shape: RoundedRectangleBorder( // حواف الزر
                  borderRadius: BorderRadius.circular(10), // نصف قطر الانحناء 10
                ),
              ),
              child: Text( // عرض نص الزر المترجم بناءً على الحالة (تغيير أو تعيين)
                circle.examinerId != null ? 'change_examiner'.tr : 'assign_examiner'.tr,
              ),
            ),
            // إذا كان هناك مختبر معين، يتم عرض زر إضافي لحذف التعيين
            if (circle.examinerId != null) ...[ // شرط عرض زر الحذف
              const SizedBox(width: 8), // مسافة بسيطة بين الأزرار
              IconButton( // زر يحتوي على أيقونة فقط
                onPressed: () => controller.assignExaminer(circle.id, null), // استدعاء دالة التعيين مع قيمة null للحذف
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent), // أيقونة سلة المهملات بلون أحمر بارز
                tooltip: 'delete_assignment'.tr, // نص تلميحي يظهر عند الوقوف على الزر "حذف التعيين"
              ),
            ],
          ],
        ),
      ),
    );
  }
}
