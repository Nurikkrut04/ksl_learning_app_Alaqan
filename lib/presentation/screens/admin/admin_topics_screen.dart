import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'admin_ui.dart';

class AdminTopicsScreen extends StatefulWidget {
  const AdminTopicsScreen({super.key});

  @override
  State<AdminTopicsScreen> createState() => _AdminTopicsScreenState();
}

class _AdminTopicsScreenState extends State<AdminTopicsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topics = await _firestoreService.getTopics();
      if (!mounted) return;
      setState(() {
        _topics = topics;
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

  Future<void> _openTopicDialog({Map<String, dynamic>? topic}) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _TopicEditorDialog(
        firestoreService: _firestoreService,
        initialTopic: topic,
      ),
    );

    if (didSave == true) {
      await _loadTopics();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              kk: 'Тақырып сақталды.',
              ru: 'Тема сохранена.',
              en: 'Topic saved.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Тақырыптарды басқару',
            ru: 'Управление темами',
            en: 'Manage topics',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTopics,
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
        onPressed: () => _openTopicDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          adminText(
            context,
            kk: 'Тақырып қосу',
            ru: 'Добавить тему',
            en: 'Add topic',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTopics,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: adminText(
                context,
                kk: 'Тақырыптар тізімі',
                ru: 'Список тем',
                en: 'Topic list',
              ),
              body: adminText(
                context,
                kk: 'Тақырып ID мәнін тұрақты ұстаған дұрыс. Мысалы: communication, family, food. Атауларды үш тілде толтыру интерфейстегі мультиязықтылықты сақтайды.',
                ru: 'ID темы лучше держать стабильным. Например: communication, family, food. Названия на трех языках сохраняют мультиязычность интерфейса.',
                en: 'Keep topic IDs stable, for example: communication, family, food. Filling names in all three languages keeps the interface multilingual.',
              ),
              icon: Icons.dashboard_customize_rounded,
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
                onRetry: _loadTopics,
              )
            else if (_topics.isEmpty)
              AdminEmptyCard(
                message: adminText(
                  context,
                  kk: 'Әзірге бірде-бір тақырып жоқ.',
                  ru: 'Пока нет ни одной темы.',
                  en: 'There are no topics yet.',
                ),
                actionHint: adminText(
                  context,
                  kk: 'Жаңа тақырып қосу үшін төмендегі батырманы пайдаланыңыз.',
                  ru: 'Используйте кнопку ниже, чтобы добавить первую тему.',
                  en: 'Use the button below to add your first topic.',
                ),
                icon: Icons.dashboard_customize_outlined,
              )
            else ...[
              Text(
                adminText(
                  context,
                  kk: 'Тақырып саны: ${_topics.length}',
                  ru: 'Количество тем: ${_topics.length}',
                  en: 'Topics count: ${_topics.length}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ..._topics.map(
                (topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.categoryCommunication.withOpacity(0.14),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: AppColors.categoryCommunication,
                        ),
                      ),
                      title: Text(
                        adminLocalizedValueForContext(topic['title'], context),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          adminText(
                            context,
                            kk:
                                'ID: ${topic['id']} | Реті: ${topic['order'] ?? 0}',
                            ru:
                                'ID: ${topic['id']} | Порядок: ${topic['order'] ?? 0}',
                            en:
                                'ID: ${topic['id']} | Order: ${topic['order'] ?? 0}',
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: adminText(
                          context,
                          kk: 'Тақырыпты өңдеу',
                          ru: 'Редактировать тему',
                          en: 'Edit topic',
                        ),
                        onPressed: () => _openTopicDialog(topic: topic),
                        icon: const Icon(Icons.edit_outlined),
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

class _TopicEditorDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final Map<String, dynamic>? initialTopic;

  const _TopicEditorDialog({
    required this.firestoreService,
    this.initialTopic,
  });

  @override
  State<_TopicEditorDialog> createState() => _TopicEditorDialogState();
}

class _TopicEditorDialogState extends State<_TopicEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _orderController;
  late final TextEditingController _kkController;
  late final TextEditingController _ruController;
  late final TextEditingController _enController;

  bool _isSaving = false;

  bool get _isEditing => widget.initialTopic != null;

  @override
  void initState() {
    super.initState();
    final title = adminToStringMap(widget.initialTopic?['title']);

    _idController = TextEditingController(
      text: (widget.initialTopic?['id'] ?? '').toString(),
    );
    _orderController = TextEditingController(
      text: (widget.initialTopic?['order'] ?? 0).toString(),
    );
    _kkController = TextEditingController(text: title['kk'] ?? '');
    _ruController = TextEditingController(text: title['ru'] ?? '');
    _enController = TextEditingController(text: title['en'] ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _orderController.dispose();
    _kkController.dispose();
    _ruController.dispose();
    _enController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestoreService.upsertTopic(
        topicId: _idController.text.trim(),
        order: int.tryParse(_orderController.text.trim()) ?? 0,
        title: {
          'kk': _kkController.text.trim(),
          'ru': _ruController.text.trim(),
          'en': _enController.text.trim(),
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
        _isEditing
            ? adminText(
                context,
                kk: 'Тақырыпты өңдеу',
                ru: 'Редактирование темы',
                en: 'Edit topic',
              )
            : adminText(
                context,
                kk: 'Жаңа тақырып',
                ru: 'Новая тема',
                en: 'New topic',
              ),
      ),
      content: SizedBox(
        width: 500,
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
                      kk: 'Тақырып ID',
                      ru: 'ID темы',
                      en: 'Topic ID',
                    ),
                  ),
                  validator: _validateTopicId,
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
                  controller: _kkController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'kk',
                    ),
                  ),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ruController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'ru',
                    ),
                  ),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _enController,
                  decoration: InputDecoration(
                    labelText: adminLanguageLabel(
                      context,
                      base: titleBase,
                      languageCode: 'en',
                    ),
                  ),
                  validator: _requiredField,
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

  String? _validateTopicId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminText(
        context,
        kk: 'Тақырып ID міндетті.',
        ru: 'ID темы обязателен.',
        en: 'Topic ID is required.',
      );
    }
    return null;
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return adminRequiredFieldText(context);
    }
    return null;
  }
}
