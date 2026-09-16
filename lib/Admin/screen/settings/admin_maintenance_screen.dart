import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/settings/admin_settings_controller.dart';

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> {
  // استخدام Get.put لضمان وجود المتحكم فور فتح الشاشة وحل مشكلة "not found"
  final controller = Get.put(AdminSettingsController());
  
  String selectedTable = 'messages';
  int selectedYear = DateTime.now().year;
  int? selectedMonth;

  final List<Map<String, String>> cleanableTables = [
    {'name': 'المحادثات ورسائل الشات', 'id': 'messages'},
    {'name': 'سجلات الإنجاز اليومي', 'id': 'daily_records'},
    {'name': 'سجلات المتابعة الشهرية', 'id': 'monthly_records'},
    {'name': 'سجلات الاختبارات', 'id': 'monthly_exams'},
    {'name': 'الإشعارات المرسلة', 'id': 'notifications'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // تم إزالة Scaffold واستبداله بـ Material ليتناسب مع Layout الأدمن الأساسي
    return Material(
      color: Colors.transparent,
      child: Obx(() => Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildUsageStatsCards(isDarkMode),
              const SizedBox(height: 32),
              _buildMaintenanceActions(isDarkMode),
              const SizedBox(height: 32),
              _buildDataCleanupSection(isDarkMode),
            ],
          ),
          if (controller.isCleaning.value)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('جاري تنفيذ العملية...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }

  Widget _buildUsageStatsCards(bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // إذا كان العرض ضيقاً (أقل من 900 بكسل) نعرض الكروت تحت بعضها
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _buildStatItem('حجم قاعدة البيانات', controller.dbSize.value, Icons.storage_rounded, Colors.blue, isDarkMode),
              const SizedBox(height: 16),
              _buildStatItem('حجم الوسائط (Storage)', controller.storageSize.value, Icons.perm_media_rounded, Colors.orange, isDarkMode),
              const SizedBox(height: 16),
              _buildStatItem('استهلاك البيانات (Bandwidth)', controller.bandwidth.value, Icons.speed_rounded, Colors.green, isDarkMode),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: _buildStatItem('حجم قاعدة البيانات', controller.dbSize.value, Icons.storage_rounded, Colors.blue, isDarkMode)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatItem('حجم الوسائط (Storage)', controller.storageSize.value, Icons.perm_media_rounded, Colors.orange, isDarkMode)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatItem('استهلاك البيانات (Bandwidth)', controller.bandwidth.value, Icons.speed_rounded, Colors.green, isDarkMode)),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Flexible(child: Text(title, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceActions(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات الصيانة السريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.fetchUsageStats(),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث الإحصائيات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => controller.clearAllMedia(),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('تفريغ كافة الوسائط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => controller.clearAllPeriodRecords(),
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('تفريغ كافة السجلات والمحادثات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataCleanupSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cleaning_services_rounded, color: Colors.indigo),
              SizedBox(width: 12),
              Text(
                'تنظيف البيانات المجدولة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'قم باختيار نوع البيانات والفترة الزمنية لحذف السجلات القديمة لتخفيف ضغط قاعدة البيانات.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTableDropdown(),
                    const SizedBox(height: 16),
                    _buildYearDropdown(),
                    const SizedBox(height: 16),
                    _buildMonthDropdown(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildTableDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildYearDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMonthDropdown()),
                ],
              );
            }
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmDataCleanup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('بدء عملية التنظيف الآن'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedTable,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'نوع البيانات', border: OutlineInputBorder()),
      items: cleanableTables.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name']!))).toList(),
      onChanged: (val) => setState(() => selectedTable = val!),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedYear,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'السنة', border: OutlineInputBorder()),
      items: List.generate(5, (index) => DateTime.now().year - index)
          .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
          .toList(),
      onChanged: (val) => setState(() => selectedYear = val!),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int?>(
      value: selectedMonth,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'الشهر (اختياري)', border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text('السنة كاملة')),
        ...List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text((index + 1).toString()))),
      ],
      onChanged: (val) => setState(() => selectedMonth = val),
    );
  }

  void _confirmDataCleanup() {
    final tableName = cleanableTables.firstWhere((t) => t['id'] == selectedTable)['name'];
    Get.defaultDialog(
      title: "تأكيد الحذف",
      middleText: "سيتم حذف بيانات ($tableName) لعام $selectedYear ${selectedMonth != null ? 'شهر $selectedMonth' : ''}. هل أنت متأكد؟",
      textConfirm: "تأكيد",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteDataByDate(selectedTable, selectedYear, month: selectedMonth);
      },
    );
  }
}
