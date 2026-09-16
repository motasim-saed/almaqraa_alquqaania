import 'package:flutter/material.dart';

// ويدجت مخصصة لعرض شريحة فلترة اختيارية - FilterChipWidget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          // اللون الأبيض للنص عند الاختيار، واللون الافتراضي للنص (يتغير حسب الثيم) عند عدم الاختيار
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, 
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      // استخدام اللون الأساسي من الثيم عند الاختيار
      selectedColor: Theme.of(context).primaryColor,
      // استخدام لون التقسيم مع شفافية بسيطة في الخلفية عند عدم الاختيار
      backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      // إزالة الإطار الافتراضي أو جعله خفيفاً جداً
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
