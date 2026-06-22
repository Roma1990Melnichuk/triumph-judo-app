# Test Audit Matrix — Triumph Judo App

> Дата аудиту: 2026-06-22  
> Метод: статичний аналіз коду (70 агентів, 1 606 853 токени)

---

## Summary Statistics

| Метрика | Значення |
|---|---|
| Всього екранів (routes) | 77 |
| Тестових файлів проаналізовано | 42 |
| **GOOD_TEST** | **0** |
| **WEAK_TEST** | **25** |
| **FAKE_COVERAGE** | **17** |
| Непокритих екранів | 61 |
| Покритих екранів | 16 |
| Знайдено HIGH багів | 71 |
| Знайдено MEDIUM багів | 103 |
| Знайдено LOW багів | ~50 |

---

## 1. All Screens Registry

### Auth / System (4 екрани)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /splash | SplashScreen | all | — | ❌ UNCOVERED |
| /removed | AccessRemovedScreen | parent | — | ❌ UNCOVERED |
| /auth/login | LoginScreen | all | auth_e2e_test.dart | WEAK_TEST |
| /auth/register | RegisterScreen | all | registration_e2e_test.dart | FAKE_COVERAGE |

### Shell / BottomNav (7 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /home | HomeScreen | all | home_e2e_test.dart | WEAK_TEST |
| /team | TeamListScreen | coach,parent | team_e2e_test.dart | WEAK_TEST |
| /rating | RatingScreen | all | rating_provider_e2e_test.dart | WEAK_TEST |
| /events | EventsScreen | all | events_e2e_test.dart | FAKE_COVERAGE |
| /nutrition | NutritionScreen | all | nutrition_e2e_test.dart | FAKE_COVERAGE |
| /belts | BeltOverviewScreen | all | belts_e2e_test.dart | WEAK_TEST |
| /settings | SettingsScreen | all | settings_e2e_test.dart | WEAK_TEST |

### Team (5 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /team/add | AddEditChildScreen (add) | coach | — | ❌ UNCOVERED |
| /team/:id | ChildProfileScreen | coach,parent | — | ❌ UNCOVERED |
| /team/:id/edit | AddEditChildScreen (edit) | coach | — | ❌ UNCOVERED |
| /team/:id/add-result | AddResultScreen | coach | — | ❌ UNCOVERED |
| /team/:id/measurements | BodyMeasurementsScreen | coach | — | ❌ UNCOVERED |

### Schedule (2 екрани)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /schedule | GroupsScreen | coach | schedule_e2e_test.dart | WEAK_TEST |
| /group/:id | GroupDetailScreen | coach | — | ❌ UNCOVERED |

### Belts (3 екрани)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /belts/edit | BeltRequirementsScreen | coach | belt_exercises_e2e_test.dart | WEAK_TEST |
| /bulk-belt | BulkBeltScreen | coach | — | ❌ UNCOVERED |
| /exercise-library | ExerciseLibraryScreen | all | — | ❌ UNCOVERED |

### Fitness (11 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /fitness/:childId | FitnessScreen | coach,parent | — | ❌ UNCOVERED |
| /fitness/:childId/exercise/:id | FitnessExerciseDetailScreen | coach,parent | — | ❌ UNCOVERED |
| /assignments | CoachAssignmentsScreen | coach | — | ❌ UNCOVERED |
| /assignments/create | CreateAssignmentWizardScreen | coach | — | ❌ UNCOVERED |
| /assignments/:id/progress | AssignmentGroupProgressScreen | coach | — | ❌ UNCOVERED |
| /assignments/:id/athletes | AssignmentAthletesScreen | coach | — | ❌ UNCOVERED |
| /assignments/:id/athlete/:childId | AssignmentDetailScreen (coach) | coach | — | ❌ UNCOVERED |
| /my-assignments | MyAssignmentsScreen | parent,athlete | fitness_assignment_e2e_test.dart | FAKE_COVERAGE |
| /my-assignments/:id | AssignmentDetailScreen (athlete) | parent,athlete | — | ❌ UNCOVERED |
| /my-assignments/:id/add-result | AddAssignmentResultScreen | parent,athlete | — | ❌ UNCOVERED |
| /bulk-fitness-goals | BulkFitnessGoalsScreen | coach | — | ❌ UNCOVERED |
| /individual-training | IndividualTrainingScreen | coach | individual_training_e2e_test.dart | FAKE_COVERAGE |

### Achievements (4 екрани)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /achievements | GrantAchievementScreen | coach | — | ❌ UNCOVERED |
| /bulk-achievements | BulkGrantAchievementsScreen | coach | — | ❌ UNCOVERED |
| /achievement-stats | AchievementStatsScreen | coach | — | ❌ UNCOVERED |
| /achievement-catalog | AchievementCatalogScreen | all | achievement_e2e_test.dart | FAKE_COVERAGE |

### Membership (7 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /membership/:childId | MembershipScreen | coach,parent | membership_e2e_test.dart | WEAK_TEST |
| /abonements | MembershipScreen (abonements) | parent | — | ❌ UNCOVERED |
| /abonements/detail | MembershipDetailScreen | parent | — | ❌ UNCOVERED |
| /checkout | CheckoutScreen | parent | — | ❌ UNCOVERED |
| /payment-success | PaymentSuccessScreen | parent | — | ❌ UNCOVERED |
| /my-abonements | MyMembershipsScreen | parent | — | ❌ UNCOVERED |
| /membership-management | CoachMembershipsScreen | coach | — | ❌ UNCOVERED |

### Nutrition (8 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /nutrition/child/:id | NutritionDashboard | coach,parent | nutrition_e2e_test.dart | FAKE_COVERAGE |
| /nutrition/child/:id/add-meal | AddMealScreen | coach,parent | — | ❌ UNCOVERED |
| /nutrition/child/:id/water | WaterScreen | coach,parent | — | ❌ UNCOVERED |
| /nutrition/child/:id/plate | MyPlateScreen | coach,parent | — | ❌ UNCOVERED |
| /nutrition/child/:id/diary | MealDiaryScreen | coach,parent | — | ❌ UNCOVERED |
| /nutrition/child/:id/stats | NutritionStatsScreen | coach,parent | nutrition_score_e2e_test.dart | FAKE_COVERAGE |
| /nutrition/products | FoodProductsScreen | all | — | ❌ UNCOVERED |
| /nutrition/tips | NutritionTipsScreen | all | — | ❌ UNCOVERED |

### Questionnaires (4 екрани)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /questionnaires | QuestionnairesScreen | all | questionnaires_e2e_test.dart | WEAK_TEST |
| /questionnaires/create | CreateQuestionnaireScreen | coach | — | ❌ UNCOVERED |
| /questionnaires/:id/results | QuestionnaireResultsScreen | coach | — | ❌ UNCOVERED |
| /questionnaires/:id/answer | AnswerQuestionnaireScreen | all | — | ❌ UNCOVERED |

### Shop (10 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /shop | ShopHomeScreen | all | shop_screens_e2e_test.dart | FAKE_COVERAGE |
| /shop/catalog | ShopCatalogScreen | all | shop_merch_types_e2e_test.dart | FAKE_COVERAGE |
| /shop/product/:id | ShopProductScreen | all | — | ❌ UNCOVERED |
| /shop/cart | ShopCartScreen | all | shop_cart_e2e_test.dart | FAKE_COVERAGE |
| /shop/checkout | ShopCheckoutScreen | all | — | ❌ UNCOVERED |
| /shop/orders | ShopMyOrdersScreen | all | — | ❌ UNCOVERED |
| /shop/orders/:id | ShopOrderDetailScreen | all | — | ❌ UNCOVERED |
| /shop/admin | ShopAdminScreen | coach | — | ❌ UNCOVERED |
| /shop/admin/add-product | ShopAddEditProductScreen (add) | coach | — | ❌ UNCOVERED |
| /shop/admin/product/:id/edit | ShopAddEditProductScreen (edit) | coach | — | ❌ UNCOVERED |

### News (6 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /news | NewsFeedScreen | all | news_e2e_test.dart | WEAK_TEST |
| /news/honor-board | HonorBoardScreen | all | — | ❌ UNCOVERED |
| /news/create | NewsCreatePostScreen (create) | coach | — | ❌ UNCOVERED |
| /news/:id | NewsPostScreen | all | — | ❌ UNCOVERED |
| /news/:id/edit | NewsCreatePostScreen (edit) | coach | — | ❌ UNCOVERED |
| /news/:id/comments | NewsCommentsScreen | all | — | ❌ UNCOVERED |

### Other (6 екранів)
| Route | Screen | Roles | Test File | Classification |
|---|---|---|---|---|
| /notifications | NotificationsScreen | all | notifications_e2e_test.dart | WEAK_TEST |
| /journey | JourneyScreen | all | journey_character_e2e_test.dart | FAKE_COVERAGE |
| /my-data | MyDataScreen | all | — | ❌ UNCOVERED |
| /events/add | AddEditEventScreen (add) | coach | — | ❌ UNCOVERED |
| /events/:id/edit | AddEditEventScreen (edit) | coach | — | ❌ UNCOVERED |

---

## 2. Непокриті екрани (61 з 77)

```
SplashScreen, AccessRemovedScreen, RegisterScreen, EventsScreen,
NutritionScreen (shell), AddEditChildScreen (add/edit), AddResultScreen,
BodyMeasurementsScreen, GroupDetailScreen, BeltRequirementsScreen,
BulkBeltScreen, ExerciseLibraryScreen, FitnessScreen,
FitnessExerciseDetailScreen, CoachAssignmentsScreen,
CreateAssignmentWizardScreen, AssignmentGroupProgressScreen,
AssignmentAthletesScreen, AssignmentDetailScreen (coach/athlete),
AddAssignmentResultScreen, BulkFitnessGoalsScreen,
GrantAchievementScreen, BulkGrantAchievementsScreen,
AchievementStatsScreen, MembershipDetailScreen, CheckoutScreen,
PaymentSuccessScreen, MyMembershipsScreen, CoachMembershipsScreen,
NutritionDashboard, AddMealScreen, WaterScreen, MyPlateScreen,
MealDiaryScreen, NutritionStatsScreen, FoodProductsScreen,
NutritionTipsScreen, CreateQuestionnaireScreen,
QuestionnaireResultsScreen, AnswerQuestionnaireScreen,
ShopProductScreen, ShopCartScreen (UI), ShopCheckoutScreen,
ShopMyOrdersScreen, ShopOrderDetailScreen, ShopAdminScreen,
ShopAddEditProductScreen (add/edit), HonorBoardScreen,
NewsCreatePostScreen (create/edit), NewsPostScreen, NewsCommentsScreen,
JourneyScreen, MyDataScreen, AddEditEventScreen (add/edit)
```

---

## 3. FAKE_COVERAGE тести (17)

| Файл | Причина |
|---|---|
| events_e2e_test.dart | Нуль testWidgets — тільки EventsNotifier unit-тести |
| nutrition_e2e_test.dart | Нуль testWidgets — NutritionNotifier Firestore CRUD |
| nutrition_score_e2e_test.dart | Дублює логіку провайдера локально, не тестує реальний код |
| registration_e2e_test.dart | Нуль widget-тестів — FormValidators static methods |
| shop_screens_e2e_test.dart | Нуль testWidgets — ShopNotifier CRUD, CartNotifier виключений |
| shop_cart_e2e_test.dart | Нуль testWidgets — CartItem/CartModel арифметика |
| shop_merch_types_e2e_test.dart | Нуль testWidgets — ShopCategory enum properties |
| membership_sessions_e2e_test.dart | Нуль testWidgets — MembershipModel unit-тести |
| individual_training_e2e_test.dart | Нуль testWidgets — IndividualTrainingNotifier CRUD |
| journey_character_e2e_test.dart | Дублює _computeStreak локально замість реального провайдера |
| achievement_e2e_test.dart | Нуль testWidgets — AchievementsNotifier Firestore CRUD |
| achievements_e2e_test.dart | Нуль testWidgets — cross-role через Firestore, не widget tree |
| peer_rank_e2e_test.dart | Тестує тільки функцію computePeerRanks() |
| coach_settings_e2e_test.dart | Нуль testWidgets — CoachSettingsNotifier provider layer |
| parent_message_delivery_e2e_test.dart | Нуль testWidgets — Firestore Map assertions |
| csv_import_e2e_test.dart | Нуль testWidgets — CsvImportService.parse() unit |
| smoke_e2e_test.dart | Нуль testWidgets — provider override механізм |

---

## 4. WEAK_TEST (25)

Спільні відсутні перевірки по всіх WEAK тестах:
- `tester.takeException() == null` — відсутнє в більшості
- Унікальний заголовок `findsOneWidget` (не `findsWidgets`)
- Тест на довгий текст (LONG_TEXT_LAYOUT_MISSING)
- FAB visibility/tapability
- SafeArea / BottomNav overlap
- Cross-role видимість
- Empty state / Error state
- Keyboard overlap

Файли: `home_e2e_test.dart`, `team_e2e_test.dart`, `rating_e2e_test.dart`,
`belts_e2e_test.dart`, `belt_exercises_e2e_test.dart`, `belt_level_picker_e2e_test.dart`,
`belt_advancement_business_e2e_test.dart`, `settings_e2e_test.dart`, `auth_e2e_test.dart`,
`profile_e2e_test.dart`, `news_e2e_test.dart`, `notifications_e2e_test.dart`,
`questionnaires_e2e_test.dart`, `membership_e2e_test.dart`, `fitness_assignment_e2e_test.dart`,
`achievement_auto_unlock_e2e_test.dart`, `attendance_e2e_test.dart`,
`role_guards_e2e_test.dart`, `cross_role_flows_e2e_test.dart`,
`user_model_e2e_test.dart`, `competitions_crud_e2e_test.dart`, `schedule_e2e_test.dart`,
`data_integrity_e2e_test.dart`, `multi_child_parent_e2e_test.dart`, `performance_e2e_test.dart`

---

## 5. Реальні баги (топ-30 HIGH)

| # | Severity | Type | Файл | Опис |
|---|---|---|---|---|
| 1 | 🔴 HIGH | DATA | home_screen.dart | `effectiveChildIdProvider` і `activeChildIdProvider` не знайдено в codebase — compile error |
| 2 | 🔴 HIGH | BUSINESS | home_screen.dart | `_achievementsSeeded` static bool: може тригерити batch write кілька разів |
| 3 | 🔴 HIGH | DATA | home_screen.dart | Coach filter по `c.coachId == user?.uid` але `filteredChildrenProvider` по `coachName` → empty list |
| 4 | 🔴 HIGH | TEXT | home_screen.dart | `'Відвідуваність'` показує belt-readiness %, а не attendance — data/text mismatch |
| 5 | 🔴 HIGH | LAYOUT | nutrition_screen.dart | FAB без bottomNavigationBar offset — перекривається nav bar |
| 6 | 🔴 HIGH | DATA | nutrition_screen.dart | `waterGoalMlProvider` глобальний без childId — всі діти бачать одну ціль |
| 7 | 🔴 HIGH | DATA | nutrition_screen.dart | `effectiveChildId` fallback `''` — Firestore query з пустим ID |
| 8 | 🔴 HIGH | LAYOUT | nutrition_stats_screen.dart | FlexibleSpaceBar: background TEXT + title: TEXT → **ДУБЛЮВАННЯ ЗАГОЛОВКУ** |
| 9 | 🔴 HIGH | LAYOUT | add_meal_screen.dart | bottom padding 120px не SafeArea-aware → GradientButton обрізається |
| 10 | 🔴 HIGH | DATA | add_meal_screen.dart | edit mode: `widget.meal.copyWith()` ігнорує `childId` параметр → wrong-child write |
| 11 | 🔴 HIGH | LAYOUT | team_list_screen.dart | FAB без `floatingActionButtonLocation` → перекривається BottomNav |
| 12 | 🔴 HIGH | LAYOUT | child_profile_screen.dart | `_changeCoach` bottom sheet: Column без Flexible+ScrollView → BOTTOM OVERFLOWED |
| 13 | 🔴 HIGH | DATA | child_profile_screen.dart | `childId` без guard → providers fired з `''` |
| 14 | 🔴 HIGH | DATA | add_edit_child_screen.dart | `_initialized` flag → stale data при reuse widget з іншим childId |
| 15 | 🔴 HIGH | DATA | belt_overview_screen.dart | `coachId ?? ''` → writes attributed to `''` в Firestore |
| 16 | 🔴 HIGH | DATA | belt_overview_screen.dart | athlete role: `childId` = null → progress = null → завжди прихований прогрес |
| 17 | 🔴 HIGH | LAYOUT | belt_requirements_screen.dart | AlertDialog column без Flexible+ScrollView → overflow з keyboard |
| 18 | 🔴 HIGH | NAVIGATION | belt_requirements_screen.dart | `TabBar.onTap: (_) {}` → тап по вкладці не перемикає TabBarView |
| 19 | 🔴 HIGH | LAYOUT | fitness_screen.dart | FlexibleSpaceBar: background + title: → **ДУБЛЮВАННЯ ЗАГОЛОВКУ** |
| 20 | 🔴 HIGH | DATA | fitness_screen.dart | FAB без bottomNavigationBar offset |
| 21 | 🔴 HIGH | DATA | coach_assignments_screen.dart | прогрес: sum/targetValue для N атлетів → завжди 100% для multi-athlete |
| 22 | 🔴 HIGH | LAYOUT | coach_assignments_screen.dart | `_showCardMenu` bottom sheet: Column без Flexible → BOTTOM OVERFLOWED |
| 23 | 🔴 HIGH | DATA | rating_screen.dart | period selector (_RatingPeriod) — чисто UI setState, ніколи не фільтрує дані |
| 24 | 🔴 HIGH | DATA | groups_screen.dart | GroupModel(id: '') → write до malformed Firestore path |
| 25 | 🔴 HIGH | DATA | group_detail_screen.dart | `coachId ?? ''` → attendance records з `coachId: ''` |
| 26 | 🔴 HIGH | LAYOUT | events_screen.dart | `_showYearPicker` і `_showTypePicker`: Column без Flexible → BOTTOM OVERFLOWED |
| 27 | 🔴 HIGH | DATA | events_screen.dart | parent multi-child: тільки перша дитина для participation |
| 28 | 🔴 HIGH | NAVIGATION | settings_screen.dart | user! force-unwrap в 5 onTap → NPE під час loading |
| 29 | 🔴 HIGH | LAYOUT | shop_home_screen.dart | `_buildCheckoutBar` bottom padding 24px не SafeArea-aware |
| 30 | 🔴 HIGH | BUSINESS | shop_home_screen.dart | Promo code 'TRIUMPH10' hardcoded client-side — security issue |

---

## 6. Тестові прогалини (patterns)

### P1 — FAKE_COVERAGE в e2e/screens/
17 файлів у `test/e2e/screens/` не містять жодного `testWidgets`.  
Вони unit-тести провайдерів, перейменовані як e2e.

### P2 — Нуль GOOD_TEST
Жоден із 42 тестових файлів не відповідає повному стандарту:
- `tester.takeException() == null`  
- `findsOneWidget` для заголовку (не `findsWidgets`)  
- Перевірка бізнес-інваріанту

### P3 — LONG_TEXT_LAYOUT_MISSING (100% екранів)
Жоден екран не має long-text regression тесту з реальними даними.

### P4 — FAB overlap не перевіряється
Жоден тест не перевіряє `fabRect.bottom < navBarRect.top`.

### P5 — Cross-role через Firestore замість UI
"Cross-role" тести читають Firestore напряму замість рендеру різних ролей у widget tree.

---

## 7. PARTIAL / NOT_IMPLEMENTED функції

| Екран/Функція | Статус | Деталі |
|---|---|---|
| RatingScreen period filter | PARTIAL | UI chips є, дані не фільтруються |
| BeltRequirementsScreen tabs | PARTIAL | `TabBar.onTap: (_) {}` → тап не працює |
| CoachAssignmentsScreen progress | PARTIAL | Multi-athlete progress formula неправильна |
| GroupDetailScreen attendance navigation | PARTIAL | August dates відсутні (_trainingDates) |
| NotificationsScreen _ComposeDialog personal target | PARTIAL | Відправка з targetValues=[] |
| ShopHomeScreen promo codes | NOT_IMPLEMENTED | Один hardcoded код |
| Individual training | FAKE_COVERAGE | Тільки provider logic, UI не покрито |
| Journey streak | PARTIAL | Off-by-one при max stage |

---

## 8. Long-Text Layout Coverage

**Всі екрани позначені як LONG_TEXT_LAYOUT_MISSING** до запуску нових тестів.

Нові тести (створені):
- `long_text_layout_e2e_test.dart` → ChildCard, TeamListScreen (9 screen × 2 variants = 18 тестів)
- `duplicate_title_regression_e2e_test.dart` → NutritionStatsScreen, TeamListScreen, RatingScreen, BeltOverviewScreen
- `fab_bottomnav_overlap_e2e_test.dart` → TeamListScreen FAB
- `abbreviated_text_regression_e2e_test.dart` → ChildCard, TeamListScreen

| Екран | Long-Text Coverage |
|---|---|
| ChildCard | ✅ COVERED (new test) |
| TeamListScreen | ✅ COVERED (new test) |
| NutritionStatsScreen | ⚠️ PARTIAL (duplicate title only) |
| HomeScreen | ⚠️ PARTIAL (long coach name) |
| ChildProfileScreen | LONG_TEXT_LAYOUT_MISSING |
| AddEditChildScreen | LONG_TEXT_LAYOUT_MISSING |
| FitnessScreen | LONG_TEXT_LAYOUT_MISSING |
| CoachAssignmentsScreen | LONG_TEXT_LAYOUT_MISSING |
| GroupDetailScreen | LONG_TEXT_LAYOUT_MISSING |
| NewsPostScreen | LONG_TEXT_LAYOUT_MISSING |
| ShopProductScreen | LONG_TEXT_LAYOUT_MISSING |
| (всі інші 49 екранів) | LONG_TEXT_LAYOUT_MISSING |

---

## 9. Нові E2E тести створені

| Файл | Що покриває | Кількість тестів |
|---|---|---|
| `test/e2e/screens/long_text_layout_e2e_test.dart` | ChildCard, TeamListScreen з довгими іменами; 3 розміри × 3 scale × 2 варіанти | 20+ |
| `test/e2e/screens/duplicate_title_regression_e2e_test.dart` | FlexibleSpaceBar duplicate header: TeamListScreen, NutritionStatsScreen, RatingScreen, BeltOverviewScreen | 5 |
| `test/e2e/screens/fab_bottomnav_overlap_e2e_test.dart` | FAB visibility, FAB rect bounds, BottomNav overlap, scroll 20 items | 6 |
| `test/e2e/screens/abbreviated_text_regression_e2e_test.dart` | 'Відвід.' → findsNothing; ChildCard, TeamListScreen | 5 |

---

## 10. Критичні баги які можуть потрапити в production

1. **`effectiveChildIdProvider` не існує** → compile error для parent users
2. **NutritionStatsScreen дублює заголовок** → UX деградація  
3. **RatingScreen period filter non-functional** → misleading UI
4. **TabBar onTap порожній** → tabs не перемикаються
5. **Promo code hardcoded client-side** → security vulnerability
6. **Multiple BOTTOM OVERFLOWED** у bottom sheets → crash на малих екранах
7. **`coachId ?? ''`** у 6+ місцях → Firestore corruption
8. **`Відвід.`** замість `Відвідування:` → аббревіатура в production

