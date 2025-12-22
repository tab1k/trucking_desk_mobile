# Fura24.kz Mobile (trucking_desk_mobile)

> Многоязычное Flutter‑приложение для экосистемы грузоперевозок: поиск транспорта, создание и сопровождение заявок, рабочее место водителя и клиента.

## Ключевые возможности
- **Для клиентов**: карта с текущим местоположением и активными рейсами, быстрые действия (создать заказ, найти транспорт, история), отслеживание груза и драг‑шторка с деталями (`lib/features/client/presentation/pages/home/home_tab.dart`).
- **Мастер создания объявления**: 4 шага с контекстными подсказками, загрузкой до 6 фотографий, выбором транспорта, оплаты и валюты; отправка формируется в `CreateOrderRequest` и уходит в `OrderRepository` через Dio (`lib/features/client/presentation/pages/home/subpages/create_order_page.dart`).
- **Локации и карты**: OpenStreetMap через `flutter_map`, геолокация и фоновые обновления от `geolocator`, ручной выбор города с поиском и дебаунсом (см. `lib/features/locations`).
- **Роли и аутентификация**: единый экран входа/регистрации с переключением «Грузоотправитель / Водитель», хранение сессии в `SharedPreferences`, автоматическое обновление токена (`lib/features/auth`).
- **Кабинет водителя**: отдельный `DriverDashboardShell` с вкладками «Главная», «Рейсы», «Кошелёк», «Профиль» (`lib/features/driver/view`).
- **Инфраструктура приложения**: маршрутизация через `go_router`, управление состоянием на `flutter_riverpod`, локализация на `easy_localization` (ru/en/kk/ch), адаптивная верстка `flutter_screenutil`, skeleton‑экраны `shimmer`.

## Технологический стек
- **Flutter 3.24+/Dart 3.8** — единая codebase для Android, iOS, Web и десктопа.
- **State & DI**: Riverpod (`Provider`, `StateNotifierProvider`), ValueNotifier для легковесных состояний.
- **Сеть**: Dio с централизованной конфигурацией (`lib/core/network/dio_provider.dart`), обработка ошибок `ApiException`.
- **Геосервисы**: `flutter_map`, `latlong2`, `geolocator`, `geocoding`, `connectivity_plus`.
- **UX**: `modal_bottom_sheet`, `flutter_svg`, `timeago`, `shimmer`, `country_code_picker`, `image_picker`, `file_picker`.
- **Локализация**: `easy_localization` + JSON‑файлы в `assets/translations` (ru/en/kk/ch).

## Структура проекта
```
lib/
  core/               # AppConfig, сеть, исключения
  router/             # GoRouter и маршруты
  shared/             # Переиспользуемые провайдеры и виджеты
  features/
    auth/             # Авторизация/регистрация, хранение сессии
    client/           # Домашний экран, заказы, профиль клиента
    driver/           # Кабинет водителя и табы
    locations/        # Поиск городов, picker
    profile/, services/...
assets/
  img/, svg/, translations/
test/
  widget_test.dart    # Точка входа для UI‑тестов
analysis_options.yaml # Набор flutter_lints
```

## Требования
- Flutter SDK 3.24+ (Dart 3.8). Проверить: `flutter --version`.
- Xcode 15+ для iOS, Android Studio / SDK 34+ для Android.
- Подписанные ключи/профили для release‑сборок (см. официальные гайды Flutter).

## Быстрый старт
1. Установите Flutter и необходимые toolchains (Android/iOS).
2. Склонируйте репозиторий и перейдите в каталог проекта.
3. Установите зависимости:  
   ```bash
   flutter pub get
   ```
4. (Опционально) Сгенерируйте ключи для переводов, если используете `locale_keys.g.dart`:  
   ```bash
   flutter pub run easy_localization:generate \
     -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys
   ```
5. Запустите приложение:  
   ```bash
   flutter run --dart-define=API_BASE_URL=https://api.dev.fura24.kz/api/v1
   ```

## Переменные окружения и конфигурация
- `API_BASE_URL` — обязательный `--dart-define`, если адрес бэкенда отличается от дефолтного `http://192.168.31.99:8000/api/v1` (`lib/core/config/app_config.dart`).  
  Примеры:
  ```bash
  flutter run -d chrome \
    --dart-define=API_BASE_URL=https://api.stage.fura24.kz/api/v1

  flutter build apk --release \
    --dart-define=API_BASE_URL=https://api.prod.fura24.kz/api/v1
  ```
- Только HTTPS на проде; для локального теста можно оставить HTTP или добавить прокси/туннель.
- Карты используют публичные тайлы OpenStreetMap. Для продакшена рекомендуется настроить собственный tile-сервер или подключить коммерческий провайдер, чтобы не нарушать ToS.

## Работа с переводами
- Файлы: `assets/translations/ru.json`, `en.json`, `kz.json`, `ch.json`.
- После изменения JSON обновите версии приложений и (при необходимости) пересоберите `locale_keys.g.dart`.
- При загрузке приложения `EasyLocalization` подхватывает локаль устройства, fallback — русская (`lib/main.dart`).

## Тесты и качество
- Анализ кода: `flutter analyze`.
- Unit/UI-тесты: `flutter test`.
- Валидация локализации (пример):  
  ```bash
  flutter pub run easy_localization:generate --watch ...
  ```
- В CI перед release стоит запускать `flutter test`, `flutter analyze` и smoke-тест сборок (`flutter build apk/appbundle/ipa`).

## Сборка и публикация
- **Android**:
  - Debug: `flutter run`.
  - Release APK: `flutter build apk --release --dart-define=API_BASE_URL=...`.
  - Play Store: `flutter build appbundle --release --dart-define=API_BASE_URL=...`.
- **iOS**:
  - Установите pods: `cd ios && pod install`.
  - TestFlight: `flutter build ipa --release --dart-define=API_BASE_URL=...`.
- **Web/Desktop** (по необходимости): `flutter build web`, `flutter build macos/windows/linux`.
- Иконки/сплэши: обновить `assets/img/logo.jpeg`, затем `flutter pub run flutter_launcher_icons:main`.

## Платформенные настройки
- Android: разрешения для сети и геолокации уже описаны в `android/app/src/main/AndroidManifest.xml`. При использовании фоновой геолокации раскомментируйте `ACCESS_BACKGROUND_LOCATION`.
- iOS: текст запросов прав (`NSLocationWhenInUseUsageDescription` и т.д.) настроен в `ios/Runner/Info.plist`. При изменении функционала обновите формулировки.
- Не забудьте добавить ключи API (если появятся) в `ios/Runner/Info.plist` и `android/app/src/main/AndroidManifest.xml`.

## Полезные сценарии разработки
- Быстро сменить роль пользователя после логина можно через `AuthRoutes` (`lib/router/routes.dart`) или метод `authController.readSession()`.
- Для визуальных отступов и адаптива используйте `ScreenUtilInit` из `lib/main.dart`.
- Общие виджеты и провайдеры храните в `lib/shared/`, чтобы не нарушать границы feature-модулей.
- Для долгих операций отправляйте ошибки через `ApiException` — они уже корректно форматируются в UI (см. `authErrorMessage` и `createOrderError`).

## Дальнейшее развитие
- Подключение реальных API для списка рейсов/кошелька водителя.
- Интеграция пушей (Firebase Cloud Messaging) для обновлений статуса груза.
- Выделение UI-тестов для мастера заказа и карт, чтобы покрыть критические пользовательские сценарии.

Готово! Если появились вопросы или идеи по улучшению, заводите issue/таску прямо рядом с модулем, к которому относится изменение.
