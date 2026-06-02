import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'admin_quiz_questions_screen.dart';
import 'admin_ui.dart';

class AdminLessonsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String sectionId;
  final String sectionTitle;

  const AdminLessonsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.sectionId,
    required this.sectionTitle,
  });

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessons = await _firestoreService.getLessonsBySection(
        widget.courseId,
        widget.sectionId,
      );
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
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

  Future<void> _openLessonDialog({Map<String, dynamic>? lesson}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _LessonEditorDialog(
        firestoreService: _firestoreService,
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        initialLesson: lesson,
      ),
    );

    if (didSave == true) {
      await _loadLessons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Сабақ сақталды.',
              ru: 'Урок сохранен.',
              en: 'Lesson saved.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openQuizQuestionsScreen(Map<String, dynamic> lesson) async {
    final languageCode = Localizations.localeOf(context).languageCode;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminQuizQuestionsScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          sectionId: widget.sectionId,
          sectionTitle: widget.sectionTitle,
          lessonId: (lesson['id'] ?? '').toString(),
          lessonTitle: adminLocalizedValue(lesson['title'], languageCode),
        ),
      ),
    );
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
            kk: 'Сабақтарды басқару',
            ru: 'Управление уроками',
            en: 'Manage lessons',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadLessons,
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
        onPressed: () => _openLessonDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          adminText(
            context,
            kk: 'Сабақ қосу',
            ru: 'Добавить урок',
            en: 'Add lesson',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLessons,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: widget.sectionTitle,
              caption: adminText(
                context,
                kk:
                    'Курс ID: ${widget.courseId} | Бөлім ID: ${widget.sectionId}',
                ru:
                    'ID курса: ${widget.courseId} | ID раздела: ${widget.sectionId}',
                en:
                    'Course ID: ${widget.courseId} | Section ID: ${widget.sectionId}',
              ),
              body: adminText(
                context,
                kk: 'Бұл экран бөлім ішіндегі сабақтарды басқаруға арналған. Әр сабақ үшін атауын, ретін және `steps` JSON тізімін өзгертуге болады. Ал тест сұрақтары әр сабақтың жеке экранында басқарылады.',
                ru: 'Этот экран нужен для управления уроками внутри раздела. Для каждого урока можно менять название, порядок и JSON-список `steps`. Тестовые вопросы управляются на отдельном экране каждого урока.',
                en: 'This screen manages lessons inside the section. You can edit each lesson title, order, and the `steps` JSON list here. Quiz questions are managed from a dedicated screen for each lesson.',
              ),
              icon: Icons.play_lesson_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              widget.courseTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
                onRetry: _loadLessons,
              )
            else if (_lessons.isEmpty)
              AdminEmptyCard(
                message: adminText(
                  context,
                  kk: 'Бұл бөлімде әзірге сабақтар жоқ.',
                  ru: 'В этом разделе пока нет уроков.',
                  en: 'There are no lessons in this section yet.',
                ),
                actionHint: adminText(
                  context,
                  kk: 'Алғашқы сабақ қосып, кейін оның `steps` құрылымын толтыра аласыз.',
                  ru: 'Добавьте первый урок, а затем заполните для него структуру `steps`.',
                  en: 'Add the first lesson, then fill in its `steps` structure.',
                ),
                icon: Icons.play_lesson_outlined,
              )
            else ...[
              Text(
                adminText(
                  context,
                  kk: 'Сабақ саны: ${_lessons.length}',
                  ru: 'Количество уроков: ${_lessons.length}',
                  en: 'Lessons count: ${_lessons.length}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ..._lessons.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openLessonDialog(lesson: lesson),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.categoryCulture.withOpacity(
                          0.14,
                        ),
                        child: const Icon(
                          Icons.play_lesson_rounded,
                          color: AppColors.categoryCulture,
                        ),
                      ),
                      title: Text(
                        adminLocalizedValue(lesson['title'], languageCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          adminText(
                            context,
                            kk:
                                'ID: ${lesson['id']} | Реті: ${lesson['order'] ?? 0} | Қадам саны: ${_stepsCount(lesson)}',
                            ru:
                                'ID: ${lesson['id']} | Порядок: ${lesson['order'] ?? 0} | Шагов: ${_stepsCount(lesson)}',
                            en:
                                'ID: ${lesson['id']} | Order: ${lesson['order'] ?? 0} | Steps: ${_stepsCount(lesson)}',
                          ),
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
                                kk: 'Тест сұрақтары',
                                ru: 'Тестовые вопросы',
                                en: 'Quiz questions',
                              ),
                              onPressed: () => _openQuizQuestionsScreen(lesson),
                              icon: const Icon(Icons.quiz_outlined),
                            ),
                            IconButton(
                              tooltip: adminText(
                                context,
                                kk: 'Сабақты өңдеу',
                                ru: 'Редактировать урок',
                                en: 'Edit lesson',
                              ),
                              onPressed: () => _openLessonDialog(lesson: lesson),
                              icon: const Icon(Icons.edit_outlined),
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

  int _stepsCount(Map<String, dynamic> lesson) {
    final steps = lesson['steps'];
    if (steps is List) return steps.length;
    return 0;
  }
}

class _LessonEditorDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String courseId;
  final String sectionId;
  final Map<String, dynamic>? initialLesson;

  const _LessonEditorDialog({
    required this.firestoreService,
    required this.courseId,
    required this.sectionId,
    this.initialLesson,
  });

  @override
  State<_LessonEditorDialog> createState() => _LessonEditorDialogState();
}

class _LessonEditorDialogState extends State<_LessonEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _orderController;
  late final TextEditingController _titleKkController;
  late final TextEditingController _titleRuController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _stepsController;

  bool _isSaving = false;

  bool get _isEditing => widget.initialLesson != null;

  @override
  void initState() {
    super.initState();
    final title = adminToStringMap(widget.initialLesson?['title']);

    _idController = TextEditingController(
      text: (widget.initialLesson?['id'] ?? '').toString(),
    );
    _orderController = TextEditingController(
      text: (widget.initialLesson?['order'] ?? 0).toString(),
    );
    _titleKkController = TextEditingController(text: title['kk'] ?? '');
    _titleRuController = TextEditingController(text: title['ru'] ?? '');
    _titleEnController = TextEditingController(text: title['en'] ?? '');
    _stepsController = TextEditingController(
      text: _encodeSteps(widget.initialLesson?['steps']),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _orderController.dispose();
    _titleKkController.dispose();
    _titleRuController.dispose();
    _titleEnController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestoreService.upsertLesson(
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        lessonId: _idController.text.trim(),
        order: int.tryParse(_orderController.text.trim()) ?? 0,
        title: {
          'kk': _titleKkController.text.trim(),
          'ru': _titleRuController.text.trim(),
          'en': _titleEnController.text.trim(),
        },
        steps: _parseSteps(_stepsController.text),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final titleBase = adminText(
      context,
      kk: 'Атауы',
      ru: 'Название',
      en: 'Title',
    );

    return AlertDialog(
      title: Text(
        adminText(
          context,
          kk: _isEditing ? 'Сабақты өңдеу' : 'Жаңа сабақ',
          ru: _isEditing ? 'Редактирование урока' : 'Новый урок',
          en: _isEditing ? 'Edit lesson' : 'New lesson',
        ),
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Сабақ ID',
                      ru: 'ID урока',
                      en: 'Lesson ID',
                    ),
                  ),
                  validator: _validateLessonId,
                ),
                const SizedBox(height: 12),
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
                  controller: _titleKkController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'kk',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleRuController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'ru',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleEnController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'en',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stepsController,
                  minLines: 10,
                  maxLines: 18,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Қадамдар JSON',
                      ru: 'JSON шагов',
                      en: 'Steps JSON',
                    ),
                    helperText: adminText(
                      context,
                      kk: 'JSON массивін пайдаланыңыз. Мысалы, әр қадамда `order`, `mediaType`, `mediaUrl`, `description` болуы мүмкін.',
                      ru: 'Используйте JSON-массив. Например, у шага могут быть `order`, `mediaType`, `mediaUrl`, `description`.',
                      en: 'Use a JSON array. A step can contain `order`, `mediaType`, `mediaUrl`, and `description`.',
                    ),
                    hintText:
                        '[\n  {\n    "order": 1,\n    "mediaType": "image",\n    "mediaUrl": "",\n    "description": {"kk": "", "ru": "", "en": ""}\n  }\n]',
                    alignLabelWithHint: true,
                  ),
                  validator: _validateSteps,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
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

  String _encodeSteps(dynamic steps) {
    if (steps is! List) return '[]';

    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(
        steps.map((item) => _normalizeJsonValue(item)).toList(),
      );
    } catch (_) {
      return '[]';
    }
  }

  List<Map<String, dynamic>> _parseSteps(String raw) {
    if (raw.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw FormatException(
        adminText(
          context,
          kk: 'JSON пішімі жарамсыз.',
          ru: 'Неверный формат JSON.',
          en: 'Invalid JSON format.',
        ),
      );
    }

    if (decoded is! List) {
      throw FormatException(
        adminText(
          context,
          kk: 'Қадамдар JSON массив болуы керек.',
          ru: 'Steps должен быть JSON-массивом.',
          en: 'Steps must be a JSON array.',
        ),
      );
    }

    return decoded.map<Map<String, dynamic>>((item) {
      if (item is! Map) {
        throw FormatException(
          adminText(
            context,
            kk: 'Әр қадам JSON объект болуы керек.',
            ru: 'Каждый шаг должен быть JSON-объектом.',
            en: 'Each step must be a JSON object.',
          ),
        );
      }

      final normalized = _normalizeJsonValue(item);
      return Map<String, dynamic>.from(normalized as Map);
    }).toList();
  }

  dynamic _normalizeJsonValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), _normalizeJsonValue(val)),
      );
    }

    if (value is List) {
      return value.map(_normalizeJsonValue).toList();
    }

    return value;
  }

  String? _validateLessonId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminText(
        context,
        kk: 'Сабақ ID міндетті.',
        ru: 'ID урока обязателен.',
        en: 'Lesson ID is required.',
      );
    }
    return null;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminRequiredFieldText(context);
    }
    return null;
  }

  String? _validateSteps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      _parseSteps(value);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('FormatException: ', '');
    }
  }
}
