import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/providers/calorie_provider.dart';
import 'package:fitfusion/services/api_service.dart';

class CalorieGoalsScreen extends StatefulWidget {
  const CalorieGoalsScreen({super.key});

  @override
  State<CalorieGoalsScreen> createState() => _CalorieGoalsScreenState();
}

class _CalorieGoalsScreenState extends State<CalorieGoalsScreen> {
  double _calories = 2000;
  double _proteinPct = 30;
  double _carbsPct = 40;
  double _fatsPct = 30;
  String _preset = 'Custom';
  bool _saving = false;

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
      setState(() {
        _calories = prov.targetCalories.toDouble();
        final p = prov.targetProtein;
        final c = prov.targetCarbs;
        final f = prov.targetFats;
        final total = (p * 4 + c * 4 + f * 9);
        if (total > 0) {
          _proteinPct = ((p * 4 / total) * 100).roundToDouble();
          _carbsPct = ((c * 4 / total) * 100).roundToDouble();
          _fatsPct = (100 - _proteinPct - _carbsPct).roundToDouble();
        }
      });
    });
  }

  void _applyPreset(String name, double p, double c, double f) {
    setState(() {
      _preset = name;
      _proteinPct = p;
      _carbsPct = c;
      _fatsPct = f;
      
      // Auto-update total calories based on selected goal
      if (name == 'Weight Loss') {
        _calories = 1750; // Caloric deficit
      } else if (name == 'Muscle Gain') {
        _calories = 2600; // Caloric surplus 
      } else if (name == 'Maintenance') {
        _calories = 2200; // Maintenance roughly
      }
    });
  }

  int get _proteinG => ((_calories * _proteinPct / 100) / 4).round();
  int get _carbsG => ((_calories * _carbsPct / 100) / 4).round();
  int get _fatsG => ((_calories * _fatsPct / 100) / 9).round();

  void _save() async {
    setState(() => _saving = true);
    
    // Save to the backend
    final response = await ApiService.instance.setCalorieGoals(
      _calories.round(), _proteinG, _carbsG, _fatsG
    );
    
    if (!mounted) return;
    setState(() => _saving = false);

    if (response.success) {
      // Refresh the provider so the dashboard instantly updates if we pop back
      Provider.of<CalorieProvider>(context, listen: false).fetchTodayData(silent: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goals saved! 🎯', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: const Color(0xFF4CAF50), duration: const Duration(seconds: 2)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goals', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

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
          "Calorie Goals",
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),

            // Daily Calorie Target
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                Text('Daily Calorie Target', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(16), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('${_calories.round()}', style: GoogleFonts.poppins(color: primaryColor, fontSize: rFont(48), fontWeight: FontWeight.w900)),
                Text('kcal / day', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(14))),
                Slider(
                  value: _calories, min: 1000, max: 4000, divisions: 60,
                  activeColor: primaryColor,
                  inactiveColor: surfaceColor,
                  onChanged: (v) => setState(() { _calories = v; _preset = 'Custom'; }),
                ),
              ]),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 32),

            // Presets
            Text('Quick Presets', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(16), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _presetButton('Weight Loss', '40/30/30', () => _applyPreset('Weight Loss', 40, 30, 30)),
                const SizedBox(width: 8),
                _presetButton('Muscle Gain', '35/45/20', () => _applyPreset('Muscle Gain', 35, 45, 20)),
                const SizedBox(width: 8),
                _presetButton('Maintenance', '30/40/30', () => _applyPreset('Maintenance', 30, 40, 30)),
                const SizedBox(width: 8),
                _presetButton('Custom', 'Manual', () => setState(() => _preset = 'Custom')),
              ]),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 32),

            // Macro Split
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Macro Split', style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(16), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Must add up to 100%', style: GoogleFonts.poppins(color: textSecondary, fontSize: rFont(12))),
                const SizedBox(height: 16),

                _macroSlider('💪 Protein', _proteinPct, const Color(0xFF2196F3), '${_proteinG}g', (v) {
                  setState(() { _proteinPct = v; _fatsPct = (100 - _proteinPct - _carbsPct).clamp(0, 100); _preset = 'Custom'; });
                }),
                _macroSlider('🌾 Carbs', _carbsPct, const Color(0xFFFFC107), '${_carbsG}g', (v) {
                  setState(() { _carbsPct = v; _fatsPct = (100 - _proteinPct - _carbsPct).clamp(0, 100); _preset = 'Custom'; });
                }),
                _macroSlider('🥑 Fats', _fatsPct, const Color(0xFF9C27B0), '${_fatsG}g', null),

                const SizedBox(height: 16),
                // Pie-like summary
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _macroBadge('P', '${_proteinPct.round()}%', const Color(0xFF2196F3)),
                  _macroBadge('C', '${_carbsPct.round()}%', const Color(0xFFFFC107)),
                  _macroBadge('F', '${_fatsPct.round()}%', const Color(0xFF9C27B0)),
                ]),
              ]),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 40),

            // Save
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Goals', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            )).animate().fadeIn(delay: 400.ms, duration: 300.ms),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _presetButton(String name, String sub, VoidCallback onTap) {
    final selected = _preset == name;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primaryColor : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? primaryColor : borderColor),
          boxShadow: isDark || selected ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Text(name, style: GoogleFonts.poppins(color: selected ? Colors.white : textPrimary, fontWeight: FontWeight.w600, fontSize: rFont(13))),
          Text(sub, style: GoogleFonts.poppins(color: selected ? Colors.white70 : textSecondary, fontSize: rFont(10))),
        ]),
      ),
    );
  }

  Widget _macroSlider(String label, double value, Color color, String grams, ValueChanged<double>? onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(14), fontWeight: FontWeight.w500)),
          Text('${value.round()}%  ($grams)', style: GoogleFonts.poppins(color: color, fontSize: rFont(13), fontWeight: FontWeight.w700)),
        ]),
        if (onChanged != null)
          Slider(
            value: value.clamp(0, 100), min: 0, max: 100, divisions: 20,
            activeColor: color,
            inactiveColor: surfaceColor,
            onChanged: (v) {
              if (v + (label.contains('Protein') ? _carbsPct : _proteinPct) <= 100) onChanged(v);
            },
          )
        else
          Slider(value: value.clamp(0, 100), min: 0, max: 100, activeColor: color, inactiveColor: surfaceColor, onChanged: null),
      ]),
    );
  }

  Widget _macroBadge(String letter, String pct, Color color) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withAlpha(isDark ? 30 : 15),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(letter, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w900, fontSize: rFont(14))),
        Text(pct, style: GoogleFonts.poppins(color: textPrimary, fontSize: rFont(10), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
