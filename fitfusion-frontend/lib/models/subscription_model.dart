// lib/models/subscription_model.dart

class Subscription {
  final String uid;
  final String planId;
  final String planName;
  final String status; // active | expired | cancelled | pending
  final int amount;
  final String billingPeriod;
  final String startDate;
  final String endDate;
  final bool autoRenew;
  final String cardLast4;
  final String cardBrand;
  final String lastPaymentId;
  final String createdAt;
  final String updatedAt;

  Subscription({
    required this.uid,
    required this.planId,
    required this.planName,
    required this.status,
    required this.amount,
    required this.billingPeriod,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.cardLast4,
    required this.cardBrand,
    required this.lastPaymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      uid: json['uid'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      status: json['status'] ?? 'pending',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      billingPeriod: json['billingPeriod'] ?? 'monthly',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      autoRenew: json['autoRenew'] == true,
      cardLast4: json['cardLast4'] ?? '',
      cardBrand: json['cardBrand'] ?? '',
      lastPaymentId: json['lastPaymentId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  bool get isActive => status == 'active';
}
