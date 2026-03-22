// lib/models/plan_model.dart

class Plan {
  final String id;
  final String name;
  final int price;
  final String currency;
  final String period;
  final String billingPeriod;
  final List<String> features;
  final String color;
  final bool popular;
  final String? savings;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.period,
    required this.billingPeriod,
    required this.features,
    required this.color,
    required this.popular,
    this.savings,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'LKR',
      period: json['period'] ?? 'monthly',
      billingPeriod: json['billingPeriod'] ?? 'monthly',
      features: List<String>.from(json['features'] ?? []),
      color: json['color'] ?? '#9E9E9E',
      popular: json['popular'] == true,
      savings: json['savings'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'currency': currency,
        'period': period,
        'billingPeriod': billingPeriod,
        'features': features,
        'color': color,
        'popular': popular,
        'savings': savings,
      };
}
