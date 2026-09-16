import 'package:flutter/material.dart';

// زر إجراء التقرير - ReportActionButton
// زر مخصص يستخدم داخل بطاقة الحلقة لعرض أنواع مختلفة من التقارير بألوان وأيقونات مميزة
class ReportActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const ReportActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام لون مشتق مع شفافية بسيطة للخلفية ليعطي مظهراً عصرياً
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}
