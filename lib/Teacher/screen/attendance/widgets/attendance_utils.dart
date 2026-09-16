import 'package:flutter/material.dart'; // استيراد حزمة فلاتر الأساسية لتصميم الواجهة
import 'package:get/get.dart'; // استيراد حزمة GetX للترجمة وإدارة الحالة
import '../../../models/daily_attendance_record_model.dart'; // استيراد نموذج سجل الحضور اليومي لاستخدام نوع البيانات (AttendanceStatus)

/// فئة تحتوي على أدوات مساعدة للتعامل مع رموز وألوان حالة الحضور.
class AttendanceUtils {
  
  /// دالة للحصول على الأيقونة المناسبة لكل حالة حضور.
  static IconData getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle; // أيقونة الصح للحضور
      case AttendanceStatus.absent:
        return Icons.remove_circle_outline; // أيقونة الغياب
      case AttendanceStatus.excused:
        return Icons.info; // أيقونة المستأذن
      case AttendanceStatus.holiday:
        return Icons.event_note; // أيقونة الإجازة
    }
  }

  /// دالة للحصول على النص المترجم لكل حالة حضور.
  static String getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'present'.tr;
      case AttendanceStatus.absent:
        return 'absent'.tr;
      case AttendanceStatus.excused:
        return 'excused'.tr;
      case AttendanceStatus.holiday:
        return 'holiday'.tr;
    }
  }

  /// دالة للحصول على اللون المميز لكل حالة حضور.
  static Color getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.excused:
        return Colors.yellow[700]!;
      case AttendanceStatus.holiday:
        return Colors.purple;
    }
  }

  /// دالة لتحويل النص المستلم إلى نوع الحالة البرمجي (Enum).
  static AttendanceStatus parseStatus(String? status) {
    if (status == null) return AttendanceStatus.present;
    switch (status.toLowerCase()) {
      case 'absent':
      case 'غائب':
      case 'غ':
      case 'danger':
        return AttendanceStatus.absent;
      case 'excused':
      case 'مستأذن':
      case 'م':
        return AttendanceStatus.excused;
      case 'holiday':
      case 'إجازة':
      case 'ج':
        return AttendanceStatus.holiday;
      case 'present':
      case 'حاضر':
      case 'ح':
      default:
        return AttendanceStatus.present;
    }
  }

  /// دالة لبناء وسم (Badge) متكامل يحتوي على الأيقونة والنص الملون.
  /// تم التعديل: إذا كان "حاضر" يظهر الصح فقط بدون نص، الباقي يظهر النص معه.
  static Widget buildAttendanceBadge(String statusString) {
    final status = parseStatus(statusString);
    final isPresent = status == AttendanceStatus.present;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(getStatusIcon(status), size: 18, color: getStatusColor(status)),
        // لا يظهر النص إذا كانت الحالة حضور
        if (!isPresent) ...[
          const SizedBox(width: 4),
          Text(
            getStatusLabel(status),
            style: TextStyle(
              color: getStatusColor(status),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
