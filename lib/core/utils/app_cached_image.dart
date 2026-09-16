import 'dart:io'; // استيراد مكتبة التعامل مع الملفات (File)
import 'package:al_maqraa/core/services/media_cache_service.dart';
import 'package:flutter/material.dart'; // استيراد مكتبة واجهات فلاتر الأساسية
import 'package:get/get.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl; // رابط الصورة المطلوب عرضها
  final double? width; // عرض الصورة (اختياري)
  final double? height; // ارتفاع الصورة (اختياري)
  final BoxFit
  fit; // كيفية ملاءمة الصورة داخل الإطار (افتراضياً تغطية BoxFit.cover)
  final Alignment alignment; // محاذاة الصورة داخل الإطار
  final Widget? placeholder; // شكل يظهر أثناء تحميل الصورة (اختياري)
  final Widget? errorWidget; // شكل يظهر في حال فشل تحميل الصورة (اختياري)

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // إذا كان الرابط فارغاً، نعرض واجهة الخطأ فوراً
    if (imageUrl.isEmpty) return _buildError();

    // البحث عن خدمة تخزين الوسائط المسجلة في التطبيق
    final mediaService = Get.find<MediaCacheService>();
    // الحصول على المسار المتوقع للصورة في ذاكرة الهاتف
    final localPath = mediaService.getCachePath(imageUrl, subFolder: 'images');

    // الحالة الأولى: إذا كانت الصورة موجودة محلياً (Cached)
    final localFile = File(localPath);
    if (localFile.existsSync()) {
      if (localFile.lengthSync() > 0) {
        // عرض الصورة من ذاكرة الهاتف فوراً لسرعة الأداء وتوفير الإنترنت
        return _buildImage(FileImage(localFile), localPath);
      } else {
        // إذا كان الملف فارغاً (0 بايت) نحذفه
        try {
          localFile.deleteSync();
        } catch (_) {}
      }
    }

    // الحالة الثانية: الصورة غير موجودة محلياً
    // نقوم ببدء عملية تحميلها في الخلفية ليتم تخزينها للمرات القادمة
    mediaService.downloadMedia(imageUrl, subFolder: 'images');

    // عرض الصورة من الرابط (Network) مع إعدادات التحميل والخطأ
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      // بناء الإطار مع تأثير التلاشي عند اكتمال الظهور
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1, // تظهر تدريجياً من شفافية 0 إلى 1
          duration: const Duration(milliseconds: 500), // مدة التأثير نصف ثانية
          curve: Curves.easeOut,
          child: child,
        );
      },
      // بناء مؤشر التحميل أثناء جلب البيانات من الإنترنت
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child; // إذا اكتمل التحميل نعرض الصورة
        }
        return placeholder ??
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  // مؤشر تحميل دائري
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null, // حساب نسبة التحميل إذا كان الحجم معروفاً
                ),
              ),
            );
      },
      // التعامل مع أخطاء التحميل (مثل انقطاع الإنترنت أو رابط تالف)
      errorBuilder: (context, error, stackTrace) {
        return _buildError();
      },
    );
  }

  /// دالة بناء الصورة باستخدام موفر الصور المحدد (ملف أو شبكة) مع معالجة حماية الملفات التالفة
  Widget _buildImage(ImageProvider provider, String localPath) {
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      // إضافة تأثير التلاشي للصور المحملة محلياً أيضاً لتكون الحركة متناسقة
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // في حال كان الملف المحفوظ محلياً تالفاً (مثل خطأ 404 محفوض كـ HTML)، نحذفه لعدم تكرار الخطأ
        try {
          File(localPath).deleteSync();
        } catch (_) {}
        return _buildError();
      },
    );
  }

  /// دالة بناء واجهة الخطأ الافتراضية
  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200], // خلفية رمادية فاتحة
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 20,
          ), // أيقونة "صورة غير مدعومة"
        );
  }

  /// دالة لإظهار تنبيه منبثق عند فشل تحميل الصورة (يدعم اللغتين)
  void _showErrorNotification() {
    // نستخدم Future.delayed لمنع تداخل التنبيهات مع عملية بناء الواجهة (Build Phase)
    Future.delayed(Duration.zero, () {
      if (!Get.isSnackbarOpen) {
        // التأكد من عدم وجود تنبيه مفتوح حالياً لتجنب الإزعاج
        Get.snackbar(
          'error'.tr, // عنوان "خطأ" مترجم
          'error_loading_image'.tr, // رسالة "حدث خطأ أثناء تحميل الصورة" مترجمة
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    });
  }
}
