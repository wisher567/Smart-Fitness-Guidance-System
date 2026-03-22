// lib/screens/subscription/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:fitfusion/models/payment_model.dart';
import 'package:fitfusion/services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Payment> _payments = [];
  int _totalPaid = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await ApiService.instance.getPaymentHistory();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final list = (res.data!['payments'] as List?)?.map((p) => Payment.fromJson(p)).toList() ?? [];
      setState(() {
        _payments = list;
        _totalPaid = (res.data!['totalPaid'] as num?)?.toInt() ?? 0;
        _isLoading = false;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error ?? 'Failed to load payment history';
      });
    }
  }

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF7CB342);
      case 'pending':   return const Color(0xFFFFB800);
      case 'failed':    return const Color(0xFFE53935);
      case 'refunded':  return const Color(0xFF4A90E2);
      default:          return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'pending':   return Icons.hourglass_bottom_rounded;
      case 'failed':    return Icons.cancel_rounded;
      case 'refunded':  return Icons.replay_rounded;
      default:          return Icons.receipt_rounded;
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
        title: const Text('Payment History',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Could not load history',
                          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: const Text('Retry', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8845C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _fetchHistory,
                      ),
                    ]),
                  ),
                )
              : RefreshIndicator(
              color: const Color(0xFFE8845C),
              onRefresh: _fetchHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8845C), Color(0xFFD4673A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFFE8845C).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Total Paid', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('LKR ${_formatPrice(_totalPaid)}',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ]),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Transactions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${_payments.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    if (_payments.isEmpty)
                      _buildEmptyState()
                    else
                      ..._payments.map((p) => _buildPaymentTile(p)),
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
        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No payments yet', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Subscribe to a plan to see your history here.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
      ]),
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    return GestureDetector(
      onTap: () => _showPaymentDetail(payment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _statusColor(payment.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(payment.status), color: _statusColor(payment.status), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(payment.planName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), fontSize: 14)),
              const SizedBox(height: 3),
              Text('${payment.invoiceNumber}  •  ${_formatDate(payment.createdAt)}',
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(payment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(payment.status.toUpperCase(),
                    style: TextStyle(color: _statusColor(payment.status), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('LKR ${_formatPrice(payment.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text('**** ${payment.cardLast4}',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E), size: 18),
          ]),
        ]),
      ),
    );
  }

  void _showPaymentDetail(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentDetailSheet(payment: payment, formatPrice: _formatPrice, formatDate: _formatDate, statusColor: _statusColor),
    );
  }
}

class _PaymentDetailSheet extends StatelessWidget {
  final Payment payment;
  final String Function(int) formatPrice;
  final String Function(String) formatDate;
  final Color Function(String) statusColor;

  const _PaymentDetailSheet({
    required this.payment,
    required this.formatPrice,
    required this.formatDate,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          _row('Invoice', payment.invoiceNumber),
          const Divider(height: 20),
          _row('Plan', payment.planName),
          const SizedBox(height: 8),
          _row('Amount', 'LKR ${formatPrice(payment.amount)}'),
          const SizedBox(height: 8),
          _row('Status', payment.status.toUpperCase(), valueColor: statusColor(payment.status)),
          const SizedBox(height: 8),
          _row('Payment Date', formatDate(payment.createdAt)),
          const SizedBox(height: 8),
          _row('Card', '•••• •••• •••• ${payment.cardLast4}'),
          const SizedBox(height: 8),
          _row('Billing Period', payment.billingPeriod),
          const SizedBox(height: 8),
          _row('Member', payment.memberName),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Row(children: [
        Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(
            color: valueColor ?? const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold, fontSize: 13)),
      ]);
}
