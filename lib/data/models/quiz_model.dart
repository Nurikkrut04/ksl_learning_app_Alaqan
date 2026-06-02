/// Модель одного вопроса теста.
///
/// Firestore path: courses/{courseId}/sections/{sectionId}/lessons/{lessonId}/tests/{testId}
///
/// Структура документа:
/// ```
/// {
///   order: 1,
///   mediaUrl: "https://res.cloudinary.com/.../video.mp4",
///   question: { kk: "...", ru: "...", en: "..." },
///   options: [ { kk: "...", ru: "...", en: "..." }, ... ],
///   correctIndex: 2
/// }
/// ```
class QuizQuestion {
  final String id;
  final int order;
  final String mediaUrl;
  final Map<String, String> question;
  final List<Map<String, String>> options;
  final int correctIndex;

  QuizQuestion({
    required this.id,
    required this.order,
    required this.mediaUrl,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromFirestore(String docId, Map<String, dynamic> data) {
    // Parse options: List<dynamic> → List<Map<String, String>>
    final rawOptions = data['options'] as List<dynamic>? ?? [];
    final options = rawOptions.map((opt) {
      if (opt is Map) {
        return Map<String, String>.from(
          opt.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
      return <String, String>{};
    }).toList();

    // Parse question: Map<String, dynamic> → Map<String, String>
    final rawQuestion = data['question'] as Map<String, dynamic>? ?? {};
    final question = Map<String, String>.from(
      rawQuestion.map((k, v) => MapEntry(k.toString(), v.toString())),
    );

    return QuizQuestion(
      id: docId,
      order: data['order'] as int? ?? 0,
      mediaUrl: data['mediaUrl'] as String? ?? '',
      question: question,
      options: options,
      correctIndex: data['correctIndex'] as int? ?? 0,
    );
  }

  /// Получить текст вопроса на нужном языке
  String getQuestion(String lang) {
    return question[lang] ?? question['ru'] ?? question['en'] ?? '';
  }

  /// Получить текст варианта ответа на нужном языке
  String getOption(int index, String lang) {
    if (index < 0 || index >= options.length) return '';
    return options[index][lang] ??
        options[index]['ru'] ??
        options[index]['en'] ??
        '';
  }

  /// Проверить правильность ответа
  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctIndex;
  }
}
