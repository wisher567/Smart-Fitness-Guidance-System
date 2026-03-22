// lib/screens/subscription/my_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:fitfusion/models/subscription_model.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/screens/subscription/plans_screen.dart';
import 'package:fitfusion/screens/subscription/payment_history_screen.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  Subscription? _subscription;
  int _daysRemaining = 0;
  int _totalDays = 30;
  bool _isLoading = true;
  bool _autoRenew = true;

  static const Color _salmon = Color(0xFFE8845C);

  // Build features from plan name since we don't persist features in subscription doc
  static const Map<String, List<String>> _planFeatures = {
    'basic_monthly': ['Gym access 6am-10pm', 'Basic equipment access', 'Locker room access', '1 Group class per week'],
    'premium_monthly': ['24/7 Gym access', 'All equipment access', 'Unlimited group classes', '1 PT session per month', 'FitFusion app full access', 'Nutrition consultation'],
    'premium_yearly': ['Everything in Premium', '2 months FREE', '2 PT sessions per month', 'Body composition analysis', 'Priority class booking', 'Guest passes (2/month)'],
    'student_monthly': ['Gym access 6am-8pm', 'Basic equipment', '2 Group classes per week', 'Valid student ID required'],
  };

  @override
  void initState() {
    super.initState();
    _fetchSubscription();
  }

  Future<void> _fetchSubscription() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.getSubscription();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final sub = res.data!['subscription'] != null
          ? Subscription.fromJson(res.data!['subscription'])
          : null;
      final days = (res.data!['daysRemaining'] as num?)?.toInt() ?? 0;
      if (sub != null) {
        final start = DateTime.tryParse(sub.startDate) ?? DateTime.now();
        final end = DateTime.tryParse(sub.endDate) ?? DateTime.now();
        final total = end.difference(start).inDays.clamp(1, 999);
        setState(() {
          _subscription = sub;
          _daysRemaining = days;
          _totalDays = total;
          _autoRenew = sub.autoRenew;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
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

  Future<void> _toggleAutoRenew(bool value) async {
    // Locally toggle; cancel subscription to disable auto-renew
    if (!value) {
      _showCancelDialog();
    } else {
      setState(() => _autoRenew = value);
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Subscription?'),
        content: const Text(
            'You will lose access to premium features at the end of your billing period. Are you sure you want to cancel?'),
        actions: [
          TextButton(
            child: const Text('Keep Plan', style: TextStyle(color: _salmon)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Plan', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              _cancelSubscription();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    final res = await ApiService.instance.cancelSubscription();
    if (!mounted) return;
    if (res.success) {
      setState(() => _autoRenew = false);
      if (_subscription != null) {
        setState(() => _subscription = Subscription.fromJson({
          ..._subscription!.toMap(),
          'status': 'cancelled',
          'autoRenew': false,
        }));
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Subscription cancelled successfully'),
        backgroundColor: Color(0xFF7CB342),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.error ?? 'Failed to cancel'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ));
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
        title: const Text('My Subscription',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _salmon))
          : _subscription == null
              ? _buildNoSubscription()
              : RefreshIndicator(
                  color: _salmon,
                  onRefresh: _fetchSubscription,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActivePlanCard(),
                        const SizedBox(height: 16),
                        _buildFeaturesCard(),
                        const SizedBox(height: 16),
                        _buildBillingCard(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 16),
                        if (_subscription!.isActive) _buildCancelButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoSubscription() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.card_membership_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Active Subscription',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Subscribe to get full access to FitFusion gym facilities.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9E9E9E))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.star_rounded, color: Colors.white),
            label: const Text('Choose a Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _salmon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen())),
          ),
        ]),
      ),
    );
  }

  Widget _buildActivePlanCard() {
    final daysUsed = _totalDays - _daysRemaining;
    final progress = (_totalDays > 0) ? (daysUsed / _totalDays).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8845C), Color(0xFFD4673A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _salmon.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_subscription!.planName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_subscription!.status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Text('$_daysRemaining days remaining',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text('LKR ${_formatPrice(_subscription!.amount)} / ${_subscription!.billingPeriod}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = _planFeatures[_subscription!.planId] ?? [];
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
          const Text('Plan Includes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: _salmon.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: _salmon, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
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
          const Text('Billing Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today_rounded, 'Next Billing Date', _formatDate(_subscription!.endDate)),
          const SizedBox(height: 10),
          _infoRow(Icons.payments_rounded, 'Amount', 'LKR ${_formatPrice(_subscription!.amount)}'),
          const SizedBox(height: 10),
          _infoRow(Icons.credit_card_rounded, 'Card on File', '•••• •••• •••• ${_subscription!.cardLast4}'),
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.autorenew_rounded, color: Color(0xFF9E9E9E), size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Auto Renew', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14))),
            Switch(
              value: _autoRenew,
              activeThumbColor: _salmon,
              onChanged: _subscription!.isActive ? _toggleAutoRenew : null,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF9E9E9E), size: 18),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }

  Widget _buildQuickActions() {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.upgrade_rounded, color: _salmon),
          label: const Text('Upgrade', style: TextStyle(color: _salmon)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _salmon),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen())),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.history_rounded, color: _salmon),
          label: const Text('History', style: TextStyle(color: _salmon)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _salmon),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
        ),
      ),
    ]);
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _showCancelDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          const Text('Cancel Subscription',
              style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFE53935)),
        ]),
      ),
    );
  }
}

// Extension to convert Subscription back to map for local state updates
extension SubscriptionMap on Subscription {
  Map<String, dynamic> toMap() => {
    'uid': uid, 'planId': planId, 'planName': planName, 'status': status,
    'amount': amount, 'billingPeriod': billingPeriod, 'startDate': startDate,
    'endDate': endDate, 'autoRenew': autoRenew, 'cardLast4': cardLast4,
    'cardBrand': cardBrand, 'lastPaymentId': lastPaymentId,
    'createdAt': createdAt, 'updatedAt': updatedAt,
  };
}
