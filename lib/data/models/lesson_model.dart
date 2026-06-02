import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class LessonModel extends Equatable {
  final String lessonId;
  final String courseId;
  final String topicId;
  final Map<String, String> title;
  final Map<String, String> content;
  final int order;
  final String type;
  final String videoUrl;
  final int duration;
  final String thumbnailUrl;
  final List<String> gestureIds;
  final bool hasQuiz;
  final List<String> prerequisites;
  final Map<String, List<String>> keyPoints;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LessonModel({
    required this.lessonId,
    required this.courseId,
    required this.topicId,
    required this.title,
    required this.content,
    required this.order,
    required this.type,
    required this.videoUrl,
    required this.duration,
    required this.thumbnailUrl,
    this.gestureIds = const [],
    this.hasQuiz = false,
    this.prerequisites = const [],
    this.keyPoints = const {},
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      lessonId: doc.id,
      courseId: data['courseId'] ?? '',
      topicId: data['topicId'] ?? '',
      title: Map<String, String>.from(data['title'] ?? {}),
      content: Map<String, String>.from(data['content'] ?? {}),
      order: data['order'] ?? 0,
      type: data['type'] ?? 'video',
      videoUrl: data['videoUrl'] ?? '',
      duration: data['duration'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      gestureIds: List<String>.from(data['gestureIds'] ?? []),
      hasQuiz: data['hasQuiz'] ?? false,
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      keyPoints: (data['keyPoints'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ??
          {},
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory LessonModel.fromMap(Map<String, dynamic> map, String id) {
    return LessonModel(
      lessonId: id,
      courseId: map['courseId'] ?? '',
      topicId: map['topicId'] ?? '',
      title: Map<String, String>.from(map['title'] ?? {}),
      content: Map<String, String>.from(map['content'] ?? {}),
      order: map['order'] ?? 0,
      type: map['type'] ?? 'video',
      videoUrl: map['videoUrl'] ?? '',
      duration: map['duration'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      gestureIds: List<String>.from(map['gestureIds'] ?? []),
      hasQuiz: map['hasQuiz'] ?? false,
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      keyPoints: (map['keyPoints'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ??
          {},
      isPublished: map['isPublished'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'courseId': courseId,
      'topicId': topicId,
      'title': title,
      'content': content,
      'order': order,
      'type': type,
      'videoUrl': videoUrl,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'gestureIds': gestureIds,
      'hasQuiz': hasQuiz,
      'prerequisites': prerequisites,
      'keyPoints': keyPoints,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String getTitle(String languageCode) {
    return title[languageCode] ?? title['en'] ?? '';
  }

  String getContent(String languageCode) {
    return content[languageCode] ?? content['en'] ?? '';
  }

  List<String> getKeyPoints(String languageCode) {
    return keyPoints[languageCode] ?? keyPoints['en'] ?? [];
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  LessonModel copyWith({
    String? lessonId,
    String? courseId,
    String? topicId,
    Map<String, String>? title,
    Map<String, String>? content,
    int? order,
    String? type,
    String? videoUrl,
    int? duration,
    String? thumbnailUrl,
    List<String>? gestureIds,
    bool? hasQuiz,
    List<String>? prerequisites,
    Map<String, List<String>>? keyPoints,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonModel(
      lessonId: lessonId ?? this.lessonId,
      courseId: courseId ?? this.courseId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gestureIds: gestureIds ?? this.gestureIds,
      hasQuiz: hasQuiz ?? this.hasQuiz,
      prerequisites: prerequisites ?? this.prerequisites,
      keyPoints: keyPoints ?? this.keyPoints,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        lessonId,
        courseId,
        topicId,
        title,
        content,
        order,
        type,
        videoUrl,
        duration,
        thumbnailUrl,
        gestureIds,
        hasQuiz,
        prerequisites,
        keyPoints,
        isPublished,
        createdAt,
        updatedAt,
      ];
}
