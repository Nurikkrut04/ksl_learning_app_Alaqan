import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String courseId;
  final Map<String, String> title;
  final Map<String, String> description;
  final String thumbnailUrl;
  final String difficulty;
  final int estimatedDuration;
  final int totalTopics;
  final int totalLessons;
  final bool isPublished;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.difficulty,
    required this.estimatedDuration,
    required this.totalTopics,
    required this.totalLessons,
    this.isPublished = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      courseId: doc.id,
      title: Map<String, String>.from(data['title'] ?? {}),
      description: Map<String, String>.from(data['description'] ?? {}),
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      estimatedDuration: data['estimatedDuration'] ?? 0,
      totalTopics: data['totalTopics'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
      isPublished: data['isPublished'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      courseId: id,
      title: Map<String, String>.from(map['title'] ?? {}),
      description: Map<String, String>.from(map['description'] ?? {}),
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      difficulty: map['difficulty'] ?? 'beginner',
      estimatedDuration: map['estimatedDuration'] ?? 0,
      totalTopics: map['totalTopics'] ?? 0,
      totalLessons: map['totalLessons'] ?? 0,
      isPublished: map['isPublished'] ?? true,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'totalTopics': totalTopics,
      'totalLessons': totalLessons,
      'isPublished': isPublished,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  String getTitle(String languageCode) {
    return title[languageCode] ?? title['en'] ?? '';
  }

  String getDescription(String languageCode) {
    return description[languageCode] ?? description['en'] ?? '';
  }

  CourseModel copyWith({
    String? courseId,
    Map<String, String>? title,
    Map<String, String>? description,
    String? thumbnailUrl,
    String? difficulty,
    int? estimatedDuration,
    int? totalTopics,
    int? totalLessons,
    bool? isPublished,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      totalTopics: totalTopics ?? this.totalTopics,
      totalLessons: totalLessons ?? this.totalLessons,
      isPublished: isPublished ?? this.isPublished,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        courseId,
        title,
        description,
        thumbnailUrl,
        difficulty,
        estimatedDuration,
        totalTopics,
        totalLessons,
        isPublished,
        order,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
