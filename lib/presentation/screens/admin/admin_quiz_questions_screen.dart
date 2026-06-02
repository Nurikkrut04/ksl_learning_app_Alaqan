import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../services/firestore_service.dart';
import 'admin_ui.dart';

class AdminQuizQuestionsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String sectionId;
  final String sectionTitle;
  final String lessonId;
  final String lessonTitle;

  const AdminQuizQuestionsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AdminQuizQuestionsScreen> createState() =>
      _AdminQuizQuestionsScreenState();
}

class _AdminQuizQuestionsScreenState extends State<AdminQuizQuestionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<QuizQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _firestoreService.getTestsForLesson(
        widget.courseId,
        widget.sectionId,
        widget.lessonId,
      );

      questions.sort((a, b) => a.order.compareTo(b.order));

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openQuestionDialog({QuizQuestion? question}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _QuizQuestionEditorDialog(
        firestoreService: _firestoreService,
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        lessonId: widget.lessonId,
        initialQuestion: question,
      ),
    );

    if (didSave == true) {
      await _loadQuestions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Тест сұрағы сақталды.',
              ru: 'Тестовый вопрос сохранен.',
              en: 'Quiz question saved.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          adminText(
            dialogContext,
            kk: 'Сұрақты жою',
            ru: 'Удалить вопрос',
            en: 'Delete question',
          ),
        ),
        content: Text(
          adminText(
            dialogContext,
            kk: 'Бұл тест сұрағын жойғыңыз келе ме? Бұл әрекетті кері қайтару мүмкін емес.',
            ru: 'Удалить этот тестовый вопрос? Это действие нельзя отменить.',
            en: 'Delete this quiz question? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              adminText(
                dialogContext,
                kk: 'Бас тарту',
                ru: 'Отмена',
                en: 'Cancel',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              adminText(
                dialogContext,
                kk: 'Жою',
                ru: 'Удалить',
                en: 'Delete',
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _firestoreService.deleteQuizQuestion(
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        lessonId: widget.lessonId,
        questionId: question.id,
      );

      await _loadQuestions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Сұрақ жойылды.',
              ru: 'Вопрос удален.',
              en: 'Question deleted.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Тест сұрақтарын басқару',
            ru: 'Управление тестовыми вопросами',
            en: 'Manage quiz questions',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadQuestions,
            tooltip: adminText(
              context,
              kk: 'Жаңарту',
              ru: 'Обновить',
              en: 'Refresh',
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuestionDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          adminText(
            context,
            kk: 'Сұрақ қосу',
            ru: 'Добавить вопрос',
            en: 'Add question',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuestions,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: widget.lessonTitle,
              caption: adminText(
                context,
                kk:
                    'Курс: ${widget.courseTitle} | Бөлім: ${widget.sectionTitle}',
                ru:
                    'Курс: ${widget.courseTitle} | Раздел: ${widget.sectionTitle}',
                en:
                    'Course: ${widget.courseTitle} | Section: ${widget.sectionTitle}',
              ),
              body: adminText(
                context,
                kk: 'Бұл экранда сабақ тестіне арналған сұрақтарды, медиа сілтемесін, жауап нұсқаларын және дұрыс жауап индексін басқаруға болады.',
                ru: 'На этом экране можно управлять вопросами теста урока, медиа-ссылкой, вариантами ответа и индексом правильного ответа.',
                en: 'This screen lets you manage lesson quiz questions, media URL, answer options, and the correct answer index.',
              ),
              icon: Icons.quiz_outlined,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              AdminErrorCard(
                message: _errorMessage!,
                onRetry: _loadQuestions,
              )
            else if (_questions.isEmpty)
              AdminEmptyCard(
                message: adminText(
                  context,
                  kk: 'Бұл сабаққа арналған тест сұрақтары әлі жоқ.',
                  ru: 'Для этого урока пока нет тестовых вопросов.',
                  en: 'There are no quiz questions for this lesson yet.',
                ),
                actionHint: adminText(
                  context,
                  kk: 'Алғашқы сұрақты қосып, тестті толық басқаруды осы жерден жалғастыра аласыз.',
                  ru: 'Добавьте первый вопрос и продолжайте полностью управлять тестом отсюда.',
                  en: 'Add the first question and manage the full quiz from here.',
                ),
                icon: Icons.quiz_outlined,
              )
            else ...[
              Text(
                adminText(
                  context,
                  kk: 'Сұрақ саны: ${_questions.length}',
                  ru: 'Количество вопросов: ${_questions.length}',
                  en: 'Questions count: ${_questions.length}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ..._questions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openQuestionDialog(question: question),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.categoryCulture.withOpacity(0.14),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: AppColors.categoryCulture,
                        ),
                      ),
                      title: Text(
                        question.getQuestion(languageCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adminText(
                                context,
                                kk:
                                    'Реті: ${question.order} | Нұсқалар: ${question.options.length} | Дұрыс жауап: ${question.correctIndex + 1}',
                                ru:
                                    'Порядок: ${question.order} | Вариантов: ${question.options.length} | Правильный ответ: ${question.correctIndex + 1}',
                                en:
                                    'Order: ${question.order} | Options: ${question.options.length} | Correct answer: ${question.correctIndex + 1}',
                              ),
                            ),
                            if (question.mediaUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  adminText(
                                    context,
                                    kk: 'Медиа тіркелген',
                                    ru: 'Медиа прикреплено',
                                    en: 'Media attached',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: SizedBox(
                        width: 96,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: adminText(
                                context,
                                kk: 'Сұрақты өңдеу',
                                ru: 'Редактировать вопрос',
                                en: 'Edit question',
                              ),
                              onPressed: () => _openQuestionDialog(
                                question: question,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: adminText(
                                context,
                                kk: 'Сұрақты жою',
                                ru: 'Удалить вопрос',
                                en: 'Delete question',
                              ),
                              onPressed: () => _deleteQuestion(question),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizQuestionEditorDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String courseId;
  final String sectionId;
  final String lessonId;
  final QuizQuestion? initialQuestion;

  const _QuizQuestionEditorDialog({
    required this.firestoreService,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    this.initialQuestion,
  });

  @override
  State<_QuizQuestionEditorDialog> createState() =>
      _QuizQuestionEditorDialogState();
}

class _QuizQuestionEditorDialogState extends State<_QuizQuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _orderController;
  late final TextEditingController _mediaUrlController;
  late final TextEditingController _questionKkController;
  late final TextEditingController _questionRuController;
  late final TextEditingController _questionEnController;
  late List<_OptionControllers> _optionControllers;

  bool _isSaving = false;
  int _correctIndex = 0;

  bool get _isEditing => widget.initialQuestion != null;

  @override
  void initState() {
    super.initState();
    final initialQuestion = widget.initialQuestion;

    _orderController = TextEditingController(
      text: (initialQuestion?.order ?? 0).toString(),
    );
    _mediaUrlController = TextEditingController(
      text: initialQuestion?.mediaUrl ?? '',
    );
    _questionKkController = TextEditingController(
      text: initialQuestion?.question['kk'] ?? '',
    );
    _questionRuController = TextEditingController(
      text: initialQuestion?.question['ru'] ?? '',
    );
    _questionEnController = TextEditingController(
      text: initialQuestion?.question['en'] ?? '',
    );
    _correctIndex = initialQuestion?.correctIndex ?? 0;

    final rawOptions =
        initialQuestion?.options ?? <Map<String, String>>[];
    final normalizedOptions = rawOptions.isEmpty
        ? List.generate(4, (_) => <String, String>{})
        : rawOptions;

    _optionControllers = normalizedOptions
        .map(
          (option) => _OptionControllers.fromMap(option),
        )
        .toList();
  }

  @override
  void dispose() {
    _orderController.dispose();
    _mediaUrlController.dispose();
    _questionKkController.dispose();
    _questionRuController.dispose();
    _questionEnController.dispose();
    for (final option in _optionControllers) {
      option.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers = [
        ..._optionControllers,
        _OptionControllers.fromMap(<String, String>{}),
      ];
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;

    final removed = _optionControllers[index];
    removed.dispose();

    setState(() {
      _optionControllers = [
        for (var i = 0; i < _optionControllers.length; i++)
          if (i != index) _optionControllers[i],
      ];

      if (_correctIndex >= _optionControllers.length) {
        _correctIndex = _optionControllers.length - 1;
      } else if (index < _correctIndex) {
        _correctIndex -= 1;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_optionControllers.length < 2) {
      _showValidationMessage(
        adminText(
          context,
          kk: 'Кемінде екі жауап нұсқасы болуы керек.',
          ru: 'Должно быть минимум два варианта ответа.',
          en: 'At least two answer options are required.',
        ),
      );
      return;
    }

    if (_correctIndex < 0 || _correctIndex >= _optionControllers.length) {
      _showValidationMessage(
        adminText(
          context,
          kk: 'Дұрыс жауап нұсқасын таңдаңыз.',
          ru: 'Выберите правильный вариант ответа.',
          en: 'Select the correct answer option.',
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestoreService.upsertQuizQuestion(
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        lessonId: widget.lessonId,
        questionId: widget.initialQuestion?.id,
        order: int.tryParse(_orderController.text.trim()) ?? 0,
        mediaUrl: _mediaUrlController.text.trim(),
        question: {
          'kk': _questionKkController.text.trim(),
          'ru': _questionRuController.text.trim(),
          'en': _questionEnController.text.trim(),
        },
        options: _optionControllers.map((option) => option.toMap()).toList(),
        correctIndex: _correctIndex,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionBase = adminText(
      context,
      kk: 'Сұрақ мәтіні',
      ru: 'Текст вопроса',
      en: 'Question text',
    );
    final optionBase = adminText(
      context,
      kk: 'Жауап нұсқасы',
      ru: 'Вариант ответа',
      en: 'Answer option',
    );

    return AlertDialog(
      title: Text(
        adminText(
          context,
          kk: _isEditing ? 'Сұрақты өңдеу' : 'Жаңа сұрақ',
          ru: _isEditing ? 'Редактирование вопроса' : 'Новый вопрос',
          en: _isEditing ? 'Edit question' : 'New question',
        ),
      ),
      content: SizedBox(
        width: 840,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isEditing) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      adminText(
                        context,
                        kk: 'Сұрақ ID: ${widget.initialQuestion!.id}',
                        ru: 'ID вопроса: ${widget.initialQuestion!.id}',
                        en: 'Question ID: ${widget.initialQuestion!.id}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Реті',
                      ru: 'Порядок',
                      en: 'Order',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediaUrlController,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Медиа URL',
                      ru: 'Media URL',
                      en: 'Media URL',
                    ),
                    helperText: adminText(
                      context,
                      kk: 'Қажет болса сурет немесе видео сілтемесін енгізіңіз.',
                      ru: 'При необходимости укажите ссылку на изображение или видео.',
                      en: 'Optionally provide an image or video URL.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionKkController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: questionBase,
                      languageCode: 'kk',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionRuController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: questionBase,
                      languageCode: 'ru',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _questionEnController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: questionBase,
                      languageCode: 'en',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        adminText(
                          context,
                          kk: 'Жауап нұсқалары',
                          ru: 'Варианты ответа',
                          en: 'Answer options',
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        adminText(
                          context,
                          kk: 'Нұсқа қосу',
                          ru: 'Добавить вариант',
                          en: 'Add option',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_optionControllers.length, (index) {
                  final option = _optionControllers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _correctIndex,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _correctIndex = value;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    adminText(
                                      context,
                                      kk:
                                          'Нұсқа ${index + 1}${_correctIndex == index ? ' • Дұрыс жауап' : ''}',
                                      ru:
                                          'Вариант ${index + 1}${_correctIndex == index ? ' • Правильный ответ' : ''}',
                                      en:
                                          'Option ${index + 1}${_correctIndex == index ? ' • Correct answer' : ''}',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (_optionControllers.length > 2)
                                  IconButton(
                                    tooltip: adminText(
                                      context,
                                      kk: 'Нұсқаны жою',
                                      ru: 'Удалить вариант',
                                      en: 'Remove option',
                                    ),
                                    onPressed: () => _removeOption(index),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: option.kkController,
                              decoration: InputDecoration(
                                labelText: adminLanguageLabel(
                                  context,
                                  base: optionBase,
                                  languageCode: 'kk',
                                ),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: option.ruController,
                              decoration: InputDecoration(
                                labelText: adminLanguageLabel(
                                  context,
                                  base: optionBase,
                                  languageCode: 'ru',
                                ),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: option.enController,
                              decoration: InputDecoration(
                                labelText: adminLanguageLabel(
                                  context,
                                  base: optionBase,
                                  languageCode: 'en',
                                ),
                              ),
                              validator: _required,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            adminText(
              context,
              kk: 'Бас тарту',
              ru: 'Отмена',
              en: 'Cancel',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(
            _isSaving
                ? adminText(
                    context,
                    kk: 'Сақталуда...',
                    ru: 'Сохранение...',
                    en: 'Saving...',
                  )
                : adminText(
                    context,
                    kk: 'Сақтау',
                    ru: 'Сохранить',
                    en: 'Save',
                  ),
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminRequiredFieldText(context);
    }
    return null;
  }
}

class _OptionControllers {
  final TextEditingController kkController;
  final TextEditingController ruController;
  final TextEditingController enController;

  _OptionControllers({
    required this.kkController,
    required this.ruController,
    required this.enController,
  });

  factory _OptionControllers.fromMap(Map<String, String> value) {
    return _OptionControllers(
      kkController: TextEditingController(text: value['kk'] ?? ''),
      ruController: TextEditingController(text: value['ru'] ?? ''),
      enController: TextEditingController(text: value['en'] ?? ''),
    );
  }

  Map<String, String> toMap() {
    return {
      'kk': kkController.text.trim(),
      'ru': ruController.text.trim(),
      'en': enController.text.trim(),
    };
  }

  void dispose() {
    kkController.dispose();
    ruController.dispose();
    enController.dispose();
  }
}
