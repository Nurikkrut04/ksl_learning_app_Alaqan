import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../data/models/course_model.dart';
import '../data/models/course_progress_summary.dart';
import '../data/models/lesson_model.dart';
import '../data/models/quiz_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Topic Operations ====================

  /// Получить все темы обучения, отсортированные по order
  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final snapshot = await _firestore
          .collection('topics')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching topics: $e');
    }
  }

  // ==================== Level Operations ====================

  /// Получить все уровни сложности, отсортированные по order
  Future<List<Map<String, dynamic>>> getLevels() async {
    try {
      final snapshot = await _firestore
          .collection('levels')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching levels: $e');
    }
  }

  // ==================== Course Operations (Catalog) ====================

  /// Получить ВСЕ курсы для каталога (вкладка "Курсы")
  /// Возвращает List<Map> с полями: id, topicId, levelId, title, description, imageUrl, order
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all courses: $e');
    }
  }

  // ==================== Course by Topic & Level ====================

  /// Получить курсы по теме и уровню
  Future<List<Map<String, dynamic>>> getCoursesByTopicAndLevel(
    String topicId,
    String levelId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('topicId', isEqualTo: topicId)
          .where('levelId', isEqualTo: levelId)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching courses by topic and level: $e');
    }
  }

  // ==================== Section Operations ====================

  /// Получить секции курса (courses/{courseId}/sections)
  Future<List<Map<String, dynamic>>> getSections(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching sections: $e');
    }
  }

  // ==================== Lesson Operations (new structure) ====================

  /// Получить уроки секции (courses/{courseId}/sections/{sectionId}/lessons)
  Future<List<Map<String, dynamic>>> getLessonsBySection(
    String courseId,
    String sectionId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching lessons by section: $e');
    }
  }

  /// Получить один урок со steps
  Future<Map<String, dynamic>?> getLessonWithSteps(
    String courseId,
    String sectionId,
    String lessonId,
  ) async {
    try {
      final doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching lesson with steps: $e');
    }
  }

  // ==================== Quiz / Test Operations ====================

  /// Получить вопросы теста для урока
  /// Path: courses/{courseId}/sections/{sectionId}/lessons/{lessonId}/tests
  Future<List<QuizQuestion>> getTestsForLesson(
    String courseId,
    String sectionId,
    String lessonId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId)
          .collection('tests')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => QuizQuestion.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching tests: $e');
    }
  }

  /// Сохранить результат теста в прогресс пользователя
  Future<void> upsertQuizQuestion({
    required String courseId,
    required String sectionId,
    required String lessonId,
    String? questionId,
    required int order,
    String mediaUrl = '',
    required Map<String, String> question,
    required List<Map<String, String>> options,
    required int correctIndex,
  }) async {
    try {
      final testsRef = _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId)
          .collection('tests');

      final normalizedId = questionId?.trim() ?? '';
      final questionRef =
          normalizedId.isEmpty ? testsRef.doc() : testsRef.doc(normalizedId);
      final existing = await questionRef.get();

      final payload = <String, dynamic>{
        'order': order,
        'mediaUrl': mediaUrl,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await questionRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving quiz question: $e');
    }
  }

  Future<void> deleteQuizQuestion({
    required String courseId,
    required String sectionId,
    required String lessonId,
    required String questionId,
  }) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId)
          .collection('tests')
          .doc(questionId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting quiz question: $e');
    }
  }

  Future<void> saveQuizProgress(
    String userId,
    String courseId,
    String sectionId,
    String lessonId,
    int correctCount,
    int totalCount,
    int percent,
  ) async {
    try {
      final key = '${courseId}_${sectionId}_$lessonId';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('quizResults')
          .set({
        key: {
          'courseId': courseId,
          'sectionId': sectionId,
          'lessonId': lessonId,
          'correctCount': correctCount,
          'totalCount': totalCount,
          'percent': percent,
          'completedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving quiz progress: $e');
    }
  }

  // ==================== User Operations ====================

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('lastLoginAt', descending: true)
          .get();

      return snapshot.docs.map(UserModel.fromFirestore).toList();
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> updateUserNotificationSettings({
    required String uid,
    required bool enabled,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'settings': {
          'notificationsEnabled': enabled,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating notification settings: $e');
    }
  }

  Future<void> updateNotificationPermissionStatus({
    required String uid,
    required String status,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'notificationPermissionStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating notification permission: $e');
    }
  }

  Future<void> saveUserPushToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'pushToken': token,
        'pushTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving push token: $e');
    }
  }

  Future<void> clearUserPushToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'pushToken': FieldValue.delete(),
        'pushTokenUpdatedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error clearing push token: $e');
    }
  }

  Future<void> activateProfessionsAccess(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'hasProfessionsAccess': true,
        'subscriptionPlan': 'professions',
        'subscriptionPriceKzt': 5000,
        'subscriptionActivatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error activating professions access: $e');
    }
  }

  // ==================== Course Operations ====================

  Future<List<CourseModel>> getCourses({
    String? difficulty,
    bool? isPublished,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('courses');

      if (isPublished != null) {
        query = query.where('isPublished', isEqualTo: isPublished);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      query = query.orderBy('order').limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }

  Stream<List<CourseModel>> watchCourses() {
    return _firestore
        .collection('courses')
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList());
  }

  // ==================== Legacy Lesson Operations ====================

  Future<List<LessonModel>> getLessons(String courseId, String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => LessonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching lessons: $e');
    }
  }

  Future<LessonModel?> getLesson(
    String courseId,
    String topicId,
    String lessonId,
  ) async {
    try {
      final doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('topics')
          .doc(topicId)
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (doc.exists) {
        return LessonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching lesson: $e');
    }
  }

  // ==================== Progress Operations ====================

  Future<void> updateLessonProgress(
    String userId,
    String courseId,
    String lessonId,
    String? sectionId,
  ) async {
    try {
      final progressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(courseId);

      final lessonProgressKey = _buildLessonProgressKey(
        lessonId: lessonId,
        sectionId: sectionId,
      );

      await progressRef.set({
        'courseId': courseId,
        'completedLessons': FieldValue.arrayUnion([lessonProgressKey]),
        'lastAccessedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating lesson progress: $e');
    }
  }

  Future<bool> isLessonCompleted(
    String userId,
    String courseId,
    String lessonId, {
    String? sectionId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(courseId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? <String, dynamic>{};
      final completedLessons =
          List<String>.from(data['completedLessons'] ?? const []);
      final lessonProgressKey = _buildLessonProgressKey(
        lessonId: lessonId,
        sectionId: sectionId,
      );

      return completedLessons.contains(lessonProgressKey) ||
          completedLessons.contains(lessonId);
    } catch (e) {
      throw Exception('Error checking lesson progress: $e');
    }
  }

  Future<List<CourseProgressSummary>> getUserCourseProgressSummaries(
    String userId,
  ) async {
    try {
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();

      final allCourses = await getAllCourses();
      final courseMap = <String, Map<String, dynamic>>{
        for (final course in allCourses) (course['id'] as String): course,
      };

      final progressDocs =
          progressSnapshot.docs.where((doc) => doc.id != 'quizResults').toList();

      Map<String, dynamic> quizResultsData = <String, dynamic>{};
      for (final doc in progressSnapshot.docs) {
        if (doc.id == 'quizResults') {
          quizResultsData = doc.data();
          break;
        }
      }

      final summaries = await Future.wait(
        progressDocs.map((doc) async {
          final data = doc.data();
          final courseId = (data['courseId'] ?? doc.id).toString();
          final course = courseMap[courseId];

          if (course == null) return null;

          final completedLessonsRaw =
              List<String>.from(data['completedLessons'] ?? const []);
          final completedLessons = completedLessonsRaw.toSet().toList();

          var totalLessons = _readInt(course['totalLessons']);
          if (totalLessons <= 0) {
            final sections = await getSections(courseId);
            totalLessons = sections.fold<int>(
              0,
              (sum, section) => sum + _readInt(section['totalLessons']),
            );
          }

          if (totalLessons <= 0) {
            totalLessons = completedLessons.length;
          }

          final accuracyValues = <int>[];
          for (final entry in quizResultsData.entries) {
            final value = entry.value;
            if (value is Map && value['courseId'] == courseId) {
              accuracyValues.add(_readInt(value['percent']));
            }
          }

          final averageAccuracy = accuracyValues.isEmpty
              ? 0
              : (accuracyValues.reduce((a, b) => a + b) /
                      accuracyValues.length)
                  .round();

          return CourseProgressSummary(
            courseId: courseId,
            topicId: (course['topicId'] ?? '').toString(),
            levelId: (course['levelId'] ?? '').toString(),
            title: _toStringMap(course['title']),
            completedLessons: completedLessons.length,
            totalLessons: totalLessons,
            averageAccuracy: averageAccuracy,
            lastAccessedAt: _parseOptionalTimestamp(data['lastAccessedAt']),
          );
        }),
      );

      final result = summaries.whereType<CourseProgressSummary>().toList()
        ..sort((a, b) {
          final aTime =
              a.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime =
              b.lastAccessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      return result;
    } catch (e) {
      throw Exception('Error fetching course progress summaries: $e');
    }
  }

  Future<void> saveQuizResult(
    String userId,
    String quizId,
    Map<String, dynamic> result,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('quizResults')
          .collection('results')
          .doc(quizId)
          .set({
        ...result,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error saving quiz result: $e');
    }
  }

  // ==================== Admin Operations ====================

  Future<void> upsertTopic({
    required String topicId,
    required Map<String, String> title,
    required int order,
  }) async {
    try {
      final topicRef = _firestore.collection('topics').doc(topicId);
      final existing = await topicRef.get();

      final payload = <String, dynamic>{
        'title': title,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await topicRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving topic: $e');
    }
  }

  Future<void> upsertCourseData({
    required String courseId,
    required String topicId,
    required String levelId,
    required int order,
    required Map<String, String> title,
    required Map<String, String> description,
    String imageUrl = '',
    int totalLessons = 0,
    bool isPublished = true,
    String? createdBy,
  }) async {
    try {
      final courseRef = _firestore.collection('courses').doc(courseId);
      final existing = await courseRef.get();

      final payload = <String, dynamic>{
        'topicId': topicId,
        'levelId': levelId,
        'order': order,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'totalLessons': totalLessons,
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['createdBy'] = createdBy ?? '';
      }

      await courseRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving course: $e');
    }
  }

  Future<void> upsertSection({
    required String courseId,
    required String sectionId,
    required int order,
    required int totalLessons,
    required Map<String, String> title,
  }) async {
    try {
      final sectionRef = _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId);
      final existing = await sectionRef.get();

      final payload = <String, dynamic>{
        'order': order,
        'totalLessons': totalLessons,
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await sectionRef.set(payload, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving section: $e');
    }
  }

  Future<void> upsertLesson({
    required String courseId,
    required String sectionId,
    required String lessonId,
    required int order,
    required Map<String, String> title,
    List<Map<String, dynamic>> steps = const [],
  }) async {
    try {
      final lessonRef = _firestore
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId);
      final existing = await lessonRef.get();

      final payload = <String, dynamic>{
        'order': order,
        'title': title,
        'steps': steps,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await lessonRef.set(payload, SetOptions(merge: true));
      await _syncLessonTotals(
        courseId: courseId,
        sectionId: sectionId,
      );
    } catch (e) {
      throw Exception('Error saving lesson: $e');
    }
  }

  Future<void> addCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.courseId).set(course.toMap());
    } catch (e) {
      throw Exception('Error adding course: $e');
    }
  }

  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.courseId).update(course.toMap());
    } catch (e) {
      throw Exception('Error updating course: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Error deleting course: $e');
    }
  }

  String _buildLessonProgressKey({
    required String lessonId,
    String? sectionId,
  }) {
    if (sectionId == null || sectionId.isEmpty) {
      return lessonId;
    }

    return '$sectionId::$lessonId';
  }

  Future<void> _syncLessonTotals({
    required String courseId,
    required String sectionId,
  }) async {
    final courseRef = _firestore.collection('courses').doc(courseId);
    final sectionsRef = courseRef.collection('sections');
    final sectionRef = sectionsRef.doc(sectionId);

    final lessonsSnapshot = await sectionRef.collection('lessons').get();
    final sectionLessonCount = lessonsSnapshot.docs.length;

    await sectionRef.set({
      'totalLessons': sectionLessonCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final sectionsSnapshot = await sectionsRef.get();
    final lessonCounts = await Future.wait(
      sectionsSnapshot.docs.map((doc) async {
        if (doc.id == sectionId) {
          return sectionLessonCount;
        }

        final snapshot = await doc.reference.collection('lessons').get();
        return snapshot.docs.length;
      }),
    );

    final courseLessonCount = lessonCounts.fold<int>(0, (sum, count) => sum + count);

    await courseRef.set({
      'totalLessons': courseLessonCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  Map<String, String> _toStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, val) => MapEntry(key, val.toString()));
    }

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }

    return <String, String>{};
  }

  // Примечание: в новых версиях Cloud Firestore offline persistence
  // включена по умолчанию на мобильных платформах.
  // Метод enablePersistence() больше не нужен.
}
