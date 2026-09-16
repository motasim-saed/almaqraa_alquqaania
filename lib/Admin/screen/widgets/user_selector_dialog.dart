import 'package:flutter/material.dart'; // استيراد مكتبة Flutter الأساسية لتصميم الواجهات
import 'package:get/get.dart'; // استيراد مكتبة GetX للإدارة والترجمة

// تعريف ويدجت عبارة عن نافذة حوار لاختيار المستخدمين
class UserSelectorDialog extends StatefulWidget {
  final List<dynamic> users; // قائمة تحتوي على بيانات المستخدمين
  final String title; // عنوان النافذة الذي سيظهر في الأعلى

  const UserSelectorDialog({
    super.key, // مفتاح السوبر للويدجت
    required this.users, // تمرير قائمة المستخدمين كمعامل مطلوب
    required this.title, // تمرير العنوان كمعامل مطلوب
  });

  @override
  State<UserSelectorDialog> createState() => _UserSelectorDialogState(); // إنشاء حالة الويدجت
}

// تعريف حالة نافذة حوار اختيار المستخدمين
class _UserSelectorDialogState extends State<UserSelectorDialog> {
  final Set<String> _selectedIds = {}; // مجموعة لتخزين المعرفات المختارة دون تكرار
  String _searchQuery = ''; // متغير لتخزين نص البحث المكتوب
  late List<dynamic> _filteredUsers; // قائمة المستخدمين بعد تطبيق الفلترة
  final ScrollController _scrollController = ScrollController(); // متحكم لعملية التمرير في القائمة

  @override
  void dispose() {
    _scrollController.dispose(); // التخلص من متحكم التمرير عند إغلاق النافذة
    super.dispose(); // استدعاء دالة dispose للأب
  }

  @override
  void initState() {
    super.initState(); // استدعاء دالة initState للأب
    _filteredUsers = widget.users; // تعيين القائمة المفلترة لتكون القائمة الكاملة عند البداية
  }

  // دالة لتحديث القائمة بناءً على نص البحث
  void _updateFilteredUsers() {
    setState(() {
      _filteredUsers = widget.users.where((u) {
        // التحقق من احتواء اسم المستخدم على نص البحث (مع تجاهل حالة الأحرف)
        return u.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList(); // تحويل النتيجة إلى قائمة
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // تحديد شكل النافذة وحوافها الدائرية
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.person_add_alt_1, color: Colors.indigo), // أيقونة إضافة شخص
          const SizedBox(width: 10), // مسافة أفقية
          Text(widget.title), // عرض عنوان النافذة
        ],
      ),
      content: SizedBox(
        width: 400, // عرض المحتوى
        height: 500, // ارتفاع المحتوى
        child: Column(
          children: [
            // حقل إدخال للبحث عن المستخدمين
            TextField(
              decoration: InputDecoration(
                hintText: 'search'.tr, // نص البحث مترجم
                prefixIcon: const Icon(Icons.search), // أيقونة البحث في البداية
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // حواف دائرية للحقل
                ),
              ),
              onChanged: (val) {
                _searchQuery = val; // تحديث قيمة البحث
                _updateFilteredUsers(); // استدعاء دالة التحديث
              },
            ),
            const SizedBox(height: 10), // مسافة رأسية
            Row(
              children: [
                // مربع اختيار لتحديد أو إلغاء تحديد الكل
                Checkbox(
                  value:
                      _selectedIds.length == widget.users.length &&
                      widget.users.isNotEmpty, // يكون مفعلاً إذا تم اختيار الجميع
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        // إضافة كافة المعرفات إلى مجموعة المختارين
                        _selectedIds.addAll(
                          widget.users.map((u) => u.id as String),
                        );
                      } else {
                        _selectedIds.clear(); // مسح كافة المختارين
                      }
                    });
                  },
                ),
                Text(
                  'select_all'.tr, // نص "تحديد الكل" مترجم
                  style: const TextStyle(fontWeight: FontWeight.bold), // خط عريض
                ),
                const Spacer(), // تباعد مرن لإزاحة النص التالي لليسار
                Text(
                  '${_selectedIds.length} / ${widget.users.length}', // عرض عدد المختارين من الإجمالي
                  style: TextStyle(color: Colors.grey[600], fontSize: 12), // تنسيق النص
                ),
              ],
            ),
            const Divider(), // خط فاصل أفقي
            Expanded(
              child: Scrollbar(
                controller: _scrollController, // ربط شريط التمرير بالمتحكم
                thumbVisibility: true, // جعل شريط التمرير مرئياً دائماً
                child: ListView.builder(
                  controller: _scrollController, // ربط القائمة بالمتحكم
                  primary: false, // تعطيل التمرير الأساسي التلقائي
                  itemCount: _filteredUsers.length, // عدد العناصر في القائمة المفلترة
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index]; // الحصول على المستخدم الحالي
                    final isSelected = _selectedIds.contains(user.id); // التحقق من حالة الاختيار
                    return CheckboxListTile(
                      title: Text(user.name), // عرض اسم المستخدم
                      subtitle: Text(user.academicNumber ?? ''), // عرض الرقم الأكاديمي إن وجد
                      value: isSelected, // حالة المربع (مختار أم لا)
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(user.id); // إضافة المستخدم للمختارين
                          } else {
                            _selectedIds.remove(user.id); // إزالة المستخدم من المختارين
                          }
                        });
                      },
                      activeColor: Colors.indigo, // لون المربع عند التفعيل
                      contentPadding: EdgeInsets.zero, // إلغاء الحواف الداخلية
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // زر الإلغاء لإغلاق النافذة دون حفظ
        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        // زر المتابعة لإغلاق النافذة وإعادة قائمة المعرفات المختارة
        ElevatedButton(
          onPressed: () => Get.back(result: _selectedIds.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo, // لون خلفية الزر
            foregroundColor: Colors.white, // لون نص الزر
          ),
          child: Text('next'.tr), // نص الزر مترجم
        ),
      ],
    );
  }
}
