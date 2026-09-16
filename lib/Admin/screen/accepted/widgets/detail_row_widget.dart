import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية لتصميم الواجهات

// ويدجت مخصصة لعرض صف من التفاصيل (أيقونة، عنوان، وقيمة) - DetailRowWidget
class DetailRowWidget extends StatelessWidget {
  final IconData icon; // تعريف متغير للأيقونة المراد عرضها
  final String label; // تعريف متغير لنص العنوان (الوصف)
  final String value; // تعريف متغير لنص القيمة المراد عرضها

  // مشيد الويدجت (Constructor) لتهيئة القيم المطلوبة عند الاستخدام
  const DetailRowWidget({
    super.key, // تمرير المفتاح الخاص بالويدجت
    required this.icon, // معامل الأيقونة مطلوب
    required this.label, // معامل العنوان مطلوب
    required this.value, // معامل القيمة مطلوب
  });

  @override
  Widget build(BuildContext context) {
    // التحقق من حالة الثيم
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;
    
    // بناء واجهة الصف مع إضافة مسافات عمودية
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ), // زيادة الحاشية العمودية قليلاً
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.indigoAccent : primaryColor, // استخدام لون متكيف مع الثيم
          ), 
          const SizedBox(
            width: 10,
          ), 
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.black87, // لون نص متكيف للعنوان
            ),
          ), 
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black, // لون نص متكيف للقيمة
                fontWeight: FontWeight.w500,
              ),
            ),
          ), 
        ],
      ),
    );
  }
}
