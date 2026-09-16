import 'package:flutter/material.dart'; // استيراد حزمة Flutter Material لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX للوصول للسياق (context) والترجمة

// تعريف ودجت (Widget) مخصص لحقل إدخال النص بشكل موحد في التطبيق
// ignore: non_constant_identifier_names
Widget DefaultFormFailed({
  required TextEditingController controller, // المتحكم في نص الحقل (لقراءة وكتابة القيمة)
  required TextInputType type, // نوع لوحة المفاتيح (إيميل، نص، أرقام، إلخ)
  void Function(String)? onSubmit, // دالة يتم تنفيذها عند الضغط على زر "Enter" في الكيبورد
  void Function(String)? onChang, // دالة يتم تنفيذها عند كل تغيير في نص الحقل
  void Function()? ontap, // دالة يتم تنفيذها عند الضغط داخل الحقل
  bool isClickable = true, // تحديد هل الحقل قابل للتفاعل أم لا

  required String? Function(String?) validate, // دالة التحقق من صحة البيانات (Validation)
  required String lable, // النص التوضيحي الذي يظهر فوق أو داخل الحقل
  required IconData prefix, // الأيقونة التي تظهر في بداية الحقل (على اليسار عادةً)
  IconData? sufix, // الأيقونة التي تظهر في نهاية الحقل (اختيارية)
  void Function()? suffixpressed, // دالة يتم تنفيذها عند الضغط على الأيقونة النهائية
  bool isPassword = false, // تحديد هل الحقل مخصص لكلمة سر (يخفي النص بنجوم)
  bool isReadOnly = false, // تحديد هل الحقل للقراءة فقط
  FocusNode? focusNode, // للتحكم في التركيز على الحقل
  TextInputAction? textInputAction, // تحديد وظيفة زر الإدخال (مثال: زر التالي أو تم)
  int? min, // أقل عدد من الأسطر (في حال كان الحقل لفقرات نصية)
  int? max, // أقصى عدد من الحروف المسموح بها
}) {
  final context = Get.context!;
  return TextFormField(
    focusNode: focusNode,
    textInputAction: textInputAction,
    minLines: min, // تحديد الحد الأدنى للأسطر
    maxLength: max, // تحديد الحد الأقصى للطول
    controller: controller, // ربط حقل النص بالمتحكم
    keyboardType: type, // تحديد نوع الكيبورد
    obscureText: isPassword, // تفعيل خاصية إخفاء النص إذا كان كلمة سر
    onFieldSubmitted: onSubmit, // ربط حدث الضغط على Enter
    onChanged: onChang, // ربط حدث تغيير النص
    enabled: isClickable, // تفعيل أو تعطيل الحقل
    validator: validate, // ربط دالة التحقق
    onTap: ontap, // ربط حدث الضغط داخل الحقل
    readOnly: isReadOnly, // تفعيل وضع القراءة فقط
    style: TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontFamily: 'Cairo',
    ),
    decoration: InputDecoration(
      labelText: lable, // وضع النص التوضيحي
      labelStyle: TextStyle(
        color: Theme.of(context).hintColor,
        fontFamily: 'Cairo',
      ),
      prefixIcon: Icon(prefix, color: Theme.of(context).colorScheme.primary), // وضع الأيقونة البدائية
      suffixIcon: sufix != null
          ? IconButton(
              onPressed: suffixpressed,
              icon: Icon(sufix, color: Theme.of(context).colorScheme.primary),
            ) // وضع أيقونة قابلة للضغط في النهاية إذا وجدت
          : null,

      // تصميم حدود الحقل الافتراضية
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), // زوايا منحنية بمقدار 14
        borderSide: BorderSide(color: Theme.of(context).dividerColor), // لون الحدود
      ),
      // تصميم حدود الحقل في حالته العادية (غير المختار)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      // تصميم حدود الحقل عند اختياره (Focus)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // لون الثيم وسماكة 2
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    ),
  );
}
