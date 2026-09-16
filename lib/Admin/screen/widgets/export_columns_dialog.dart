import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة

// نافذة تحديد أعمدة التصدير - ExportColumnsDialog
// تُستخدم هذه النافذة عند رغبة المسؤول في تصدير بيانات (مثل قائمة الطلاب أو المعلمين) إلى ملف Excel
// تتيح للمسؤول اختيار الأعمدة المحددة التي يريد تضمينها في الملف المصدر.
class ExportColumnsDialog extends StatefulWidget {
  final Map<String, String> availableColumns; // خريطة تحتوي على مفاتيح الأعمدة وقيمها (العناوين)
  final String? title; // عنوان النافذة (اختياري)

  const ExportColumnsDialog({
    super.key,
    required this.availableColumns,
    this.title,
  });

  @override
  State<ExportColumnsDialog> createState() => _ExportColumnsDialogState();
}

class _ExportColumnsDialogState extends State<ExportColumnsDialog> {
  late Map<String, bool> _selectedColumns; // تخزين حالة اختيار كل عمود (مختار أم لا)
  final ScrollController _scrollController = ScrollController(); // متحكم التمرير للقائمة

  @override
  void dispose() {
    _scrollController.dispose(); // تنظيف متحكم التمرير عند إغلاق النافذة
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // تهيئة جميع الأعمدة لتكون مختارة بشكل افتراضي عند فتح النافذة
    _selectedColumns = {
      for (var key in widget.availableColumns.keys) key: true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // عرض العنوان الممرر أو العنوان الافتراضي المترجم
      title: Text(widget.title ?? 'select_columns_to_export'.tr),
      content: SizedBox(
        width: double.maxFinite, // جعل العرض يأخذ أقصى مساحة متاحة في التنبيه
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true, // إظهار شريط التمرير دائماً
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min, // تقليص حجم العمود حسب المحتوى
              children: widget.availableColumns.entries.map((entry) {
                // بناء عنصر اختيار (Checkbox) لكل عمود متاح
                return CheckboxListTile(
                  title: Text(entry.value), // اسم العمود (مثلاً: الاسم، الهاتف)
                  value: _selectedColumns[entry.key], // حالة الاختيار الحالية
                  activeColor: Colors.indigo, // لون الاختيار عند التفعيل
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedColumns[entry.key] = value ?? false; // تحديث حالة الاختيار
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
      actions: [
        // زر الإلغاء
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        // زر التصدير
        ElevatedButton(
          onPressed: () {
            // جلب المفاتيح المختارة فقط (التي قيمتها true)
            final selectedKeys = _selectedColumns.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();

            // التأكد من اختيار عمود واحد على الأقل قبل المتابعة
            if (selectedKeys.isEmpty) {
              Get.snackbar('alert'.tr, 'select_at_least_one_column'.tr);
              return;
            }
            // إغلاق النافذة وإعادة قائمة الأعمدة المختارة للجهة المستدعية
            Get.back(result: selectedKeys);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo, // لون الزر الأساسي
            foregroundColor: Colors.white, // لون نص الزر
          ),
          child: Text('export'.tr), // نص "تصدير" مترجم
        ),
      ],
    );
  }
}
