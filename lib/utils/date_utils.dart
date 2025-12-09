
/// 하루의 시작 시간을 고려한 날짜 계산
/// 예: 하루 시작이 오전 6시라면, 2024-01-01 05:00은 2023-12-31로 계산됨
DateTime getDateKey(DateTime dateTime, int dayStartHour) {
  DateTime adjusted;
  
  if (dateTime.hour < dayStartHour) {
    // 하루 시작 시간 이전이면 전날로 간주
    adjusted = dateTime.subtract(const Duration(days: 1));
  } else {
    adjusted = dateTime;
  }
  
  return DateTime(adjusted.year, adjusted.month, adjusted.day);
}

/// 현재 날짜 키 가져오기 (하루 시작 시간 고려)
DateTime getTodayKey(int dayStartHour) {
  return getDateKey(DateTime.now(), dayStartHour);
}

/// 두 날짜가 같은 날인지 확인 (하루 시작 시간 고려)
bool isSameDay(DateTime date1, DateTime date2, int dayStartHour) {
  final key1 = getDateKey(date1, dayStartHour);
  final key2 = getDateKey(date2, dayStartHour);
  return key1.year == key2.year &&
         key1.month == key2.month &&
         key1.day == key2.day;
}

/// 날짜 범위 계산 (하루 시작 시간 고려)
List<DateTime> getDateRange(DateTime start, DateTime end, int dayStartHour) {
  final List<DateTime> dates = [];
  var current = getDateKey(start, dayStartHour);
  final endKey = getDateKey(end, dayStartHour);
  
  while (!current.isAfter(endKey)) {
    dates.add(current);
    current = current.add(const Duration(days: 1));
  }
  
  return dates;
}

