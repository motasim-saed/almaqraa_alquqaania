import 'package:flutter/material.dart'; // استيراد مكتبة فلاتر الأساسية لتصميم الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة والترجمة والتنقل
import '../../controller/chat_controller.dart'; // استيراد متحكم الدردشة الخاص بالأدمن
import '../../models/admin_models.dart'; // استيراد نماذج البيانات (مثل المحادثات والمستخدمين)
import 'contact_selection_screen.dart'; // استيراد شاشة اختيار جهة الاتصال لبدء محادثة جديدة
import 'package:al_maqraa/Student/pages/chat_screen.dart'; // استيراد شاشة الدردشة الفعلية
import '../widgets/admin_stat_card.dart'; // استيراد عنصر بطاقة الإحصائيات المخصص
import 'package:al_maqraa/core/utils/app_cached_image.dart'; // استيراد أداة عرض الصور المخبأة (Cache)
import 'package:al_maqraa/core/services/notification_service.dart'; // لحذف الإشعار عند فتح المحادثة
import 'package:al_maqraa/core/controllers/global_batch_controller.dart';

// شاشة صندوق الوارد للمسؤول (AdminInboxScreen) وتعرض قائمة المحادثات النشطة مع إمكانية الفلترة
class AdminInboxScreen extends StatelessWidget { // تعريف كلاس الشاشة كـ StatelessWidget
  final String? roleFilter; // متغير لتحديد الدور المراد عرضه (معلم أو طالب)
  const AdminInboxScreen({super.key, this.roleFilter}); // مشيد الكلاس مع تمرير مفتاح وفلتر الدور

  @override // إعادة تعريف دالة البناء
  Widget build(BuildContext context) { // دالة بناء واجهة المستخدم
    // تهيئة أو جلب نسخة من متحكم الدردشة بناءً على الدور المفلتر باستخدام tag فريد
    final controller = Get.put(AdminChatController(), tag: roleFilter ?? 'all'); // ربط المتحكم بالواجهة

    return Scaffold( // إرجاع هيكل الصفحة الأساسي
      backgroundColor: Colors.transparent, // جعل الخلفية شفافة لتنسجم مع تصميم الحاوية الأب
      body: RefreshIndicator( // إضافة ميزة السحب للتحديث (Pull to Refresh)
        onRefresh: () => controller.refreshData(), // استدعاء دالة تحديث البيانات من المتحكم
        color: Colors.indigo, // لون مؤشر التحميل
        child: CustomScrollView( // استخدام عرض تمرير مخصص لدعم العناصر المنزلقة (Slivers)
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), // ضمان قابلية التمرير حتى لو كانت القائمة قصيرة ليعمل التحديث
          slivers: [ // قائمة العناصر المنزلقة داخل التمرير
            // جزء الهيدر الذي يحتوي على بطاقات الإحصائيات وفلاتر الجنس
            SliverToBoxAdapter( // محول لتحويل الوجت العادي إلى عنصر منزلق
              child: _buildHeader(context, controller), // استدعاء دالة بناء الهيدر
            ), // نهاية عنصر الهيدر
            
            // شريط البحث الذي يظهر ويختفي (ينطوي) عند التمرير
            SliverAppBar( // شريط تطبيق منزلق
              floating: true, // جعل الشريط يظهر فور البدء بالتمرير للأعلى
              snap: true, // جعل الشريط يظهر بالكامل تلقائياً عند التوقف عن التمرير للأعلى
              backgroundColor: Colors.transparent, // جعل خلفية الشريط شفافة
              elevation: 0, // إلغاء الظل الخاص بالشريط
              automaticallyImplyLeading: false, // منع إظهار زر الرجوع التلقائي
              titleSpacing: 24, // تحديد المسافة الجانبية للعنوان
              title: _buildSearchField(context, controller), // استدعاء دالة بناء حقل البحث كعنوان للشريط
            ), // نهاية شريط البحث المنزلق

            // عنصر منزلق يعرض قائمة المحادثات بشكل فعلي
            _buildChatListSliver(controller), // استدعاء دالة بناء القائمة
          ], // نهاية قائمة العناصر المنزلقة
        ), // نهاية التمرير المخصص
      ), // نهاية ميزة السحب للتحديث
      floatingActionButton: FloatingActionButton( // زر عائم لإضافة محادثة جديدة
        heroTag: 'fab_${roleFilter ?? 'all'}', // معرف فريد للزر لتجنب أخطاء الانتقال بين الشاشات
        onPressed: () => // وظيفة الزر عند الضغط
            Get.to(() => ContactSelectionScreen(roleFilter: roleFilter)), // الانتقال لشاشة اختيار جهة الاتصال
        backgroundColor: Colors.indigo, // تحديد اللون النيلي لخلفية الزر
        child: const Icon(Icons.message, color: Colors.white), // وضع أيقونة رسالة بيضاء داخل الزر
      ), // نهاية الزر العائم
    ); // نهاية الهيكل الأساسي
  } // نهاية دالة البناء

  // دالة بناء ويدجت حقل البحث بتصميم عصري يدعم اللغات
  Widget _buildSearchField(BuildContext context, AdminChatController controller) { // استقبال السياق والمتحكم
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container( // حاوية لحقل البحث لتحديد التصميم والظل
      height: 45, // تحديد ارتفاع الحقل
      decoration: BoxDecoration( // تحديد نمط الحاوية
        color: Theme.of(context).cardColor, // لون خلفية الحقل بناءً على الثيم
        borderRadius: BorderRadius.circular(12), // زوايا منحنية بمقدار 12
        boxShadow: [ // إضافة ظل للحاوية
          BoxShadow( // تفاصيل الظل
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, // مدى تشتت الظل
            offset: const Offset(0, 4), // إزاحة الظل للأسفل
          ), // نهاية الظل
        ], // نهاية قائمة الظلال
      ), // نهاية نمط الحاوية
      child: TextField( // حقل إدخال النص
        onChanged: (value) => controller.searchQuery.value = value, // تحديث قيمة البحث في المتحكم عند كل تغيير
        decoration: InputDecoration( // تحديد شكل الحقل والرموز
          hintText: 'search_chats'.tr, // نص تلميحي مترجم لدعم اللغتين
          hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 14), // نمط ولون نص التلميح
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20), // أيقونة بحث
          border: InputBorder.none, // إزالة الحدود الافتراضية للحقل
          contentPadding: const EdgeInsets.symmetric(vertical: 10), // حشوة داخلية للنص
        ), // نهاية تصميم الحقل
      ), // نهاية حقل النص
    ); // نهاية حاوية البحث
  } // نهاية دالة بناء البحث

  // دالة بناء قائمة المحادثات التي تستجيب للتغييرات وتدعم الـ Slivers
  Widget _buildChatListSliver(AdminChatController controller) { // استقبال المتحكم
    return Obx(() { // استخدام Obx لمراقبة التغييرات في بيانات المتحكم وإعادة البناء تلقائياً
      // التحقق إذا كانت البيانات قيد التحميل والقائمة فارغة لعرض مؤشر انتظار
      if (controller.isLoading.value && controller.chats.isEmpty) { // شرط التحميل
        return const SliverFillRemaining( // عنصر يملأ المساحة المتبقية
          child: Center(child: CircularProgressIndicator()), // عرض دائرة التحميل في المنتصف
        ); // نهاية عنصر التحميل
      } // نهاية شرط التحميل

      // الحصول على قائمة المحادثات المفلترة بناءً على الدور والبحث المختار
      final chats = controller.getFilteredChats(roleFilter); // استدعاء دالة الفلترة من المتحكم

      // التحقق إذا كانت القائمة فارغة لعرض رسالة تنبيه للمستخدم مترجمة
      if (chats.isEmpty) { // شرط القائمة الفارغة
        return SliverFillRemaining( // عنصر يملأ المساحة المتبقية
          child: Center( // توسيط المحتوى
            child: Column( // ترتيب المحتوى عمودياً
              mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
              children: [ // قائمة الوجتات داخل العمود
                Icon( // أيقونة تعبيرية للقائمة الفارغة
                  Icons.chat_outlined, // أيقونة دردشة محددة
                  size: 64, // حجم الأيقونة
                  color: Colors.indigo.withValues(alpha: 0.2), // لون نيلي شفاف جداً
                ), // نهاية الأيقونة
                const SizedBox(height: 16), // مسافة عمودية
                Text( // نص التنبيه
                  'no_chats_yet'.tr, // نص مترجم لدعم اللغتين
                  style: TextStyle(color: Colors.grey[600], fontSize: 18), // نمط النص ولونه
                ), // نهاية النص
              ], // نهاية قائمة العمود
            ), // نهاية العمود
          ), // نهاية التوسيط
        ); // نهاية العنصر الماليء للمساحة
      } // نهاية شرط القائمة الفارغة

      // بناء القائمة الحقيقية للمحادثات باستخدام SliverList للأداء العالي
      return SliverPadding( // إضافة حواف حول القائمة المنزلقة
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // حواف جانبية وعمودية
        sliver: SliverList( // قائمة منزلقة تدعم العناصر المتكررة
          delegate: SliverChildBuilderDelegate( // مفوض لبناء العناصر عند الطلب لتحسين الذاكرة
            (context, index) { // دالة بناء كل عنصر بناءً على الفهرس
              final chat = chats[index]; // جلب بيانات المحادثة الحالية من القائمة
              return _buildChatTile(context, chat); // استدعاء دالة بناء بطاقة المحادثة
            }, // نهاية دالة البناء
            childCount: chats.length, // تحديد إجمالي عدد العناصر في القائمة
          ), // نهاية المفوض
        ), // نهاية القائمة المنزلقة
      ); // نهاية الحواف المحيطة
    }); // نهاية مراقب التغييرات
  } // نهاية دالة بناء القائمة

  // دالة بناء الجزء العلوي (الهيدر) الذي يحتوي على الإحصائيات والفلاتر مع هامش إضافي
  Widget _buildHeader(BuildContext context, AdminChatController controller) { // استقبال السياق والمتحكم
    return Padding( // إضافة حواف حول الهيدر بالكامل
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), // إضافة هامش علوي (16) لتحسين التنسيق كما طلب المستخدم
      child: Obx(() { // مراقبة التغييرات لتحديث أرقام الإحصائيات فورياً
        // تصفية المحادثات بناءً على الدور الحالي والبطاقة (batch) المحددة لحساب الأرقام المعروضة في البطاقات
        int? batchFilter;
        if (Get.isRegistered<GlobalBatchController>()) {
          batchFilter = Get.find<GlobalBatchController>().selectedBatch.value;
        }

        final roleChats = controller.chats // الوصول لكافة المحادثات
            .where((c) {
              bool roleMatch = roleFilter == null || c.userRole == roleFilter;
              bool batchMatch = batchFilter == null || c.batchNumber == batchFilter;
              return roleMatch && batchMatch;
            }) // فلترة حسب الدور والدفعة
            .toList(); // تحويل النتيجة لقائمة
        final total = roleChats.length; // حساب إجمالي عدد المحادثات للدور الحالي
        final males = roleChats.where((c) => c.gender == Gender.male).length; // حساب عدد محادثات البنين
        final females = roleChats.where((c) => c.gender == Gender.female).length; // حساب عدد محادثات البنات

        return Row( // ترتيب بطاقات الإحصائيات أفقياً
          children: [ // قائمة العناصر داخل الصف
            // بطاقة الفلترة الخاصة بـ "الكل"
            Expanded( // جعل البطاقة تأخذ مساحة متساوية مع غيرها
              child: _buildFilterCard( // استدعاء دالة بناء بطاقة الفلترة
                controller: controller, // تمرير المتحكم
                targetGender: Gender.all, // تحديد النوع المستهدف (الكل)
                title: 'all'.tr, // عنوان مترجم لدعم اللغتين
                value: total.toString(), // قيمة العدد الإجمالي
                icon: Icons.all_inclusive, // أيقونة ترمز للشمولية
                color: Colors.indigo, // اللون النيلي
              ), // نهاية بطاقة الكل
            ), // نهاية التوسع
            const SizedBox(width: 12), // مسافة أفقية بين البطاقات
            // بطاقة الفلترة الخاصة بـ "البنين"
            Expanded( // جعل البطاقة تأخذ مساحة متساوية
              child: _buildFilterCard( // استدعاء دالة بناء بطاقة الفلترة
                controller: controller, // تمرير المتحكم
                targetGender: Gender.male, // تحديد النوع المستهدف (ذكر)
                title: 'boys'.tr, // عنوان مترجم (بنين)
                value: males.toString(), // قيمة عدد البنين
                icon: Icons.male, // أيقونة ذكر
                color: Colors.blue, // اللون الأزرق
              ), // نهاية بطاقة البنين
            ), // نهاية التوسع
            const SizedBox(width: 12), // مسافة أفقية بين البطاقات
            // بطاقة الفلترة الخاصة بـ "البنات"
            Expanded( // جعل البطاقة تأخذ مساحة متساوية
              child: _buildFilterCard( // استدعاء دالة بناء بطاقة الفلترة
                controller: controller, // تمرير المتحكم
                targetGender: Gender.female, // تحديد النوع المستهدف (أنثى)
                title: 'girls'.tr, // عنوان مترجم (بنات)
                value: females.toString(), // قيمة عدد البنات
                icon: Icons.female, // أيقونة أنثى
                color: Colors.pink, // اللون الوردي
              ), // نهاية بطاقة البنات
            ), // نهاية التوسع
          ], // نهاية قائمة الصف
        ); // نهاية الصف الأفقي
      }), // نهاية مراقب التغييرات
    ); // نهاية الحواف المحيطة بالهيدر
  } // نهاية دالة بناء الهيدر

  // دالة بناء بطاقة الفلترة التفاعلية التي تتيح للمستخدم الاختيار
  Widget _buildFilterCard({ // استقبال المعايير المطلوبة للبطاقة
    required AdminChatController controller, // المتحكم
    required Gender targetGender, // نوع الجنس المستهدف بالبطاقة
    required String title, // عنوان البطاقة
    required String value, // القيمة العددية
    required IconData icon, // الأيقونة
    required Color color, // اللون الأساسي
  }) { // بداية جسم الدالة
    // التحقق برمجياً إذا كان هذا الفلتر هو المختار حالياً من قبل المستخدم
    final isSelected = controller.selectedGenderFilter.value == targetGender; // مقارنة الحالة الحالية بالهدف
    return InkWell( // وجت تفاعلي يستجيب للمس مع تأثير بصري
      onTap: () => controller.selectedGenderFilter.value = targetGender, // تحديث الفلتر المختار في المتحكم عند الضغط
      borderRadius: BorderRadius.circular(16), // تحديد زوايا تأثير اللمس لتتطابق مع البطاقة
      child: Container( // حاوية لتطبيق الحدود الملونة عند الاختيار
        decoration: BoxDecoration( // نمط الحاوية
          borderRadius: BorderRadius.circular(16), // زوايا منحنية بمقدار 16
          border: isSelected // تطبيق حدود ملونة فقط إذا كانت البطاقة مختارة
              ? Border.all(color: color, width: 2) // حدود بلون الفلتر وبسمك 2
              : Border.all(color: Colors.transparent, width: 2), // حدود شفافة إذا لم تكن مختارة
        ), // نهاية النمط
        child: AdminStatCard( // استخدام العنصر المخصص لعرض الإحصائيات
          title: title, // تمرير العنوان
          value: value, // تمرير القيمة
          icon: icon, // تمرير الأيقونة
          color: isSelected ? color : Colors.grey, // تلوين البطاقة باللون الأساسي إذا اختيرت وإلا بالرمادي
          isSmall: true, // تحديد الحجم الصغير ليناسب الترتيب الأفقي
        ), // نهاية بطاقة الإحصائيات المخصصة
      ), // نهاية حاوية الحدود
    ); // نهاية الوجت التفاعلي
  } // نهاية دالة بناء بطاقة الفلترة

  // دالة بناء بطاقة المحادثة الواحدة (العنصر المتكرر في القائمة)
  Widget _buildChatTile(BuildContext context, ChatModel chat) { // استقبال السياق وبيانات المحادثة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container( // حاوية لتنسيق خلفية وظل بطاقة المحادثة
      margin: const EdgeInsets.only(bottom: 12), // إضافة مسافة سفلية لفصل البطاقات عن بعضها
      decoration: BoxDecoration( // نمط الحاوية
        color: Theme.of(context).cardColor, // لون خلفية البطاقة يعتمد على الثيم
        borderRadius: BorderRadius.circular(16), // زوايا منحنية بمقدار 16
        boxShadow: [ // إضافة ظل خفيف للبطاقة لإبرازها عن الخلفية
          BoxShadow( // تفاصيل الظل
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03), // الظل متوافق مع الثيم
            blurRadius: 10, // مدى تشتت ونعومة الظل
            offset: const Offset(0, 4), // إزاحة الظل للأسفل بمقدار 4 بكسل
          ), // نهاية الظل
        ], // نهاية قائمة الظلال
      ), // نهاية النمط
      child: ListTile( // وجت قائمة قياسي لتنظيم الصورة والعنوان والنص والوقت
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // حشوة داخلية للبطاقة
        leading: Stack( // استخدام Stack لوضع مؤشر الدور فوق صورة المستخدم
          children: [ // قائمة العناصر داخل الـ Stack
            // صورة المستخدم الشخصية مع دعم التحميل المخبأ (Cache)
            CircleAvatar( // حاوية دائرية للصورة
              radius: 28, // نصف قطر الدائرة 28 بكسل
              backgroundColor: Colors.indigo.withValues(alpha: 0.1), // لون خلفية افتراضي نيلي خفيف
              child: chat.userAvatar != null && chat.userAvatar!.isNotEmpty // التحقق من وجود رابط للصورة
                  ? ClipOval( // قص الصورة بشكل دائري لتناسب الـ Avatar
                      child: AppCachedImage( // استخدام أداة عرض الصور المخبأة
                        imageUrl: chat.userAvatar!, // رابط الصورة
                        width: 56, // عرض الصورة (ضعف نصف القطر)
                        height: 56, // ارتفاع الصورة
                        fit: BoxFit.cover, // ملء الصورة بالكامل مع القص للمحافظة على التناسب
                      ), // نهاية أداة الصورة
                    ) // نهاية قص الصورة
                  : Text( // عرض الحرف الأول من الاسم إذا لم توجد صورة
                      chat.userName.isNotEmpty ? chat.userName[0] : '?', // جلب أول حرف أو علامة استفهام
                      style: const TextStyle( // نمط النص داخل الدائرة
                        fontWeight: FontWeight.bold, // خط عريض
                        color: Colors.indigo, // لون نيلي
                        fontSize: 20, // حجم الخط 20
                      ), // نهاية نمط النص
                    ), // نهاية عرض النص
            ), // نهاية دائرة الصورة
            // مؤشر ملون صغير في الزاوية يعبر عن دور المستخدم (معلم/طالب)
            Positioned( // تحديد موقع المؤشر بدقة داخل الـ Stack
              right: 0, // وضعه في الجهة اليمنى
              bottom: 0, // وضعه في الجهة السفلية
              child: Container( // حاوية المؤشر الملون
                width: 14, // عرض الدائرة 14 بكسل
                height: 14, // ارتفاع الدائرة 14 بكسل
                decoration: BoxDecoration( // نمط دائرة المؤشر
                  color: chat.userRole == 'teacher' // اختيار اللون بناءً على الدور
                      ? Colors.blue // اللون الأزرق للمعلم
                      : Colors.green, // اللون الأخضر للطالب
                  shape: BoxShape.circle, // جعل الشكل دائري
                  border: Border.all(color: Theme.of(context).cardColor, width: 2), // إطار يعتمد على الثيم لفصل المؤشر عن الصورة
                ), // نهاية النمط
              ), // نهاية حاوية المؤشر
            ), // نهاية تحديد الموقع
          ], // نهاية عناصر الـ Stack
        ), // نهاية الـ Stack الخاص بالصورة
        title: Row( // تنظيم اسم المستخدم والوقت في صف واحد
          children: [ // قائمة العناصر داخل الصف
            Expanded( // استخدام Expanded لتجنب تجاوز مساحة الشاشة
              child: Row(
                children: [
                  Flexible(
                    child: Text( // عرض اسم المستخدم
                      chat.userName, // نص الاسم
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle( // نمط الاسم
                        fontWeight: FontWeight.w600, // وزن الخط شبه عريض
                        fontSize: 16, // حجم الخط 16
                        fontFamily: 'Cairo', // استخدام خط كايرو العربي
                      ), // نهاية النمط
                    ),
                  ),
                  if (chat.unreadCount > 0) ...[
                    const SizedBox(width: 8), // مسافة بين الاسم والعداد
                    Container(
                      padding: const EdgeInsets.all(6), // حشوة الدائرة
                      decoration: const BoxDecoration(
                        color: Colors.red, // لون العداد أحمر
                        shape: BoxShape.circle, // شكل العداد دائري
                      ),
                      child: Text(
                        chat.unreadCount > 99 ? '+99' : chat.unreadCount.toString(), // كتابة عدد الرسائل أو 99+
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), // نمط الرقم
                      ),
                    ),
                  ],
                ],
              ),
            ), // نهاية التوسع
            const SizedBox(width: 8), // مسافة قبل الوقت
            // عرض وقت آخر تحديث للمحادثة بصيغة (ساعة:دقيقة)
            Text( // نص الوقت
              "${chat.updatedAt.hour}:${chat.updatedAt.minute.toString().padLeft(2, '0')}", // تنسيق الوقت
              style: TextStyle(color: Colors.grey[400], fontSize: 12), // نمط ولون الوقت (رمادي خفيف)
            ), // نهاية نص الوقت
          ], // نهاية عناصر الصف
        ), // نهاية صف العنوان
        subtitle: Row( // تنظيم نص آخر رسالة في صف
          children: [ // قائمة العناصر داخل الصف
            Expanded( // جعل نص الرسالة يتوسع ليملأ المساحة المتاحة
              child: Text( // عرض نص آخر رسالة
                chat.lastMessage, // محتوى الرسالة
                maxLines: 1, // السماح بسطر واحد فقط
                overflow: TextOverflow.ellipsis, // إظهار ثلاث نقاط في حال كان النص طويلاً
                style: TextStyle( // نمط نص الرسالة
                  color: chat.unreadCount > 0 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).hintColor, // تغيير لون النص بناءً على الثيم
                  fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal, // تغليظ عند وجود غير مقروءة
                  fontFamily: 'Cairo', // استخدام خط كايرو
                ), // نهاية النمط
              ), // نهاية نص الرسالة
            ), // نهاية التوسع
          ], // نهاية عناصر الصف
        ), // نهاية صف العنوان الفرعي
        onTap: () {
          // تصفير العداد فوراً وحذف الإشعار عند فتح المحادثة
          final adminController = Get.find<AdminChatController>(tag: roleFilter ?? 'all');
          adminController.markAsRead(chat.id);
          NotificationService().cancelNotification(chat.userId.hashCode);
          NotificationService().cancelNotification(chat.id.hashCode);
          // الانتقال لشاشة الدردشة التفصيلية مع تمرير كافة البيانات الضرورية للطرف الآخر
          Get.to( // استخدام GetX للتنقل بين الشاشات
            () => ChatScreen( // شاشة المحادثة المستهدفة
              otherUserId: chat.userId, // معرف المستخدم الآخر
              otherUserName: chat.userName, // اسم المستخدم الآخر
              otherUserRole: chat.userRole, // دور المستخدم الآخر
              chatType: chat.type, // نوع المحادثة (فردية/جماعية)
            ), // نهاية تعريف الشاشة
          ); // نهاية الانتقال
        }, // نهاية وظيفة الضغط
      ), // نهاية الـ ListTile
    ); // نهاية حاوية بطاقة المحادثة
  } // نهاية دالة بناء بطاقة المحادثة
} // نهاية كلاس الشاشة
