import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// ويدجت مخصص لتغليف أي عنصر تفاعلي بخاصية الإرشاد والتوجيه (Showcase)
/// بنمط متناسق مع لغة التطبيق (العربية - خط القاهرة) وألوان الهوية.
class CustomShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final ShapeBorder targetShapeBorder;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;
  final VoidCallback? onTargetClick;

  const CustomShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.targetShapeBorder = const CircleBorder(),
    this.targetPadding = const EdgeInsets.all(6.0),
    this.tooltipPosition,
    this.onTargetClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      targetPadding: targetPadding,
      targetBorderRadius: BorderRadius.circular(100),
      tooltipPosition: tooltipPosition,
      onTargetClick: () {
        if (onTargetClick != null) {
          onTargetClick!();
        } else {
          ShowCaseWidget.of(context).next();
        }
      },
      disposeOnTap: false,
      disableDefaultTargetGestures: false,
      tooltipBackgroundColor: isDark
          ? const Color(0xFF2C2C2E)
          : primaryColor,
      textColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.amberAccent,
      ),
      descTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        height: 1.4,
        color: Colors.white,
      ),
      child: child,
    );
  }
}
