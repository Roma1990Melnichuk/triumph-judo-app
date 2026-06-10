class TariffPlan {
  const TariffPlan({
    required this.name,
    required this.days,
    required this.price,
  });

  final String name;
  final int days;
  final double price;

  static const defaults = <TariffPlan>[
    TariffPlan(name: 'Разове тренування', days: 1, price: 150),
    TariffPlan(name: '1 тиждень', days: 7, price: 550),
    TariffPlan(name: '1 місяць', days: 30, price: 1450),
    TariffPlan(name: '3 місяці', days: 90, price: 3600),
    TariffPlan(name: '6 місяців', days: 180, price: 6000),
    TariffPlan(name: '12 місяців', days: 365, price: 9600),
  ];

  Map<String, dynamic> toMap() => {'name': name, 'days': days, 'price': price};

  factory TariffPlan.fromMap(Map<String, dynamic> m) => TariffPlan(
        name: m['name'] as String,
        days: (m['days'] as num).toInt(),
        price: (m['price'] as num).toDouble(),
      );
}
