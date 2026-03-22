import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/providers/nutrition_provider.dart';

class CalorieStatsPage extends StatefulWidget {
  const CalorieStatsPage({super.key});

  @override
  State<CalorieStatsPage> createState() => _CalorieStatsPageState();
}

class _CalorieStatsPageState extends State<CalorieStatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      nutritionProvider.fetchTodayMeals();
      nutritionProvider.fetchWeeklyReport();
      nutritionProvider.fetchNutritionTargets();
    });
  }

  Future<void> _onRefresh() async {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    await Future.wait([
      nutritionProvider.fetchTodayMeals(force: true),
      nutritionProvider.fetchWeeklyReport(force: true),
      nutritionProvider.fetchNutritionTargets(force: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFFFE7235), // Fitfusion Orange
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(context, isDark),
                    const SizedBox(height: 28),
                    _buildMainContent(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Calorie Stats",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDark) {
    final provider = Provider.of<NutritionProvider>(context);

    if (provider.isLoading && provider.todayMeals == null && provider.weeklyReport == null) {
      return SizedBox(
        height: 400,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFE7235)),
        ),
      );
    }

    if (provider.error != null && provider.todayMeals == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Error loading stats: ${provider.error}",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Extract Today's Totals
    final todayData = provider.todayMeals ?? {};
    final nutrition = todayData['totals'] ?? {};
    final int calories = (nutrition['calories'] is num) ? (nutrition['calories'] as num).toInt() : 0;
    final int carbs = (nutrition['carbs'] is num) ? (nutrition['carbs'] as num).toInt() : 0;
    final int protein = (nutrition['protein'] is num) ? (nutrition['protein'] as num).toInt() : 0;
    final int fats = (nutrition['fats'] is num) ? (nutrition['fats'] as num).toInt() : 0;
    
    // Calculate total macros for percentage
    final int totalMacros = carbs + protein + fats;
    final double carbPct = totalMacros > 0 ? carbs / totalMacros : 0;
    final double protPct = totalMacros > 0 ? protein / totalMacros : 0;
    final double fatPct = totalMacros > 0 ? fats / totalMacros : 0;
    
    final targets = provider.nutritionTargets ?? {};
    final weeklyAvg = (provider.weeklyReport?['weeklyAverages']?['calories'] ?? 0).round();
    
    // Overall fill max relative to an arbitrary target (e.g. 250g total macros or 2000 kcal)
    // To make the charts look good, we'll use local scaling relative to their own percentage of total macros.
    
    final String currentMonth = DateFormat('MMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kcal + Month selector ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                calories.toString(),
                style: GoogleFonts.inter(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  "kcal",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentMonth,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ),

        const SizedBox(height: 32),

        // ── Macro Bar chart (Custom) ───────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroBar(isDark, "Fat", "${(fatPct * 100).round()}%", const Color(0xFF1A1A1A), fatPct.clamp(0.1, 1.0)),
              _buildMacroBar(isDark, "Protein", "${(protPct * 100).round()}%", const Color(0xFF3B82F6), protPct.clamp(0.1, 1.0)),
              _buildMacroBar(isDark, "Carbs", "${(carbPct * 100).round()}%", const Color(0xFFF97316), carbPct.clamp(0.1, 1.0)),
              _buildMacroBar(isDark, "Total", "${totalMacros}g", const Color(0xFF6DBD2E), 0.8), // Placeholder for total visual
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
        ),

        const SizedBox(height: 32),
        Divider(color: isDark ? const Color(0xFF333333) : Colors.grey.shade200, thickness: 1, height: 1),
        const SizedBox(height: 8),

        // ── Legend list ───────────────────────────────────────
        _legendRow(isDark, const Color(0xFF1A1A1A), "Fat", "${fats}g / ${targets['fats'] ?? 70}g").animate().fadeIn(delay: 150.ms),
        _divider(isDark),
        _legendRow(isDark, const Color(0xFF3B82F6), "Protein", "${protein}g / ${targets['protein'] ?? 150}g").animate().fadeIn(delay: 200.ms),
        _divider(isDark),
        _legendRow(isDark, const Color(0xFFF97316), "Carbs", "${carbs}g / ${targets['carbs'] ?? 250}g").animate().fadeIn(delay: 250.ms),
        _divider(isDark),
        _legendRow(isDark, const Color(0xFF6DBD2E), "Weekly Avg", "$weeklyAvg kcal").animate().fadeIn(delay: 300.ms),
        _divider(isDark),

        const SizedBox(height: 32),

        // ── Weekly Progress Chart ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Weekly Progress",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
        
        const SizedBox(height: 24),
        
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(right: 24, left: 16),
            child: _buildWeeklyChart(provider.weeklyReport, isDark),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWeeklyChart(Map<String, dynamic>? reportData, bool isDark) {
    if (reportData == null || reportData.isEmpty) {
      return Center(
        child: Text(
          "No weekly data available.",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }
    
    // Parse the report data which might be structured differently based on backend
    List<double> caloriesList = List.filled(7, 0.0);
    List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    try {
      if (reportData.containsKey('report')) {
        var report = reportData['report'];
        if (report is List) {
          // Process array of daily summaries
          for (int i = 0; i < report.length && i < 7; i++) {
            var dayData = report[i];
            var cals = dayData['totals']?['calories'] ?? dayData['calories'] ?? 0;
            caloriesList[i] = (cals is num) ? cals.toDouble() : 0.0;
            
            // Try to set correct day labels if date is provided
            if (dayData['date'] != null) {
               DateTime date = DateTime.parse(dayData['date']);
               days[i] = DateFormat('E').format(date).substring(0, 1);
            }
          }
        } else if (report is Map) {
          // Process map with date keys
          int i = 0;
          for (var entry in report.entries.take(7)) {
            var dayData = entry.value;
            var cals = dayData is Map ? (dayData['calories'] ?? 0) : 0;
            caloriesList[i] = (cals is num) ? cals.toDouble() : 0.0;
            
            DateTime date = DateTime.parse(entry.key);
            days[i] = DateFormat('E').format(date).substring(0, 1);
            i++;
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing weekly report: $e");
    }

    double maxCals = caloriesList.fold(0.0, (m, v) => v > m ? v : m);
    if (maxCals == 0) maxCals = 2000; // Default scale
    maxCals = maxCals * 1.2; // Add headroom

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxCals,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 500 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: List.generate(
          caloriesList.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: caloriesList[index],
                color: index == caloriesList.length - 1 ? const Color(0xFFFE7235) : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxCals,
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBar(bool isDark, String title, String percentage, Color color, double fillFraction) {
    const totalHeight = 180.0;
    // Normalize fill height
    final fillHeight = (totalHeight * fillFraction).clamp(40.0, totalHeight);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 72,
              height: totalHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Container(
              width: 72,
              height: fillHeight,
              decoration: BoxDecoration(
                color: isDark && title == "Fat" ? const Color(0xFF444444) : color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(50),
                    blurRadius: 10, offset: const Offset(0, 5)
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                percentage,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white54 : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
      thickness: 1,
      indent: 24,
      endIndent: 24,
    );
  }

  Widget _legendRow(bool isDark, Color color, String name, String value) {
    Color effectiveColor = (isDark && name == "Fat") ? const Color(0xFF444444) : color;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: effectiveColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
