# KSL Learning App - Казахский Жестовый Язык

Мобильное приложение для изучения казахского жестового языка (КЖЯ) для детей, семей и начинающих.

## 📱 О проекте

Кроссплатформенное мобильное приложение на Flutter с serverless архитектурой для изучения казахского жестового языка.

### Основные возможности:

- ✅ Структурированное обучение (Курсы → Темы → Уроки)
- ✅ Видео демонстрации жестов
- ✅ Интерактивные тесты после уроков
- ✅ Отслеживание прогресса обучения
- ✅ Офлайн режим (Hive)
- ✅ Мультиязычность (Казахский, Русский, Английский)
- ✅ Аутентификация пользователей (Firebase Auth)
- ✅ Административная панель

## 🛠 Технологический стек

### Frontend
- **Flutter** (Dart) - Кроссплатформенная разработка
- **Provider** - State Management
- **Hive** - Локальное хранилище для офлайн режима

### Backend (Serverless)
- **Firebase Authentication** - Аутентификация
- **Cloud Firestore** - NoSQL база данных
- **Firebase Security Rules** - Контроль доступа
- **Cloud Functions** (опционально) - Для админ операций

### Медиа
- **Cloudinary** - Хранение и стриминг видео

## 📋 Предварительные требования

Перед началом работы убедитесь, что у вас установлено:

1. **Flutter SDK** (>=3.0.0)
   ```bash
   flutter --version
   ```
   Если Flutter не установлен: https://docs.flutter.dev/get-started/install

2. **Dart SDK** (входит в Flutter)

3. **Android Studio** или **VS Code** с Flutter расширениями

4. **Git**

5. Для iOS разработки: **Xcode** (только macOS)

6. **Firebase CLI** (для настройки Firebase)
   ```bash
   npm install -g firebase-tools
   ```

7. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

## 🚀 Установка и запуск

### Шаг 1: Клонирование проекта

```bash
cd /path/to/your/directory
# Проект уже создан как ksl_learning_app
cd ksl_learning_app
```

### Шаг 2: Установка зависимостей

```bash
flutter pub get
```

### Шаг 3: Настройка Firebase

#### 3.1 Создание Firebase проекта

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Add project" (Добавить проект)
3. Введите название проекта: `ksl-learning-app`
4. Следуйте инструкциям мастера

#### 3.2 Включение необходимых сервисов

В Firebase Console:

**Authentication:**
- Перейдите в "Authentication" → "Sign-in method"
- Включите "Email/Password"

**Firestore Database:**
- Перейдите в "Firestore Database"
- Нажмите "Create database"
- Выберите "Start in production mode"
- Выберите регион (europe-west)

**Storage** (опционально, если не используете Cloudinary):
- Перейдите в "Storage"
- Нажмите "Get started"

#### 3.3 Настройка Firebase для Flutter

```bash
# Войдите в Firebase
firebase login

# Настройте Firebase для Flutter (автоматически создаст firebase_options.dart)
flutterfire configure
```

Выберите созданный Firebase проект и платформы (Android, iOS).

#### 3.4 Настройка Security Rules

Перейдите в Firestore Database → Rules и вставьте:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isAdmin();
      
      match /progress/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
    
    match /courses/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    match /gestures/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    match /appSettings/{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

### Шаг 4: Настройка Cloudinary (для видео)

1. Зарегистрируйтесь на [Cloudinary](https://cloudinary.com/)
2. В Dashboard скопируйте:
   - Cloud Name
   - API Key
   - API Secret

3. Откройте `lib/core/config/cloudinary_config.dart` и замените:
```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String apiKey = 'YOUR_API_KEY';
static const String apiSecret = 'YOUR_API_SECRET';
```

### Шаг 5: Генерация локализации

```bash
flutter gen-l10n
```

### Шаг 6: Запуск приложения

#### На эмуляторе Android:
```bash
flutter run
```

#### На конкретном устройстве:
```bash
# Посмотреть список устройств
flutter devices

# Запустить на конкретном устройстве
flutter run -d <device-id>
```

## 📂 Структура проекта

```
ksl_learning_app/
├── lib/
│   ├── core/                       # Ядро приложения
│   │   ├── config/                 # Конфигурация (Firebase, Cloudinary)
│   │   ├── constants/              # Константы
│   │   ├── localization/           # Локализация
│   │   ├── theme/                  # Темы, цвета, стили
│   │   └── utils/                  # Утилиты
│   ├── data/                       # Слой данных
│   │   ├── models/                 # Модели данных
│   │   ├── repositories/           # Репозитории
│   │   └── local/                  # Локальное хранилище (Hive)
│   ├── presentation/               # Слой представления
│   │   ├── providers/              # State Management (Provider)
│   │   ├── screens/                # Экраны приложения
│   │   └── widgets/                # Виджеты
│   ├── services/                   # Сервисы (Auth, Firestore, Hive)
│   ├── app.dart                    # Конфигурация MaterialApp
│   └── main.dart                   # Точка входа
├── assets/                         # Ресурсы (изображения, шрифты)
├── pubspec.yaml                    # Зависимости
└── README.md                       # Этот файл
```

## 🔥 Firestore структура данных

### Collections:

#### users/{userId}
```json
{
  "email": "user@example.com",
  "displayName": "Имя",
  "role": "user",
  "preferredLanguage": "kk",
  "avatarUrl": null,
  "createdAt": Timestamp,
  "lastLoginAt": Timestamp,
  "isOnline": false,
  "settings": {
    "notificationsEnabled": true,
    "offlineMode": true,
    "theme": "light"
  }
}
```

#### courses/{courseId}
```json
{
  "title": {
    "kk": "Негізгі қимылдар",
    "ru": "Базовые жесты",
    "en": "Basic Gestures"
  },
  "description": {...},
  "thumbnailUrl": "cloudinary_url",
  "difficulty": "beginner",
  "totalTopics": 5,
  "totalLessons": 25,
  "isPublished": true,
  "order": 1
}
```

## 👨‍💻 Разработка

### Создание первого администратора

После регистрации первого пользователя, вручную установите роль admin в Firestore:

1. Откройте Firebase Console → Firestore Database
2. Найдите документ пользователя: `users/{userId}`
3. Измените поле `role` на `"admin"`

### Добавление курсов и уроков

Используйте административную панель в приложении (доступна только для admin).

### Тестовые данные

Вы можете импортировать тестовые данные через Firebase Console или создать их через админ панель.

## 🧪 Тестирование

```bash
# Запуск unit тестов
flutter test

# Запуск integration тестов
flutter drive --target=test_driver/app.dart
```

## 📱 Сборка для продакшена

### Android (APK)
```bash
flutter build apk --release
```

### Android (App Bundle для Google Play)
```bash
flutter build appbundle --release
```

### iOS (требуется macOS и Xcode)
```bash
flutter build ios --release
```

## 🌐 Поддерживаемые языки

- 🇰🇿 Казахский (kk)
- 🇷🇺 Русский (ru)
- 🇬🇧 Английский (en)

## 🔐 Безопасность

- Аутентификация через Firebase Authentication
- Контроль доступа через Firestore Security Rules
- Пароли хешируются Firebase Auth
- Админ права проверяются на уровне Security Rules

## 📝 TODO / Будущие улучшения

- [ ] Система достижений
- [ ] Социальные функции (друзья, рейтинги)
- [ ] Push уведомления
- [ ] Темная тема
- [ ] Распознавание жестов через камеру (ML)
- [ ] Голосовые подсказки
- [ ] Расширенная аналитика прогресса

## ⚠️ Известные проблемы

1. **Firebase не настроен**: Если видите ошибку при запуске, выполните `flutterfire configure`
2. **Локализация не работает**: Выполните `flutter gen-l10n`
3. **Hive ошибки**: Убедитесь что выполнен `flutter pub get`

## 📧 Контакты и поддержка

- Email: support@ksl-app.kz
- GitHub Issues: [создать issue]

## 📄 Лицензия

Этот проект создан для дипломной работы.

---

**Разработано с ❤️ для изучения казахского жестового языка**
