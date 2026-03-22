// lib/models/saved_card_model.dart

class SavedCard {
  final String cardId;
  final String last4;
  final String brand; // visa | mastercard | amex | other
  final String expiryMonth;
  final String expiryYear;
  final String cardholderName;
  final bool isDefault;
  final String createdAt;

  SavedCard({
    required this.cardId,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      cardId: json['cardId'] ?? '',
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? 'other',
      expiryMonth: json['expiryMonth'] ?? '',
      expiryYear: json['expiryYear'] ?? '',
      cardholderName: json['cardholderName'] ?? '',
      isDefault: json['isDefault'] == true,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
