import 'package:flutter/material.dart'; // استيراد حزمة واجهات فلاتر الأساسية لتمثيل الـ Widgets
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة السهلة
import 'package:quran/quran.dart' as quran; // استيراد مكتبة القرآن الكريم لجلب بيانات السور والصفحات

/// ويدجت موحد لعرض إحصائيات الخطط (PlanStatsWidget)
/// يستخدم في شاشة السجل اليومي وشاشة الخطط لضمان تناسق البيانات والترجمة
class PlanStatsWidget extends StatelessWidget { // تعريف الكلاس كويدجت غير متغير (Stateless)
  final String description; // متغير لتخزين وصف الخطة أو البيانات المهيكلة
  final Color? color; // لون اختياري للتحكم في مظهر النصوص
  final bool isCompact; // متغير لتحديد ما إذا كان العرض مصغراً أو كاملاً
  final bool isAnnual;

  const PlanStatsWidget({ // مشيد الكلاس لاستلام القيم الأولية
    super.key, // مفتاح السوبر للويدجت
    required this.description, // وصف الخطة مطلوب دائماً
    this.color, // اللون اختياري
    this.isCompact = false, // القيمة الافتراضية للعرض المصغر هي خطأ
    this.isAnnual = false,
  }); // نهاية المشيد

  @override // إعادة تعريف دالة البناء الأساسية
  Widget build(BuildContext context) { // دالة بناء واجهة المستخدم
    // التحقق من أن النص يبدأ بتنسيق البيانات المنظم الحديث STRUCT_V1
    if (description.startsWith('STRUCT_V1|')) { 
      final parts = description.split('|'); // تقسيم النص إلى أجزاء بناءً على علامة الـ |
      if (parts.length >= 6) { // التأكد من وجود كافة الحقول المطلوبة
        final startSurahId = int.tryParse(parts[1]) ?? 1; // تحويل معرف سورة البداية لرقم صحيح
        final endSurahId = int.tryParse(parts[2]) ?? 114; // تحويل معرف سورة النهاية لرقم صحيح
        final totalPages = parts[3]; // جلب عدد الصفحات الكلي
        final rate = parts[4]; // جلب معدل الإنجاز (يومي/شهري)
        final note = parts[5]; // جلب الملاحظات الإضافية

        // جلب أرقام الصفحات الفعلية من مكتبة القرآن الكريم
        final startPage = quran.getPageNumber(startSurahId, 1); 
        final endPage = quran.getPageNumber(endSurahId, quran.getVerseCount(endSurahId)); 

        // بناء نص نطاق السور المترجم مع دمج أرقام الصفحات بجانب الأسماء
        final surahRange = '${'surah_$startSurahId'.tr} ($startPage) ➔ ${'surah_$endSurahId'.tr} ($endPage)'; 

        return Column( // عرض البيانات في عمود رأسي
          crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر من جهة البداية
          children: [ // قائمة العناصر
            Text( // عرض نص السور والصفحات
              surahRange, 
              style: TextStyle( 
                color: isCompact 
                    ? Theme.of(context).textTheme.bodyLarge?.color 
                    : Colors.white, 
                fontSize: isCompact ? 15 : 18, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Cairo', 
              ), 
            ), 
            if (!isCompact) const Divider(color: Colors.white24, height: 24), // فاصل في العرض الكامل
            if (isCompact) const SizedBox(height: 8), // مساحة في العرض المصغر
            
            // عرض إجمالي الصفحات المستهدفة بشكل منظم
            _buildStatRow( 
              Icons.description_outlined, 
              '${'target_pages'.tr}: $totalPages', 
              isCompact ? Theme.of(context).hintColor : Colors.white70, 
            ), 
            const SizedBox(height: 8), 
            
            // عرض المعدل اليومي/الشهري المستهدف بشكل منظم
            _buildStatRow( 
              Icons.trending_up, 
              isAnnual ? 'pages_per_month'.tr.replaceAll('@pages', rate) : 'pages_per_day'.tr.replaceAll('@pages', rate), 
              isCompact ? Theme.of(context).hintColor : Colors.white70, 
            ), 
            
            if (note.isNotEmpty) ...[ // عرض الملاحظة إذا وجدت
              if (!isCompact) const Divider(color: Colors.white12, height: 20), 
              if (isCompact) const SizedBox(height: 4), 
              Text( 
                note, 
                style: TextStyle( 
                  color: isCompact 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.white70, 
                  fontSize: 12, 
                  fontStyle: FontStyle.italic, 
                  fontFamily: 'Cairo', 
                ), 
              ), 
            ], 
          ], 
        ); 
      } 
    } 

    // معالجة البيانات القديمة (Legacy Data) بذكاء وحذر لتجنب أخطاء تحويل الأرقام العادية
    return _buildLegacyContent(context); 
  }

  /// دالة لمعالجة وترجمة البيانات القديمة (Legacy Data) بشكل دقيق ومنظم
  Widget _buildLegacyContent(BuildContext context) {
    // تقسيم النص إلى أسطر لمعالجتها بشكل مستقل ومنع تداخل الأرقام
    List<String> lines = description.split('\n'); // تقسيم النص لعدة أسطر
    List<Widget> contentWidgets = []; // قائمة لتخزين الودجت الناتجة لكل سطر

    for (var line in lines) { // الدوران على كل سطر في الوصف
      String processedLine = line.trim(); // إزالة المسافات الزائدة
      if (processedLine.isEmpty) continue; // تخطي الأسطر الفارغة

      // 1. معالجة سطر النطاق (Target) الذي يحتوي على أرقام السور
      if (processedLine.toLowerCase().contains('target') || processedLine.contains('->')) { 
        // استبدال كلمة target بكلمة "عدد الصفحات المستهدفة" المترجمة
        processedLine = processedLine.replaceAll(RegExp(r'target:', caseSensitive: false), '${'target_pages'.tr}:'); 
        
        // البحث عن أرقام السور المكتوبة بصيغة surah_X أو أرقام مجردة
        processedLine = processedLine.replaceAllMapped(RegExp(r'(surah_)?\d{1,3}'), (match) {
          int id = int.tryParse(match.group(2)!) ?? 0; // استخراج الرقم المحتمل للسورة
          if (id >= 1 && id <= 114) { // التحقق من أن الرقم يقع ضمن نطاق سور القرآن (1-114)
            int page = quran.getPageNumber(id, 1); // جلب رقم صفحة البداية للسورة
            return '${'surah_$id'.tr} ($page)'; // إرجاع اسم السورة المترجم مع رقم الصفحة
          } 
          return match.group(0)!; // إرجاع النص الأصلي إذا لم يكن رقم سورة
        }); 
        processedLine = processedLine.replaceAll('->', '➔'); // تحويل السهم لشكل جمالي
      } 
      // 2. معالجة سطر إجمالي الصفحات (تغيير المسمى فقط دون تحويل الرقم)
      else if (processedLine.toLowerCase().contains('total_pages')) { 
        processedLine = processedLine.replaceAll(RegExp(r'total_pages:', caseSensitive: false), '${'total_pages'.tr}:'); 
      } 
      // 3. معالجة الأسطر التي تحتوي على نصوص عربية ومعدلات (نترك الأرقام العشرية كما هي)
      else { 
         // ترجمة الكلمات التقنية إذا وجدت في أسطر أخرى بشكل عشوائي
         processedLine = processedLine.replaceAll('target:', '${'target_pages'.tr}:') 
                                      .replaceAll('total_pages:', '${'total_pages'.tr}:'); 
      } 

      contentWidgets.add( // إضافة النص المعالج كودجت نصي منظم
        Padding( 
          padding: const EdgeInsets.only(bottom: 6.0), // إضافة مسافة بسيطة بين الأسطر
          child: Text( 
            processedLine, // السطر بعد المعالجة والترجمة
            style: TextStyle( 
              color: isCompact 
                  ? Theme.of(context).textTheme.bodyLarge?.color 
                  : Colors.white, // تلوين النص حسب وضع العرض
              fontSize: isCompact ? 14 : 16, // حجم الخط
              fontFamily: 'Cairo', // نوع الخط العربي
              height: 1.4, // المسافة بين الأسطر
            ), 
          ), 
        ), 
      ); 
    } 

    return Column( // عرض كافة الأسطر المعالجة في عمود منظم
      crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النص لليمين (أو اليسار حسب اللغة)
      children: contentWidgets, // قائمة الأسطر
    ); 
  }

  /// دالة مساعدة لبناء صف إحصائي يحتوي على أيقونة ونص
  Widget _buildStatRow(IconData icon, String text, Color textColor) { 
    return Row( // ترتيب الأيقونة والنص أفقياً
      children: [ 
        Icon(icon, color: textColor.withValues(alpha: 0.8), size: 18), // عرض الأيقونة
        const SizedBox(width: 10), // مسافة فاصلة
        Expanded( // استهلاك المساحة المتبقية
          child: Text( 
            text, // النص المترجم (الإحصائية)
            style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'Cairo'), // تنسيق النص
          ), 
        ), 
      ], 
    ); 
  } 
}
