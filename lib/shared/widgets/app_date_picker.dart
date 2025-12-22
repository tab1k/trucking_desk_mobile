import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  return _showCalendarSheet<DateTime>(
    context,
    title: title ?? tr('calendar.select_date'),
    initialStart: initialDate,
    firstAllowed: firstDate,
    lastAllowed: lastDate,
    pickRange: false,
  );
}

Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  return _showCalendarSheet<DateTimeRange>(
    context,
    title: title ?? tr('calendar.select_range'),
    initialStart: initialRange?.start,
    initialEnd: initialRange?.end,
    firstAllowed: firstDate,
    lastAllowed: lastDate,
    pickRange: true,
  );
}

Future<T?> _showCalendarSheet<T>(
  BuildContext context, {
  required String title,
  required bool pickRange,
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? firstAllowed,
  DateTime? lastAllowed,
}) {
  final now = DateTime.now();
  final first = firstAllowed ?? now.subtract(const Duration(days: 365));
  final last = lastAllowed ?? now.add(const Duration(days: 365));
  DateTime? tempStart = initialStart;
  DateTime? tempEnd = pickRange ? initialEnd : initialStart;
  DateTime displayedMonth = DateTime(
    (tempStart ?? now).year,
    (tempStart ?? now).month,
    1,
  );
  final locale = Localizations.localeOf(context).toLanguageTag();
  final weekdayLabels = _weekdayLabels(locale);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                void onDateSelected(DateTime date) {
                  setSheetState(() {
                    if (!pickRange) {
                      tempStart = date;
                      tempEnd = date;
                      return;
                    }
                    if (tempStart == null || tempEnd != null) {
                      tempStart = date;
                      tempEnd = null;
                    } else {
                      if (date.isBefore(tempStart!)) {
                        tempEnd = tempStart;
                        tempStart = date;
                      } else {
                        tempEnd = date;
                      }
                    }
                  });
                }

                void changeMonth(int offset) {
                  final candidate = DateTime(
                    displayedMonth.year,
                    displayedMonth.month + offset,
                    1,
                  );
                  if (candidate.isBefore(
                        DateTime(first.year, first.month, 1),
                      ) ||
                      candidate.isAfter(DateTime(last.year, last.month, 1))) {
                    return;
                  }
                  setSheetState(() => displayedMonth = candidate);
                }

                List<DateTime?> buildMonthDays(DateTime month) {
                  final firstDay = DateTime(month.year, month.month, 1);
                  final daysInMonth = DateUtils.getDaysInMonth(
                    month.year,
                    month.month,
                  );
                  final leading = (firstDay.weekday + 6) % 7;
                  final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
                  final result = <DateTime?>[];
                  for (var i = 0; i < leading; i++) {
                    result.add(null);
                  }
                  for (var day = 0; day < daysInMonth; day++) {
                    result.add(DateTime(month.year, month.month, day + 1));
                  }
                  while (result.length < totalCells) {
                    result.add(null);
                  }
                  return result;
                }

                bool isStart(DateTime date) =>
                    tempStart != null && DateUtils.isSameDay(tempStart, date);
                bool isEnd(DateTime date) =>
                    tempEnd != null && DateUtils.isSameDay(tempEnd, date);
                bool isInRange(DateTime date) {
                  if (tempStart == null || tempEnd == null) return false;
                  return !date.isBefore(tempStart!) && !date.isAfter(tempEnd!);
                }

                final monthDays = buildMonthDays(displayedMonth);
                final canConfirm =
                    tempStart != null &&
                    (!pickRange || (pickRange && tempEnd != null));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      tempStart != null && (tempEnd != null || !pickRange)
                          ? pickRange
                              ? '${_formatDate(tempStart!, locale)} — ${_formatDate(tempEnd ?? tempStart!, locale)}'
                              : _formatDate(tempStart!, locale)
                          : pickRange
                              ? tr('calendar.hint_range')
                              : tr('calendar.hint_single'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '${_monthLabel(displayedMonth.month, locale)} ${displayedMonth.year}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final label in weekdayLabels) Text(label),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Expanded(
                      child: GridView.builder(
                        itemCount: monthDays.length,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.1,
                            ),
                        itemBuilder: (context, index) {
                          final date = monthDays[index];
                          final isDisabled =
                              date == null ||
                              date.isBefore(first) ||
                              date.isAfter(last);
                          final selectedStart =
                              date != null && !isDisabled && isStart(date);
                          final selectedEnd =
                              date != null && !isDisabled && isEnd(date);
                          final withinRange =
                              date != null && !isDisabled && isInRange(date);

                          Color bgColor = Colors.transparent;
                          if (withinRange) bgColor = const Color(0xFFE3F2FD);
                          if (selectedStart || selectedEnd) {
                            bgColor = const Color(0xFF00B2FF);
                          }

                          return GestureDetector(
                            onTap:
                                isDisabled || date == null
                                    ? null
                                    : () => onDateSelected(date),
                            child: Container(
                              margin: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                date?.day.toString() ?? '',
                                style: TextStyle(
                                  color:
                                      isDisabled
                                          ? Colors.grey
                                          : (selectedStart || selectedEnd)
                                          ? Colors.white
                                          : Colors.black,
                                  fontWeight:
                                      (selectedStart || selectedEnd)
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempStart = null;
                              tempEnd = null;
                            });
                          },
                          child: Text(tr('calendar.clear')),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed:
                              canConfirm
                                  ? () {
                                    if (!pickRange) {
                                      Navigator.of(context).pop(tempStart);
                                    } else {
                                      Navigator.of(context).pop(
                                        DateTimeRange(
                                          start: tempStart!,
                                          end: tempEnd ?? tempStart!,
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B2FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(tr('calendar.confirm')),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

String _monthLabel(int month, String localeTag) {
  final date = DateTime(DateTime.now().year, month, 1);
  final formatted = DateFormat.MMMM(localeTag).format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

String _formatDate(DateTime date, String localeTag) {
  return DateFormat('dd MMM yyyy', localeTag).format(date);
}

List<String> _weekdayLabels(String localeTag) {
  final symbols = DateFormat.E(localeTag).dateSymbols;
  final weekdays = symbols.STANDALONENARROWWEEKDAYS;
  return [
    weekdays[1],
    weekdays[2],
    weekdays[3],
    weekdays[4],
    weekdays[5],
    weekdays[6],
    weekdays[0],
  ];
}
