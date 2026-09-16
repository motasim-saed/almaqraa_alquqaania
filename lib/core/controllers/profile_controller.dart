import 'dart:async'; // استيراد مكتبة التعامل مع العمليات المتزامنة والمستقبلية
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والتنقل
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد حزمة Supabase للتعامل مع قاعدة البيانات السحابية
import '../../Auth/routing/auth_route.dart'; // استيراد مسارات المصادقة للتوجيه بعد تسجيل الخروج
import '../services/local_db_service.dart'; // استيراد خدمة قاعدة البيانات المحلية للحفظ المؤقت (Caching)

class ProfileController extends GetxController {
  // إنشاء نسخة من عميل Supabase للقيام بالاستعلامات
  final SupabaseClient _supabase = Supabase.instance.client;
  // إنشاء نسخة من خدمة قاعدة البيانات المحلية (SQLite أو مشابه)
  final LocalDbService _localDb = LocalDbService();

  // تعريف المتغيرات المراقبة (Observable) التي تحدث الواجهة تلقائياً عند تغيير قيمتها:
  var name = ''.obs; // اسم المستخدم
  var email = ''.obs; // بريد المستخدم
  var role = ''.obs; // دور المستخدم (student, teacher, admin)
  var academicNumber = ''.obs; // الرقم الأكاديمي
  var phoneNumber = ''.obs; // رقم الهاتف
  var hifzLevel = ''.obs; // مستوى الحفظ (خاص بالطلاب)
  var teacherName = ''.obs; // اسم المعلم المرتبط بالطالب
  var circleName = ''.obs; // اسم الحلقة الدراسية
  var avatarUrl = ''.obs; // رابط الصورة الشخصية للمستخدم
  var additionalInfo = {}.obs; // مخزن للبيانات الإضافية المتنوعة
  var isSupervisor = false.obs; // هل الطالب مشرف على الحلقة

  var isLoading =
      false.obs; // متغير لمتابعة حالة التحميل (True أثناء جلب البيانات)

  // متغير للاحتفاظ باشتراك البث المباشر (Real-time stream) لإلغائه عند الضرورة
  StreamSubscription? _profileSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchProfile(); // جلب بيانات الملف الشخصي فور تشغيل المتحكم
    _initRealtimeSubscription(); // تفعيل خاصية التحديث اللحظي للبيانات
  }

  /// إعداد الاتصال اللحظي بمقعد البيانات لمراقبة أي تحديث في ملف المستخدم
  void _initRealtimeSubscription() {
    final user =
        _supabase.auth.currentUser; // الحصول على المستخدم الحالي المسجل
    if (user != null) {
      _profileSubscription?.cancel(); // إلغاء أي اشتراك قديم لتجنب التكرار

      // بدء الاستماع للتغييرات في جدول 'profiles' للسجل الخاص بهذا المستخدم فقط
      _profileSubscription = _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
            if (data.isNotEmpty) {
              final profile = data.first;
              // تحديث القيم في الواجهة فور تغيرها في قاعدة البيانات
              name.value = profile['full_name'] ?? 'مستخدم';
              phoneNumber.value = profile['phone'] ?? '';
              academicNumber.value =
                  profile['academic_number']?.toString() ?? 'N/A';

              // تحديث الصورة الشخصية مع إضافة بصمة زمنية لضمان عدم تحميل الصورة القديمة من الكاش
              String? newAvatar = profile['avatar_url'];
              if (newAvatar != null && newAvatar.isNotEmpty) {
                avatarUrl.value =
                    "$newAvatar?v=${DateTime.now().millisecondsSinceEpoch}";
              }

              _saveToCache(); // تحديث النسخة المحفوظة محلياً بعد التغيير اللحظي
            }
          });
    }
  }

  /// دالة لجلب كافة تفاصيل الملف الشخصي من جداول متعددة بناءً على نوع المستخدم
  Future<void> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. تحميل الكاش أولاً للعرض الفوري
    await _loadFromCache();

    // 2. تفعيل مؤشر التحميل فقط إذا لم تكن هناك بيانات معروضة (أول دخول)
    if (name.value.isEmpty) {
      isLoading.value = true;
    }

    try {
      email.value = user.email ?? ''; // تعيين البريد من بيانات الجلسة

      // 1. جلب البيانات الأساسية من جدول الملفات الشخصية العام
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse != null) {
        name.value = profileResponse['full_name'] ?? 'مستخدم';
        role.value = profileResponse['role'] ?? 'student';
        academicNumber.value = profileResponse['academic_number'] ?? 'N/A';
        phoneNumber.value = profileResponse['phone'] ?? '';
        avatarUrl.value = profileResponse['avatar_url'] ?? '';

        // تحسين: تفضيل البريد الإلكتروني المخزن في جدول البروفايلات لأنه قد يكون أكثر دقة من بريد الجلسة في بعض الأدوار
        if (profileResponse['email'] != null &&
            profileResponse['email'].toString().isNotEmpty &&
            !profileResponse['email'].toString().startsWith('examiner_')) {
          email.value = profileResponse['email'];
        }
      } else {
        // إذا لم توجد بيانات في البروفايلات، نتحقق مما إذا كان المستخدم مديراً (Admin)
        final adminData = await _supabase
            .from('admins')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (adminData != null) {
          name.value = adminData['full_name'] ?? 'Admin';
          role.value = 'admin';
        }
      }

      // 2. جلب البيانات التفصيلية حسب دور المستخدم (طالب أم معلم)
      if (role.value == 'student') {
        // جلب تفاصيل الطالب من جدول الطلاب (مثل مستوى الحفظ)
        final studentData = await _supabase
            .from('students')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (studentData != null) {
          additionalInfo.value = studentData;
          hifzLevel.value = studentData['hifz_level'] ?? '';
        }

        // جلب بيانات الحلقة والمعلم المرتبط بهذا الطالب
        final circleMember = await _supabase
            .from('circle_members')
            .select('circle_id, circles!inner(id, name, teacher_id, supervisor_id)')
            .eq('student_id', user.id)
            .maybeSingle();

        if (circleMember != null && circleMember['circles'] != null) {
          final circle = circleMember['circles'];
          circleName.value = circle['name'] ?? '';
          final circleId = circle['id']?.toString() ?? circleMember['circle_id']?.toString() ?? '';
          final supervisorId = circle['supervisor_id']?.toString();
          
          final localSupervisor = await _localDb.getData('is_supervisor_${user.id}') == true ||
              (circleId.isNotEmpty && await _localDb.getData('circle_supervisor_$circleId') == user.id);

          isSupervisor.value = (supervisorId == user.id) || localSupervisor;

          final teacherId = circle['teacher_id'];
          if (teacherId != null) {
            // جلب اسم المعلم من جدول البروفايلات باستخدام معرف المعلم
            final tProfile = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('id', teacherId)
                .maybeSingle();
            teacherName.value = tProfile?['full_name'] ?? '';
          }
        }
      } else if (role.value == 'teacher') {
        // إذا كان المستخدم معلماً، نجلب اسم الحلقة التي يشرف عليها
        final teacherCircle = await _supabase
            .from('circles')
            .select('name')
            .eq('teacher_id', user.id)
            .maybeSingle();
        circleName.value = teacherCircle?['name'] ?? '';
      } else if (role.value == 'examiner') {
        // إذا كان المستخدم مختبراً، نجلب اسم الحلقة التي يشرف على اختباراتها
        final examinerCircle = await _supabase
            .from('circles')
            .select('name')
            .eq('examiner_id', user.id)
            .maybeSingle();
        circleName.value = examinerCircle?['name'] ?? '';
      }

      // 3. حفظ النسخة الأحدث من البيانات التي تم جلبها في الكاش المحلي
      _saveToCache();
    } catch (e) {
      // 4. في حالة حدوث خطأ (مثل فقدان الاتصال)، نقوم بتحميل البيانات من الكاش المحلي بدلاً من ترك الحقول فارغة
      await _loadFromCache();
    } finally {
      isLoading.value = false; // إخفاء مؤشر التحميل
    }
  }

  /// دالة لحفظ جميع بيانات البروفايل الحالية في قاعدة البيانات المحلية (SQLite)
  void _saveToCache() async {
    Map<String, dynamic> cacheData = {
      'name': name.value,
      'email': email.value,
      'role': role.value,
      'academicNumber': academicNumber.value,
      'phoneNumber': phoneNumber.value,
      'hifzLevel': hifzLevel.value,
      'teacherName': teacherName.value,
      'circleName': circleName.value,
      // ignore: invalid_use_of_protected_member
      'additionalInfo': additionalInfo.value,
      'avatarUrl': avatarUrl.value,
      'isSupervisor': isSupervisor.value,
    };
    await _localDb.saveData('profile_data', cacheData);
  }

  /// دالة لاسترجاع البيانات من الكاش المحلي عند الحاجة
  Future<void> _loadFromCache() async {
    final cachedData = await _localDb.getData('profile_data');
    if (cachedData != null) {
      name.value = cachedData['name'] ?? '';
      email.value = cachedData['email'] ?? '';
      role.value = cachedData['role'] ?? '';
      academicNumber.value = cachedData['academicNumber'] ?? '';
      phoneNumber.value = cachedData['phoneNumber'] ?? '';
      hifzLevel.value = cachedData['hifzLevel'] ?? '';
      teacherName.value = cachedData['teacherName'] ?? '';
      circleName.value = cachedData['circleName'] ?? '';
      avatarUrl.value = cachedData['avatarUrl'] ?? '';
      additionalInfo.value = cachedData['additionalInfo'] ?? {};
      isSupervisor.value = cachedData['isSupervisor'] == true;
    }
  }

  /// دالة تسجيل الخروج: تقوم بتنظيف البيانات، إلغاء الاشتراكات، والتوجه لصفحة الدخول
  Future<void> logout() async {
    _profileSubscription?.cancel(); // إيقاف مراقبة التغييرات اللحظية

    // ملاحظة: لا يتم مسح بيانات المصادقة المؤمنة (Biometrics/Credentials)
    // بناءً على طلب المستخدم للسماح بالدخول أوفلاين دائماً.

    try {
      // الخروج مع مهلة زمنية لضمان عدم التعليق عند فقدان الإنترنت
      await _supabase.auth.signOut().timeout(const Duration(seconds: 1));
    } catch (e) {
      // تجاهل الخطأ لأن الخروج المحلي تم بنجاح
    }

    Get.offAllNamed(
      AuthRoutes.login,
    ); // الانتقال لصفحة تسجيل الدخول وحذف مسار الصفحات السابقة
  }

  @override
  void onClose() {
    _profileSubscription
        ?.cancel(); // إلغاء الاشتراك عند تدمير المتحكم لمنع تسرب الذاكرة
    super.onClose();
  }
}
