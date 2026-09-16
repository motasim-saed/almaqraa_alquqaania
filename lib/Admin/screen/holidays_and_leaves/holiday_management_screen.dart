import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهات المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../controller/holiday_controller.dart'; // استيراد متحكم الإجازات
import '../../models/admin_models.dart'; // استيراد نماذج البيانات
import 'package:intl/intl.dart'; // استيراد حزمة تنسيق التاريخ

class HolidayManagementScreen extends StatelessWidget { // تعريف فئة شاشة إدارة الإجازات
  const HolidayManagementScreen({super.key}); // منشئ الفئة

  @override
  Widget build(BuildContext context) { // دالة بناء واجهة المستخدم
    final HolidayController controller = Get.put(HolidayController()); // إيجاد أو إنشاء مثيل للمتحكم
    final theme = Theme.of(context); // الحصول على بيانات الثيم الحالي
    final isDark = theme.brightness == Brightness.dark; // التحقق مما إذا كان الوضع الغامق مفعلاً

    final bool isMobile = // التحقق مما إذا كان الجهاز محمولاً وشاشته صغيرة
        (GetPlatform.isAndroid || GetPlatform.isIOS) &&
        MediaQuery.of(context).size.width < 600;

    return Scaffold( // إرجاع هيكل الصفحة الأساسي
      backgroundColor: isDark // تحديد لون الخلفية بناءً على الثيم
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8F9FD),
      appBar: isMobile // عرض شريط التطبيق العلوي فقط في الأجهزة المحمولة
          ? AppBar(
              title: Text( // عنوان الشاشة
                'holiday_management'.tr, // نص مترجم لإدارة الإجازات
                style: const TextStyle(
                  fontFamily: 'Cairo', // نوع الخط
                  fontWeight: FontWeight.bold, // خط عريض
                ),
              ),
              backgroundColor: theme.primaryColor, // لون خلفية شريط التطبيق
              centerTitle: true, // توسيط العنوان
              elevation: 0, // إلغاء الظل
            )
          : null, // لا يوجد شريط تطبيق في غير الأجهزة المحمولة

      floatingActionButton: FloatingActionButton.extended( // زر عائم لإضافة إجازة
        onPressed: () => _showHolidayFormDialog(context, controller), // فتح نافذة الإضافة عند الضغط
        label: Text( // نص الزر
          'add_holiday'.tr, // نص مترجم لإضافة إجازة
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.add), // أيقونة الإضافة
        backgroundColor: theme.primaryColor, // لون خلفية الزر
        foregroundColor: Colors.white, // لون محتوى الزر (أبيض)
        elevation: isDark ? 8 : 4, // ارتفاع الظل
        shape: RoundedRectangleBorder( // شكل حواف الزر
          borderRadius: BorderRadius.circular(16), // حواف دائرية
          side: BorderSide( // إطار خفيف للزر
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.1),
            width: 1,
          ),
        ),
      ),

      body: Column( // محتوى الصفحة داخل عمود
        children: [
          Expanded( // توسيع المحتوى ليأخذ المساحة المتاحة
            child: Obx(() { // استخدام Obx لمراقبة التغييرات في بيانات المتحكم
              if (controller.isLoading.value) { // عرض مؤشر تحميل إذا كانت البيانات قيد الجلب
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.holidays; // الحصول على قائمة الإجازات

              if (list.isEmpty) { // عرض رسالة في حال خلو القائمة
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon( // أيقونة تعبر عن عدم وجود بيانات
                        Icons.event_busy,
                        size: 80,
                        color: theme.dividerColor,
                      ),
                      const SizedBox(height: 16),
                      Text( // نص "لا توجد بيانات"
                        'no_data'.tr,
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 18,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder( // بناء قائمة قابلة للتمرير
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: list.length, // عدد العناصر في القائمة
                itemBuilder: (context, index) {
                  final holiday = list[index]; // بيانات الإجازة الحالية
                  final bool isRecurring = holiday.dayOfWeek != null; // هل الإجازة متكررة أسبوعياً؟

                  return Container( // حاوية لكل عنصر في القائمة
                    margin: const EdgeInsets.only(bottom: 12), // مسافة من الأسفل
                    decoration: BoxDecoration( // تصميم الحاوية
                      color: theme.cardColor, // لون الخلفية
                      borderRadius: BorderRadius.circular(16), // حواف دائرية
                      border: Border.all( // إطار للحاوية
                        color: isDark
                            ? theme.dividerColor
                            : theme.dividerColor.withValues(alpha: 0.1),
                      ),
                      boxShadow: [ // ظل للحاوية
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile( // عنصر قائمة قياسي
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      onTap: () => _showHolidayFormDialog( // فتح نافذة التعديل عند الضغط
                        context,
                        controller,
                        holiday: holiday,
                      ),
                      leading: CircleAvatar( // أيقونة في بداية العنصر
                        backgroundColor:
                            (isRecurring ? Colors.orange : theme.primaryColor)
                                .withValues(alpha: 0.1),
                        child: Icon( // الأيقونة المناسبة لنوع الإجازة
                          isRecurring ? Icons.repeat : Icons.calendar_today,
                          color: isRecurring
                              ? Colors.orange
                              : theme.primaryColor,
                        ),
                      ),
                      title: Text( // عنوان العنصر (سبب الإجازة)
                        holiday.reason,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      subtitle: Padding( // تفاصيل إضافية تحت العنوان
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          // عرض نص التاريخ بناءً على نوع الإجازة
                          isRecurring
                              ? '${'recurring_holiday'.tr}: ${_getDayName(holiday.dayOfWeek!)}'
                              : holiday.endDate != null
                              ? '${'range_holiday'.tr}: ${DateFormat('yyyy-MM-dd').format(holiday.date!)} - ${DateFormat('yyyy-MM-dd').format(holiday.endDate!)}'
                              : '${'date_holiday'.tr}: ${DateFormat('yyyy-MM-dd').format(holiday.date!)}',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: Row( // أزرار في نهاية العنصر
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton( // زر التعديل
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => _showHolidayFormDialog(
                              context,
                              controller,
                              holiday: holiday,
                            ),
                          ),
                          IconButton( // زر الحذف
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, controller, holiday),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) { // دالة لتحويل رقم اليوم إلى اسمه المترجم
    switch (day) {
      case 1:
        return 'monday'.tr;
      case 2:
        return 'tuesday'.tr;
      case 3:
        return 'wednesday'.tr;
      case 4:
        return 'thursday'.tr;
      case 5:
        return 'friday'.tr;
      case 6:
        return 'saturday'.tr;
      case 7:
        return 'sunday'.tr;
      default:
        return '';
    }
  }

  void _confirmDelete( // دالة لعرض نافذة تأكيد الحذف
    BuildContext context,
    HolidayController controller,
    HolidayModel holiday,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Get.dialog( // عرض نافذة حوار
      AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text( // عنوان نافذة التأكيد
          'confirm_delete'.tr,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text( // نص رسالة التأكيد
          '${'delete_confirm_msg'.tr} ${holiday.reason}?',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [ // أزرار العمليات
          TextButton( // زر الإلغاء
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton( // زر الحذف
            onPressed: () {
              controller.deleteHoliday(holiday.id!); // استدعاء دالة الحذف من المتحكم
              Get.back(); // العودة للخلف
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.red.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.0),
                ),
              ),
            ),
            child: Text(
              'delete'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHolidayFormDialog( // دالة لعرض نافذة إضافة أو تعديل الإجازة
    BuildContext context,
    HolidayController controller, {
    HolidayModel? holiday,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isEdit = holiday != null; // هل هي عملية تعديل؟
    final reasonController = TextEditingController(text: holiday?.reason ?? ''); // متحكم نص السبب
    DateTime? selectedDate = holiday?.date; // التاريخ المختار
    DateTime? selectedEndDate = holiday?.endDate; // تاريخ النهاية المختار
    int? selectedDayOfWeek = holiday?.dayOfWeek; // اليوم الأسبوعي المختار
    RxString type = (holiday?.dayOfWeek != null ? 'recurring' : 'date').obs; // نوع الإجازة المختار

    Get.dialog( // عرض نافذة الحوار
      Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // تحديد أقصى عرض للنافذة
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( // عنوان النافذة بناءً على الحالة
                    isEdit ? 'edit'.tr : 'add_holiday'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField( // حقل نصي لإدخال السبب
                    controller: reasonController,
                    style: const TextStyle(fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      labelText: 'plan_details'.tr,
                      labelStyle: TextStyle(color: theme.hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx( // مراقبة اختيار نوع الإجازة
                    () => Column(
                      children: [
                        RadioListTile<String>( // خيار إجازة بتاريخ محدد
                          title: Text(
                            'date_holiday'.tr,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          value: 'date',
                          activeColor: theme.primaryColor,
                          groupValue: type.value,
                          onChanged: (val) => type.value = val!,
                        ),
                        RadioListTile<String>( // خيار إجازة متكررة
                          title: Text(
                            'recurring_holiday'.tr,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          value: 'recurring',
                          activeColor: theme.primaryColor,
                          groupValue: type.value,
                          onChanged: (val) => type.value = val!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() { // عرض حقول الإدخال بناءً على النوع المختار
                    if (type.value == 'date') {
                      return StatefulBuilder(
                        builder: (context, setState) => Column(
                          children: [
                            ListTile( // حقل اختيار تاريخ البداية
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                selectedDate == null
                                    ? 'start_date'.tr
                                    : DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedDate!),
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              trailing: Icon(
                                Icons.calendar_month,
                                color: theme.primaryColor,
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => selectedDate = date);
                                }
                              },
                            ),
                            ListTile( // حقل اختيار تاريخ النهاية (اختياري)
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                selectedEndDate == null
                                    ? 'end_date'.tr
                                    : DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedEndDate!),
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              subtitle: Text( // نص توضيحي
                                'optional_for_range'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Cairo',
                                  color: theme.hintColor,
                                ),
                              ),
                              trailing: Icon(
                                Icons.calendar_month,
                                color: theme.primaryColor,
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      selectedEndDate ??
                                      selectedDate ??
                                      DateTime.now(),
                                  firstDate: selectedDate ?? DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() => selectedEndDate = date);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      return StatefulBuilder( // حقل اختيار اليوم للأسبوعي
                        builder: (context, setState) =>
                            DropdownButtonFormField<int>(
                              dropdownColor: theme.cardColor,
                              decoration: InputDecoration(
                                labelText: 'select_day'.tr,
                                labelStyle: TextStyle(color: theme.hintColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              value: selectedDayOfWeek,
                              items: List.generate(7, (index) {
                                int dayNum = index + 1;
                                return DropdownMenuItem(
                                  value: dayNum,
                                  child: Text(
                                    _getDayName(dayNum),
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                );
                              }),
                              onChanged: (val) =>
                                  setState(() => selectedDayOfWeek = val),
                            ),
                      );
                    }
                  }),
                  const SizedBox(height: 30),
                  SizedBox( // زر الحفظ النهائي
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.isEmpty) return; // عدم الحفظ إذا كان السبب فارغاً
                        final updatedHoliday = HolidayModel( // إنشاء كائن الإجازة الجديد أو المحدث
                          id: holiday?.id,
                          reason: reasonController.text,
                          date: type.value == 'date' ? selectedDate : null,
                          endDate: type.value == 'date' ? selectedEndDate : null,
                          dayOfWeek: type.value == 'recurring'
                              ? selectedDayOfWeek
                              : null,
                        );
                        if (isEdit) { // استدعاء الدالة المناسبة (تحديث أو إضافة)
                          controller.updateHoliday(updatedHoliday);
                        } else {
                          controller.addHoliday(updatedHoliday);
                        }
                        Get.back(); // العودة للخلف
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 6,
                        shadowColor: theme.primaryColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide( // إطار خفيف للزر
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.2 : 0.0,
                            ),
                          ),
                        ),
                      ),
                      child: Text( // نص الزر بناءً على الحالة
                        isEdit ? 'save'.tr : 'add'.tr,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
