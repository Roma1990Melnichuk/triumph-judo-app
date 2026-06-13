# Claude Code — інструкції для цього проекту

## Команда «перевір все» / «check everything»

Коли користувач пише щось на кшталт **«перевір все»**, **«check everything»**, **«все ок?»** — виконай три кроки по черзі:

```powershell
flutter analyze --no-fatal-infos
flutter test --reporter compact
flutter build apk --debug --quiet
```

Або одним скриптом:
```powershell
.\scripts\check_all.ps1
```

### Що вважається успіхом
| Крок | Умова успіху |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings (infos — ок) |
| `flutter test` | всі тести green, жодного failed |
| `flutter build apk --debug` | виходить без помилок |

Якщо щось впало — повідом які саме кроки і покажи перші рядки помилки.

## Layout & overflow — обов'язкові правила

### FlexibleSpaceBar — подвійний заголовок
`FlexibleSpaceBar` з одночасно заповненим `background` (в якому є Text із назвою) **і** `title:` → назва відображається двічі.  
**Правило:** якщо заголовок вже є в `background`, `title:` **НЕ вказувати**.

```dart
// ❌ НЕПРАВИЛЬНО
FlexibleSpaceBar(
  background: Column(children: [Text('Назва екрану')]),
  title: Text('Назва'),   // ← дублює заголовок
)

// ✓ ПРАВИЛЬНО
FlexibleSpaceBar(
  background: Column(children: [Text('Назва екрану')]),
  // title: — відсутній
)
```

### showModalBottomSheet — overflow
`Column(mainAxisSize: MainAxisSize.min)` в `builder` **без** `Flexible + SingleChildScrollView` → BOTTOM OVERFLOWED коли список довгий.  
**Правило:** завжди загортати список в `Flexible(child: SingleChildScrollView(...))`.

```dart
// ❌ НЕПРАВИЛЬНО
showModalBottomSheet(builder: (_) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [...items],   // overflow при > ~8 елементах
));

// ✓ ПРАВИЛЬНО
showModalBottomSheet(
  isScrollControlled: true,
  builder: (_) => SafeArea(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Заголовок'),
      Flexible(child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [...items],
      ))),
    ],
  )),
);
```

### e2e тести — обов'язково після будь-якої UI-зміни

1. Тест для зміненого екрану — у `test/e2e/screens/<feature>_e2e_test.dart`
2. **НЕ suppressувати overflow** у `FlutterError.onError` — overflow повинен валити тест
3. Перевіряти що заголовок не дублюється: `expect(find.text('Назва'), findsOneWidget)`
4. Якщо є модалі/пікери з довгими списками — тест повинен їх відкрити і перевірити відсутність overflow

```dart
// ❌ НЕПРАВИЛЬНО — ховає баги
FlutterError.onError = (d) {
  if (d.toString().contains('overflowed')) return; // ЗАБОРОНЕНО
  handler?.call(d);
};

// ✓ ПРАВИЛЬНО — overflow автоматично валить тест
testWidgets('екран без overflow', (tester) async {
  await tester.pumpWidget(buildScreen());
  await tester.pump();
  expect(tester.takeException(), isNull);
  expect(find.text('Назва'), findsOneWidget);  // рівно один раз
});
```

Після зміни запустити:
```powershell
flutter test test/e2e/screens/ --reporter compact
```

## Загальні правила

- Проект: Flutter + Firebase Android (клуб дзюдо «Тріумф»)
- Мова UI: українська (всі текстові рядки — uk)
- Іконки: `TriumphIcon(TIcon.x)` — WebP з непрозорим фоном → **не використовувати ColorFilter.srcIn**, тільки Material `Icons.*` або `ShaderMask(BlendMode.srcATop)`
- Завантаження фото/відео: Cloudinary (`lib/core/utils/cloudinary_upload.dart`), не Firebase Storage
- Тести: `flutter test`, файли в `test/`

## Структура

```
lib/
  core/          — моделі, константи, сервіси
  features/      — екрани/провайдери по фічах
  shared/        — спільні віджети
test/            — unit-тести (без Firebase, без UI)
scripts/         — допоміжні скрипти
```
