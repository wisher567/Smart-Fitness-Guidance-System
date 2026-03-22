// lib/models/payment_model.dart

class Payment {
  final String id;
  final String uid;
  final String memberName;
  final String memberEmail;
  final String planId;
  final String planName;
  final int amount;
  final String currency;
  final String status; // pending | completed | failed | refunded
  final String paymentMethod;
  final String cardLast4;
  final String cardBrand;
  final String invoiceNumber;
  final String billingPeriod;
  final String startDate;
  final String endDate;
  final String createdAt;
  final String receiptUrl;
  final String notes;

  Payment({
    required this.id,
    required this.uid,
    required this.memberName,
    required this.memberEmail,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.cardLast4,
    required this.cardBrand,
    required this.invoiceNumber,
    required this.billingPeriod,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.receiptUrl,
    required this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      memberName: json['memberName'] ?? '',
      memberEmail: json['memberEmail'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'LKR',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'card',
      cardLast4: json['cardLast4'] ?? '',
      cardBrand: json['cardBrand'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      billingPeriod: json['billingPeriod'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      createdAt: json['createdAt'] ?? '',
      receiptUrl: json['receiptUrl'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
