import 'package:uuid/uuid.dart';

class PaymentCard {
  final String id;
  final String label;   // назва (напр. "Monobank", "ПриватБанк")
  final String number;  // номер картки або IBAN (як ввів тренер)
  final String holder;  // ім'я власника

  const PaymentCard({
    required this.id,
    required this.label,
    required this.number,
    required this.holder,
  });

  factory PaymentCard.create({
    required String label,
    required String number,
    required String holder,
  }) =>
      PaymentCard(
        id: const Uuid().v4(),
        label: label,
        number: number,
        holder: holder,
      );

  factory PaymentCard.fromMap(Map<String, dynamic> m) => PaymentCard(
        id: m['id'] as String? ?? const Uuid().v4(),
        label: m['label'] as String? ?? '',
        number: m['number'] as String? ?? '',
        holder: m['holder'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'number': number,
        'holder': holder,
      };
}
