import 'dart:convert'; // استيراد مكتبة تحويل البيانات مثل JSON
import 'package:flutter/material.dart'; // استيراد حزمة واجهات المستخدم من فلاتر
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة والمسارات
import 'package:http/http.dart' as http; // استيراد مكتبة الطلبات البرمجية HTTP
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة لفتح الروابط الخارجية
import '../../../../core/utils/app_constants.dart'; // استيراد الثوابت الخاصة بالتطبيق
import '../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالأدمن
import '../../../controller/applicants/applicants_controller.dart'; // استيراد متحكم المتقدمين

// ويدجت لعرض نافذة تفاصيل المتقدم (معلم أو طالب)
class ApplicantDetailsDialog extends StatelessWidget {
  final dynamic applicant; // متغير لتخزين بيانات المتقدم
  final bool isTeacher; // متغير لتحديد ما إذا كان المتقدم معلماً أم لا

  // مشيد الفئة لاستقبال البيانات المطلوبة للنافذة
  const ApplicantDetailsDialog({
    super.key, // مفتاح الويدجت الأساسي
    required this.applicant, // بيانات المتقدم المطلوبة
    required this.isTeacher, // تحديد نوع الطلب (معلم/طالب)
  });

  @override
  Widget build(BuildContext context) {
    // الحصول على نسخة من متحكم المتقدمين أو إنشاؤه إذا لم يكن موجوداً
    final controller = Get.isRegistered<ApplicantsController>()
        ? Get.find<ApplicantsController>()
        : Get.put(ApplicantsController());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // تحديد شكل النافذة بحواف دائرية
      child: Container(
        padding: const EdgeInsets.all(20), // إضافة هوامش داخلية للنافذة
        constraints: const BoxConstraints(maxWidth: 500), // تحديد أقصى عرض للنافذة بـ 500 بكسل
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // تحديد حجم العمود ليكون مضغوطاً حسب المحتوى
            crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر من البداية
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المسافة بين العنوان وزر الإغلاق
                children: [
                  Text(
                    isTeacher
                        ? 'teacher_applicant_details'.tr // عرض عنوان "تفاصيل طلب المعلم" مترجم
                        : 'student_applicant_details'.tr, // عرض عنوان "تفاصيل طلب الطالب" مترجم
                    style: const TextStyle(
                      fontSize: 20, // حجم خط العنوان
                      fontWeight: FontWeight.bold, // جعل خط العنوان عريضاً
                      color: Colors.indigo, // لون العنوان أرجواني
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context), // إغلاق النافذة عند الضغط على الزر
                    icon: const Icon(Icons.close), // أيقونة الإغلاق
                  ),
                ],
              ),
              const Divider(), // إضافة خط فاصل تحت العنوان
              const SizedBox(height: 16), // مساحة فارغة بارتفاع 16 بكسل

              _buildInfoRow('name'.tr, applicant.name), // عرض سطر الاسم
              _buildInfoRow('email'.tr, applicant.email), // عرض سطر البريد الإلكتروني
              _buildInfoRow('phone'.tr, applicant.phone, isPhone: true), // عرض سطر الهاتف مع ميزة اتجاه النص
              _buildInfoRow('age'.tr, applicant.age?.toString() ?? '-'), // عرض سطر العمر أو "-" إذا كان فارغاً
              _buildInfoRow(
                'qualification'.tr,
                applicant.academicQualification ?? '-', // عرض سطر المؤهل الدراسي
              ),
              _buildInfoRow(
                'batch_number'.tr,
                applicant.batchNumber?.toString() ?? '-', // عرض رقم الدفعة
              ),
              _buildInfoRow(
                isTeacher ? 'specialization'.tr : 'level'.tr, // عرض التخصص للمعلم أو المستوى للطالب
                isTeacher ? applicant.specialization : applicant.level,
              ),
              _buildInfoRow('academic_number'.tr, applicant.academicNumber), // عرض الرقم الأكاديمي
              _buildInfoRow(
                'gender'.tr,
                applicant.gender == Gender.male ? 'male'.tr : 'female'.tr, // عرض الجنس (ذكر/أنثى)
              ),

              if (isTeacher) ...[ // إذا كان المتقدم معلماً يتم عرض هذه الحقول
                const Divider(height: 24), // خط فاصل إضافي
                _buildInfoRow(
                  'sponsorship_status'.tr,
                  !applicant.canCoverBalance
                      ? 'needs_sponsorship'.tr // حالة "يحتاج كفالة"
                      : 'not_needs_sponsorship'.tr, // حالة "لا يحتاج كفالة"
                ),

                if (applicant.eligibilityProof != null &&
                    applicant.eligibilityProof!.isNotEmpty) ...[ // إذا وجد ملف إثبات الأهلية
                  const SizedBox(height: 16),
                  Text(
                    'eligibility_proof'.tr, // عنوان "إثبات الأهلية"
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilePreview(applicant.eligibilityProof!), // عرض معاينة لملف الأهلية
                ],

                if (applicant.pledgeFileUrl != null &&
                    applicant.pledgeFileUrl!.isNotEmpty) ...[ // إذا وجد ملف التعهد
                  const SizedBox(height: 16),
                  Text(
                    'pledge_file'.tr, // عنوان "ملف التعهد"
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilePreview(applicant.pledgeFileUrl!), // عرض معاينة لملف التعهد
                ],
              ],

              if (!isTeacher) ...[ // إذا كان المتقدم طالباً يتم عرض هذه الحقول
                _buildInfoRow(
                  'distribution_status'.tr,
                  applicant.isDistributed
                      ? 'distributed'.tr // حالة "تم التوزيع"
                      : 'not_distributed'.tr, // حالة "لم يتم التوزيع"
                ),
                if (applicant.pledgeFileUrl != null &&
                    applicant.pledgeFileUrl!.isNotEmpty) ...[ // إذا وجد ملف التعهد للطالب
                  const SizedBox(height: 16),
                  Text(
                    'pledge_file'.tr, // عنوان "ملف التعهد"
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilePreview(applicant.pledgeFileUrl!), // عرض معاينة لملف التعهد
                ],
              ],

              const SizedBox(height: 24), // مساحة فارغة قبل أزرار الإجراءات
              Obx(
                () => controller.isProcessing.value
                    ? const Center(child: CircularProgressIndicator()) // عرض مؤشر تحميل أثناء معالجة الطلب
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _confirmAction(context, 'approve', () async {
                                    await controller.approveApplicant(
                                      applicant.id, // استدعاء دالة الموافقة من المتحكم
                                    );
                                  }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // اللون الأخضر للموافقة
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text('accept'.tr), // نص زر "قبول" مترجم
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showRejectionDialog(context), // فتح نافذة لإدخال سبب الرفض
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red, // اللون الأحمر للرفض
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text('reject'.tr), // نص زر "رفض" مترجم
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء معاينة للملف (سواء كان رابطاً مباشراً أو يحتاج لجلب رابط من السيرفر)
  Widget _buildFilePreview(String path) {
    if (path.startsWith('http')) { // إذا كان الرابط يبدأ بـ http، يتم عرضه مباشرة
      return _buildFileContent(path);
    }

    // استخدام FutureBuilder لجلب الرابط الموقع من خادم Django
    return FutureBuilder<String>(
      future: _getSignedUrlFromDjango(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()), // عرض تحميل أثناء الانتظار
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildFileContent(''); // عرض أيقونة افتراضية في حال وجود خطأ
        }
        return _buildFileContent(snapshot.data!); // عرض المحتوى بالرابط الذي تم جلبه
      },
    );
  }

  // دالة لجلب الرابط الموقع للملفات من خادم Django لضمان الوصول الآمن
  Future<String> _getSignedUrlFromDjango(String fileName) async {
    try {
      // تحديد نوع الملف المطلوب عرضه بناءً على بيانات المتقدم
      final String type = isTeacher && applicant.eligibilityProof == fileName
          ? 'view-eligibility'
          : 'view-pledge';

      // بناء رابط الـ API للطلب
      final url = Uri.parse(
        "${AppConstants.djangoApiBaseUrl}/management/$type/${applicant.id}/",
      );
      // إرسال طلب GET مع ترويسات الصلاحية
      final response = await http.get(
        url,
        headers: {
          'X-API-KEY': AppConstants.djangoApiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // فك تشفير رد الـ JSON
        return data['url'] ?? ''; // إرجاع الرابط من البيانات المستلمة
      }
    } catch (e) {
    }
    return ''; // إرجاع نص فارغ في حالة الفشل
  }

  // دالة لبناء شكل عرض محتوى الملف (صورة أو أيقونة مستند)
  Widget _buildFileContent(String fullUrl) {
    // تحديد ما إذا كان الملف مستنداً بناءً على الامتداد
    final isPdfOrDoc =
        fullUrl.toLowerCase().contains('.pdf') ||
        fullUrl.toLowerCase().contains('.doc') ||
        fullUrl.toLowerCase().contains('.txt');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isPdfOrDoc && fullUrl.isNotEmpty) // إذا كانت صورة وليست مستنداً ولها رابط
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey[100],
              child: Image.network(
                fullUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container( // شكل بديل في حال فشل تحميل الصورة
                    height: 100,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          color: Colors.grey,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'document_file'.tr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
        if (isPdfOrDoc || fullUrl.isEmpty) // إذا كان الملف مستنداً أو الرابط غير موجود
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Icon(
                Icons.insert_drive_file,
                size: 40,
                color: Colors.indigo,
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _launchURL(fullUrl), // فتح الرابط في المتصفح الخارجي
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text('view_file'.tr), // نص "عرض الملف" مترجم
        ),
      ],
    );
  }

  // دالة لفتح الروابط الخارجية بشكل آمن
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication); // محاولة فتح التطبيق الخارجي
      } else {
        Get.snackbar('error'.tr, 'failed_open_link'.tr); // عرض تنبيه في حال تعذر الفتح
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_open_link'.tr);
    }
  }

  // دالة لعرض نافذة تأكيد الإجراء قبل تنفيذه
  void _confirmAction(
    BuildContext context,
    String type,
    VoidCallback onConfirm,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(
          type == 'approve' ? 'confirm_approval'.tr : 'confirm_rejection'.tr, // عنوان التنبيه
        ),
        content: Text(
          type == 'approve'
              ? 'approval_confirmation_msg'.tr // رسالة تأكيد القبول
              : 'rejection_confirmation_msg'.tr, // رسالة تأكيد الرفض
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)), // زر التراجع
          ElevatedButton(
            onPressed: () {
              Get.back(); // إغلاق نافذة التأكيد
              onConfirm(); // تنفيذ العملية المطلوبة
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr), // زر التأكيد
          ),
        ],
      ),
    );
  }

  // دالة لعرض نافذة تطلب من المسؤول كتابة سبب الرفض
  void _showRejectionDialog(BuildContext context) {
    final reasonController = TextEditingController(); // متحكم لحقل نص السبب
    Get.dialog(
      AlertDialog(
        title: Text('rejection_reason'.tr), // عنوان "سبب الرفض"
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: 'rejection_reason_hint'.tr), // تلميح للمسؤول
          maxLines: 3, // السماح بكتابة حتى 3 أسطر
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)), // زر إلغاء
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('warning'.tr, 'please_enter_rejection_reason'.tr); // تنبيه في حال ترك الحقل فارغاً
                return;
              }
              Get.back(); // إغلاق نافذة سبب الرفض
              await Get.find<ApplicantsController>().rejectApplicant(
                applicant.id,
                reasonController.text.trim(), // إرسال طلب الرفض مع السبب المكتوب
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm_rejection_btn'.tr), // زر تنفيذ الرفض
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء سطر يعرض معلومة معينة (تسمية وقيمة)
  Widget _buildInfoRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // عرض ثابت للتسمية لضمان التنسيق
            child: Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: isPhone
                ? Directionality(
                    textDirection: TextDirection.ltr, // جعل أرقام الهاتف تظهر من اليسار لليمين دائماً
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(value, style: const TextStyle(fontSize: 16)),
                    ),
                  )
                : Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
