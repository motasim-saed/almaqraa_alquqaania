import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية
import 'package:get/get.dart'; // استيراد GetX لإدارة الحالة والترجمة
import '../../models/admin_models.dart'; // استيراد نماذج البيانات
import '../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import 'widgets/teachers/teacher_card.dart'; // استيراد كرت عرض المعلم
import 'widgets/teachers/teacher_filter_bar.dart'; // استيراد شريط الفلترة

// شاشة المعلمين المقبولين - تعرض قائمة المعلمين حسب الجنس مع إحصائيات سريعة
class AcceptedTeachersScreen extends StatelessWidget {
  final Gender gender; // تحديد نوع الجنس المعروض في الشاشة (ذكر/أنثى)

  // معامل اختياري للجنس مع قيمة افتراضية لتجنب الأخطاء
  const AcceptedTeachersScreen({super.key, this.gender = Gender.male});

  @override
  Widget build(BuildContext context) {
    // التأكد من تهيئة المتحكم أو استدعاؤه إذا كان موجوداً مسبقاً
    final controller = Get.isRegistered<AcceptedTeachersController>() 
        ? Get.find<AcceptedTeachersController>() 
        : Get.put(AcceptedTeachersController());

    return Scaffold(
      backgroundColor: Colors.transparent, // جعل الخلفية شفافة لتتناسب مع التخطيط الرئيسي
      body: Column(
        children: [
          // عرض الإحصائيات السريعة (العدد والنوع) في المنتصف
          //  _buildQuickStats(controller),
          
          // عرض شريط الفلترة (التصفية حسب الكفالة والتوزيع)
          TeacherFilterBar(controller: controller, gender: gender),
          
          // عرض القائمة داخل مساحة مرنة
          Expanded(
            child: Obx(() {
              // إظهار مؤشر تحميل إذا كانت البيانات قيد الجلب
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // تصفية القائمة بناءً على خيارات الفلترة المحددة
              final list = controller.filteredTeachersList(gender);

              // إظهار رسالة "لا توجد بيانات" إذا كانت القائمة فارغة
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'no_data'.tr,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              // بناء شبكة (Grid) لعرض كروت المعلمين بشكل متجاوب
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
                      mainAxisExtent: 200, // ارتفاع الكرت الثابت
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      // بناء كرت لكل معلم في القائمة
                      return TeacherCard(item: list[index], controller: controller);
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
