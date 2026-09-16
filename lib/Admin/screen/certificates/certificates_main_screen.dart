import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/admin_models.dart';
import 'certificates_circles_tab.dart';
import 'certificates_settings_tab.dart';
import '../../controller/certificates/certificates_controller.dart';

class CertificatesMainScreen extends StatefulWidget {
  const CertificatesMainScreen({super.key});

  @override
  State<CertificatesMainScreen> createState() => _CertificatesMainScreenState();
}

class _CertificatesMainScreenState extends State<CertificatesMainScreen> with TickerProviderStateMixin {
  late TabController _genderTabController;
  late TabController _modeTabController;
  bool _isHeaderExpanded = false;
  final controller = Get.put(CertificatesController());

  @override
  void initState() {
    super.initState();
    _genderTabController = TabController(length: 2, vsync: this);
    _modeTabController = TabController(length: 2, vsync: this);
    
    _genderTabController.addListener(() => setState(() {}));
    _modeTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _genderTabController.dispose();
    _modeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildCollapseToggle(theme, isDark),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isHeaderExpanded ? 150 : 0,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _buildFullHeader(theme, isDark),
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _genderTabController,
              children: [
                _buildModeView(Gender.male),
                _buildModeView(Gender.female),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapseToggle(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _isHeaderExpanded = !_isHeaderExpanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'filter_options_and_templates'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13, 
                // تم تغيير اللون هنا ليناسب الثيم الغامق
                color: isDark ? Colors.white : theme.primaryColor,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isHeaderExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: isDark ? Colors.white70 : theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullHeader(ThemeData theme, bool isDark) {
    final unselectedColor = isDark ? Colors.white38 : theme.colorScheme.onSurface.withValues(alpha: 0.5);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          if (_isHeaderExpanded)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          // تبويبات البنين والبنات - تم تحسين الوضوح هنا
          TabBar(
            controller: _genderTabController,
            indicator: BoxDecoration(
              // لون خلفية التبويب المختار - جعلناه أكثر وضوحاً في الغامق
              color: isDark ? theme.primaryColor.withValues(alpha: 0.3) : theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? theme.primaryColor.withValues(alpha: 0.6) : theme.primaryColor.withValues(alpha: 0.3)
              ),
            ),
            dividerColor: Colors.transparent,
            labelColor: isDark ? Colors.white : theme.primaryColor,
            unselectedLabelColor: unselectedColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.male, size: 20), const SizedBox(width: 8), Text('boys_section'.tr)])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.female, size: 20), const SizedBox(width: 8), Text('girls_section'.tr)])),
            ],
          ),
          const SizedBox(height: 16),
          // تبويبات إصدار الشهادات والإعدادات
          TabBar(
            controller: _modeTabController,
            indicator: BoxDecoration(
              color: _genderTabController.index == 0 ? Colors.indigo : Colors.pink,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: unselectedColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.print, size: 18), const SizedBox(width: 8), Text('issue_certificates'.tr)])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.settings_suggest, size: 18), const SizedBox(width: 8), Text('template_settings'.tr)])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeView(Gender gender) {
    return TabBarView(
      controller: _modeTabController,
      children: [
        CertificatesCirclesTab(gender: gender),
        CertificatesSettingsTab(gender: gender),
      ],
    );
  }
}
