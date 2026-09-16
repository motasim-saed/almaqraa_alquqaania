import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:url_launcher/url_launcher.dart'; // استيراد حزمة فتح الروابط الخارجية (واتساب)
import '../../controller/chat_controller.dart'; // استيراد متحكم الدردشة الخاص بالمسؤول
// import '../../models/admin_models.dart'; // استيراد النماذج والبيانات الخاصة بالمسؤول
import 'package:al_maqraa/Student/pages/chat_screen.dart'; // استيراد شاشة الدردشة الأساسية

// شاشة اختيار جهة الاتصال لبدء محادثة جديدة
// تتيح للمسؤول البحث عن المعلمين أو الطلاب لبدء مراسلتهم بشكل فردي
class ContactSelectionScreen extends StatefulWidget {
  // تعريف ودجت الحالة المتغيرة لشاشة اختيار جهات الاتصال
  final String?
  roleFilter; // متغير اختياري لتحديد فلتر الدور (معلم / طالب) لتقليل النتائج المعروضة
  const ContactSelectionScreen({
    super.key,
    this.roleFilter,
  }); // منشئ الصف مع تمرير مفتاح فريد وفلتر الدور

  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState(); // إنشاء الحالة المرتبطة بهذه الودجت
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  // تعريف حالة شاشة اختيار جهات الاتصال
  late final AdminChatController
  controller; // تعريف متغير لمتحكم الدردشة الذي سيتم جلبه
  final TextEditingController _searchController =
      TextEditingController(); // تعريف متحكم للتحكم في نص حقل البحث
  final _searchQuery =
      "".obs; // تعريف متغير تفاعلي (Observable) لمراقبة تغييرات نص البحث

  @override
  void initState() {
    // دالة يتم استدعاؤها عند تهيئة الشاشة لأول مرة
    super.initState(); // استدعاء دالة التهيئة الأصلية من الفئة الأب
    // إيجاد المتحكم المرتبط بالدور الحالي باستخدام GetX عبر الوسم (tag)
    controller = Get.find<AdminChatController>(
      tag: widget.roleFilter ?? 'all',
    ); // البحث عن المتحكم المناسب (معلمين/طلاب أو الكل)
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة المستخدم للشاشة
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.indigo,),
      // إرجاع هيكل الشاشة الأساسي الذي يوفر الخلفية والعناصر
      // تمت إزالة اللون الثابت ليدعم الثيم الفاتح والغامق
      body:
      Column(
        // ترتيب العناصر في اتجاه عمودي (من الأعلى للأسفل)
        children: [
          // قائمة العناصر الموجودة داخل العمود
          _buildHeader(), // استدعاء دالة بناء الهيدر الذي يحتوي على العنوان وحقل البحث
          const SizedBox(height: 5), // إضافة مسافة فاصلة عمودية بمقدار 16 بكسل
          Expanded(
            child: _buildContactList(),
          ), // بناء قائمة جهات الاتصال وتوسيعها لتأخذ كل المساحة المتاحة
        ],
      ),
    );
  }

  // بناء الهيدر العلوي الذي يحتوي على زر الرجوع والعنوان وشريط البحث
  Widget _buildHeader() {
    // دالة ترجع ودجت الهيدر
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      // حاوية لتصميم وتنسيق الهيدر
      padding: const EdgeInsets.fromLTRB(
        24,
        2,
        24,
        2,
      ), // تحديد الهوامش الداخلية (يسار: 24، أعلى: 48، يمين: 24، أسفل: 24)

      child: Column(
        // ترتيب عناصر الهيدر بشكل عمودي
        children: [
          // قائمة العناصر داخل الهيدر
          Row(
            // ترتيب زر الرجوع والعنوان بشكل أفقي
            children: [
              // قائمة العناصر داخل الصف

              const SizedBox(width: 18), // مسافة أفقية فاصلة بمقدار 8 بكسل
              // عنوان الشاشة يتغير بناءً على الدور المطلوب اختياره
              Text(
                // ودجت لعرض النص
                widget.roleFilter == 'teacher'
                    ? 'select_teacher'.tr
                    : 'select_student'
                          .tr, // اختيار مفتاح الترجمة بناءً على الفلتر
                style: TextStyle(
                  // تحديد نمط وتنسيق الخط
                  fontSize: 24, // حجم الخط 24 بكسل
                  fontWeight: FontWeight.bold, // جعل الخط عريضاً
                  color: colorScheme.primary, // تحديد لون الخط متوافق مع الثيم
                ),
              ),
            ],
          ),
          const SizedBox(height: 15), // مسافة عمودية فاصلة بمقدار 20 بكسل
          // حقل البحث لتصفية جهات الاتصال
          TextField(
            // حقل لإدخال النصوص
            controller:
                _searchController, // ربط الحقل بمتحكم النص المحدد سابقاً
            onChanged: (val) => _searchQuery.value =
                val, // تحديث متغير البحث التفاعلي عند كل تغيير في النص
            decoration: InputDecoration(
              // تحديد شكل وتنسيق حقل الإدخال
              hintText:
                  'search_contacts'.tr, // نص تلميحي يظهر عند فراغ الحقل (مترجم)
              hintStyle: TextStyle(
                color: theme.hintColor,
              ), // لون التلميح بناءً على الثيم
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.primary,
              ), // أيقونة بحث متوافقة مع الثيم
              filled: true, // تفعيل خاصية تعبئة خلفية الحقل باللون
              fillColor: theme
                  .scaffoldBackgroundColor, // تحديد لون التعبئة بلون خلفية الشاشة
              border: OutlineInputBorder(
                // تحديد حدود الحقل بنمط الحواف المنحنية
                borderRadius: BorderRadius.circular(
                  30,
                ), // جعل الحواف دائرية تماماً بنصف قطر 30
                borderSide: BorderSide.none, // إخفاء خط الحدود الخارجي
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء قائمة جهات الاتصال المفلترة بناءً على شروط البحث والفلاتر
  Widget _buildContactList() {
    // دالة ترجع قائمة جهات الاتصال
    return Obx(() {
      // استخدام Obx لإعادة بناء الواجهة تلقائياً عند تغير البيانات المراقبة
      // جلب جميع ملفات المستخدمين وتصفيتها محلياً بناءً على الدور والجنس ونص البحث
      final baseContacts = controller.getFilteredUserProfiles(
        widget.roleFilter,
      );
      final contacts = baseContacts.where((p) {
        bool searchMatch = p.name.toLowerCase().contains(
          // التحقق من احتواء الاسم على نص البحث
          _searchQuery.value
              .toLowerCase(), // تحويل نص البحث والاسم لحروف صغيرة للمقارنة الدقيقة
        );
        return searchMatch; // إرجاع العنصر فقط إذا تحققت جميع الشروط
      }).toList(); // تحويل نتائج التصفية إلى قائمة فعلية

      // عرض رسالة تنبيه في حال لم يتم العثور على أي نتائج مطابقة
      if (contacts.isEmpty) {
        // إذا كانت القائمة المصفاة فارغة
        return Center(
          child: Text('no_contacts_found'.tr),
        ); // عرض نص "لا توجد نتائج" في منتصف المساحة
      }

      return ListView.builder(
        // بناء قائمة العناصر بشكل كفؤ وقابل للتمرير
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ), // إضافة هوامش أفقية للقائمة بمقدار 24 بكسل
        itemCount: contacts.length, // تحديد إجمالي عدد العناصر في القائمة
        itemBuilder: (context, index) {
          // دالة بناء كل عنصر بناءً على فهرسه
          final user =
              contacts[index]; // الحصول على بيانات المستخدم الحالي من القائمة
          return Card(
            // وضع كل عنصر داخل بطاقة لإعطائه مظهراً بارزاً
            margin: const EdgeInsets.only(
              bottom: 8,
            ), // إضافة مسافة سفلية بين البطاقات
            shape: RoundedRectangleBorder(
              // تحديد شكل حواف البطاقة
              borderRadius: BorderRadius.circular(
                12,
              ), // جعل حواف البطاقة دائرية بنصف قطر 12
            ),
            child: ListTile(
              // عنصر قائمة قياسي يسهل ترتيب المحتويات
              leading: CircleAvatar(
                // أيقونة دائرية تظهر في بداية العنصر
                backgroundColor: Theme.of(context).colorScheme.primary
                    .withValues(
                      alpha: 0.1,
                    ), // لون خلفية الأيقونة متوافق مع الثيم
                child: Text(
                  // عرض الحرف الأول من اسم المستخدم داخل الدائرة
                  user.name.isNotEmpty
                      ? user.name[0]
                      : '?', // عرض أول حرف أو علامة استفهام إذا كان فارغاً
                  style: TextStyle(
                    // تحديد تنسيق حرف الأفاتار
                    color: Theme.of(
                      context,
                    ).colorScheme.primary, // لون الحرف متوافق مع الثيم
                    fontWeight: FontWeight.bold, // جعل الحرف عريضاً
                  ),
                ),
              ),
              title: Text(
                // عرض اسم المستخدم كعنوان رئيسي للعنصر
                user.name, // الاسم المسترجع من بيانات المستخدم
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ), // جعل الخط سميكاً بدرجة 600
              ),
              subtitle: Text(
                // عرض دور المستخدم (معلم أو طالب) كعنوان فرعي
                user.role == 'teacher'
                    ? 'teacher'.tr
                    : 'student'.tr, // ترجمة الدور (معلم/طالب) بناءً على قيمته
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ), // لون باهت وحجم خط صغير
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).hintColor,
                      size: 20,
                    ),
                    tooltip: 'خيارات',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'whatsapp') {
                        final phone = user.phone;
                        if (phone != null && phone.trim().isNotEmpty) {
                          final rawPhone = phone.replaceAll(
                            RegExp(r'[\s\-\(\)\+]'),
                            '',
                          );
                          final whatsappUri = Uri.parse('https://wa.me/$rawPhone');
                          if (!await launchUrl(
                            whatsappUri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            Get.snackbar(
                              'تنبيه',
                              'تعذّر فتح واتساب',
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        } else {
                          Get.snackbar(
                            'تنبيه',
                            'لا يوجد رقم هاتف مسجل لهذا المستخدم',
                            backgroundColor: Colors.orangeAccent,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'whatsapp',
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'تواصل بالواتساب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: Color(0xFF25D366),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    // أيقونة تظهر في نهاية العنصر للإشارة لإمكانية الإرسال
                    Icons.send_rounded, // شكل أيقونة الإرسال (سهم)
                    color: Theme.of(
                      context,
                    ).colorScheme.primary, // لون الأيقونة متوافق مع الثيم
                    size: 20, // حجم الأيقونة 20 بكسل
                  ),
                ],
              ),
              onTap: () {
                // الوظيفة التي يتم تنفيذها عند الضغط على العنصر
                // إغلاق شاشة الاختيار ثم الانتقال مباشرة لشاشة المحادثة مع المستخدم المختار
                Get.back(); // إغلاق الشاشة الحالية (شاشة الاختيار)
                Get.to(
                  // الانتقال إلى شاشة الدردشة
                  () => ChatScreen(
                    // بناء كائن شاشة الدردشة مع تمرير البيانات اللازمة
                    otherUserId:
                        user.id, // تمرير المعرف الفريد للمستخدم المختار
                    otherUserName:
                        user.name, // تمرير اسم المستخدم لبدء المحادثة معه
                    otherUserRole: user
                        .role, // تمرير دور المستخدم (لأغراض العرض أو الفلترة داخل الدردشة)
                    chatType: 'chat', // تحديد نوع الدردشة كمحادثة نصية مباشرة
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
