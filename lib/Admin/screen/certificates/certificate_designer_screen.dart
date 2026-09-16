import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/certificates/certificates_controller.dart';

// شاشة تصميم الشهادات (CertificateDesignerScreen)
class CertificateDesignerScreen extends StatefulWidget {
  final CertificateTemplate template;

  const CertificateDesignerScreen({super.key, required this.template});

  @override
  State<CertificateDesignerScreen> createState() =>
      _CertificateDesignerScreenState();
}

class _CertificateDesignerScreenState extends State<CertificateDesignerScreen> {
  late double nameX, nameY, gradeX, gradeY;
  late double nameSize, gradeSize;
  late Color nameColor, gradeColor;
  
  final controller = Get.find<CertificatesController>();

  @override
  void initState() {
    super.initState();
    nameX = widget.template.nameX;
    nameY = widget.template.nameY;
    gradeX = widget.template.gradeX;
    gradeY = widget.template.gradeY;
    nameSize = widget.template.nameFontSize;
    gradeSize = widget.template.gradeFontSize;
    nameColor = widget.template.nameColor;
    gradeColor = widget.template.gradeColor;
  }

  void _save() {
    try {
      controller.updateTemplate(
        widget.template.id,
        nX: nameX,
        nY: nameY,
        gX: gradeX,
        gY: gradeY,
        nSize: nameSize,
        gSize: gradeSize,
        nColor: nameColor,
        gColor: gradeColor,
      );
      Get.back();
      Get.snackbar('success'.tr, 'design_saved_success'.tr, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, 'design_save_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('${'format'.tr}: ${widget.template.adminTitle}', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.titleLarge?.color,
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 1.414,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          if (widget.template.backgroundImagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(widget.template.backgroundImagePath!),
                                fit: BoxFit.fill,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                              ),
                            )
                          else
                            Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                ),
                                child: Center(child: Text('no_background_image'.tr, style: TextStyle(color: theme.hintColor)))
                            ),

                          Positioned(
                            left: nameX * constraints.maxWidth - 60,
                            top: nameY * constraints.maxHeight - 20,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: _buildText('sample_student_name'.tr, nameSize, nameColor),
                              ),
                              onDragEnd: (details) {
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localOffset = renderBox.globalToLocal(details.offset);
                                setState(() {
                                  nameX = (localOffset.dx + 60) / constraints.maxWidth;
                                  nameY = (localOffset.dy + 20) / constraints.maxHeight;
                                });
                              },
                              child: _buildText('sample_student_name'.tr, nameSize, nameColor, moving: true),
                            ),
                          ),

                          Positioned(
                            left: gradeX * constraints.maxWidth - 40,
                            top: gradeY * constraints.maxHeight - 15,
                            child: Draggable(
                              feedback: Material(
                                color: Colors.transparent,
                                child: _buildText('95', gradeSize, gradeColor),
                              ),
                              onDragEnd: (details) {
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localOffset = renderBox.globalToLocal(details.offset);
                                setState(() {
                                  gradeX = (localOffset.dx + 40) / constraints.maxWidth;
                                  gradeY = (localOffset.dy + 15) / constraints.maxHeight;
                                });
                              },
                              child: _buildText('95', gradeSize, gradeColor, moving: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildControls(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildText(String t, double s, Color c, {bool moving = false}) {
    return Container(
      decoration: moving
          ? BoxDecoration(border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1))
          : null,
      child: Text(
        t,
        style: TextStyle(
          fontSize: s,
          color: c,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildSlider('name_font_size'.tr, nameSize, (v) => setState(() => nameSize = v), theme)),
              const SizedBox(width: 20),
              Expanded(child: _buildColorPicker('name_font_color'.tr, nameColor, (c) => setState(() => nameColor = c), theme)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSlider('grade_font_size'.tr, gradeSize, (v) => setState(() => gradeSize = v), theme)),
              const SizedBox(width: 20),
              Expanded(child: _buildColorPicker('grade_font_color'.tr, gradeColor, (c) => setState(() => gradeColor = c), theme)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(
                'designer_instruction'.tr,
                style: TextStyle(color: theme.hintColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, Function(double) onC, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: val,
            min: 20,
            max: 40,
            onChanged: onC,
            activeColor: theme.primaryColor,
            inactiveColor: theme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(String title, Color currentColor, Function(Color) onSelect, ThemeData theme) {
    final colors = [
      Colors.black, Colors.grey.shade800, Colors.white,
      Colors.indigo, Colors.blue, Colors.lightBlue,
      Colors.pink, Colors.red, Colors.orange,
      Colors.green, Colors.teal, Colors.amber,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) => GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentColor.toARGB32() == c.toARGB32() ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                  width: currentColor.toARGB32() == c.toARGB32() ? 2.5 : 1
                ),
                boxShadow: [
                  if (currentColor.toARGB32() == c.toARGB32())
                    BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 1)
                ],
              ),
              child: currentColor.toARGB32() == c.toARGB32() 
                ? Icon(Icons.check, size: 14, color: c == Colors.white ? Colors.black : Colors.white)
                : null,
            ),
          )).toList(),
        ),
      ],
    );
  }
}
