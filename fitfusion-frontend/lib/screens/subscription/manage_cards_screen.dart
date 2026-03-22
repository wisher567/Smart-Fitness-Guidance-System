// lib/screens/subscription/manage_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitfusion/models/saved_card_model.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/screens/subscription/widgets/card_input_formatters.dart';

class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({super.key});

  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  List<SavedCard> _cards = [];
  bool _isLoading = true;
  bool _showAddForm = false;

  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;

  static const Color _salmon = Color(0xFFE8845C);

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.getSavedCards();
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _cards = (res.data!['cards'] as List?)?.map((c) => SavedCard.fromJson(c)).toList() ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

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
    if (DateTime(year, month + 1).isBefore(DateTime.now())) return 'Card expired';
    return null;
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final rawNum = _cardNumberCtrl.text.replaceAll(' ', '');
    final last4 = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : rawNum;
    final parts = _expiryCtrl.text.split('/');

    final res = await ApiService.instance.addSavedCard({
      'last4': last4,
      'brand': _detectBrand(_cardNumberCtrl.text),
      'expiryMonth': parts[0],
      'expiryYear': parts.length > 1 ? parts[1] : '',
      'cardholderName': _nameCtrl.text.trim(),
      'isDefault': _isDefault || _cards.isEmpty,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.success) {
      _cardNumberCtrl.clear(); _expiryCtrl.clear(); _cvvCtrl.clear(); _nameCtrl.clear();
      setState(() => _showAddForm = false);
      _fetchCards();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Card added successfully'),
        backgroundColor: Color(0xFF7CB342),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.error ?? 'Failed to add card'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteCard(SavedCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Card?'),
        content: Text('Remove card ending in ${card.last4}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), elevation: 0),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await ApiService.instance.deleteSavedCard(card.cardId);
    if (!mounted) return;
    if (res.success) {
      _fetchCards();
    }
  }

  Widget _buildCardBrandIcon(String brand) {
    switch (brand) {
      case 'visa':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF1A1F71), borderRadius: BorderRadius.circular(4)),
          child: const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        );
      case 'mastercard':
        return SizedBox(
          width: 40, height: 28,
          child: Stack(children: [
            Positioned(left: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
            Positioned(right: 0, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
          ]),
        );
      case 'amex':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF007BC1), borderRadius: BorderRadius.circular(4)),
          child: const Text('AMEX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        );
      default:
        return const Icon(Icons.credit_card_rounded, color: Color(0xFF9E9E9E), size: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Saved Cards',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _salmon),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _salmon))
          : RefreshIndicator(
              color: _salmon,
              onRefresh: _fetchCards,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showAddForm) ...[_buildAddCardForm(), const SizedBox(height: 16)],
                    if (_cards.isEmpty && !_showAddForm)
                      _buildEmptyState()
                    else
                      ..._cards.map((c) => _buildCardTile(c)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.credit_card_off_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No saved cards', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Card', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _salmon,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () => setState(() => _showAddForm = true),
        ),
      ]),
    );
  }

  Widget _buildCardTile(SavedCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        _buildCardBrandIcon(card.brand),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('•••• •••• •••• ${card.last4}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            if (card.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _salmon.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('DEFAULT', style: TextStyle(color: _salmon, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          Text('${card.cardholderName}  ${card.expiryMonth}/${card.expiryYear}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 22),
          onPressed: () => _deleteCard(card),
        ),
      ]),
    );
  }

  Widget _buildAddCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
                onPressed: () => setState(() => _showAddForm = false),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberCtrl,
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: const Icon(Icons.credit_card_rounded, color: _salmon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _salmon, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardNumberInputFormatter()],
              validator: (v) {
                final n = (v ?? '').replaceAll(' ', '');
                return n.length != 16 ? 'Enter valid 16-digit number' : null;
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryCtrl,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    prefixIcon: const Icon(Icons.date_range_rounded, color: _salmon, size: 18),
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
                prefixIcon: const Icon(Icons.person_rounded, color: _salmon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _salmon, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Checkbox(value: _isDefault, activeColor: _salmon, onChanged: (v) => setState(() => _isDefault = v!)),
              const Text('Set as default card', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _salmon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _addCard,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
