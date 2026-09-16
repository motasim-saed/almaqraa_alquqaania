import 'package:get/get.dart';
import '../../Admin/models/admin_models.dart';

class AppDateUtils {
  static int getDaysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  static String getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'saturday'.tr;
      case DateTime.sunday:
        return 'sunday'.tr;
      case DateTime.monday:
        return 'monday'.tr;
      case DateTime.tuesday:
        return 'tuesday'.tr;
      case DateTime.wednesday:
        return 'wednesday'.tr;
      case DateTime.thursday:
        return 'thursday'.tr;
      case DateTime.friday:
        return 'friday'.tr;
      default:
        return '';
    }
  }

  static String getShortDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'sat'.tr;
      case DateTime.sunday:
        return 'sun'.tr;
      case DateTime.monday:
        return 'mon'.tr;
      case DateTime.tuesday:
        return 'tue'.tr;
      case DateTime.wednesday:
        return 'wed'.tr;
      case DateTime.thursday:
        return 'thu'.tr;
      case DateTime.friday:
        return 'fri'.tr;
      default:
        return '';
    }
  }

  static bool isHoliday(DateTime date, List<HolidayModel> holidays) {
    // Normalize date to compare only year-month-day
    final checkDate = DateTime(date.year, date.month, date.day);

    for (var h in holidays) {
      if (h.date != null) {
        final startDate = DateTime(h.date!.year, h.date!.month, h.date!.day);

        if (h.endDate != null) {
          // Range holiday
          final endDate = DateTime(
            h.endDate!.year,
            h.endDate!.month,
            h.endDate!.day,
          );
          if ((checkDate.isAtSameMomentAs(startDate) ||
                  checkDate.isAfter(startDate)) &&
              (checkDate.isAtSameMomentAs(endDate) ||
                  checkDate.isBefore(endDate))) {
            return true;
          }
        } else {
          // Single day holiday
          if (checkDate.isAtSameMomentAs(startDate)) {
            return true;
          }
        }
      }

      // Check recurring weekday holidays
      if (h.dayOfWeek != null && h.dayOfWeek == date.weekday) {
        return true;
      }
    }
    return false;
  }
}
