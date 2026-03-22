import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/main.dart' show routeObserver;
import 'package:fitfusion/providers/calorie_provider.dart';
import 'package:fitfusion/screens/calories/calorie_goals_screen.dart';
import 'package:fitfusion/screens/hydration/hydration_screen.dart';

class CalorieDashboardScreen extends StatefulWidget {
  const CalorieDashboardScreen({super.key});

  @override
  State<CalorieDashboardScreen> createState() => _CalorieDashboardScreenState();
}

class _CalorieDashboardScreenState extends State<CalorieDashboardScreen>
    with RouteAware {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<CalorieProvider>(context, listen: false);
      prov.fetchTodayData();
      prov.fetchWeeklyData();
      // Auto-refresh is removed in rewrite, handled via background syncs
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    final prov = Provider.of<CalorieProvider>(context, listen: false);
    prov.fetchTodayData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final prov = Provider.of<CalorieProvider>(context);

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
          "Calorie Dashboard",
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Today / Week toggle
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(25)),
            child: Row(children: [
              _pillToggle('Today', 'today', prov),
              _pillToggle('Week', 'weekly', prov),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.tune, color: textSecondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieGoalsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: prov.isLoading && prov.totalCaloriesConsumed == 0 && prov.targetCalories == 2000
            ? _buildShimmer()
            : prov.error != null && prov.totalCaloriesConsumed == 0
                ? _buildError(prov)
                : RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () async {
                      await prov.fetchTodayData();
                      if (prov.selectedRange == 'weekly') await prov.fetchWeeklyData();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 16),
                      child: Column(children: [
                        _buildMainCalorieCard(prov),
                        const SizedBox(height: 20),
                        _buildCalorieFlow(prov),
                        const SizedBox(height: 20),
                        if (prov.selectedRange == 'today') ...[
                          _buildMacroBreakdown(prov),
                          const SizedBox(height: 20),
                          _buildWorkoutCalories(prov),
                          const SizedBox(height: 20),
                          _buildHydrationCard(prov),
                        ] else ...[
                          _buildWeeklyChart(prov),
                        ],
                        const SizedBox(height: 20),
                        _buildAIInsight(prov),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
      ),
    );
  }

  Widget _pillToggle(String label, String value, CalorieProvider prov) {
    final selected = prov.selectedRange == value;
    return GestureDetector(
      onTap: () => prov.setSelectedRange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: selected ? Colors.white : textSecondary, fontSize: rFont(12), fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Main Calorie Card ──────────────────────────────────────────────────────
  Widget _buildMainCalorieCard(CalorieProvider prov) {
    final consumed = prov.totalCaloriesConsumed;
    final burned = prov.totalCaloriesBurned;
    final target = prov.targetCalories;
    final remaining = prov.caloriesRemaining;
    final pct = prov.percentComplete;
    final status = prov.status;

    Color statusColor;
    String statusText;
    if (status == 'over') {
      statusColor = const Color(0xFFF44336);
      statusText = 'kcal over target ⚠️';
    } else if (status == 'on-track') {
      statusColor = const Color(0xFFFF9800);
      statusText = 'kcal on track 🎯';
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusText = 'kcal remaining today 🎯';
    }

    final displayNum = remaining;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: displayNum),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
          builder: (_, value, __) => Text('$value', style: GoogleFonts.poppins(color: statusColor, fontSize: rFont(48), fontWeight: FontWeight.w900)),
        ),
        Text(statusText, style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(14))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _miniStat('🍽️', '$consumed', 'consumed'),
          const SizedBox(width: 32),
          _miniStat('🔥', '$burned', 'burned'),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (pct / 100).clamp(0.0, 1.5)),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: surfaceColor,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Column(children: [
      Text('$emoji $value', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(16), fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11))),
    ]);
  }

  // ── Calorie Flow ───────────────────────────────────────────────────────────
  Widget _buildCalorieFlow(CalorieProvider prov) {
    return Row(children: [
      Expanded(child: _flowBox('🍽️', '${prov.totalCaloriesConsumed}', 'Consumed', const Color(0xFFFF9800))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, color: textSecondary, size: 20)),
      Expanded(child: _flowBox('🔥', '-${prov.totalCaloriesBurned}', 'Burned', primaryColor)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, color: textSecondary, size: 20)),
      Expanded(child: _flowBox('⚡', '=${prov.netCalories}', 'Net', const Color(0xFF4CAF50))),
    ]).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _flowBox(String emoji, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: [
        Text(emoji, style: TextStyle(fontSize: rFont(20))),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
          duration: const Duration(milliseconds: 1500),
          builder: (_, v, __) => Text(value.startsWith('-') ? '-$v' : value.startsWith('=') ? '=$v' : '$v',
            style: GoogleFonts.poppins(color: accent, fontSize: rFont(16), fontWeight: FontWeight.w800)),
        ),
        Text(label, style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(10))),
      ]),
    );
  }

  // ── Macro Breakdown ────────────────────────────────────────────────────────
  Widget _buildMacroBreakdown(CalorieProvider prov) {
    final macroItems = [
      {'name': 'Protein', 'emoji': '💪', 'color': const Color(0xFF2196F3), 'actual': prov.totalProtein, 'target': prov.targetProtein},
      {'name': 'Carbs', 'emoji': '🌾', 'color': const Color(0xFFFFC107), 'actual': prov.totalCarbs, 'target': prov.targetCarbs},
      {'name': 'Fats', 'emoji': '🥑', 'color': const Color(0xFF9C27B0), 'actual': prov.totalFats, 'target': prov.targetFats},
      {'name': 'Fiber', 'emoji': '🥦', 'color': const Color(0xFF4CAF50), 'actual': prov.totalFiber, 'target': prov.targetFiber},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Today's Macros", style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(18), fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...macroItems.map((m) {
          final actual = m['actual'] as double;
          final tgt = m['target'] as double;
          final pct = tgt > 0 ? (actual / tgt) : 0.0;
          final color = m['color'] as Color;
          final statusIcon = actual >= tgt ? '✅' : (pct < 0.5 ? '⬇️' : '⬆️');

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Text(m['emoji'] as String, style: TextStyle(fontSize: rFont(18))),
              const SizedBox(width: 8),
              SizedBox(width: 55, child: Text(m['name'] as String, style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(13), fontWeight: FontWeight.w500))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (pct).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v, minHeight: 8,
                      backgroundColor: surfaceColor,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${actual.toInt()}g/${tgt.toInt()}g', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11), fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text(statusIcon, style: TextStyle(fontSize: rFont(12))),
            ]),
          );
        }),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ── Workout Calories ───────────────────────────────────────────────────────
  Widget _buildWorkoutCalories(CalorieProvider prov) {
    final displayWorkouts = prov.completedWorkouts;
    final totalBurned = prov.totalCaloriesBurned;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Calories Burned from Workouts', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(16), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (displayWorkouts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text('No workouts today', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(14))),
              Text('Complete a workout to burn calories! 💪', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(12))),
            ]),
          )
        else ...[
          ...displayWorkouts.map((w) {
            final name = w['exerciseName'] as String? ?? 'Workout';
            final kcal = w['caloriesBurned'];
            final kcalStr = kcal != null && kcal != 0 ? '$kcal kcal' : '🔥';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center_rounded, color: primaryColor, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : Colors.black54, fontSize: rFont(13)))),
                Text(kcalStr, style: GoogleFonts.poppins(
                  color: primaryColor, fontSize: rFont(13), fontWeight: FontWeight.w600)),
              ]),
            );
          }),
          Divider(color: borderColor),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total burned', style: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold, fontSize: rFont(14))),
            Text('🔥 $totalBurned kcal', style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold, fontSize: rFont(14))),
          ]),
        ],
      ]),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  // ── Hydration Card ─────────────────────────────────────────────────────────
  Widget _buildHydrationCard(CalorieProvider prov) {
    final totalMl = prov.hydrationMl;
    final goalMl = prov.hydrationTargetMl;
    final pct = goalMl > 0 ? (totalMl / goalMl * 100).clamp(0, 100) : 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          SizedBox(
            width: 60, height: 60,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0).toDouble(), strokeWidth: 5,
                backgroundColor: surfaceColor,
                valueColor: AlwaysStoppedAnimation(pct >= 80 ? primaryColor : textSecondary),
              ),
              Text('💧', style: TextStyle(fontSize: rFont(20))),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hydration Today', style: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold, fontSize: rFont(14))),
            Text('${totalMl}ml of ${(goalMl / 1000).toStringAsFixed(1)}L', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(12))),
          ])),
          Icon(Icons.chevron_right, color: textSecondary, size: 20),
        ]),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  // ── Weekly Chart ───────────────────────────────────────────────────────────
  Widget _buildWeeklyChart(CalorieProvider prov) {
    final days = prov.weeklyData;
    if (days.isEmpty) {
      if (prov.isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly Overview', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(18), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Legend
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text('Consumed', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11))),
          const SizedBox(width: 12),
          Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF29B6F6), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text('Burned', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: days.asMap().entries.map((entry) {
                final d = entry.value;
                return BarChartGroupData(x: entry.key, barRods: [
                  BarChartRodData(
                    toY: (d['consumed'] ?? 0).toDouble(), width: 10,
                    color: primaryColor, borderRadius: BorderRadius.circular(3)),
                  BarChartRodData(
                    toY: (d['burned'] ?? 0).toDouble(), width: 10,
                    color: const Color(0xFF29B6F6), borderRadius: BorderRadius.circular(3)),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  return Text(days[idx]['dayName'] ?? '', style: GoogleFonts.poppins(color: textSecondary, fontSize: 10));
                })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) {
                  return Text('${v.toInt()}', style: GoogleFonts.poppins(color: textSecondary, fontSize: 9));
                })),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500,
                getDrawingHorizontalLine: (_) => FlLine(color: borderColor, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gIdx, rod, rIdx) {
                    final label = rIdx == 0 ? 'Consumed' : 'Burned';
                    return BarTooltipItem('$label\n${rod.toY.toInt()} kcal',
                      GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Avg consumed: ${prov.weeklyAvgCalories.toInt()} kcal/day',
          style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(11))),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  // ── AI Insight ─────────────────────────────────────────────────────────────
  Widget _buildAIInsight(CalorieProvider prov) {
    // Only use prov.aiInsight since weekly insight is consolidated
    final insight = prov.aiInsight;
    if (insight.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(isDark ? 30 : 15), borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: primaryColor, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🔥', style: TextStyle(fontSize: rFont(16))),
          const SizedBox(width: 8),
          Text('AI Calorie Insight', style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(14), fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => prov.fetchTodayData(),
            child: Icon(Icons.refresh, color: primaryColor, size: 18),
          ),
        ]),
        const SizedBox(height: 8),
        Text(insight, style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87, fontSize: rFont(13), height: 1.5)),
      ]),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 20),
          Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 20),
          Row(children: List.generate(3, (_) => Expanded(child: Container(height: 90, margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))))),
          const SizedBox(height: 20),
          Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        ]),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(CalorieProvider prov) {
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
            onPressed: () => prov.fetchTodayData(),
            child: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ]),
      ),
    ));
  }
}
