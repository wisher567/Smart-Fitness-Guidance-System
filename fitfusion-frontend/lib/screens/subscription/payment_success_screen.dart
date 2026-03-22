// lib/screens/subscription/payment_success_screen.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:fitfusion/models/plan_model.dart';
import 'package:fitfusion/home_page.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String paymentId;
  final String invoiceNumber;
  final Plan plan;
  final String cardLast4;
  final String endDate;

  const PaymentSuccessScreen({
    super.key,
    required this.paymentId,
    required this.invoiceNumber,
    required this.plan,
    required this.cardLast4,
    required this.endDate,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confettiCtrl.play());
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatDate(String isoString) {
    try {
      final d = DateTime.parse(isoString);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = _formatDate(today.toIso8601String());
    final nextStr = _formatDate(widget.endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (_, value, __) => Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8845C).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Color(0xFFE8845C), size: 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text('Payment Successful! 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Welcome to ${widget.plan.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15)),
                  const SizedBox(height: 28),

                  // Receipt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _receiptRow('Invoice', widget.invoiceNumber),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                        _receiptRow('Plan', widget.plan.name),
                        const SizedBox(height: 10),
                        _receiptRow('Amount', 'LKR ${_formatPrice(widget.plan.price)}'),
                        const SizedBox(height: 10),
                        _receiptRow('Date', todayStr),
                        const SizedBox(height: 10),
                        _receiptRow('Card', '•••• •••• •••• ${widget.cardLast4}'),
                        const SizedBox(height: 10),
                        _receiptRow('Next Billing', nextStr),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Points Badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8845C).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Text('🏆', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('+100 Points Earned!',
                            style: TextStyle(color: Color(0xFFE8845C), fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('For subscribing to FitFusion',
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE8845C)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('View Receipt',
                            style: TextStyle(color: Color(0xFFE8845C), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (r) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8845C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Go to Dashboard',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [Color(0xFFE8845C), Color(0xFFD4673A), Color(0xFFFFB800), Color(0xFF7CB342)],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(children: [
      Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    ]);
  }
}
