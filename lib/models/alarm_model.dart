import 'package:flutter/material.dart';

class AlarmModel {
  final String id;
  final TimeOfDay time;
  final String label;
  bool isEnabled;
  final List<int> repeatDays; // 0=Sunday, 1=Monday, etc.
  final String soundPath; // Path to alarm sound

  AlarmModel({
    required this.id,
    required this.time,
    required this.label,
    this.isEnabled = true,
    this.repeatDays = const [],
    this.soundPath = 'sounds/alarm.mp3',
  });

  AlarmModel copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    String? soundPath,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'soundPath': soundPath,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      label: json['label'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatDays: List<int>.from(json['repeatDays'] as List? ?? []),
      soundPath: json['soundPath'] as String? ?? 'sounds/alarm.mp3',
    );
  }

  String get formattedTime {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get repeatText {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';

    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return repeatDays.map((day) => days[day]).join(', ');
  }
}
