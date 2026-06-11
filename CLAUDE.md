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
