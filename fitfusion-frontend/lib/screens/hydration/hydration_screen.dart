import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/providers/hydration_provider.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> with TickerProviderStateMixin {
  String _selectedType = 'water';
  late ConfettiController _confettiCtrl;
  late AnimationController _ringAnimCtrl;
  late Animation<double> _ringAnim;
  bool _goalCelebrated = false;

  // --- Theme Helpers (matching Leaderboard) ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primaryColor => const Color(0xFFFE7235); // Fitfusion Orange
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;
  Color get borderColor => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  Color get surfaceColor => isDark ? const Color(0xFF2A2A2D) : const Color(0xFFF0F0F0);

  double rFont(double size) {
    double w = MediaQuery.of(context).size.width;
    if (w < 360) return size * 0.85;
    if (w > 414) return size * 1.1;
    return size;
  }

  static const _drinkTypes = [
    {'type': 'water', 'icon': '💧', 'label': 'Water'},
    {'type': 'juice', 'icon': '🥤', 'label': 'Juice'},
    {'type': 'tea', 'icon': '🍵', 'label': 'Tea'},
    {'type': 'coffee', 'icon': '☕', 'label': 'Coffee'},
    {'type': 'coconut', 'icon': '🥥', 'label': 'Coconut Water'},
    {'type': 'other', 'icon': '🧃', 'label': 'Other'},
  ];

  static const _quickAmounts = [
    {'ml': 150, 'icon': '🥤', 'label': '150ml'},
    {'ml': 250, 'icon': '☕', 'label': '250ml'},
    {'ml': 350, 'icon': '🧃', 'label': '350ml'},
    {'ml': 500, 'icon': '💧', 'label': '500ml'},
    {'ml': 750, 'icon': '🚰', 'label': '750ml'},
  ];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _ringAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _ringAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ringAnimCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<HydrationProvider>(context, listen: false);
      prov.loadToday();
      prov.loadWeekly();
      prov.loadGoal();
      prov.startAutoRefresh();
      _ringAnimCtrl.forward();
    });
  }

  @override
  void dispose() {
    Provider.of<HydrationProvider>(context, listen: false).stopAutoRefresh();
    _confettiCtrl.dispose();
    _ringAnimCtrl.dispose();
    super.dispose();
  }

  void _onLog(int ml) async {
    final icon = _drinkTypes.firstWhere((d) => d['type'] == _selectedType)['icon'] ?? '💧';
    final prov = Provider.of<HydrationProvider>(context, listen: false);
    final result = await prov.logWater(ml, _selectedType, icon);

    if (!mounted) return;

    final pts = result?['dailySummary']?['pointsEarned'] ?? 0;
    if (pts > 0 && !_goalCelebrated) {
      _goalCelebrated = true;
      _confettiCtrl.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$pts points earned! 💧 Daily hydration goal complete!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Re-animate the ring
    _ringAnimCtrl.reset();
    _ringAnimCtrl.forward();
  }

  void _showCustomAmountSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Custom Amount', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl, autofocus: true, keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: textPrimary, fontSize: 24),
            decoration: InputDecoration(hintText: 'ml', hintStyle: GoogleFonts.poppins(color: textSecondary),
              filled: true, fillColor: surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) { Navigator.pop(context); _onLog(v); }
            },
            child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          )),
        ]),
      ),
    );
  }

  void _showGoalSettings() {
    final prov = Provider.of<HydrationProvider>(context, listen: false);
    double goalMl = (prov.goalMl).toDouble();
    bool reminders = prov.goal?['reminderEnabled'] == true;
    int interval = (prov.goal?['reminderIntervalHours'] ?? 2) as int;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Hydration Goal', style: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('${goalMl.round()} ml / day', style: GoogleFonts.poppins(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w800)),
          Slider(
            value: goalMl, min: 500, max: 5000, divisions: 18,
            activeColor: primaryColor,
            onChanged: (v) => setBS(() => goalMl = v),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Reminders', style: GoogleFonts.poppins(color: textPrimary)),
            Switch(value: reminders, activeTrackColor: primaryColor, onChanged: (v) => setBS(() => reminders = v)),
          ]),
          if (reminders) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Every', style: GoogleFonts.poppins(color: textSecondary)),
              DropdownButton<int>(
                value: interval, dropdownColor: cardColor,
                style: GoogleFonts.poppins(color: textPrimary),
                items: [1, 2, 3, 4].map((h) => DropdownMenuItem(value: h, child: Text('$h hour${h > 1 ? 's' : ''}'))).toList(),
                onChanged: (v) => setBS(() => interval = v!),
              ),
            ]),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () { Navigator.pop(ctx); prov.setGoal(goalMl.round(), reminders, interval); },
            child: Text('Save Goal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  void _confirmDelete(String logId) {
    final prov = Provider.of<HydrationProvider>(context, listen: false);
    showModalBottomSheet(
      context: context, backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Delete this log?', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: BorderSide(color: textSecondary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: textSecondary)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () { Navigator.pop(context); prov.deleteLog(logId); },
              child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final prov = Provider.of<HydrationProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hydration Tracker",
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textSecondary),
            onPressed: _showGoalSettings,
          ),
        ],
      ),
      body: Stack(children: [
        SafeArea(
          top: false,
          child: prov.isLoading && prov.todayData == null
              ? _buildShimmer()
              : prov.error != null && prov.todayData == null
                  ? _buildError(prov)
                  : RefreshIndicator(
                      color: primaryColor,
                      onRefresh: () async {
                        await prov.loadToday();
                        await prov.loadWeekly();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 16),
                        child: Column(children: [
                          _buildStreakBadge(prov),
                          const SizedBox(height: 24),
                          _buildWaterRing(prov, w),
                          const SizedBox(height: 24),
                          _buildDrinkTypeChips(),
                          const SizedBox(height: 16),
                          _buildQuickAddButtons(),
                          const SizedBox(height: 24),
                          _buildTodayLogList(prov),
                          const SizedBox(height: 24),
                          _buildWeeklyChart(prov),
                          const SizedBox(height: 80),
                        ]),
                      ),
                    ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            colors: [primaryColor, const Color(0xFFFF9800), Colors.white, const Color(0xFFFFCC80)],
            numberOfParticles: 30,
          ),
        ),
      ]),
    );
  }

  // ── Streak Badge ──────────────────────────────────────────────────────────
  Widget _buildStreakBadge(HydrationProvider prov) {
    int streak = 0;
    final weekly = prov.weeklyData?['weeklyData'] as List?;
    if (weekly != null) {
      for (int i = weekly.length - 1; i >= 0; i--) {
        if (weekly[i]['goalReached'] == true) {
          streak++;
        } else {
          break;
        }
      }
    }

    if (streak <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(isDark ? 51 : 25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withAlpha(76)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🔥', style: TextStyle(fontSize: rFont(16))),
            const SizedBox(width: 6),
            Text('$streak day${streak > 1 ? 's' : ''} streak!',
              style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(13), fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Water Ring ─────────────────────────────────────────────────────────────
  Widget _buildWaterRing(HydrationProvider prov, double w) {
    final ringSize = (w * 0.6).clamp(180.0, 260.0);
    final total = prov.totalMl;
    final goal = prov.goalMl;
    final pct = prov.percent;

    String amountStr;
    if (total >= 1000) {
      amountStr = '${(total / 1000).toStringAsFixed(1)}L';
    } else {
      amountStr = '${total}ml';
    }

    return AnimatedBuilder(
      animation: _ringAnim,
      builder: (_, __) => CircularPercentIndicator(
        radius: ringSize / 2,
        lineWidth: 16,
        percent: (pct * _ringAnim.value).clamp(0.0, 1.0),
        backgroundColor: surfaceColor,
        linearGradient: LinearGradient(colors: prov.goalReached
            ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
            : [primaryColor, const Color(0xFFFF9800)]),
        circularStrokeCap: CircularStrokeCap.round,
        animation: false,
        center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(amountStr, style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(32), fontWeight: FontWeight.w800)),
          Text('of ${(goal / 1000).toStringAsFixed(1)}L', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(14))),
          const SizedBox(height: 4),
          Text('${(pct * 100).round()}%', style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(16), fontWeight: FontWeight.w700)),
          if (prov.goalReached) ...[
            const SizedBox(height: 4),
            Text('🎉 Goal Reached!', style: GoogleFonts.poppins(color: const Color(0xFF4CAF50), fontSize: rFont(12), fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Drink Type Chips ───────────────────────────────────────────────────────
  Widget _buildDrinkTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _drinkTypes.map((d) {
        final selected = _selectedType == d['type'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = d['type'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? primaryColor : cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: selected ? primaryColor : borderColor),
                boxShadow: isDark ? [] : [
                  if (!selected) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(d['icon'] as String, style: TextStyle(fontSize: rFont(16))),
                const SizedBox(width: 6),
                Text(d['label'] as String, style: GoogleFonts.poppins(
                  color: selected ? Colors.white : textSecondary,
                  fontSize: rFont(12), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
      }).toList()),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  // ── Quick Add Buttons ──────────────────────────────────────────────────────
  Widget _buildQuickAddButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        ..._quickAmounts.map((q) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _QuickAddBtn(
            label: q['label'] as String, icon: q['icon'] as String,
            onTap: () => _onLog(q['ml'] as int),
            cardColor: cardColor, primaryColor: primaryColor,
            textPrimary: textPrimary, borderColor: borderColor,
            isDark: isDark,
          ),
        )),
        _QuickAddBtn(
          label: 'Custom', icon: '✏️', onTap: _showCustomAmountSheet,
          cardColor: cardColor, primaryColor: primaryColor,
          textPrimary: textPrimary, borderColor: borderColor,
          isDark: isDark,
        ),
      ]),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  // ── Today's Log List ───────────────────────────────────────────────────────
  Widget _buildTodayLogList(HydrationProvider prov) {
    final logs = prov.logs;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text("Today's Intake", style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(18), fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: primaryColor.withAlpha(40), borderRadius: BorderRadius.circular(10)),
          child: Text('${logs.length}', style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(12), fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 12),
      if (logs.isEmpty)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Text('💧', style: TextStyle(fontSize: rFont(40))),
            const SizedBox(height: 8),
            Text('No water logged yet today', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(14))),
            Text('Tap a quick add button to get started!', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(12))),
          ]),
        )
      else
        ...logs.asMap().entries.map((entry) {
          final log = entry.value as Map<String, dynamic>;
          final time = log['loggedAt'] != null ? DateFormat.jm().format(DateTime.parse(log['loggedAt'])) : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: primaryColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(log['icon'] ?? '💧', style: TextStyle(fontSize: rFont(18)))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${log['amount']} ml', style: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: rFont(14))),
                Text('${(log['type'] ?? 'water').toString().substring(0, 1).toUpperCase()}${(log['type'] ?? 'water').toString().substring(1)} · $time',
                    style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11))),
              ])),
              GestureDetector(
                onTap: () => _confirmDelete(log['id'] ?? ''),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ]),
          ).animate().fadeIn(delay: Duration(milliseconds: entry.key * 50)).slideX(begin: 0.1);
        }),
    ]);
  }

  // ── Weekly Chart ───────────────────────────────────────────────────────────
  Widget _buildWeeklyChart(HydrationProvider prov) {
    final weeklyData = prov.weeklyData;
    if (weeklyData == null) return const SizedBox.shrink();

    final days = weeklyData['weeklyData'] as List? ?? [];
    final avg = weeklyData['weeklyAverage'] ?? 0;
    final insight = weeklyData['weeklyInsight'] ?? '';
    final goalMl = prov.goalMl;
    final maxMl = days.fold<int>(goalMl, (m, d) => (d['totalMl'] as int? ?? 0) > m ? d['totalMl'] as int : m);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('This Week', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(18), fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          ...days.asMap().entries.map((entry) {
            final d = entry.value as Map<String, dynamic>;
            final total = d['totalMl'] as int? ?? 0;
            final reached = d['goalReached'] == true;
            final isToday = d['date'] == today;
            final barFraction = maxMl > 0 ? (total / maxMl).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 36, child: Text(d['dayName'] ?? '', style: GoogleFonts.poppins(
                  color: isToday ? textPrimary : textSecondary, fontSize: rFont(12), fontWeight: isToday ? FontWeight.bold : FontWeight.normal))),
                Expanded(child: Container(
                  height: 14,
                  decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(7)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: reached ? primaryColor : (isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(7),
                        border: isToday ? Border.all(color: primaryColor, width: 1.5) : null,
                      ),
                    ),
                  ).animate().custom(delay: Duration(milliseconds: entry.key * 80), duration: 600.ms,
                    builder: (_, value, child) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: barFraction * value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: reached ? primaryColor : (isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(7),
                          border: isToday ? Border.all(color: primaryColor, width: 1.5) : null,
                        ),
                      ),
                    ),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 52, child: Text('${total}ml', textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(color: reached ? primaryColor : textSecondary, fontSize: rFont(11), fontWeight: FontWeight.w600))),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Text('Weekly average: ${avg}ml/day', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(12))),
        ]),
      ),
      if (insight.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(isDark ? 30 : 15), borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: primaryColor, width: 3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('💡', style: TextStyle(fontSize: rFont(16))),
              const SizedBox(width: 8),
              Text('AI Insight', style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(14), fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(insight, style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87, fontSize: rFont(13), height: 1.5)),
          ]),
        ),
      ],
    ]).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── Shimmer loading ────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 30),
          Container(width: 220, height: 220, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(height: 30),
          Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
          )),
        ]),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError(HydrationProvider prov) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade800)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(prov.error ?? 'Something went wrong', textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: textPrimary, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => prov.loadToday(),
            child: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ]),
      ),
    ));
  }
}

// ── Quick Add Button widget ──────────────────────────────────────────────────
class _QuickAddBtn extends StatefulWidget {
  final String label, icon;
  final VoidCallback onTap;
  final Color cardColor, primaryColor, textPrimary, borderColor;
  final bool isDark;
  const _QuickAddBtn({
    required this.label, required this.icon, required this.onTap,
    required this.cardColor, required this.primaryColor,
    required this.textPrimary, required this.borderColor,
    required this.isDark,
  });

  @override
  State<_QuickAddBtn> createState() => _QuickAddBtnState();
}

class _QuickAddBtnState extends State<_QuickAddBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1, end: 0.92).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.cardColor, borderRadius: BorderRadius.circular(25),
            border: Border.all(color: widget.primaryColor.withAlpha(100)),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(widget.label, style: GoogleFonts.poppins(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
