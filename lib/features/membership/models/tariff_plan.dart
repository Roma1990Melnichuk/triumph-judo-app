class TariffPlan {
  const TariffPlan({
    required this.name,
    required this.days,
    required this.price,
    this.oldPrice,
    this.badge = '',
  });

  final String name;
  final int days;
  final double price;
  final double? oldPrice;
  final String badge;

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  int get discountPct =>
      hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  static const defaults = <TariffPlan>[
    TariffPlan(name: 'Разове тренування', days: 1, price: 150),
    TariffPlan(name: '1 тиждень', days: 7, price: 550),
    TariffPlan(name: '1 місяць', days: 30, price: 1450, oldPrice: 1650, badge: 'Популярний'),
    TariffPlan(name: '3 місяці', days: 90, price: 3600, oldPrice: 4500, badge: 'Вигідний'),
    TariffPlan(name: '6 місяців', days: 180, price: 6000, oldPrice: 8000, badge: 'VIP'),
    TariffPlan(name: '12 місяців', days: 365, price: 9600, oldPrice: 14400),
  ];

  Map<String, dynamic> toMap() => {
        'name': name,
        'days': days,
        'price': price,
        if (oldPrice != null) 'oldPrice': oldPrice,
        'badge': badge,
      };

  factory TariffPlan.fromMap(Map<String, dynamic> m) => TariffPlan(
        name: m['name'] as String,
        days: (m['days'] as num).toInt(),
        price: (m['price'] as num).toDouble(),
        oldPrice: m['oldPrice'] != null ? (m['oldPrice'] as num).toDouble() : null,
        badge: m['badge'] as String? ?? '',
      );
}
