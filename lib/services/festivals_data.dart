import 'dart:collection';

class Festival {
  final String name;
  final String emoji;
  const Festival(this.name, this.emoji);
}

class FestivalsData {
  static const int _startYear = 2026;
  static const int _endYear = 2035;

  static const Map<String, List<Festival>> _fixed = {
    '01-01': [Festival("New Year's Day", '🎉')],
    '01-13': [Festival('Lohri', '🔥')],
    '01-14': [
      Festival('Makar Sankranti', '🪁'),
      Festival('Pongal', '🌾'),
    ],
    '01-26': [Festival('Republic Day', '🇮🇳')],
    '02-14': [Festival("Valentine's Day", '💝')],
    '03-08': [Festival("International Women's Day", '👩')],
    '03-22': [Festival('World Water Day', '💧')],
    '04-07': [Festival('World Health Day', '🏥')],
    '04-14': [Festival('Ambedkar Jayanti', '⚖️')],
    '04-22': [Festival('Earth Day', '🌍')],
    '05-01': [Festival('Labour Day', '👷')],
    '06-05': [Festival('World Environment Day', '🌳')],
    '06-21': [Festival('International Yoga Day', '🧘')],
    '07-01': [Festival("National Doctors' Day", '🩺')],
    '08-15': [Festival('Independence Day', '🇮🇳')],
    '09-05': [Festival("Teacher's Day", '👩‍🏫')],
    '10-02': [Festival('Gandhi Jayanti', '🕊️')],
    '10-31': [Festival('Halloween', '🎃')],
    '11-14': [Festival("Children's Day", '🧒')],
    '12-25': [Festival('Christmas', '🎄')],
    '12-31': [Festival("New Year's Eve", '🥳')],
  };

  // Lunar festivals follow the Hindu lunar calendar; dates below are the
  // best-known dates for each year (approx. for moon-sighting ones).
  static const Map<String, Map<int, String>> _moveable = {
    'Diwali': {
      2026: '11-08', 2027: '10-29', 2028: '10-17', 2029: '11-05',
      2030: '10-26', 2031: '10-14', 2032: '11-02', 2033: '10-22',
      2034: '11-11', 2035: '10-31',
    },
    'Holi': {
      2026: '03-03', 2027: '03-22', 2028: '03-11', 2029: '03-01',
      2030: '03-19', 2031: '03-09', 2032: '02-27', 2033: '03-15',
      2034: '03-05', 2035: '03-24',
    },
    'Maha Shivratri': {
      2026: '02-15', 2027: '03-06', 2028: '02-26', 2029: '02-13',
      2030: '03-04', 2031: '02-22', 2032: '03-11', 2033: '02-28',
      2034: '02-19', 2035: '03-09',
    },
    'Raksha Bandhan': {
      2026: '08-28', 2027: '08-17', 2028: '08-05', 2029: '08-24',
      2030: '08-13', 2031: '09-02', 2032: '08-21', 2033: '08-10',
      2034: '08-29', 2035: '08-18',
    },
    'Janmashtami': {
      2026: '09-04', 2027: '08-26', 2028: '08-14', 2029: '09-02',
      2030: '08-22', 2031: '08-12', 2032: '08-29', 2033: '08-18',
      2034: '09-06', 2035: '08-27',
    },
    'Ganesh Chaturthi': {
      2026: '09-14', 2027: '09-05', 2028: '08-24', 2029: '09-12',
      2030: '09-01', 2031: '09-21', 2032: '09-09', 2033: '08-29',
      2034: '09-17', 2035: '09-06',
    },
    'Dussehra': {
      2026: '10-20', 2027: '10-09', 2028: '09-27', 2029: '10-16',
      2030: '10-06', 2031: '09-25', 2032: '10-13', 2033: '10-02',
      2034: '10-22', 2035: '10-11',
    },
    'Guru Nanak Jayanti': {
      2026: '11-24', 2027: '11-14', 2028: '11-03', 2029: '11-21',
      2030: '11-10', 2031: '10-30', 2032: '11-16', 2033: '11-06',
      2034: '11-25', 2035: '11-14',
    },
    'Buddha Purnima': {
      2026: '05-01', 2027: '04-21', 2028: '05-09', 2029: '04-29',
      2030: '04-18', 2031: '05-06', 2032: '04-25', 2033: '05-14',
      2034: '05-03', 2035: '04-23',
    },
    'Eid al-Fitr (approx)': {
      2026: '03-20', 2027: '03-09', 2028: '02-26', 2029: '02-15',
      2030: '02-05', 2031: '01-25', 2032: '01-14', 2033: '01-04',
      2034: '12-13', 2035: '12-02',
    },
    'Eid al-Adha (approx)': {
      2026: '05-29', 2027: '05-18', 2028: '05-06', 2029: '04-26',
      2030: '04-16', 2031: '04-05', 2032: '03-24', 2033: '03-15',
      2034: '03-04', 2035: '02-21',
    },
    'Onam (approx)': {
      2026: '08-27', 2027: '09-14', 2028: '09-03', 2029: '08-22',
      2030: '08-10', 2031: '08-29', 2032: '08-17', 2033: '09-05',
      2034: '09-25', 2035: '09-13',
    },
  };

  static const Map<String, String> _emoji = {
    'Diwali': '🪔',
    'Holi': '🎨',
    'Maha Shivratri': '🔱',
    'Raksha Bandhan': '🪢',
    'Janmashtami': '🥁',
    'Ganesh Chaturthi': '🐘',
    'Dussehra': '🏹',
    'Guru Nanak Jayanti': '🙏',
    'Buddha Purnima': '☸️',
    'Eid al-Fitr (approx)': '🌙',
    'Eid al-Adha (approx)': '🕌',
    'Onam (approx)': '🌸',
  };

  static SplayTreeMap<DateTime, List<Festival>>? _all;

  static SplayTreeMap<DateTime, List<Festival>> get _events {
    if (_all == null) {
      final map = SplayTreeMap<DateTime, List<Festival>>();
      for (var year = _startYear; year <= _endYear; year++) {
        for (final entry in _fixed.entries) {
          final parts = entry.key.split('-');
          _put(map,
              DateTime(year, int.parse(parts[0]), int.parse(parts[1])),
              entry.value);
        }
        final easterDate = _easter(year);
        _put(map, easterDate, const [Festival('Easter Sunday', '🐣')]);
        _put(map, easterDate.subtract(const Duration(days: 2)),
            const [Festival('Good Friday', '✝️')]);
        _put(map, easterDate.subtract(const Duration(days: 46)),
            const [Festival('Ash Wednesday', '🙏')]);
        for (final entry in _moveable.entries) {
          final dateStr = entry.value[year];
          if (dateStr == null) continue;
          final parts = dateStr.split('-');
          _put(
            map,
            DateTime(year, int.parse(parts[0]), int.parse(parts[1])),
            [
              Festival(entry.key, _emoji[entry.key] ?? '🎉'),
            ],
          );
        }
      }
      _all = map;
    }
    return _all!;
  }

  static void _put(SplayTreeMap<DateTime, List<Festival>> map, DateTime day,
      List<Festival> festivals) {
    map.putIfAbsent(DateTime(day.year, day.month, day.day), () => [])
        .addAll(festivals);
  }

  static DateTime _easter(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static List<Festival> forDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? const [];
  }

  static List<(DateTime, Festival)> upcoming(DateTime from, {int limit = 10}) {
    final result = <(DateTime, Festival)>[];
    final start = DateTime(from.year, from.month, from.day);
    for (final entry in _events.entries) {
      final date = entry.key;
      if (date.isBefore(start)) continue;
      for (final f in entry.value) {
        result.add((date, f));
        if (result.length >= limit) return result;
      }
    }
    return result;
  }
}
