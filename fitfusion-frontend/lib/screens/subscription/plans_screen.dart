// lib/screens/subscription/plans_screen.dart
import 'package:flutter/material.dart';
import 'package:fitfusion/models/plan_model.dart';
import 'package:fitfusion/models/subscription_model.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/screens/subscription/payment_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Plan> _plans = [];
  Subscription? _currentSubscription;
  int _daysRemaining = 0;
  bool _isLoading = true;
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final res = await ApiService.instance.getPlans();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final data = res.data!;
      final rawPlans = (data['plans'] as List?)?.map((p) => Plan.fromJson(p)).toList() ?? [];
      Subscription? sub;
      if (data['currentSubscription'] != null) {
        sub = Subscription.fromJson(data['currentSubscription']);
        if (sub.isActive) {
          final end = DateTime.tryParse(sub.endDate) ?? DateTime.now();
          _daysRemaining = end.difference(DateTime.now()).inDays.clamp(0, 9999);
        }
      }
      setState(() {
        _plans = rawPlans;
        _currentSubscription = sub;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Plan> get _filteredPlans =>
      _plans.where((p) => p.billingPeriod == _selectedPeriod).toList();

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  int _colorFromHex(String hex) => int.parse(hex.replaceAll('#', '0xFF'));

  void _selectPlan(Plan plan) {
    if (_currentSubscription?.planId == plan.id && _currentSubscription!.isActive) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(plan: plan)));
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
        title: const Text('Choose Your Plan',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
          : RefreshIndicator(
              color: const Color(0xFFE8845C),
              onRefresh: _fetchPlans,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Subscription Banner
                    if (_currentSubscription != null && _currentSubscription!.isActive) ...[
                      _buildActiveBanner(),
                      const SizedBox(height: 16),
                    ],

                    // Period Toggle
                    _buildPeriodToggle(),
                    const SizedBox(height: 20),

                    // Plan Cards
                    ..._filteredPlans.map((plan) => _buildPlanCard(plan)),

                    // Bottom Info
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_rounded, size: 14, color: Color(0xFF9E9E9E)),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text('Secure payment  •  Cancel anytime  •  No hidden fees',
                                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8845C), Color(0xFFD4673A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFE8845C).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Plan', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(_currentSubscription!.planName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('$_daysRemaining days remaining',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('ACTIVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _periodButton('monthly', 'Monthly'),
          _periodButton('yearly', 'Yearly  🎉 Save 2 months'),
        ],
      ),
    );
  }

  Widget _periodButton(String period, String label) {
    final selected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8845C) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF9E9E9E),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    final isCurrent = _currentSubscription?.planId == plan.id && _currentSubscription!.isActive;
    final accentColor = Color(_colorFromHex(plan.color));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.popular ? const Color(0xFFE8845C) : const Color(0xFFF0F0F0),
          width: plan.popular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.popular ? const Color(0xFFE8845C).withOpacity(0.15) : Colors.black.withOpacity(0.05),
            blurRadius: plan.popular ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.popular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8845C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('MOST POPULAR',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      if (plan.popular) const SizedBox(height: 6),
                      Text(plan.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      if (plan.savings != null) ...[
                        const SizedBox(height: 4),
                        Text(plan.savings!,
                            style: const TextStyle(color: Color(0xFF7CB342), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  RichText(
                    text: TextSpan(children: [
                      const TextSpan(
                          text: 'LKR ', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                      TextSpan(
                          text: _formatPrice(plan.price),
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A), fontSize: 28, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Text('/ ${plan.period}',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                ]),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845C).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFFE8845C), size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13))),
                ]),
              )).toList(),
            ),
          ),

          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? const Color(0xFF7CB342)
                      : plan.popular
                          ? const Color(0xFFE8845C)
                          : Colors.white,
                  foregroundColor: isCurrent || plan.popular ? Colors.white : const Color(0xFFE8845C),
                  side: (!plan.popular && !isCurrent)
                      ? const BorderSide(color: Color(0xFFE8845C))
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isCurrent ? null : () => _selectPlan(plan),
                child: Text(
                  isCurrent ? 'Current Plan ✓' : 'Get ${plan.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
