import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة
import '../../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import '../../../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../filter_chip_widget.dart'; // استيراد ويدجت شريحة الفلترة المخصصة

// شريط الفلترة للمعلمين المقبولين - TeacherFilterBar (ويدجت لعرض خيارات التصفية)
class TeacherFilterBar extends StatelessWidget {
  final AcceptedTeachersController controller; // تعريف المتحكم للوصول إلى البيانات والعمليات
  final Gender gender; // تعريف المتغير لتحديد الجنس (ذكر/أنثى) للفلترة

  const TeacherFilterBar({
    super.key, // المفتاح الفريد للويدجت
    required this.controller, // تمرير المتحكم كمعامل مطلوب
    required this.gender, // تمرير الجنس كمعامل مطلوب
  });

  @override
  Widget build(BuildContext context) {
    // تحديد فلتر الكفالة المناسب بناءً على الجنس (ذكر أو أنثى)
    final sponsorshipFilter = gender == Gender.male
        ? controller.maleSponsorshipFilter
        : controller.femaleSponsorshipFilter;

    // تحديد فلتر التوزيع المناسب بناءً على الجنس (ذكر أو أنثى)
    final distributionFilter = gender == Gender.male
        ? controller.maleDistributionFilter
        : controller.femaleDistributionFilter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // استخدام لون الخلفية من سمة التطبيق مع إطار سفلي
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // جعل الشريط قابل للتمرير أفقياً
        child: Obx(() { // استخدام Obx لتحديث الواجهة تلقائياً عند تغير البيانات
          // تصفية المعلمين بناءً على الجنس المحدد
          final teachers = controller.acceptedTeachers
              .where((t) => t.gender == gender)
              .toList();

          final allCount = teachers.length; // حساب العدد الإجمالي للمعلمين
          // حساب عدد المعلمين الذين يحتاجون لكفالة (لا يمكنهم تغطية الرصيد)
          final neededSponsorshipCount = teachers.where((t) => !t.canCoverBalance).length;
          // حساب عدد المعلمين الذين لا يحتاجون لكفالة
          final notNeededSponsorshipCount = teachers.where((t) => t.canCoverBalance).length;

          // حساب الأعداد الحقيقية للتوزيع بناءً على ربط الحلقات عبر المتحكم
          final distributedCount = teachers.where((t) => controller.isTeacherDistributed(t.id)).length;
          final notDistributedCount = allCount - distributedCount; // حساب عدد غير الموزعين

          return Row(
            children: [
              // عرض عنوان قسم الكفالة مترجماً مع تنسيق الخط
              Text('${'sponsorship'.tr}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              FilterChipWidget(
                label: '${'all'.tr} ($allCount)', // تسمية "الكل" مع العدد الإجمالي
                isSelected: sponsorshipFilter.value == 'all', // التحقق مما إذا كان خيار "الكل" مختاراً
                onTap: () => sponsorshipFilter.value = 'all', // تغيير قيمة الفلتر إلى "الكل" عند النقر
              ),
              const SizedBox(width: 8), // مسافة أفقية بين العناصر
              FilterChipWidget(
                label: '${'needs_sponsorship'.tr} ($neededSponsorshipCount)', // تسمية "يحتاج كفالة" مع العدد
                isSelected: sponsorshipFilter.value == 'needed', // التحقق من اختيار فلتر "يحتاج"
                onTap: () => sponsorshipFilter.value = 'needed', // تغيير الفلتر إلى "يحتاج" عند النقر
              ),
              const SizedBox(width: 8), // مسافة أفقية
              FilterChipWidget(
                label: '${'not_needs_sponsorship'.tr} ($notNeededSponsorshipCount)', // تسمية "لا يحتاج" مع العدد
                isSelected: sponsorshipFilter.value == 'not_needed', // التحقق من اختيار فلتر "لا يحتاج"
                onTap: () => sponsorshipFilter.value = 'not_needed', // تغيير الفلتر إلى "لا يحتاج"
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12), // هامش للمقسم العمودي
                child: SizedBox(
                  height: 24, 
                  child: VerticalDivider(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    thickness: 1,
                  ),
                ), // رسم خط عمودي فاصل بين الأقسام
              ),

              // قسم التوزيع (عرض حالة توزيع المعلمين على الحلقات)
              Text('${'distribution'.tr}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              FilterChipWidget(
                label: '${'all'.tr} ($allCount)', // خيار عرض الجميع في التوزيع
                isSelected: distributionFilter.value == 'all', // حالة الاختيار
                onTap: () => distributionFilter.value = 'all', // تنفيذ الفلترة للكل
              ),
              const SizedBox(width: 8), // مسافة
              FilterChipWidget(
                label: '${'distributed'.tr} ($distributedCount)', // خيار الموزعين مع عددهم
                isSelected: distributionFilter.value == 'distributed', // حالة الاختيار
                onTap: () => distributionFilter.value = 'distributed', // فلترة الموزعين
              ),
              const SizedBox(width: 8), // مسافة
              FilterChipWidget(
                label: '${'not_distributed'.tr} ($notDistributedCount)', // خيار غير الموزعين مع عددهم
                isSelected: distributionFilter.value == 'not_distributed', // حالة الاختيار
                onTap: () => distributionFilter.value = 'not_distributed', // فلترة غير الموزعين
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12), // هامش للمقسم الأخير
                child: SizedBox(
                  height: 24, 
                  child: VerticalDivider(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    thickness: 1,
                  ),
                ), // خط فاصل عمودي
              ),

              // زر لتصدير قائمة المعلمين (Excel/PDF) بناءً على الفلاتر الحالية
              IconButton(
                onPressed: () => controller.exportTeachers(gender), // استدعاء دالة التصدير في المتحكم
                icon: const Icon(Icons.description_outlined, color: Colors.green), // أيقونة ملف خضراء (ثابتة لأنها تمثل إكسل)
                tooltip: 'export'.tr, // نص تلميحي مترجم لزر التصدير
              ),
            ],
          );
        }),
      ),
    );
  }

  // رسائل عامة للعمليات (تدعم العربية والإنجليزية عبر الترجمة)
  void showSuccess(String message) => Get.snackbar(
    'success'.tr, 
    message.tr, 
    backgroundColor: Colors.green, 
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
  );
  void showError(String error) => Get.snackbar(
    'error'.tr, 
    error.tr, 
    backgroundColor: Colors.red, 
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
  );
}
