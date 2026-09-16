import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import '../../controller/quran_circles_controller.dart'; // استيراد متحكم حلقات القرآن
import '../../controller/admin_layout_controller.dart'; // استيراد متحكم تخطيط صفحة المسؤول
import '../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import 'widgets/circle_details_dialog.dart'; // استيراد نافذة تفاصيل الحلقة
import 'widgets/add_circle_dialog.dart'; // استيراد نافذة إضافة حلقة جديدة

import '../widgets/admin_stat_card.dart'; // استيراد بطاقة الإحصائيات الخاصة بالمسؤول

// شاشة إدارة الحلقات القرآنية
// تتيح للمسؤول عرض، إضافة، حذف، والبحث في الحلقات القرآنية القائمة
class QuranCirclesScreen extends StatelessWidget { // تعريف كلاس شاشة حلقات القرآن
  const QuranCirclesScreen({super.key}); // المنشئ الثابت للشاشة

  @override // إعادة تعريف دالة البناء
  Widget build(BuildContext context) { // دالة بناء واجهة المستخدم
    // تهيئة المتحكمات اللازمة (المعلمون والطلاب المقبولون مطلوبون لنوافذ الإضافة والتعديل)
    final controller = Get.put(QuranCirclesController()); // تهيئة متحكم حلقات القرآن
    Get.put(AcceptedTeachersController()); // تهيئة متحكم المعلمين المقبولين
    Get.put(AcceptedStudentsController()); // تهيئة متحكم الطلاب المقبولين
    final layoutController = Get.find<AdminLayoutController>(); // البحث عن متحكم التخطيط العام

    // مزامنة فلتر الجنس بين شريط التنقل الرئيسي وهذه الشاشة
    ever(layoutController.quranCirclesGenderFilter, (val) { // مراقبة التغير في فلتر الجنس
      controller.selectedGenderFilter.value = val; // تحديث قيمة الفلتر في المتحكم المحلي
    }); // نهاية المراقبة

    // المزامنة الأولية عند فتح الشاشة
    controller.selectedGenderFilter.value = // تعيين القيمة الابتدائية لفلتر الجنس
        layoutController.quranCirclesGenderFilter.value; // جلب القيمة من متحكم التخطيط

    return Scaffold( // إرجاع هيكل الصفحة الأساسي
      backgroundColor: Colors.transparent, // تعيين خلفية شفافة لتتناسب مع التصميم العام
      body: Column( // استخدام عمود لترتيب المحتويات
        children: [ // قائمة العناصر داخل العمود
          _buildHeader(controller), // استدعاء دالة بناء الهيدر (العنوان والأزرار)
          Expanded(child: _buildFilteredList(controller)), // عرض قائمة الحلقات المفلترة في المساحة المتبقية
        ], // نهاية عناصر العمود
      ), // نهاية العمود
    ); // نهاية الهيكل
  } // نهاية دالة البناء

  // بناء الهيدر العلوي للشاشة
  Widget _buildHeader(QuranCirclesController controller) { // دالة بناء الجزء العلوي
    return Padding( // إضافة هوامش حول الهيدر
      padding: const EdgeInsets.all(24.0), // هامش بمقدار 24 بكسل
      child: Column( // ترتيب محتويات الهيدر عمودياً
        crossAxisAlignment: CrossAxisAlignment.stretch, // تمدد المحتويات لعرض الشاشة
        children: [ // قائمة العناصر
          Row( // صف لزر الإضافة
            mainAxisAlignment: MainAxisAlignment.end, // محاذاة الزر لجهة اليمين
            children: [ // قائمة العناصر في الصف
              // زر إضافة حلقة جديدة
              ElevatedButton.icon( // زر بارز مع أيقونة
                onPressed: () => Get.dialog(const AddCircleDialog()), // فتح نافذة الإضافة عند الضغط
                icon: const Icon(Icons.add), // أيقونة الإضافة
                label: Text('add_circle'.tr), // نص الزر المترجم
                style: ElevatedButton.styleFrom( // تنسيق مظهر الزر
                  backgroundColor: Colors.indigo, // لون الخلفية أرجواني
                  foregroundColor: Colors.white, // لون النص والأيقونة أبيض
                  padding: const EdgeInsets.symmetric( // هوامش داخلية
                    horizontal: 20, // 20 من الجانبين
                    vertical: 12, // 12 من الأعلى والأسفل
                  ), // نهاية الهوامش
                  shape: RoundedRectangleBorder( // شكل حواف الزر
                    borderRadius: BorderRadius.circular(12), // تدوير الحواف بمقدار 12
                  ), // نهاية شكل الحواف
                ), // نهاية التنسيق
              ), // نهاية زر الإضافة
            ], // نهاية عناصر الصف
          ), // نهاية الصف
          const SizedBox(height: 20), // مسافة فاصلة بارتفاع 20
          // بطاقات فلترة الجنس وإحصائيات سريعة
          Obx( // أداة لتحديث الواجهة تلقائياً عند تغير البيانات
            () => Row( // صف يحتوي على بطاقات الإحصائيات/الفلترة
              children: [ // قائمة البطاقات
                Expanded( // البطاقة الأولى: بنين
                  child: _buildFilterCard( // بناء بطاقة الفلترة
                    controller: controller, // تمرير المتحكم
                    targetGender: Gender.male, // استهداف فئة الذكور
                    title: 'boys'.tr, // عنوان البطاقة (بنين)
                    value: controller.maleCirclesCount.toString(), // عدد حلقات البنين
                    icon: Icons.male, // أيقونة ذكر
                    color: Colors.blue, // لون أزرق للبنين
                  ), // نهاية بناء البطاقة
                ), // نهاية Expanded
                const SizedBox(width: 12), // مسافة فاصلة بعرض 12
                Expanded( // البطاقة الثانية: بنات
                  child: _buildFilterCard( // بناء بطاقة الفلترة
                    controller: controller, // تمرير المتحكم
                    targetGender: Gender.female, // استهداف فئة الإناث
                    title: 'girls'.tr, // عنوان البطاقة (بنات)
                    value: controller.femaleCirclesCount.toString(), // عدد حلقات البنات
                    icon: Icons.female, // أيقونة أنثى
                    color: Colors.pink, // لون وردي للبنات
                  ), // نهاية بناء البطاقة
                ), // نهاية Expanded
                const SizedBox(width: 12), // مسافة فاصلة بعرض 12
                Expanded( // البطاقة الثالثة: الكل
                  child: _buildFilterCard( // بناء بطاقة الفلترة
                    controller: controller, // تمرير المتحكم
                    targetGender: Gender.all, // استهداف جميع الفئات
                    title: 'all'.tr, // عنوان البطاقة (الكل)
                    value: controller.totalCirclesCount.toString(), // إجمالي عدد الحلقات
                    icon: Icons.all_inclusive, // أيقونة شاملة
                    color: Colors.indigo, // لون أرجواني للكل
                  ), // نهاية بناء البطاقة
                ), // نهاية Expanded
              ], // نهاية قائمة البطاقات
            ), // نهاية الصف
          ), // نهاية Obx
        ], // نهاية عناصر العمود
      ), // نهاية العمود
    ); // نهاية Padding
  } // نهاية دالة بناء الهيدر

  // بناء بطاقة فلترة تفاعلية
  Widget _buildFilterCard({ // دالة بناء بطاقة فلترة مخصصة
    required QuranCirclesController controller, // المتحكم
    required Gender targetGender, // الجنس المستهدف
    required String title, // عنوان البطاقة
    required String value, // قيمة الإحصائية
    required IconData icon, // الأيقونة
    required Color color, // اللون
  }) { // بداية جسم الدالة
    final isSelected = controller.selectedGenderFilter.value == targetGender; // التحقق من اختيار هذه الفئة
    return InkWell( // عنصر قابل للضغط
      onTap: () => controller.selectedGenderFilter.value = targetGender, // تغيير الفلتر عند الضغط
      borderRadius: BorderRadius.circular(16), // تدوير حواف منطقة الضغط
      child: Container( // حاوية البطاقة المنسقة
        decoration: BoxDecoration( // تنسيق الحاوية
          borderRadius: BorderRadius.circular(16), // تدوير حواف الحاوية
          border: isSelected // وضع إطار في حالة الاختيار
              ? Border.all(color: color, width: 2) // إطار ملون بسمك 2
              : Border.all(color: Colors.transparent, width: 2), // إطار شفاف في حالة عدم الاختيار
        ), // نهاية التنسيق
        child: AdminStatCard( // استدعاء ويدجت بطاقة الإحصائيات
          title: title, // العنوان
          value: value, // القيمة
          icon: icon, // الأيقونة
          color: isSelected ? color : Colors.grey, // اللون يعتمد على حالة الاختيار
          isSmall: true, // حجم البطاقة صغير
        ), // نهاية بطاقة الإحصائيات
      ), // نهاية الحاوية
    ); // نهاية InkWell
  } // نهاية دالة بناء بطاقة الفلترة

  // بناء قائمة الحلقات المفلترة بناءً على الجنس والبحث
  Widget _buildFilteredList(QuranCirclesController controller) { // دالة بناء القائمة
    return Padding( // إضافة هوامش جانبية للقائمة
      padding: const EdgeInsets.symmetric(horizontal: 24.0), // هامش أفقي 24
      child: Obx(() { // مراقبة التغيرات لتحديث القائمة
        if (controller.isLoading.value) { // التحقق من حالة التحميل
          return const Center(child: CircularProgressIndicator()); // عرض مؤشر تحميل دائري
        } // نهاية حالة التحميل

        // تصفية الحلقات بناءً على خيارات المستخدم
        final filteredCircles = controller.quranCircles.where((c) { // فلترة القائمة الأصلية
          bool genderMatch = // شرط مطابقة الجنس
              controller.selectedGenderFilter.value == Gender.all || // إذا كان الفلتر يشمل الكل
              c.gender == controller.selectedGenderFilter.value; // أو إذا طابق جنس الحلقة الفلتر
          bool searchMatch = // شرط مطابقة البحث
              controller.searchQuery.value.isEmpty || // إذا كان حقل البحث فارغاً
              c.name.toLowerCase().contains( // أو إذا احتوى اسم الحلقة على نص البحث
                controller.searchQuery.value.toLowerCase(), // تحويل نص البحث لصغير للمقارنة
              ) || // أو
              c.teacherName.toLowerCase().contains( // إذا احتوى اسم المعلم على نص البحث
                controller.searchQuery.value.toLowerCase(), // تحويل نص البحث لصغير
              ); // نهاية شرط البحث
          return genderMatch && searchMatch; // إرجاع النتيجة إذا تحقق كلا الشرطين
        }).toList(); // تحويل النتائج إلى قائمة

        // حالة عدم وجود نتائج
        if (filteredCircles.isEmpty) { // إذا كانت القائمة المفلترة فارغة
          return Center( // وضع المحتوى في المنتصف
            child: Column( // ترتيب عمودي لرسالة "لا توجد نتائج"
              mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
              children: [ // قائمة العناصر
                Icon( // أيقونة تشير لعدم وجود بيانات
                  Icons.group_off_outlined, // أيقونة مجموعة ملغاة
                  size: 64, // حجم كبير للأيقونة
                  color: Colors.grey[400], // لون رمادي باهت
                ), // نهاية الأيقونة
                const SizedBox(height: 16), // مسافة فاصلة 16
                Text( // نص يوضح سبب عدم وجود نتائج
                  controller.searchQuery.value.isNotEmpty // التحقق إذا كان السبب هو البحث
                      ? 'no_matching_circles'.tr // رسالة "لا توجد نتائج مطابقة"
                      : 'no_circles_yet'.tr, // رسالة "لا توجد حلقات مضافة"
                  style: TextStyle(color: Colors.grey[600]), // تنسيق النص بلون رمادي
                ), // نهاية النص
              ], // نهاية العناصر
            ), // نهاية العمود
          ); // نهاية التوسيط
        } // نهاية حالة القائمة الفارغة

        return LayoutBuilder( // لبناء واجهة متجاوبة مع عرض الشاشة
          builder: (context, constraints) { // دالة البناء مع القيود المتاحة
            // ضبط التخطيط الشبكي بناءً على عرض الشاشة
            final width = constraints.maxWidth; // عرض المساحة المتاحة
            int crossAxisCount = 2; // العدد الافتراضي للأعمدة (2)
            double aspectRatio = 1.0; // النسبة الافتراضية للطول والعرض (1)

            if (width < 600) { // للشاشات الصغيرة جداً
              crossAxisCount = 2; // عمودان
              aspectRatio = 0.85; // جعل العناصر أكثر طولاً
            } else if (width < 900) { // للشاشات المتوسطة (تابلت)
              crossAxisCount = 3; // 3 أعمدة
              aspectRatio = 1.0; // عناصر مربعة
            } else if (width < 1200) { // للشاشات الكبيرة (لابتوب)
              crossAxisCount = 4; // 4 أعمدة
              aspectRatio = 1.1; // عناصر أعرض قليلاً
            } else { // للشاشات الواسعة جداً
              crossAxisCount = 5; // 5 أعمدة
              aspectRatio = 1.2; // عناصر عريضة
            } // نهاية شروط التجاوب

            return GridView.builder( // بناء الشبكة بطريقة فعالة
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( // تحديد خصائص الشبكة
                crossAxisCount: crossAxisCount, // عدد الأعمدة المحسوب
                childAspectRatio: aspectRatio, // النسبة المحسوبة
                crossAxisSpacing: 16, // المسافة الأفقية بين العناصر
                mainAxisSpacing: 16, // المسافة الرأسية بين العناصر
              ), // نهاية خصائص الشبكة
              itemCount: filteredCircles.length, // عدد العناصر الإجمالي
              itemBuilder: (context, index) { // دالة بناء كل عنصر
                final circle = filteredCircles[index]; // جلب بيانات الحلقة الحالية
                return _buildCircleCard(circle, controller); // بناء بطاقة الحلقة
              }, // نهاية itemBuilder
            ); // نهاية GridView
          }, // نهاية بناء LayoutBuilder
        ); // نهاية LayoutBuilder
      }), // نهاية Obx
    ); // نهاية Padding
  } // نهاية دالة بناء القائمة المفلترة

  // بناء بطاقة الحلقة الواحدة
  Widget _buildCircleCard( // دالة بناء بطاقة تعريفية للحلقة
    QuranCircleModel circle, // بيانات الحلقة
    QuranCirclesController controller, // المتحكم
  ) { // بداية جسم الدالة
    return Card( // حاوية بطاقة بتصميم ماتيريال
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // تدوير حواف البطاقة
      elevation: 2, // إضافة ظل خفيف
      child: InkWell( // جعل البطاقة قابلة للتفاعل والضغط
        onTap: () { // عند الضغط على البطاقة
          // عرض تفاصيل الحلقة عند الضغط
          Get.dialog(CircleDetailsDialog(circle: circle)); // فتح نافذة التفاصيل
        }, // نهاية onTap
        borderRadius: BorderRadius.circular(16), // تدوير حواف تأثير الضغط
        child: Padding( // هوامش داخلية لمحتوى البطاقة
          padding: const EdgeInsets.all(12.0), // هامش 12 من جميع الجهات
          child: Column( // ترتيب محتوى البطاقة عمودياً
            crossAxisAlignment: CrossAxisAlignment.start, // محاذاة المحتوى للبداية
            mainAxisSize: MainAxisSize.min, // تصغير حجم العمود حسب المحتوى
            children: [ // قائمة العناصر داخل البطاقة
              Row( // صف علوي للأيقونة وزر الحذف
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع العناصر على الأطراف
                children: [ // قائمة عناصر الصف
                  CircleAvatar( // أيقونة دائرية صغيرة
                    radius: 18, // نصف قطر الدائرة
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1), // لون خلفية خفيف
                    child:
                        const Icon(Icons.group, color: Colors.indigo, size: 20), // أيقونة مجموعة
                  ), // نهاية CircleAvatar
                  // زر حذف الحلقة
                  IconButton( // زر أيقونة للحذف
                    iconSize: 18, // حجم الأيقونة صغير
                    padding: EdgeInsets.zero, // إلغاء الهوامش الافتراضية
                    constraints: const BoxConstraints(), // إلغاء القيود الافتراضية للحجم
                    icon: const Icon(Icons.delete_outline, color: Colors.red), // أيقونة سلة مهملات حمراء
                    onPressed: () => _confirmDelete(circle.id, controller), // استدعاء تأكيد الحذف
                  ), // نهاية زر الحذف
                ], // نهاية عناصر الصف
              ), // نهاية الصف
              const SizedBox(height: 8), // مسافة فاصلة 8
              Text( // نص يعرض اسم الحلقة
                circle.name, // اسم الحلقة من البيانات
                style: const TextStyle( // تنسيق الاسم
                  fontWeight: FontWeight.bold, // خط عريض
                  fontSize: 14, // حجم خط 14
                ), // نهاية التنسيق
                maxLines: 1, // سطر واحد فقط
                overflow: TextOverflow.ellipsis, // وضع نقاط في حال كان النص طويلاً
              ), // نهاية نص الاسم
              const SizedBox(height: 4), // مسافة فاصلة 4
              Text( // نص يعرض اسم المعلم
                '${'teacher'.tr}: ${circle.teacherName}', // كلمة معلم مترجمة متبوعة بالاسم
                style: TextStyle(color: Colors.grey[600], fontSize: 12), // لون رمادي وحجم 12
                maxLines: 1, // سطر واحد
                overflow: TextOverflow.ellipsis, // نقاط عند الزيادة
              ), // نهاية نص المعلم
              const SizedBox(height: 2), // مسافة فاصلة صغيرة
              if (circle.batchNumber != null) // عرض رقم الدفعة إذا وجد
                Container( // حاوية ملونة صغيرة لرقم الدفعة
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // هوامش داخلية
                  decoration: BoxDecoration( // تنسيق الحاوية
                    color: Colors.indigo.withValues(alpha: 0.1), // خلفية فاتحة
                    borderRadius: BorderRadius.circular(4), // تدوير بسيط
                  ), // نهاية التنسيق
                  child: Text( // نص رقم الدفعة
                    '${'batch_number'.tr}: ${circle.batchNumber}', // كلمة دفعة متبوعة بالرقم
                    style: const TextStyle( // تنسيق النص
                      color: Colors.indigo, // لون أرجواني
                      fontSize: 10, // حجم صغير جداً
                      fontWeight: FontWeight.w600, // خط شبه عريض
                    ), // نهاية التنسيق
                  ), // نهاية النص
                ), // نهاية الحاوية
              const Spacer(), // تمدد لدفع المعلومات التالية لأسفل البطاقة
              // عرض عدد الطلاب في الحلقة
              Row( // صف يحتوي على أيقونة المستخدمين والعدد
                children: [ // قائمة العناصر
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[400]), // أيقونة شخص صغيرة
                  const SizedBox(width: 4), // مسافة صغيرة 4
                  Expanded( // النص يأخذ باقي مساحة الصف
                    child: Text( // نص عدد الطلاب
                      '${circle.studentIds.length} ${'students'.tr}', // عدد الطلاب متبوع بكلمة طلاب مترجمة
                      style: TextStyle(color: Colors.grey[400], fontSize: 11), // لون فاتح وحجم صغير
                      maxLines: 1, // سطر واحد
                      overflow: TextOverflow.ellipsis, // نقاط عند الزيادة
                    ), // نهاية نص العدد
                  ), // نهاية Expanded
                ], // نهاية عناصر الصف
              ), // نهاية الصف
            ], // نهاية عناصر العمود
          ), // نهاية العمود
        ), // نهاية Padding
      ), // نهاية InkWell
    ); // نهاية Card
  } // نهاية دالة بناء بطاقة الحلقة

  // نافذة تأكيد الحذف
  void _confirmDelete(String id, QuranCirclesController controller) { // دالة لإظهار حوار التأكيد
    Get.dialog( // عرض نافذة منبثقة (Dialog)
      AlertDialog( // تنبيه قياسي
        title: Text('delete_circle'.tr), // عنوان النافذة (حذف الحلقة)
        content: Text('confirm_delete_circle'.tr), // رسالة التأكيد (هل أنت متأكد؟)
        actions: [ // أزرار الإجراءات (تراجع أو تأكيد)
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)), // زر إلغاء يغلق النافذة
          TextButton( // زر تأكيد الحذف
            onPressed: () { // عند الضغط للتأكيد
              Get.back(); // إغلاق نافذة التأكيد أولاً
              controller.deleteCircle(id); // تنفيذ عملية الحذف من المتحكم
            }, // نهاية الضغط
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)), // نص "حذف" باللون الأحمر
          ), // نهاية زر التأكيد
        ], // نهاية الأزرار
      ), // نهاية AlertDialog
    ); // نهاية Get.dialog
  } // نهاية دالة تأكيد الحذف
} // نهاية الكلاس
