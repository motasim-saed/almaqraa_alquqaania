import 'package:flutter/material.dart'; // استيراد مكتبة متريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة

class StudentLeaveRequestScreen extends StatelessWidget { // تعريف كلاس شاشة طلب الاستئذان للطالب
  const StudentLeaveRequestScreen({super.key}); // منشئ الكلاس مع مفتاح فريد

  @override
  Widget build(BuildContext context) { // بناء واجهة المستخدم الخاصة بالشاشة
    return Scaffold( // العنصر الأساسي لهيكل الصفحة
      appBar: AppBar(title: Text('request_leave'.tr)), // شريط التطبيق العلوي مع عنوان مترجم
      body: Padding( // إضافة هوامش داخلية لمحتوى الصفحة
        padding: const EdgeInsets.all(16.0), // مقدار الهامش 16 بكسل من جميع الجهات
        child: Column( // ترتيب العناصر بشكل رأسي
          children: [
            TextField( // حقل إدخال نصي لسبب الاستئذان
              decoration: InputDecoration( // تنسيق شكل حقل الإدخال
                labelText: 'leave_reason'.tr, // نص توضيحي داخل الحقل مترجم
                border: const OutlineInputBorder(), // حدود خارجية للحقل
              ),
              maxLines: 3, // السماح بكتابة حتى 3 أسطر
            ),
            const SizedBox(height: 20), // مسافة فارغة بارتفاع 20 بكسل
            ElevatedButton( // زر لإرسال الطلب
              onPressed: () { // الإجراء عند الضغط على الزر
                Get.back(); // العودة إلى الشاشة السابقة
                Get.snackbar('success'.tr, 'request_sent'.tr); // إظهار رسالة نجاح منبثقة مترجمة
              },
              child: Text('submit_request'.tr), // نص الزر مترجم
            ),
          ],
        ),
      ),
    );
  }
}
