// lib/screens/subscription/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitfusion/models/plan_model.dart';
import 'package:fitfusion/models/saved_card_model.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/screens/subscription/payment_success_screen.dart';
import 'package:fitfusion/screens/subscription/widgets/card_input_formatters.dart';

class PaymentScreen extends StatefulWidget {
  final Plan plan;
  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  List<SavedCard> _savedCards = [];
  SavedCard? _selectedCard;
  bool _isAddingNewCard = true;
  bool _saveCard = false;
  bool _isProcessing = false;
  String _detectedBrand = 'other';

  static const Color _salmon = Color(0xFFE8845C);

  @override
  void initState() {
    super.initState();
    _fetchSavedCards();
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedCards() async {
    final res = await ApiService.instance.getSavedCards();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final cards = (res.data!['cards'] as List?)
              ?.map((c) => SavedCard.fromJson(c))
              .toList() ??
          [];
      setState(() {
        _savedCards = cards;
        if (cards.isNotEmpty) {
          _isAddingNewCard = false;
          _selectedCard = cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
        }
      });
    }
  }

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _detectBrand(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('4')) return 'visa';
    if (n.startsWith('5') || n.startsWith('2')) return 'mastercard';
    if (n.startsWith('3')) return 'amex';
    return 'other';
  }

  String? _validateExpiry(String? v) {
    if (v == null || !v.contains('/')) return 'Invalid format (MM/YY)';
    final parts = v.split('/');
    if (parts.length < 2 || parts[1].isEmpty) return 'Invalid format';
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');
    if (month == null || month < 1 || month > 12) return 'Invalid month';
    if (year == null) return 'Invalid year';
    final expiry = DateTime(year, month + 1);
    if (expiry.isBefore(DateTime.now())) return 'Card expired';
    return null;
  }

  Future<void> _processPayment() async {
    String last4;
    String brand;
    String expiryMonth;
    String expiryYear;
    String cardholderName;

    if (_selectedCard != null && !_isAddingNewCard) {
      last4 = _selectedCard!.last4;
      brand = _selectedCard!.brand;
      expiryMonth = _selectedCard!.expiryMonth;
      expiryYear = _selectedCard!.expiryYear;
      cardholderName = _selectedCard!.cardholderName;
    } else {
      if (!_formKey.currentState!.validate()) return;
      final rawNum = _cardNumberCtrl.text.replaceAll(' ', '');
      last4 = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : rawNum;
      brand = _detectBrand(_cardNumberCtrl.text);
      final parts = _expiryCtrl.text.split('/');
      expiryMonth = parts[0];
      expiryYear = parts.length > 1 ? parts[1] : '';
      cardholderName = _nameCtrl.text.trim();
    }

    setState(() => _isProcessing = true);

    try {
      // Optionally save card first
      if (_isAddingNewCard && _saveCard && _selectedCard == null) {
        await ApiService.instance.addSavedCard({
          'last4': last4,
          'brand': brand,
          'expiryMonth': _expiryCtrl.text.split('/')[0],
          'expiryYear': _expiryCtrl.text.split('/').length > 1 ? _expiryCtrl.text.split('/')[1] : '',
          'cardholderName': cardholderName,
          'isDefault': _savedCards.isEmpty,
        });
      }

      final res = await ApiService.instance.subscribePlan(
        planId: widget.plan.id,
        cardDetails: {
          'last4': last4,
          'brand': brand,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'cardholderName': cardholderName,
        },
      );

      if (!mounted) return;

      if (res.success && res.data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              paymentId: res.data!['paymentId'] ?? '',
              invoiceNumber: res.data!['invoiceNumber'] ?? '',
              plan: widget.plan,
              cardLast4: last4,
              endDate: res.data!['endDate'] ?? '',
            ),
          ),
        );
      } else {
        setState(() => _isProcessing = false);
        _showError(res.error ?? 'Payment failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment failed: $msg'),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nextBilling = DateTime.now().add(widget.plan.billingPeriod == 'monthly'
        ? const Duration(days: 30)
        : const Duration(days: 365));
    final nextBillingStr =
        '${nextBilling.day} ${_monthName(nextBilling.month)} ${nextBilling.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('DEMO', style: TextStyle(color: Color(0xFFE8845C), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(nextBillingStr),
                    const SizedBox(height: 20),
                    if (_savedCards.isNotEmpty) ...[
                      _buildSavedCards(),
                      const SizedBox(height: 16),
                    ],
                    if (_isAddingNewCard) ...[
                      _buildNewCardForm(),
                      const SizedBox(height: 16),
                    ],
                    _buildSecurityBadges(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(String nextBillingStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.fitness_center_rounded, color: Color(0xFFE8845C), size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(widget.plan.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)))),
            Text('LKR ${_formatPrice(widget.plan.price)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE8845C), fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _summaryRow('Billing Period', widget.plan.billingPeriod == 'monthly' ? 'Monthly' : 'Yearly'),
          const SizedBox(height: 8),
          _summaryRow('Next Billing Date', nextBillingStr),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Total Due Today',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
            const Spacer(),
            Text('LKR ${_formatPrice(widget.plan.price)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(children: [
      Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
    ]);
  }

  Widget _buildSavedCards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saved Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 10),
        ..._savedCards.map((c) => _buildCardTile(c)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _selectedCard = null;
            _isAddingNewCard = true;
          }),
          icon: const Icon(Icons.add_rounded, color: _salmon),
          label: const Text('Add New Card', style: TextStyle(color: _salmon)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _salmon),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTile(SavedCard card) {
    final isSelected = _selectedCard?.cardId == card.cardId;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCard = card;
        _isAddingNewCard = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _salmon.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _salmon : const Color(0xFFF0F0F0), width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          _buildCardBrandIcon(card.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•••• •••• •••• ${card.last4}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              Text('${card.cardholderName}  ${card.expiryMonth}/${card.expiryYear}',
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            ]),
          ),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: _salmon),
        ]),
      ),
    );
  }

  Widget _buildNewCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cardNumberCtrl,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card_rounded, color: _salmon),
              suffixIcon: _detectedBrand != 'other'
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildCardBrandIcon(_detectedBrand))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _salmon, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberInputFormatter(),
            ],
            onChanged: (v) => setState(() => _detectedBrand = _detectBrand(v)),
            validator: (v) {
              final n = (v ?? '').replaceAll(' ', '');
              return n.length != 16 ? 'Enter valid 16-digit card number' : null;
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _expiryCtrl,
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: _salmon, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _salmon, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ExpiryDateFormatter()],
                validator: _validateExpiry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvCtrl,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock_rounded, color: _salmon, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _salmon, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [LengthLimitingTextInputFormatter(4)],
                validator: (v) => (v ?? '').length < 3 ? 'Invalid CVV' : null,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'As on card',
              prefixIcon: const Icon(Icons.person_rounded, color: _salmon),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _salmon, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v ?? '').isEmpty ? 'Enter cardholder name' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Checkbox(
              value: _saveCard,
              activeColor: _salmon,
              onChanged: (v) => setState(() => _saveCard = v!),
            ),
            const Text('Save card for future payments',
                style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecurityBadges() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _securityBadge(Icons.lock_rounded, 'SSL Secured'),
      const SizedBox(width: 16),
      _securityBadge(Icons.verified_rounded, 'Verified'),
      const SizedBox(width: 16),
      _securityBadge(Icons.shield_rounded, 'Protected'),
    ]);
  }

  Widget _securityBadge(IconData icon, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
    ]);
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _salmon,
            disabledBackgroundColor: _salmon.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _isProcessing ? null : _processPayment,
          child: _isProcessing
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  const SizedBox(width: 12),
                  const Text('Processing Payment...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Pay LKR ${_formatPrice(widget.plan.price)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
        ),
      ),
    );
  }

  Widget _buildCardBrandIcon(String brand) {
    switch (brand) {
      case 'visa':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF1A1F71), borderRadius: BorderRadius.circular(4)),
          child: const Text('VISA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        );
      case 'mastercard':
        return SizedBox(
          width: 40, height: 28,
          child: Stack(children: [
            Positioned(
                left: 0,
                child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
            Positioned(
                right: 0,
                child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
          ]),
        );
      case 'amex':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF007BC1), borderRadius: BorderRadius.circular(4)),
          child: const Text('AMEX',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
        );
      default:
        return const Icon(Icons.credit_card_rounded, color: Color(0xFF9E9E9E), size: 32);
    }
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}
