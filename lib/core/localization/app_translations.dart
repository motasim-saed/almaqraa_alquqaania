import 'package:get/get.dart';
import 'translations/auth_translations.dart';
import 'translations/common_translations.dart';
import 'translations/admin_translations.dart';
import 'translations/teacher_translations.dart';
import 'translations/student_translations.dart';
import 'translations/coordinator_translations.dart';
import 'translations/examiner_translations.dart';
import 'translations/showcase_translations.dart';

// هذا الملف هو المسؤول عن تجميع كافة الترجمات في التطبيق
// تم تقسيم الترجمات إلى ملفات منفصلة لتسهيل الإدارة والصيانة
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar': {
          ...authTranslationsAr,
          ...commonTranslationsAr,
          ...adminTranslationsAr,
          ...teacherTranslationsAr,
          ...studentTranslationsAr,
          ...coordinatorTranslationsAr,
          ...examinerTranslationsAr,
          ...showcaseTranslationsAr,
        },
        'en': {
          ...authTranslationsEn,
          ...commonTranslationsEn,
          ...adminTranslationsEn,
          ...teacherTranslationsEn,
          ...studentTranslationsEn,
          ...coordinatorTranslationsEn,
          ...examinerTranslationsEn,
          ...showcaseTranslationsEn,
        },
      };
}
