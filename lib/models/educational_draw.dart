import 'dart:convert';
import 'package:flutter/services.dart';

class EducationalDraw {
  final String id;
  final String title;
  final String category;
  final String imagePath;
  final List<String> bullets;

  const EducationalDraw({
    required this.id,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.bullets,
  });

  factory EducationalDraw.fromJson(Map<String, dynamic> json) {
    return EducationalDraw(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      imagePath: json['image'] as String,
      bullets: (json['bullets'] as List).map((b) => b as String).toList(),
    );
  }

  static Future<List<EducationalDraw>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/educational_draws.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['educational_draws'] as List)
        .map((j) => EducationalDraw.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

/// How educational draws are triggered during gameplay.
enum EduTriggerMode {
  off,          // No educational draws
  everyN,       // Every N regular draws
  betweenRounds // Once at the start of each new round
}

class EduSettings {
  final EduTriggerMode mode;
  final int everyN; // Only used when mode == everyN

  const EduSettings({
    this.mode = EduTriggerMode.everyN,
    this.everyN = 5,
  });

  EduSettings copyWith({EduTriggerMode? mode, int? everyN}) {
    return EduSettings(
      mode: mode ?? this.mode,
      everyN: everyN ?? this.everyN,
    );
  }

  /// Returns true if an educational draw should be shown after [drawCount]
  /// regular draws have been made in the current round.
  bool shouldShowAfterDraw(int drawCount) {
    if (mode == EduTriggerMode.everyN && drawCount > 0 && drawCount % everyN == 0) {
      return true;
    }
    return false;
  }

  /// Returns true if an educational draw should be shown when a new round starts.
  bool shouldShowOnRoundStart() {
    return mode == EduTriggerMode.betweenRounds;
  }

  String get description {
    switch (mode) {
      case EduTriggerMode.off:
        return 'Off';
      case EduTriggerMode.everyN:
        return 'Every $everyN draws';
      case EduTriggerMode.betweenRounds:
        return 'Between rounds';
    }
  }
}
