# Інструкція з налаштування та запуску

## 1. Встановіть Flutter SDK

1. Завантажте: https://docs.flutter.dev/get-started/install/windows/mobile
2. Розпакуйте у `C:\flutter`
3. Додайте `C:\flutter\bin` до системної змінної `PATH`

## 2. Встановіть Android Studio

1. Завантажте: https://developer.android.com/studio
2. Встановіть із усіма компонентами за замовчуванням (Android SDK, AVD)
3. Після встановлення: Android Studio → SDK Manager → встановіть Android 14 (API 34)

## 3. Перевірте середовище

Відкрийте термінал у цій папці та виконайте:
```
flutter doctor
```
Виправіть всі помилки (accept Android licenses, тощо).

## 4. Ініціалізуйте Flutter-проект

```
flutter create . --project-name judo_app --org com.judoclub
```
Це створить Android-файли без перезапису вашого коду в lib/.

## 5. Налаштуйте Firebase

### 5а. Створіть Firebase-проект
1. Зайдіть на https://console.firebase.google.com
2. Натисніть "Додати проект" → введіть назву → створіть
3. Увімкніть Google Analytics (за бажанням)

### 5б. Додайте Android-застосунок
1. У Firebase Console → Project Overview → натисніть Android-іконку
2. Android package name: `com.judoclub.judo_app`
3. Введіть нікнейм застосунку (наприклад: "Дзюдо Клуб")
4. Завантажте `google-services.json`
5. Помістіть `google-services.json` у папку `android/app/`

### 5в. Увімкніть сервіси Firebase
У Firebase Console:
- **Authentication** → Sign-in method → Email/Password → Увімкнути
- **Firestore Database** → Створити базу → Режим "Тест" (на початку)
- **Storage** → Почати

### 5г. Встановіть FlutterFire CLI та налаштуйте
```
dart pub global activate flutterfire_cli
flutterfire configure
```
Це замінить файл `lib/firebase_options.dart` на реальний конфіг.

## 6. Встановіть залежності

```
flutter pub get
```

## 7. Налаштуйте Firestore Rules

У Firebase Console → Firestore → Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Authenticated users can read children list
    match /children/{childId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
    
    // Users can read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Results: read for all, write for coaches
    match /competition_results/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
    
    // Belt requirements: read for all, write for coaches
    match /belt_requirements/{belt} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
    
    // Belt progress: read for all, write for coaches
    match /belt_progress/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
    
    // Competition types: read for all, write for coaches
    match /competition_types/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
  }
}
```

## 8. Запустіть застосунок

Підключіть Android-пристрій або запустіть емулятор, потім:
```
flutter run
```

## 9. Збірка для Google Play

```
flutter build appbundle --release
```
Файл буде у `build/app/outputs/bundle/release/app-release.aab`
