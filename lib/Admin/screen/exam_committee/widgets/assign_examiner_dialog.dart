import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import '../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import '../../../controller/quran_circles_controller.dart'; // استيراد متحكم الحلقات القرآنية
import '../../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين

// حوار تعيين مختبر - AssignExaminerDialog
// يتيح للمشرف اختيار معلم ليكون مختبراً لحلقة معينة
class AssignExaminerDialog extends StatefulWidget { 
  final QuranCircleModel circle; 
  const AssignExaminerDialog({super.key, required this.circle}); 

  @override
  State<AssignExaminerDialog> createState() => _AssignExaminerDialogState(); 
}

class _AssignExaminerDialogState extends State<AssignExaminerDialog> { 
  final _teachersController = Get.find<AcceptedTeachersController>(); 
  final _circlesController = Get.find<QuranCirclesController>(); 
  String? _selectedTeacherId; 

  @override
  void initState() { 
    super.initState(); 
    _selectedTeacherId = widget.circle.examinerId; 
  }

  @override
  Widget build(BuildContext context) { 
    final theme = Theme.of(context); // الحصول على بيانات الثيم الحالي
    final colorScheme = theme.colorScheme; // الحصول على مخطط الألوان

    final availableTeachers = _teachersController.acceptedTeachers.where((t) { 
      return t.gender == widget.circle.gender && 
          !widget.circle.teacherIds.contains(t.id); 
    }).toList(); 

    return Dialog( 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
      backgroundColor: theme.dialogBackgroundColor, // دعم خلفية الحوار حسب الثيم
      child: Container( 
        width: 450, 
        padding: const EdgeInsets.all(24), 
        child: Column( 
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            // عنوان الحوار بلون متوافق مع الثيم (Primary Color)
            Text( 
              'assign_examiner_to_circle'.tr, 
              style: TextStyle( 
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: colorScheme.primary, 
              ),
            ),
            const SizedBox(height: 8), 
            // وصف توضيحي بلون التلميح المتوافق مع الثيم
            Text( 
              '${'choose_examiner_for_circle'.tr} "${widget.circle.name}"', 
              style: TextStyle(color: theme.hintColor, fontSize: 14), 
            ),
            const Divider(height: 32), 
            
            ConstrainedBox( 
              constraints: const BoxConstraints(maxHeight: 300), 
              child: availableTeachers.isEmpty 
                  ? Center( 
                      child: Padding( 
                        padding: const EdgeInsets.all(16.0), 
                        child: Text( 
                          'no_available_examiners'.tr, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: colorScheme.error), // استخدام لون الخطأ من الثيم
                        ),
                      ),
                    )
                  : ListView.builder( 
                      shrinkWrap: true, 
                      itemCount: availableTeachers.length, 
                      itemBuilder: (context, index) { 
                        final t = availableTeachers[index]; 
                        return RadioListTile<String>( 
                          title: Text(
                            t.name,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          ), 
                          subtitle: Text(
                            t.specialization,
                            style: TextStyle(color: theme.hintColor),
                          ), 
                          activeColor: colorScheme.primary, // لون الاختيار من الثيم
                          value: t.id, 
                          groupValue: _selectedTeacherId, 
                          onChanged: (val) { 
                            setState(() => _selectedTeacherId = val); 
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24), 
            
            Row( 
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [ 
                TextButton( 
                  onPressed: () => Get.back(), 
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(color: theme.hintColor),
                  ), 
                ),
                const SizedBox(width: 12), 
                ElevatedButton( 
                  onPressed: _selectedTeacherId == null 
                      ? null 
                      : () { 
                          _circlesController.assignExaminer(
                            widget.circle.id, 
                            _selectedTeacherId, 
                          );
                          Get.back(); 
                        },
                  style: ElevatedButton.styleFrom( 
                    backgroundColor: colorScheme.primary, // اللون الرئيسي من الثيم
                    foregroundColor: colorScheme.onPrimary, // لون النص المتوافق مع الخلفية
                    disabledBackgroundColor: theme.disabledColor,
                    shape: RoundedRectangleBorder( 
                      borderRadius: BorderRadius.circular(10), 
                    ),
                  ),
                  child: Text('confirm_assignment'.tr), 
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
