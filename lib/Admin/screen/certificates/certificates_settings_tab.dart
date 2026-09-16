import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/certificates/certificates_controller.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/admin_models.dart';
import 'certificate_designer_screen.dart';
import '../../../core/services/certificate_service.dart';
import 'certificate_preview_screen.dart';

class CertificatesSettingsTab extends StatelessWidget {
  final Gender gender;

  const CertificatesSettingsTab({super.key, required this.gender});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CertificatesController>();
    final color = gender == Gender.male ? Colors.indigo : Colors.pink;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        Text(
           gender == Gender.male ? 'boys_template_settings'.tr : 'girls_template_settings'.tr, 
           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)
        ),
        const SizedBox(height: 8),
        Text(
          'customize_cert_design_msg'.tr, 
          style: TextStyle(color: theme.hintColor, fontSize: 13)
        ),
        const SizedBox(height: 24),
        _buildGenderSection(context, controller, gender, color, isDark),
      ],
    );
  }

  Widget _buildGenderSection(BuildContext context, CertificatesController controller, Gender gender, Color color, bool isDark) {
    final theme = Theme.of(context);
    final title = gender == Gender.male ? 'boys_templates'.tr : 'girls_templates'.tr;
    final icon = gender == Gender.male ? Icons.male : Icons.female;

    return Obx(() {
      final genderTemplates = controller.templates.where((t) => t.gender == gender).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => controller.addTemplate(gender),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('add_template'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (genderTemplates.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1))
              ),
              child: Center(child: Text('no_templates_yet'.tr, style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold))),
            )
          else
            ...genderTemplates.map((template) => _buildTemplateCard(context, controller, template, color, isDark)),
        ],
      );
    });
  }

  Widget _buildTemplateCard(BuildContext context, CertificatesController controller, CertificateTemplate template, Color themeColor, bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: isDark ? 0 : 0.5,
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.15))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: isDark ? 0.05 : 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.style_rounded, color: themeColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none, 
                      hintText: 'template_name_hint'.tr, 
                      isDense: true, 
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(color: theme.hintColor),
                    ),
                    style: TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    controller: TextEditingController(text: template.adminTitle),
                    onSubmitted: (val) => controller.updateTemplate(template.id, adminTitle: val),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeTemplate(template.id),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'delete_template'.tr,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : theme.scaffoldBackgroundColor.withValues(alpha: 0.8), 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: isDark ? theme.dividerColor : theme.dividerColor.withValues(alpha: 0.1))
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: theme.hintColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'grade_range_for_template'.tr, 
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const Spacer(),
                      _buildSmallInput(context, template.minGrade.toString(), (val) => controller.updateTemplate(template.id, minGrade: int.tryParse(val))),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      _buildSmallInput(context, template.maxGrade.toString(), (val) => controller.updateTemplate(template.id, maxGrade: int.tryParse(val))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (template.backgroundImagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          File(template.backgroundImagePath!),
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(controller, template.id),
                        icon: const Icon(Icons.image_outlined, size: 16),
                        label: Text(template.backgroundImagePath == null ? 'upload_design'.tr : 'change_design'.tr, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => CertificateDesignerScreen(template: template)),
                        icon: const Icon(Icons.design_services_rounded, size: 16),
                        label: Text('text_positions'.tr, style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final pdfFuture = CertificateService.generateCertificatePdf(
                            studentName: 'sample_student_name'.tr,
                            finalResult: 99,
                            template: template,
                          );
                          Get.to(() => CertificatePreviewScreen(
                            pdfFuture: pdfFuture,
                            title: 'preview_template'.tr,
                          ));
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: Text('preview_pdf'.tr, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInput(BuildContext context, String initialValue, Function(String) onSubmitted) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 45,
      height: 32,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 13,
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
          filled: true,
          fillColor: theme.cardColor,
        ),
        controller: TextEditingController(text: initialValue),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Future<void> _pickImage(CertificatesController controller, String templateId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      controller.updateTemplate(templateId, bgPath: image.path);
    }
  }
}
