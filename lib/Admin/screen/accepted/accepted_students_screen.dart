import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية للواجهات
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import '../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
import '../../controller/quran_circles_controller.dart'; // استيراد متحكم حلقات القرآن
import 'widgets/students/student_filter_bar.dart'; // استيراد شريط الفلترة الخاص بالطلاب
import 'widgets/students/student_card.dart'; // استيراد كرت عرض بيانات الطالب

// شاشة الطلاب المقبولين - AcceptedStudentsScreen
// تعرض قائمة الطلاب بناءً على الجنس مع إحصائيات سريعة وفلترة متقدمة
class AcceptedStudentsScreen extends StatelessWidget {
  final Gender gender; // تحديد نوع الجنس المعروض (ذكر/أنثى)

  // مشيد الويدجت مع معامل الجنس وقيمة افتراضية (ذكور)
  const AcceptedStudentsScreen({super.key, this.gender = Gender.male});

  @override
  Widget build(BuildContext context) {
    // تهيئة أو جلب المتحكم الخاص بالطلاب المقبولين
    final controller = Get.isRegistered<AcceptedStudentsController>() 
        ? Get.find<AcceptedStudentsController>() 
        : Get.put(AcceptedStudentsController());
    
    // التأكد من تهيئة متحكم حلقات القرآن لاستخدامه في توزيع الطلاب
    if (!Get.isRegistered<QuranCirclesController>()) {
      Get.lazyPut(() => QuranCirclesController());
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // جعل الخلفية شفافة لتنسجم مع التخطيط الرئيسي
      // تم إلغاء الـ AppBar التقليدي ودمج العنوان مع الإحصائية في الـ body
      body: Column(
        children: [

          // شريط الفلترة (لالتصفية حسب الكفالة أو التوزيع)
          StudentFilterBar(controller: controller, gender: gender),
          
          // عرض القائمة داخل مساحة مرنة
          Expanded(
            child: Obx(() {
              // إظهار مؤشر تحميل إذا كانت البيانات قيد الجلب من السيرفر
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // جلب القائمة المفلترة بناءً على الجنس وخيارات التصفية
              final list = controller.filteredStudentsList(gender);

              // إظهار واجهة "لا توجد بيانات" إذا كانت القائمة فارغة
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey), // أيقونة قبعة تخرج رمادية
                      const SizedBox(height: 16),
                      Text(
                        'no_data'.tr, // نص "لا توجد بيانات" مترجم
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              // بناء شبكة عرض الطلاب بشكل متجاوب (Responsive Grid)
              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1; // الافتراضي عمود واحد (للموبايل)
                  if (constraints.maxWidth > 1400) {
                    crossAxisCount = 4; // 4 أعمدة للشاشات الكبيرة جداً
                  } else if (constraints.maxWidth > 1000) {
                    crossAxisCount = 3; // 3 أعمدة للأجهزة اللوحية العريضة
                  } else if (constraints.maxWidth > 650) {
                    crossAxisCount = 2; // عمودان للأجهزة المتوسطة
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 200, // ارتفاع الكرت الثابت ليتطابق مع بطاقات المعلمين
                    ),
                    itemCount: list.length, // عدد الطلاب في القائمة
                    itemBuilder: (context, index) {
                      // بناء كرت لكل طالب في القائمة
                      return StudentCard(item: list[index], controller: controller);
                    },
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
