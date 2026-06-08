import '../models/achievement_model.dart';

const List<AchievementDef> kAchievements = [
  // ── Пояси (AUTO) ────────────────────────────────────────────────────────────
  AchievementDef(id: 'belt_white',        name: 'Білий пояс',             emoji: '⚪', description: 'Отримав білий пояс.',            category: AchievementCategory.belts, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'belt_whiteYellow',  name: 'Біло-жовтий пояс',       emoji: '🟡', description: 'Отримав біло-жовтий пояс.',       category: AchievementCategory.belts, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'belt_yellow',       name: 'Жовтий пояс',            emoji: '🟡', description: 'Отримав жовтий пояс.',            category: AchievementCategory.belts, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'belt_yellowOrange', name: 'Жовто-помаранчевий',     emoji: '🟠', description: 'Отримав жовто-помаранчевий пояс.', category: AchievementCategory.belts, rarity: AchievementRarity.rare,     type: AchievementType.auto),
  AchievementDef(id: 'belt_orange',       name: 'Помаранчевий пояс',      emoji: '🟠', description: 'Отримав помаранчевий пояс.',      category: AchievementCategory.belts, rarity: AchievementRarity.rare,     type: AchievementType.auto),
  AchievementDef(id: 'belt_orangeGreen',  name: 'Помаранчево-зелений',    emoji: '🟢', description: 'Отримав помаранчево-зелений пояс.', category: AchievementCategory.belts, rarity: AchievementRarity.rare,    type: AchievementType.auto),
  AchievementDef(id: 'belt_green',        name: 'Зелений пояс',           emoji: '🟢', description: 'Отримав зелений пояс.',           category: AchievementCategory.belts, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'belt_greenBlue',    name: 'Зелено-синій пояс',      emoji: '🔵', description: 'Отримав зелено-синій пояс.',      category: AchievementCategory.belts, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'belt_blue',         name: 'Синій пояс',             emoji: '🔵', description: 'Отримав синій пояс.',             category: AchievementCategory.belts, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'belt_blueBrown',    name: 'Синьо-коричневий',       emoji: '🟤', description: 'Отримав синьо-коричневий пояс.',  category: AchievementCategory.belts, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'belt_brown',        name: 'Коричневий пояс',        emoji: '🟤', description: 'Отримав коричневий пояс.',        category: AchievementCategory.belts, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'belt_black',        name: 'Чорний пояс (Дан)',      emoji: '⚫', description: 'Досягнув чорного поясу. Легенда!', category: AchievementCategory.belts, rarity: AchievementRarity.mythic,   type: AchievementType.auto),

  // ── Турніри (AUTO) ──────────────────────────────────────────────────────────
  AchievementDef(id: 'first_tournament',   name: 'Перший турнір',         emoji: '🎯', description: 'Взяв участь у першому турнірі.',     category: AchievementCategory.tournaments, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'first_medal',        name: 'Перша медаль',          emoji: '🥉', description: 'Завоював першу медаль.',             category: AchievementCategory.tournaments, rarity: AchievementRarity.rare,     type: AchievementType.auto),
  AchievementDef(id: 'champion',           name: 'Чемпіон турніру',       emoji: '🥇', description: 'Посів перше місце на турнірі.',      category: AchievementCategory.tournaments, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'medals_10',          name: '10 медалей',            emoji: '🏅', description: 'Зібрав 10 медалей.',                 category: AchievementCategory.tournaments, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'medals_20',          name: '20 медалей',            emoji: '🏆', description: 'Зібрав 20 медалей. Абсолютний чемпіон!', category: AchievementCategory.tournaments, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'bronze_medalist',     name: 'Бронзовий призер',      emoji: '🥉', description: 'Посів третє місце на турнірі.',      category: AchievementCategory.tournaments, rarity: AchievementRarity.rare,      type: AchievementType.auto),
  AchievementDef(id: 'silver_medalist',     name: 'Срібний призер',        emoji: '🥈', description: 'Посів друге місце на турнірі.',      category: AchievementCategory.tournaments, rarity: AchievementRarity.epic,      type: AchievementType.auto),
  AchievementDef(id: 'podium_5_streak',    name: '5 подіумів поспіль',    emoji: '🏆', description: 'П\'ять турнірів — п\'ять медалей.',  category: AchievementCategory.tournaments, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'tournament_3_streak', name: '3 турніри',            emoji: '🎯', description: 'Взяв участь у 3 турнірах.',          category: AchievementCategory.tournaments, rarity: AchievementRarity.rare,     type: AchievementType.auto),

  // ── Тренування (AUTO) ───────────────────────────────────────────────────────
  AchievementDef(id: 'first_training',  name: 'Перший крок',      emoji: '🥋', description: 'Перше тренування.',           category: AchievementCategory.training, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'trainings_10',   name: 'Новачок',           emoji: '🥋', description: '10 тренувань.',              category: AchievementCategory.training, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'trainings_50',   name: 'Наполегливий',      emoji: '🥋', description: '50 тренувань.',              category: AchievementCategory.training, rarity: AchievementRarity.rare,     type: AchievementType.auto),
  AchievementDef(id: 'trainings_100',  name: 'Боєць',             emoji: '🥋', description: '100 тренувань.',             category: AchievementCategory.training, rarity: AchievementRarity.epic,     type: AchievementType.auto),
  AchievementDef(id: 'trainings_250',  name: 'Майстер татамі',    emoji: '🥋', description: '250 тренувань.',             category: AchievementCategory.training, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'trainings_500',  name: 'Легенда залу',      emoji: '🥋', description: '500 тренувань.',             category: AchievementCategory.training, rarity: AchievementRarity.mythic,   type: AchievementType.auto),

  // ── Регулярність / Дисципліна (AUTO) ────────────────────────────────────────
  AchievementDef(id: 'streak_7',           name: '7 днів поспіль',        emoji: '🔥', description: 'Тиждень без пропусків.',           category: AchievementCategory.discipline, rarity: AchievementRarity.common,    type: AchievementType.auto),
  AchievementDef(id: 'streak_14',          name: '14 днів поспіль',       emoji: '🔥', description: 'Два тижні без пропусків.',         category: AchievementCategory.discipline, rarity: AchievementRarity.rare,     type: AchievementType.auto),
  AchievementDef(id: 'streak_30',          name: 'Невидимий воїн',        emoji: '🥷', description: '30 тренувань поспіль без пропусків.', category: AchievementCategory.discipline, rarity: AchievementRarity.epic,  type: AchievementType.auto, isHidden: true),
  AchievementDef(id: 'streak_100',         name: '100 днів прогресу',     emoji: '🔥', description: '100 тренувальних днів поспіль.',   category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'year_no_miss',       name: 'Рік без пропусків',     emoji: '👑', description: 'Жодного пропуску за рік.',         category: AchievementCategory.discipline, rarity: AchievementRarity.mythic,   type: AchievementType.auto),
  AchievementDef(id: 'attendance_100_year', name: '100% відвідуваності',  emoji: '💯', description: '100% відвідуваності за рік.',      category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'autumn_discipline',  name: 'Осінній самурай',       emoji: '🍂', description: 'Жодного пропуску з вересня по листопад.',  category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'winter_discipline',  name: 'Зимовий самурай',       emoji: '❄️', description: 'Жодного пропуску з грудня по лютий.',       category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'spring_discipline',  name: 'Весняний самурай',      emoji: '🌱', description: 'Жодного пропуску з березня по травень.',     category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),
  AchievementDef(id: 'summer_discipline',  name: 'Літній самурай',        emoji: '☀️', description: 'Жодного пропуску з червня по серпень.',      category: AchievementCategory.discipline, rarity: AchievementRarity.legendary, type: AchievementType.auto),

  // ── Поведінка (MANUAL) ──────────────────────────────────────────────────────
  AchievementDef(id: 'friend_of_team',  name: 'Друг команди',      emoji: '🤝', description: 'Завжди допомагає іншим.',      category: AchievementCategory.behavior, rarity: AchievementRarity.rare,     type: AchievementType.manual),
  AchievementDef(id: 'team_leader',     name: 'Лідер групи',       emoji: '🤝', description: 'Веде за собою.',              category: AchievementCategory.behavior, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'team_support',   name: 'Підтримка команди',  emoji: '🤝', description: 'Підтримує товаришів.',        category: AchievementCategory.behavior, rarity: AchievementRarity.rare,     type: AchievementType.manual),
  AchievementDef(id: 'fair_play',       name: 'Чесна боротьба',    emoji: '🤝', description: 'Завжди бореться чесно.',      category: AchievementCategory.behavior, rarity: AchievementRarity.rare,     type: AchievementType.manual),
  AchievementDef(id: 'respect',         name: 'Повага до суперника', emoji: '🤝', description: 'Виявляє повагу до всіх.',   category: AchievementCategory.behavior, rarity: AchievementRarity.rare,     type: AchievementType.manual),

  // ── Техніка (MANUAL) ────────────────────────────────────────────────────────
  AchievementDef(id: 'throw_master',    name: 'Майстер кидка',     emoji: '🥋', description: 'Відмінна техніка кидків.',    category: AchievementCategory.technique, rarity: AchievementRarity.epic,    type: AchievementType.manual),
  AchievementDef(id: 'hold_master',     name: 'Король утримань',   emoji: '🥋', description: 'Еталонне утримання.',        category: AchievementCategory.technique, rarity: AchievementRarity.epic,    type: AchievementType.manual),
  AchievementDef(id: 'pain_master',     name: 'Майстер больових',  emoji: '🥋', description: 'Освоїв больові прийоми.',    category: AchievementCategory.technique, rarity: AchievementRarity.epic,    type: AchievementType.manual),
  AchievementDef(id: 'counter_master',  name: 'Майстер контратак', emoji: '🥋', description: 'Майстерні контратаки.',      category: AchievementCategory.technique, rarity: AchievementRarity.epic,    type: AchievementType.manual),
  AchievementDef(id: 'technician_of_year', name: 'Технік року',   emoji: '🥋', description: 'Найкраща техніка сезону.',   category: AchievementCategory.technique, rarity: AchievementRarity.legendary, type: AchievementType.manual),

  // ── Теорія (MANUAL) ─────────────────────────────────────────────────────────
  AchievementDef(id: 'judo_expert',       name: 'Знавець дзюдо',        emoji: '📖', description: 'Відмінно знає теорію.',       category: AchievementCategory.theory, rarity: AchievementRarity.rare,  type: AchievementType.manual),
  AchievementDef(id: 'judo_historian',    name: 'Історик дзюдо',        emoji: '📖', description: 'Знає історію дзюдо.',         category: AchievementCategory.theory, rarity: AchievementRarity.rare,  type: AchievementType.manual),
  AchievementDef(id: 'judo_code',         name: 'Кодекс дзюдо',         emoji: '📖', description: 'Дотримується кодексу.',        category: AchievementCategory.theory, rarity: AchievementRarity.rare,  type: AchievementType.manual),
  AchievementDef(id: 'terminology_master', name: 'Майстер термінів',    emoji: '📖', description: 'Знає всю термінологію.',       category: AchievementCategory.theory, rarity: AchievementRarity.epic,  type: AchievementType.manual),

  // ── Особливі (MANUAL) ───────────────────────────────────────────────────────
  AchievementDef(id: 'senseis_chosen',    name: 'Обранець сенсея',       emoji: '👑', description: 'Особлива нагорода від тренера.',   category: AchievementCategory.special, rarity: AchievementRarity.legendary, type: AchievementType.manual),
  AchievementDef(id: 'club_pride',        name: 'Гордість клубу',        emoji: '👑', description: 'Гордість ТРІУМФУ.',               category: AchievementCategory.special, rarity: AchievementRarity.legendary, type: AchievementType.manual),
  AchievementDef(id: 'example_for_younger', name: 'Приклад для молодших', emoji: '🥋', description: 'Натхнення для інших.',          category: AchievementCategory.special, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'triumph_legend',    name: 'Легенда ТРІУМФУ',       emoji: '🏆', description: 'Найвища нагорода клубу.',          category: AchievementCategory.special, rarity: AchievementRarity.mythic,   type: AchievementType.manual),
  AchievementDef(id: 'secret_technique',   name: 'Секретна техніка',      emoji: '🎁', description: '???',                              category: AchievementCategory.special, rarity: AchievementRarity.epic,      type: AchievementType.manual, isHidden: true),
  AchievementDef(id: 'lightning',          name: 'Блискавка',             emoji: '⚡', description: '???',                              category: AchievementCategory.special, rarity: AchievementRarity.legendary, type: AchievementType.manual, isHidden: true),
  AchievementDef(id: 'perfect_attestation', name: 'Без помилок',          emoji: '✅', description: 'Бездоганно склав атестацію.',       category: AchievementCategory.special, rarity: AchievementRarity.epic,      type: AchievementType.manual),

  // ── Сезонні (MANUAL) ────────────────────────────────────────────────────────
  AchievementDef(id: 'autumn_champion',    name: 'Осінній чемпіон',      emoji: '🍂', description: 'Вересень–листопад без пропусків.',  category: AchievementCategory.seasonal, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'winter_warrior',     name: 'Зимовий воїн',         emoji: '❄️', description: 'Грудень–лютий без пропусків.',      category: AchievementCategory.seasonal, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'spring_breakthrough', name: 'Весняний прорив',     emoji: '🌱', description: 'Березень–травень без пропусків.',   category: AchievementCategory.seasonal, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'summer_champion',    name: 'Літній чемпіон',       emoji: '☀️', description: 'Червень–серпень без пропусків.',    category: AchievementCategory.seasonal, rarity: AchievementRarity.epic,     type: AchievementType.manual),
  AchievementDef(id: 'golden_era',         name: 'Золота ера',           emoji: '🏆', description: '3 сезони поспіль без пропусків.',   category: AchievementCategory.seasonal, rarity: AchievementRarity.mythic,   type: AchievementType.manual),

  // ── Швидка атестація (AUTO/MANUAL) ──────────────────────────────────────────
  AchievementDef(id: 'fast_attestation',  name: 'Швидка атестація',      emoji: '⚡', description: 'Достроково здав пояс.',            category: AchievementCategory.special,  rarity: AchievementRarity.mythic,    type: AchievementType.manual),
];

/// Helper: get def by id
AchievementDef? achievementById(String id) {
  try {
    return kAchievements.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
}

/// All manual achievements grouped by category
Map<AchievementCategory, List<AchievementDef>> get manualAchievementsByCategory {
  final result = <AchievementCategory, List<AchievementDef>>{};
  for (final def in kAchievements.where((d) => d.isManual)) {
    (result[def.category] ??= []).add(def);
  }
  return result;
}

/// ALL achievements grouped by category (for coach to grant any)
Map<AchievementCategory, List<AchievementDef>> get allAchievementsByCategory {
  final result = <AchievementCategory, List<AchievementDef>>{};
  for (final def in kAchievements) {
    (result[def.category] ??= []).add(def);
  }
  return result;
}
