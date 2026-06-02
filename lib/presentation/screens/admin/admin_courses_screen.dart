import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'admin_sections_screen.dart';
import 'admin_ui.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _levels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _firestoreService.getAllCourses(),
        _firestoreService.getTopics(),
        _firestoreService.getLevels(),
      ]);

      if (!mounted) return;
      setState(() {
        _courses = List<Map<String, dynamic>>.from(results[0] as List);
        _topics = List<Map<String, dynamic>>.from(results[1] as List);
        _levels = List<Map<String, dynamic>>.from(results[2] as List);
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

  Future<void> _openCourseDialog({Map<String, dynamic>? course}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseEditorDialog(
        firestoreService: _firestoreService,
        initialCourse: course,
        topics: _topics,
        levels: _levels,
        createdBy: context.read<AuthProvider>().firebaseUser?.email ?? '',
      ),
    );

    if (didSave == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Курс сақталды.',
              ru: 'Курс сохранен.',
              en: 'Course saved.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openSectionsScreen(Map<String, dynamic> course) async {
    final languageCode = context.read<LanguageProvider>().currentLanguageCode;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSectionsScreen(
          courseId: (course['id'] ?? '').toString(),
          courseTitle: adminLocalizedValue(course['title'], languageCode),
        ),
      ),
    );

    if (!mounted) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LanguageProvider>().currentLanguageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Курстарды басқару',
            ru: 'Управление курсами',
            en: 'Manage courses',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
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
        onPressed: () => _openCourseDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          adminText(
            context,
            kk: 'Курс қосу',
            ru: 'Добавить курс',
            en: 'Add course',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: adminText(
                context,
                kk: 'Курс карточкалары',
                ru: 'Карточки курсов',
                en: 'Course cards',
              ),
              body: adminText(
                context,
                kk: 'Бұл жерде курстың негізгі деректерін өзгертуге болады: тақырып, деңгей, атауы, сипаттамасы, сурет сілтемесі, реті және жариялану күйі. Әр курс ішінен бөлімдерге өту де қолжетімді.',
                ru: 'Здесь можно менять основные данные курса: тему, уровень, название, описание, ссылку на изображение, порядок и статус публикации. Для каждого курса также доступен переход к разделам.',
                en: 'Here you can edit the core course data: topic, level, title, description, image URL, order, and publish state. Each course also links to section management.',
              ),
              icon: Icons.menu_book_rounded,
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
                onRetry: _loadData,
              )
            else if (_courses.isEmpty)
              AdminEmptyCard(
                message: adminText(
                  context,
                  kk: 'Әзірге бірде-бір курс жоқ.',
                  ru: 'Пока нет ни одного курса.',
                  en: 'There are no courses yet.',
                ),
                actionHint: adminText(
                  context,
                  kk: 'Алдымен тақырыптар мен деңгейлер дайын екеніне көз жеткізіп, содан кейін жаңа курс қосыңыз.',
                  ru: 'Убедитесь, что темы и уровни уже подготовлены, затем добавьте новый курс.',
                  en: 'Make sure topics and levels are ready first, then add a new course.',
                ),
                icon: Icons.menu_book_outlined,
              )
            else ...[
              Text(
                adminText(
                  context,
                  kk: 'Курс саны: ${_courses.length}',
                  ru: 'Количество курсов: ${_courses.length}',
                  en: 'Courses count: ${_courses.length}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ..._courses.map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openSectionsScreen(course),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.categoryFood.withOpacity(0.14),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.categoryFood,
                        ),
                      ),
                      title: Text(
                        adminLocalizedValue(course['title'], languageCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          adminText(
                            context,
                            kk:
                                'Тақырып: ${_topicTitle(course['topicId'], languageCode)} | Деңгей: ${_levelTitle(course['levelId'], languageCode)} | Реті: ${course['order'] ?? 0} | Сабақ саны: ${course['totalLessons'] ?? 0}',
                            ru:
                                'Тема: ${_topicTitle(course['topicId'], languageCode)} | Уровень: ${_levelTitle(course['levelId'], languageCode)} | Порядок: ${course['order'] ?? 0} | Уроков: ${course['totalLessons'] ?? 0}',
                            en:
                                'Topic: ${_topicTitle(course['topicId'], languageCode)} | Level: ${_levelTitle(course['levelId'], languageCode)} | Order: ${course['order'] ?? 0} | Lessons: ${course['totalLessons'] ?? 0}',
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
                                kk: 'Бөлімдерді ашу',
                                ru: 'Открыть разделы',
                                en: 'Open sections',
                              ),
                              onPressed: () => _openSectionsScreen(course),
                              icon: const Icon(Icons.view_agenda_outlined),
                            ),
                            IconButton(
                              tooltip: adminText(
                                context,
                                kk: 'Курсты өңдеу',
                                ru: 'Редактировать курс',
                                en: 'Edit course',
                              ),
                              onPressed: () => _openCourseDialog(course: course),
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

  String _topicTitle(dynamic topicId, String languageCode) {
    for (final topic in _topics) {
      if (topic['id'] == topicId) {
        return adminLocalizedValue(topic['title'], languageCode);
      }
    }
    return topicId?.toString() ?? '';
  }

  String _levelTitle(dynamic levelId, String languageCode) {
    for (final level in _levels) {
      if (level['id'] == levelId) {
        return adminLocalizedValue(level['title'], languageCode);
      }
    }
    return levelId?.toString() ?? '';
  }
}

class _CourseEditorDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final Map<String, dynamic>? initialCourse;
  final List<Map<String, dynamic>> topics;
  final List<Map<String, dynamic>> levels;
  final String createdBy;

  const _CourseEditorDialog({
    required this.firestoreService,
    required this.topics,
    required this.levels,
    required this.createdBy,
    this.initialCourse,
  });

  @override
  State<_CourseEditorDialog> createState() => _CourseEditorDialogState();
}

class _CourseEditorDialogState extends State<_CourseEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _orderController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _totalLessonsController;
  late final TextEditingController _titleKkController;
  late final TextEditingController _titleRuController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descKkController;
  late final TextEditingController _descRuController;
  late final TextEditingController _descEnController;

  late String _selectedTopicId;
  late String _selectedLevelId;
  bool _isPublished = true;
  bool _isSaving = false;

  bool get _isEditing => widget.initialCourse != null;

  @override
  void initState() {
    super.initState();
    final title = adminToStringMap(widget.initialCourse?['title']);
    final description = adminToStringMap(widget.initialCourse?['description']);

    _idController = TextEditingController(
      text: (widget.initialCourse?['id'] ?? '').toString(),
    );
    _orderController = TextEditingController(
      text: (widget.initialCourse?['order'] ?? 0).toString(),
    );
    _imageUrlController = TextEditingController(
      text: (widget.initialCourse?['imageUrl'] ?? '').toString(),
    );
    _totalLessonsController = TextEditingController(
      text: (widget.initialCourse?['totalLessons'] ?? 0).toString(),
    );
    _titleKkController = TextEditingController(text: title['kk'] ?? '');
    _titleRuController = TextEditingController(text: title['ru'] ?? '');
    _titleEnController = TextEditingController(text: title['en'] ?? '');
    _descKkController = TextEditingController(text: description['kk'] ?? '');
    _descRuController = TextEditingController(text: description['ru'] ?? '');
    _descEnController = TextEditingController(text: description['en'] ?? '');

    _selectedTopicId = (widget.initialCourse?['topicId'] ??
            widget.topics.firstOrNull?['id'] ??
            '')
        .toString();
    _selectedLevelId = (widget.initialCourse?['levelId'] ??
            widget.levels.firstOrNull?['id'] ??
            '')
        .toString();
    _isPublished = widget.initialCourse?['isPublished'] as bool? ?? true;
  }

  @override
  void dispose() {
    _idController.dispose();
    _orderController.dispose();
    _imageUrlController.dispose();
    _totalLessonsController.dispose();
    _titleKkController.dispose();
    _titleRuController.dispose();
    _titleEnController.dispose();
    _descKkController.dispose();
    _descRuController.dispose();
    _descEnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestoreService.upsertCourseData(
        courseId: _idController.text.trim(),
        topicId: _selectedTopicId,
        levelId: _selectedLevelId,
        order: int.tryParse(_orderController.text.trim()) ?? 0,
        title: {
          'kk': _titleKkController.text.trim(),
          'ru': _titleRuController.text.trim(),
          'en': _titleEnController.text.trim(),
        },
        description: {
          'kk': _descKkController.text.trim(),
          'ru': _descRuController.text.trim(),
          'en': _descEnController.text.trim(),
        },
        imageUrl: _imageUrlController.text.trim(),
        totalLessons: int.tryParse(_totalLessonsController.text.trim()) ?? 0,
        isPublished: _isPublished,
        createdBy: widget.createdBy,
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
    final locale = Localizations.localeOf(context).languageCode;
    final titleBase = adminText(
      context,
      kk: 'Атауы',
      ru: 'Название',
      en: 'Title',
    );
    final descriptionBase = adminText(
      context,
      kk: 'Сипаттамасы',
      ru: 'Описание',
      en: 'Description',
    );

    return AlertDialog(
      title: Text(
        adminText(
          context,
          kk: _isEditing ? 'Курсты өңдеу' : 'Жаңа курс',
          ru: _isEditing ? 'Редактирование курса' : 'Новый курс',
          en: _isEditing ? 'Edit course' : 'New course',
        ),
      ),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.topics.isEmpty || widget.levels.isEmpty) ...[
                  AdminEmptyCard(
                    message: adminText(
                      context,
                      kk: 'Курс құру үшін алдымен тақырыптар мен деңгейлерді толтыру керек.',
                      ru: 'Чтобы создать курс, сначала заполните темы и уровни.',
                      en: 'Create topics and levels first before adding a course.',
                    ),
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _idController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Курс ID',
                      ru: 'ID курса',
                      en: 'Course ID',
                    ),
                  ),
                  validator: _validateCourseId,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedTopicId.isEmpty ? null : _selectedTopicId,
                  items: widget.topics
                      .map(
                        (topic) => DropdownMenuItem<String>(
                          value: topic['id'].toString(),
                          child: Text(adminLocalizedValue(topic['title'], locale)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.topics.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTopicId = value;
                          });
                        },
                  validator: (_) => _validateSelectedValue(
                    _selectedTopicId,
                    kk: 'Тақырыпты таңдаңыз.',
                    ru: 'Выберите тему.',
                    en: 'Select a topic.',
                  ),
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Тақырып',
                      ru: 'Тема',
                      en: 'Topic',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedLevelId.isEmpty ? null : _selectedLevelId,
                  items: widget.levels
                      .map(
                        (level) => DropdownMenuItem<String>(
                          value: level['id'].toString(),
                          child: Text(adminLocalizedValue(level['title'], locale)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.levels.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedLevelId = value;
                          });
                        },
                  validator: (_) => _validateSelectedValue(
                    _selectedLevelId,
                    kk: 'Деңгейді таңдаңыз.',
                    ru: 'Выберите уровень.',
                    en: 'Select a level.',
                  ),
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Деңгей',
                      ru: 'Уровень',
                      en: 'Level',
                    ),
                  ),
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
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Сурет URL',
                      ru: 'URL изображения',
                      en: 'Image URL',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalLessonsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      kk: 'Жалпы сабақ саны',
                      ru: 'Всего уроков',
                      en: 'Total lessons',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isPublished,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    adminText(
                      context,
                      kk: 'Жарияланған',
                      ru: 'Опубликован',
                      en: 'Published',
                    ),
                  ),
                  subtitle: Text(
                    adminText(
                      context,
                      kk: 'Өшірілсе, курс пайдаланушылар каталогында көрінбейді.',
                      ru: 'Если выключено, курс не будет виден пользователям в каталоге.',
                      en: 'When disabled, the course will be hidden from the user catalog.',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isPublished = value;
                    });
                  },
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
                  controller: _descKkController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: descriptionBase,
                      languageCode: 'kk',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descRuController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: descriptionBase,
                      languageCode: 'ru',
                    ),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descEnController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: descriptionBase,
                      languageCode: 'en',
                    ),
                  ),
                  validator: _required,
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

  String? _validateCourseId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminText(
        context,
        kk: 'Курс ID міндетті.',
        ru: 'ID курса обязателен.',
        en: 'Course ID is required.',
      );
    }
    return null;
  }

  String? _validateSelectedValue(
    String value, {
    required String kk,
    required String ru,
    required String en,
  }) {
    if (value.trim().isEmpty) {
      return adminText(context, kk: kk, ru: ru, en: en);
    }
    return null;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminRequiredFieldText(context);
    }
    return null;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
