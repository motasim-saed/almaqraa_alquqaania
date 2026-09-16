import 'package:flutter/material.dart'; // استيراد حزمة ماتيريال لتصميم واجهة المستخدم
import 'package:get/get.dart'; // استيراد حزمة GetX لإدارة الحالة والترجمة
import 'package:al_maqraa/core/controllers/global_batch_controller.dart';
import '../../../models/admin_models.dart'; // استيراد نماذج البيانات الخاصة بالمسؤول
import '../../../controller/quran_circles_controller.dart'; // استيراد متحكم الحلقات القرآنية
import '../../../controller/accepted/accepted_teachers_controller.dart'; // استيراد متحكم المعلمين المقبولين
import '../../../controller/accepted/accepted_students_controller.dart'; // استيراد متحكم الطلاب المقبولين
// import '../../../core/controllers/global_batch_controller.dart'; // استيراد متحكم الدفعات

// حوار إضافة/تعديل حلقة - AddCircleDialog (نسخة مطورة لسطح المكتب مع فلترة عمودية وإصلاح الأخطاء)
class AddCircleDialog extends StatefulWidget {
  final QuranCircleModel? circle; // كائن الحلقة في حال كان الطلب "تعديل"
  const AddCircleDialog({super.key, this.circle}); // منشئ الفئة

  @override
  State<AddCircleDialog> createState() => _AddCircleDialogState();
}

class _AddCircleDialogState extends State<AddCircleDialog> {
  // تعريف متحكمات حقول النصوص والبحث
  final _nameController = TextEditingController();
  final _teacherSearchController = TextEditingController();
  final _studentSearchController = TextEditingController();

  // قوائم لتخزين المختارين حالياً (استخدام RxList لضمان تحديث العدادات فوراً)
  final RxList<TeacherModel> _selectedTeachers = <TeacherModel>[].obs;
  final RxList<StudentModel> _selectedStudents = <StudentModel>[].obs;

  // متغيرات مراقبة لنصوص البحث والفئة العمرية المختار والجنس
  final _localGenderFilter = Rxn<Gender>(); // استخدام Rxn لدعم القيم الخالية
  final _teacherSearchQuery = "".obs;
  final _studentSearchQuery = "".obs;
  final _selectedAgeCategory = "all".obs;
  final _selectedBatchNumber = Rxn<int>(); // رقم الدفعة المختار

  // جلب المتحكمات المسجلة
  final _teachersController = Get.find<AcceptedTeachersController>();
  final _studentsController = Get.find<AcceptedStudentsController>();
  final _circlesController = Get.find<QuranCirclesController>();
  final _globalBatchController = Get.find<GlobalBatchController>();

  bool get isEdit => widget.circle != null;

  @override
  void initState() {
    super.initState();
    // تهيئة البيانات عند الفتح
    if (isEdit) {
      _nameController.text = widget.circle!.name;
      // ربط المعلمين والطلاب الحاليين بالحلقة عند التعديل
      _selectedBatchNumber.value = widget.circle!.batchNumber;
      for (var id in widget.circle!.teacherIds) {
        final teacher = _teachersController.acceptedTeachers.firstWhereOrNull(
          (t) => t.id == id,
        );
        if (teacher != null) {
          _selectedTeachers.add(teacher);
          _localGenderFilter.value = teacher.gender;
        }
      }
      for (var id in widget.circle!.studentIds) {
        final student = _studentsController.acceptedStudents.firstWhereOrNull(
          (s) => s.id == id,
        );
        if (student != null) _selectedStudents.add(student);
      }
    } else {
      // تعيين الجنس الافتراضي عند الإضافة الجديدة والدفعة
      _localGenderFilter.value =
          _circlesController.selectedGenderFilter.value != Gender.all
          ? _circlesController.selectedGenderFilter.value
          : Gender.male;
      _selectedBatchNumber.value = _globalBatchController.selectedBatch.value;
    }
  }

  // دالة مساعدة لفلترة الطلاب بناءً على الفئة العمرية المختارة
  List<StudentModel> _getFilteredStudentsByAge(
    List<StudentModel> students,
    String category,
  ) {
    if (category == "all") return students;
    switch (category) {
      case 'unspecified':
        return students.where((s) => s.age == null || s.age == 0).toList();
      case '0-15':
        return students
            .where((s) => (s.age ?? 0) > 0 && (s.age ?? 0) <= 15)
            .toList();
      case '15-20':
        return students
            .where((s) => (s.age ?? 0) > 15 && (s.age ?? 0) <= 20)
            .toList();
      case '20-30':
        return students
            .where((s) => (s.age ?? 0) > 20 && (s.age ?? 0) <= 30)
            .toList();
      case '30-40':
        return students
            .where((s) => (s.age ?? 0) > 30 && (s.age ?? 0) <= 40)
            .toList();
      case '40-50':
        return students
            .where((s) => (s.age ?? 0) > 40 && (s.age ?? 0) <= 50)
            .toList();
      case '50+':
        return students.where((s) => (s.age ?? 0) > 50).toList();
      default:
        return students;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // تحديد العرض ليكون كبيراً ومناسباً لشاشات سطح المكتب
    double dialogWidth = MediaQuery.of(context).size.width * 0.9;
    if (dialogWidth > 1200) dialogWidth = 1200;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.indigoAccent.withValues(alpha: 0.3)
              : Colors.indigo.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
     backgroundColor: isDark
          ? Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface
          : Colors.white,
      child: Container(
        width: dialogWidth,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // الهيدر (العنوان وزر الإغلاق)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'edit_circle'.tr : 'add_new_circle'.tr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? theme.primaryColor : Colors.indigo,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await _teachersController.refreshData();
                        await _studentsController.refreshData();
                        Get.snackbar(
                          'success'.tr,
                          'data_refreshed'.tr,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.refresh, color: Colors.indigo),
                      tooltip: 'refresh_data'.tr,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // محتوى الحوار المنقسم لجانبين
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- الجانب الأيمن: إعدادات الحلقة والمعلمين ---
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            _nameController,
                            'circle_name'.tr,
                            Icons.edit,
                            isDark,
                            theme,
                          ),
                          const SizedBox(height: 24),
                          _buildBatchSelection(isDark, theme),
                          const SizedBox(height: 24),
                          if (!isEdit) _buildGenderSelection(isDark, theme),
                          const SizedBox(height: 24),
                          _buildTeacherSection(isDark, theme),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 48,
                    thickness: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),

                  // --- الجانب الأيسر: الطلاب والفلترة العمرية العمودية ---
                  Expanded(
                    flex: 5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // شريط الفئات العمرية (Navigation Sidebar)
                        _buildAgeFilterSidebar(isDark, theme),
                        VerticalDivider(
                          width: 24,
                          thickness: 0.5,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        // قائمة الطلاب المفلترة
                        Expanded(child: _buildStudentSection(isDark, theme)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // أزرار التحكم السفلية مع تجميد الزر عند التحميل
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => ElevatedButton(
                    onPressed: _circlesController.isLoading.value
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _circlesController.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'save'.tr : 'add'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بناء شريط الفلترة العمري الجانبي المحدث بالأعداد الحقيقية
  Widget _buildAgeFilterSidebar(bool isDark, ThemeData theme) {
    final categories = [
      {'key': 'all', 'label': 'all'.tr},
      {'key': 'unspecified', 'label': 'not_specified'.tr},
      {'key': '0-15', 'label': '0 - 15'},
      {'key': '15-20', 'label': '15 - 20'},
      {'key': '20-30', 'label': '20 - 30'},
      {'key': '30-40', 'label': '30 - 40'},
      {'key': '40-50', 'label': '40 - 50'},
      {'key': '50+', 'label': '50+'},
    ];

    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'age_range'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              // جلب قائمة الطلاب المتاحة حالياً لحساب الأعداد لكل فئة في الشريط الجانبي
              final query = _studentSearchQuery.value.toLowerCase();
              final gender = _localGenderFilter.value;
              final batch = _selectedBatchNumber.value;
              final baseStudents = _studentsController.acceptedStudents.where((
                s,
              ) {
                bool matchesGender = gender == null || s.gender == gender;
                bool matchesSearch = s.name.toLowerCase().contains(query);
                bool matchesBatch = batch == null || s.batchNumber == batch;
                bool isCurrent =
                    isEdit && widget.circle!.studentIds.contains(s.id);
                return matchesGender &&
                    matchesSearch &&
                    matchesBatch &&
                    (isCurrent || !s.isDistributed);
              }).toList();

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedAgeCategory.value == cat['key'];
                  final count = _getFilteredStudentsByAge(
                    baseStudents,
                    cat['key']!,
                  ).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => _selectedAgeCategory.value = cat['key']!,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            // عرض عدد الطلاب المنتمين لهذه الفئة
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.indigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  // بناء قسم المعلمين
  Widget _buildTeacherSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_teachers'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildSearchField(
          _teacherSearchController,
          (v) => _teacherSearchQuery.value = v,
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        Obx(() {
          final query = _teacherSearchQuery.value.toLowerCase();
          final gender = _localGenderFilter.value;
          final batch = _selectedBatchNumber.value;
          final teachers = _teachersController.acceptedTeachers.where((t) {
            bool matchesGender = gender == null || t.gender == gender;
            bool matchesSearch = t.name.toLowerCase().contains(query);
            bool matchesBatch = batch == null || t.batchNumber == batch;
            bool isCurrent = isEdit && widget.circle!.teacherIds.contains(t.id);
            bool isAvailable = !_circlesController.assignedTeacherIds.contains(
              t.id,
            );
            return matchesGender &&
                matchesSearch &&
                matchesBatch &&
                (isCurrent || isAvailable);
          }).toList();

          return Container(
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              itemCount: teachers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final t = teachers[index];
                return Obx(() {
                  final isSelected = _selectedTeachers.any((s) => s.id == t.id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(
                      t.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "${'specialization'.tr}: ${t.specialization} | ${'age'.tr}: ${t.age ?? '?'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    onChanged: (val) {
                      if (val == true) {
                        _selectedTeachers.add(t);
                      } else {
                        _selectedTeachers.removeWhere((s) => s.id == t.id);
                      }
                    },
                  );
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // بناء قسم الطلاب مع العداد المختار المحدث تفاعلياً
  Widget _buildStudentSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'select_students'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            // تحديث العداد المختار باستخدام Obx و RxList المختار
            Obx(
              () => Text(
                "${'count'.tr}: ${_selectedStudents.length}",
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchField(
          _studentSearchController,
          (v) => _studentSearchQuery.value = v,
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            final query = _studentSearchQuery.value.toLowerCase();
            final gender = _localGenderFilter.value;
            final ageCat = _selectedAgeCategory.value;
            final batch = _selectedBatchNumber.value;

            // الفلترة الأساسية للطلاب
            final baseStudents = _studentsController.acceptedStudents.where((
              s,
            ) {
              bool matchesGender = gender == null || s.gender == gender;
              bool matchesSearch = s.name.toLowerCase().contains(query);
              bool matchesBatch = batch == null || s.batchNumber == batch;
              bool isCurrent =
                  isEdit && widget.circle!.studentIds.contains(s.id);
              return matchesGender &&
                  matchesSearch &&
                  matchesBatch &&
                  (isCurrent || !s.isDistributed);
            }).toList();

            // الفلترة العمرية الموجهة
            final filteredStudents = _getFilteredStudentsByAge(
              baseStudents,
              ageCat,
            );

            if (filteredStudents.isEmpty) {
              return Center(
                child: Text(
                  'no_students_found'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                itemCount: filteredStudents.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final s = filteredStudents[index];
                  return Obx(() {
                    final isSelected = _selectedStudents.any(
                      (selected) => selected.id == s.id,
                    );
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "${'level'.tr}: ${s.level} | ${'age'.tr}: ${s.age ?? '?'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      onChanged: (val) {
                        if (val == true) {
                          _selectedStudents.add(s);
                        } else {
                          _selectedStudents.removeWhere(
                            (selected) => selected.id == s.id,
                          );
                        }
                      },
                    );
                  });
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // بناء حقل نصي بسيط يدعم الثيم
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark,
    ThemeData theme,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.indigo),
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: isDark ? theme.cardColor : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide(color: Colors.grey[700]!)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide(color: Colors.grey[700]!)
              : BorderSide.none,
        ),
      ),
    );
  }

  // اختيار الجنس يدعم الثيم
  Widget _buildGenderSelection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'circle_gender'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              _buildGenderRadio(Gender.male, 'male'.tr, isDark),
              const SizedBox(width: 20),
              _buildGenderRadio(Gender.female, 'female'.tr, isDark),
            ],
          ),
        ),
      ],
    );
  }

  // بناء اختيار الدفعة
  Widget _buildBatchSelection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'batch'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final batches = _globalBatchController.availableBatches;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.transparent,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedBatchNumber.value,
                isExpanded: true,
                dropdownColor: isDark
                    ? theme.dialogBackgroundColor
                    : Colors.white,
                hint: Text(
                  'select_batch'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
                items: batches.map((batch) {
                  return DropdownMenuItem<int>(
                    value: batch,
                    child: Text(
                      '${'batch'.tr} $batch',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && _selectedBatchNumber.value != val) {
                    _selectedBatchNumber.value = val;
                    _selectedTeachers.clear();
                    _selectedStudents.clear();
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGenderRadio(Gender value, String label, bool isDark) {
    return InkWell(
      onTap: () {
        _localGenderFilter.value = value;
        _selectedTeachers.clear();
        _selectedStudents.clear();
      },
      child: Row(
        children: [
          Radio<Gender>(
            value: value,
            groupValue: _localGenderFilter.value,
            activeColor: Colors.indigo,
            onChanged: (val) {
              if (val != null) {
                _localGenderFilter.value = val;
                _selectedTeachers.clear();
                _selectedStudents.clear();
              }
            },
          ),
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController controller,
    Function(String) onChanged,
    bool isDark,
    ThemeData theme,
  ) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: 'search_contacts'.tr,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.indigo),
        isDense: true,
        filled: true,
        fillColor: isDark ? theme.cardColor : Colors.transparent,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty ||
        _selectedTeachers.isEmpty ||
        _selectedStudents.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'fill_all_fields'.tr,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedBatchNumber.value == null) {
      Get.snackbar(
        'warning'.tr,
        'please_select_batch'.tr,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    try {
      if (isEdit) {
        _circlesController.updateQuranCircle(
          circleId: widget.circle!.id,
          name: _nameController.text.trim(),
          teachers: _selectedTeachers,
          students: _selectedStudents,
          batchNumber: _selectedBatchNumber.value!,
        );
      } else {
        _circlesController.addQuranCircle(
          name: _nameController.text.trim(),
          teachers: _selectedTeachers,
          students: _selectedStudents,
          batchNumber: _selectedBatchNumber.value!,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'error_occurred'.tr}: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
