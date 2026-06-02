import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'admin_lessons_screen.dart';
import 'admin_ui.dart';

class AdminSectionsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const AdminSectionsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AdminSectionsScreen> createState() => _AdminSectionsScreenState();
}

class _AdminSectionsScreenState extends State<AdminSectionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sections = await _firestoreService.getSections(widget.courseId);
      if (!mounted) return;
      setState(() {
        _sections = sections;
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

  Future<void> _openSectionDialog({Map<String, dynamic>? section}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _SectionEditorDialog(
        firestoreService: _firestoreService,
        courseId: widget.courseId,
        initialSection: section,
      ),
    );

    if (didSave == true) {
      await _loadSections();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Бөлім сақталды.',
              ru: 'Раздел сохранен.',
              en: 'Section saved.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openLessonsScreen(Map<String, dynamic> section) async {
    final languageCode = Localizations.localeOf(context).languageCode;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLessonsScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          sectionId: (section['id'] ?? '').toString(),
          sectionTitle: adminLocalizedValue(section['title'], languageCode),
        ),
      ),
    );

    if (!mounted) return;
    await _loadSections();
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
            kk: 'Бөлімдерді басқару',
            ru: 'Управление разделами',
            en: 'Manage sections',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadSections,
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
        onPressed: () => _openSectionDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          adminText(
            context,
            kk: 'Бөлім қосу',
            ru: 'Добавить раздел',
            en: 'Add section',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSections,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: widget.courseTitle,
              caption: adminText(
                context,
                kk: 'Курс ID: ${widget.courseId}',
                ru: 'ID курса: ${widget.courseId}',
                en: 'Course ID: ${widget.courseId}',
              ),
              body: adminText(
                context,
                kk: 'Бұл экран таңдалған курс ішіндегі бөлімдерді басқаруға арналған: тізімді көру, жаңа бөлім қосу, өңдеу және әр бөлімнің сабақтарына өту.',
                ru: 'Этот экран нужен для управления разделами внутри выбранного курса: просмотр списка, добавление, редактирование и переход к урокам каждого раздела.',
                en: 'This screen manages sections inside the selected course: listing, creating, editing, and opening lessons for each section.',
              ),
              icon: Icons.view_agenda_rounded,
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
                onRetry: _loadSections,
              )
            else if (_sections.isEmpty)
              AdminEmptyCard(
                message: adminText(
                  context,
                  kk: 'Бұл курста әзірге бөлімдер жоқ.',
                  ru: 'В этом курсе пока нет разделов.',
                  en: 'There are no sections in this course yet.',
                ),
                actionHint: adminText(
                  context,
                  kk: 'Алдымен бөлім қосып, содан кейін оның ішіне сабақтар енгізуге болады.',
                  ru: 'Сначала добавьте раздел, а затем внутри него можно будет создать уроки.',
                  en: 'Add a section first, then you can create lessons inside it.',
                ),
                icon: Icons.view_agenda_outlined,
              )
            else ...[
              Text(
                adminText(
                  context,
                  kk: 'Бөлім саны: ${_sections.length}',
                  ru: 'Количество разделов: ${_sections.length}',
                  en: 'Sections count: ${_sections.length}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ..._sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openLessonsScreen(section),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.14),
                        child: const Icon(
                          Icons.view_agenda_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        adminLocalizedValue(section['title'], languageCode),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          adminText(
                            context,
                            kk:
                                'ID: ${section['id']} | Реті: ${section['order'] ?? 0} | Сабақ саны: ${section['totalLessons'] ?? 0}',
                            ru:
                                'ID: ${section['id']} | Порядок: ${section['order'] ?? 0} | Уроков: ${section['totalLessons'] ?? 0}',
                            en:
                                'ID: ${section['id']} | Order: ${section['order'] ?? 0} | Lessons: ${section['totalLessons'] ?? 0}',
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
                                kk: 'Сабақтарды ашу',
                                ru: 'Открыть уроки',
                                en: 'Open lessons',
                              ),
                              onPressed: () => _openLessonsScreen(section),
                              icon: const Icon(Icons.play_lesson_outlined),
                            ),
                            IconButton(
                              tooltip: adminText(
                                context,
                                kk: 'Бөлімді өңдеу',
                                ru: 'Редактировать раздел',
                                en: 'Edit section',
                              ),
                              onPressed: () => _openSectionDialog(section: section),
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
}

class _SectionEditorDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String courseId;
  final Map<String, dynamic>? initialSection;

  const _SectionEditorDialog({
    required this.firestoreService,
    required this.courseId,
    this.initialSection,
  });

  @override
  State<_SectionEditorDialog> createState() => _SectionEditorDialogState();
}

class _SectionEditorDialogState extends State<_SectionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _orderController;
  late final TextEditingController _totalLessonsController;
  late final TextEditingController _titleKkController;
  late final TextEditingController _titleRuController;
  late final TextEditingController _titleEnController;

  bool _isSaving = false;

  bool get _isEditing => widget.initialSection != null;

  @override
  void initState() {
    super.initState();
    final title = adminToStringMap(widget.initialSection?['title']);

    _idController = TextEditingController(
      text: (widget.initialSection?['id'] ?? '').toString(),
    );
    _orderController = TextEditingController(
      text: (widget.initialSection?['order'] ?? 0).toString(),
    );
    _totalLessonsController = TextEditingController(
      text: (widget.initialSection?['totalLessons'] ?? 0).toString(),
    );
    _titleKkController = TextEditingController(text: title['kk'] ?? '');
    _titleRuController = TextEditingController(text: title['ru'] ?? '');
    _titleEnController = TextEditingController(text: title['en'] ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _orderController.dispose();
    _totalLessonsController.dispose();
    _titleKkController.dispose();
    _titleRuController.dispose();
    _titleEnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestoreService.upsertSection(
        courseId: widget.courseId,
        sectionId: _idController.text.trim(),
        order: int.tryParse(_orderController.text.trim()) ?? 0,
        totalLessons: int.tryParse(_totalLessonsController.text.trim()) ?? 0,
        title: {
          'kk': _titleKkController.text.trim(),
          'ru': _titleRuController.text.trim(),
          'en': _titleEnController.text.trim(),
        },
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
          kk: _isEditing ? 'Бөлімді өңдеу' : 'Жаңа бөлім',
          ru: _isEditing ? 'Редактирование раздела' : 'Новый раздел',
          en: _isEditing ? 'Edit section' : 'New section',
        ),
      ),
      content: SizedBox(
        width: 520,
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
                      kk: 'Бөлім ID',
                      ru: 'ID раздела',
                      en: 'Section ID',
                    ),
                  ),
                  validator: _validateSectionId,
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

  String? _validateSectionId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminText(
        context,
        kk: 'Бөлім ID міндетті.',
        ru: 'ID раздела обязателен.',
        en: 'Section ID is required.',
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
}
