// import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهات المستخدم
// import 'package:get/get.dart'; // استيراد حزمة GetX للترجمة والتحكم بالمسارات

// /// شاشة طلب الاستئذان للمعلم: تمكن المعلم من كتابة سبب غيابه وإرساله للإدارة
// class TeacherLeaveRequestScreen extends StatelessWidget {
//   // منشئ الكلاس الثابت مع مفتاح فريد للودجت
//   const TeacherLeaveRequestScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // بناء هيكل الصفحة الأساسي (Scaffold)
//     return Scaffold(
//       // شريط التطبيق العلوي (AppBar)
//       appBar: AppBar(
//         // عرض عنوان الصفحة مترجماً (طلب استئذان)
//         title: Text('teacher_request_leave'.tr, 
//           style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
//         centerTitle: true, // توسيط العنوان في شريط التطبيق
//       ),
//       // جسم الصفحة مع إضافة هوامش داخلية
//       body: Padding(
//         padding: const EdgeInsets.all(16.0), // إضافة مسافة 16 بكسل من جميع الجهات
//         child: Column(
//           children: [
//             // حقل نصي (TextField) لإدخال سبب الاستئذان أو الإجازة
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'teacher_leave_reason'.tr, // النص التوضيحي داخل الحقل (مترجم)
//                 hintText: 'enter_notes_here'.tr, // نص تلميحي يختفي عند الكتابة
//                 border: const OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(12)), // جعل حواف الحقل دائرية
//                 ),
//                 prefixIcon: const Icon(Icons.note_alt_outlined), // إضافة أيقونة في بداية الحقل
//               ),
//               maxLines: 5, // السماح بكتابة حتى 5 أسطر للتفاصيل
//               style: const TextStyle(fontFamily: 'Cairo'), // استخدام خط القاهرة للنص المدخل
//             ),
//             const SizedBox(height: 24), // مسافة عمودية فاصلة قبل الزر
//             // زر إرسال الطلب (ElevatedButton)
//             SizedBox(
//               width: double.infinity, // جعل الزر يأخذ كامل عرض الشاشة المتاح
//               height: 50, // تحديد ارتفاع الزر
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.indigo, // لون خلفية الزر (نيلي)
//                   foregroundColor: Colors.white, // لون النص والأيقونة (أبيض)
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12), // جعل حواف الزر دائرية
//                   ),
//                 ),
//                 // الوظيفة التي تنفذ عند الضغط على الزر
//                 onPressed: () {
//                   // العودة للشاشة السابقة (الخروج من صفحة الطلب)
//                   Get.back();
//                   // إظهار رسالة نجاح منبثقة (Snackbar) لإعلام المعلم بإتمام العملية
//                   Get.snackbar(
//                     'success'.tr, // عنوان الرسالة (نجاح)
//                     'teacher_request_sent'.tr, // محتوى الرسالة (تم إرسال الطلب بنجاح)
//                     backgroundColor: Colors.green, // لون خلفية الرسالة أخضر للنجاح
//                     colorText: Colors.white, // لون النص أبيض
//                     snackPosition: SnackPosition.BOTTOM, // إظهار الرسالة في أسفل الشاشة
//                     margin: const EdgeInsets.all(16), // هوامش حول الرسالة المنبثقة
//                   );
//                 },
//                 icon: const Icon(Icons.send_rounded), // أيقونة الإرسال بجانب النص
//                 label: Text(
//                   'submit_teacher_request'.tr, // نص الزر المترجم (إرسال الطلب)
//                   style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
