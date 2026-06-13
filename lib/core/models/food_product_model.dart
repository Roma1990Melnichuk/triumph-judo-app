import 'package:cloud_firestore/cloud_firestore.dart';

enum FoodCategory {
  protein, vegetables, grains, fruits, drinks;

  String get label => switch (this) {
    FoodCategory.protein    => 'Білки',
    FoodCategory.vegetables => 'Овочі',
    FoodCategory.grains     => 'Крупи',
    FoodCategory.fruits     => 'Фрукти',
    FoodCategory.drinks     => 'Напої',
  };

  static FoodCategory fromString(String v) =>
      FoodCategory.values.firstWhere((e) => e.name == v, orElse: () => FoodCategory.protein);
}

class FoodProductModel {
  const FoodProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final String       id;
  final String       name;
  final FoodCategory category;
  final String       description;
  final String?      imageUrl;
  final int          calories;
  final double       protein;
  final double       fat;
  final double       carbs;

  factory FoodProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FoodProductModel(
      id:          doc.id,
      name:        d['name']        as String? ?? '',
      category:    FoodCategory.fromString(d['category'] as String? ?? ''),
      description: d['description'] as String? ?? '',
      imageUrl:    d['imageUrl']    as String?,
      calories:    d['calories']    as int?    ?? 0,
      protein:     (d['protein']    as num?)?.toDouble() ?? 0,
      fat:         (d['fat']        as num?)?.toDouble() ?? 0,
      carbs:       (d['carbs']      as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':        name,
    'category':    category.name,
    'description': description,
    'imageUrl':    imageUrl,
    'calories':    calories,
    'protein':     protein,
    'fat':         fat,
    'carbs':       carbs,
  };

  static const List<FoodProductModel> defaults = [
    FoodProductModel(id: 'fp_chicken', name: 'Куряча грудка', category: FoodCategory.protein,
      description: 'Нежирне м\'ясо з високим вмістом білка. Ідеально для відновлення після тренувань.',
      calories: 165, protein: 31, fat: 3.6, carbs: 0),
    FoodProductModel(id: 'fp_eggs', name: 'Яйця', category: FoodCategory.protein,
      description: 'Повноцінний білок з усіма необхідними амінокислотами.',
      calories: 155, protein: 13, fat: 11, carbs: 1.1),
    FoodProductModel(id: 'fp_cottage', name: 'Творог', category: FoodCategory.protein,
      description: 'Казеїновий білок — повільне засвоєння, ідеально на ніч.',
      calories: 98, protein: 11, fat: 4, carbs: 3.4),
    FoodProductModel(id: 'fp_salmon', name: 'Лосось', category: FoodCategory.protein,
      description: 'Омега-3 жирні кислоти та білок для відновлення м\'язів.',
      calories: 208, protein: 20, fat: 13, carbs: 0),
    FoodProductModel(id: 'fp_tuna', name: 'Тунець', category: FoodCategory.protein,
      description: 'Нежирне джерело білка, багате на йод та вітамін D.',
      calories: 130, protein: 29, fat: 1, carbs: 0),
    FoodProductModel(id: 'fv_broccoli', name: 'Броколі', category: FoodCategory.vegetables,
      description: 'Антиоксиданти, вітамін C, клітковина. Обов\'язковий елемент раціону спортсмена.',
      calories: 34, protein: 2.8, fat: 0.4, carbs: 7),
    FoodProductModel(id: 'fv_spinach', name: 'Шпинат', category: FoodCategory.vegetables,
      description: 'Залізо, магній, вітамін K — підтримка м\'язів і кісток.',
      calories: 23, protein: 2.9, fat: 0.4, carbs: 3.6),
    FoodProductModel(id: 'fv_carrot', name: 'Морква', category: FoodCategory.vegetables,
      description: 'Бета-каротин для зору та імунітету.',
      calories: 41, protein: 0.9, fat: 0.2, carbs: 10),
    FoodProductModel(id: 'fv_tomato', name: 'Томати', category: FoodCategory.vegetables,
      description: 'Лікопін, вітамін C, антиоксиданти.',
      calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
    FoodProductModel(id: 'fv_cucumber', name: 'Огірок', category: FoodCategory.vegetables,
      description: 'Гідратація, клітковина, мінімум калорій.',
      calories: 15, protein: 0.6, fat: 0.1, carbs: 3.6),
    FoodProductModel(id: 'fg_oats', name: 'Вівсянка', category: FoodCategory.grains,
      description: 'Складні вуглеводи — стабільна енергія на тренуванні.',
      calories: 389, protein: 17, fat: 7, carbs: 66),
    FoodProductModel(id: 'fg_buckwheat', name: 'Гречка', category: FoodCategory.grains,
      description: 'Повноцінний рослинний білок, залізо, рутин.',
      calories: 343, protein: 13, fat: 3.4, carbs: 72),
    FoodProductModel(id: 'fg_rice', name: 'Бурий рис', category: FoodCategory.grains,
      description: 'Повільні вуглеводи, клітковина для тривалої насиченості.',
      calories: 370, protein: 7.9, fat: 2.9, carbs: 77),
    FoodProductModel(id: 'fg_pasta', name: 'Цільнозернові макарони', category: FoodCategory.grains,
      description: 'Складні вуглеводи з клітковиною, ідеальні перед змаганнями.',
      calories: 350, protein: 13, fat: 2, carbs: 71),
    FoodProductModel(id: 'ff_banana', name: 'Банан', category: FoodCategory.fruits,
      description: 'Калій, магній — відновлення після тренувань. Швидка енергія.',
      calories: 89, protein: 1.1, fat: 0.3, carbs: 23),
    FoodProductModel(id: 'ff_apple', name: 'Яблуко', category: FoodCategory.fruits,
      description: 'Клітковина, вітамін C, поліфеноли.',
      calories: 52, protein: 0.3, fat: 0.2, carbs: 14),
    FoodProductModel(id: 'ff_blueberry', name: 'Чорниця', category: FoodCategory.fruits,
      description: 'Антиоксиданти для покращення кровообігу та когнітивних функцій.',
      calories: 57, protein: 0.7, fat: 0.3, carbs: 14),
    FoodProductModel(id: 'ff_orange', name: 'Апельсин', category: FoodCategory.fruits,
      description: 'Вітамін C для імунітету та відновлення.',
      calories: 47, protein: 0.9, fat: 0.1, carbs: 12),
    FoodProductModel(id: 'fd_water', name: 'Вода', category: FoodCategory.drinks,
      description: 'Основа гідратації. 30–40 мл на кг маси тіла на день.',
      calories: 0, protein: 0, fat: 0, carbs: 0),
    FoodProductModel(id: 'fd_protein', name: 'Протеїновий коктейль', category: FoodCategory.drinks,
      description: 'Швидке засвоєння білка після тренування.',
      calories: 120, protein: 24, fat: 2, carbs: 4),
    FoodProductModel(id: 'fd_isotonic', name: 'Ізотонік', category: FoodCategory.drinks,
      description: 'Відновлення електролітів під час інтенсивних тренувань.',
      calories: 50, protein: 0, fat: 0, carbs: 13),
  ];
}
