import 'package:equatable/equatable.dart';

class CourseProgressSummary extends Equatable {
  final String courseId;
  final String topicId;
  final String levelId;
  final Map<String, String> title;
  final int completedLessons;
  final int totalLessons;
  final int averageAccuracy;
  final DateTime? lastAccessedAt;

  const CourseProgressSummary({
    required this.courseId,
    required this.topicId,
    required this.levelId,
    required this.title,
    required this.completedLessons,
    required this.totalLessons,
    required this.averageAccuracy,
    this.lastAccessedAt,
  });

  int get progressPercent {
    if (totalLessons <= 0) return 0;

    final percent = ((completedLessons / totalLessons) * 100).round();
    if (percent < 0) return 0;
    if (percent > 100) return 100;
    return percent;
  }

  double get progressValue {
    if (totalLessons <= 0) return 0;
    return completedLessons / totalLessons;
  }

  String getTitle(String languageCode) {
    return title[languageCode] ?? title['ru'] ?? title['en'] ?? '';
  }

  @override
  List<Object?> get props => [
        courseId,
        topicId,
        levelId,
        title,
        completedLessons,
        totalLessons,
        averageAccuracy,
        lastAccessedAt,
      ];
}
