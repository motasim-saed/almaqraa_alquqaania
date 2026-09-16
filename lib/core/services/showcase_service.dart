import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

/// خدمة إدارة الإرشاد والتوجيه التفاعلي (Showcase)
/// تتحقق من حالة رؤية الدليل الإرشادي لكل دور وتسمح بإعادة الضبط.
class ShowcaseService extends GetxService {
  late final GetStorage _box;
  static const String _keyPrefix = 'has_seen_showcase_';

  Future<ShowcaseService> init() async {
    _box = GetStorage();
    return this;
  }

  /// التحقق مما إذا كان المستخدم قد شاهد الدليل لدور معين (مثل student, teacher, examiner, coordinator, admin)
  bool hasSeenShowcase(String role) {
    return _box.read<bool>('$_keyPrefix$role') ?? false;
  }

  /// تعيين أن المستخدم قد شاهد الدليل الإرشادي لدور معين
  Future<void> markShowcaseAsSeen(String role) async {
    await _box.write('$_keyPrefix$role', true);
  }

  /// إعادة ضبط الدليل الإرشادي لدور معين لإعادة إظهاره
  Future<void> resetShowcase(String role) async {
    await _box.write('$_keyPrefix$role', false);
  }

  /// إعادة ضبط الدليل الإرشادي لجميع الأدوار
  Future<void> resetAllShowcases() async {
    final keys = ['student', 'teacher', 'examiner', 'coordinator', 'admin'];
    for (final role in keys) {
      await _box.write('$_keyPrefix$role', false);
    }
  }
}
