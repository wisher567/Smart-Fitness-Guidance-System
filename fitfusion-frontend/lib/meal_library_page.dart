import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MealLibraryPage extends StatefulWidget {
  const MealLibraryPage({super.key});

  @override
  State<MealLibraryPage> createState() => _MealLibraryPageState();
}

class _MealLibraryPageState extends State<MealLibraryPage> {
  bool _isLoading = true;
  String _selectedCategory = 'breakfast';
  Map<String, dynamic> _libraryData = {};

  final List<String> _categories = ['breakfast', 'lunch', 'dinner', 'snack'];
  
  List<Map<String, dynamic>> _dates = [];
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _generateDates();
    _fetchLibrary();
  }

  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      // Auto-select today
      if (index == 6) _selectedDate = dateString;
      
      return {
        'day': DateFormat('MMM').format(date),
        'date': DateFormat('dd').format(date),
        'fullDate': dateString,
      };
    });
  }

  Future<void> _fetchLibrary() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.instance.getMealLibrary();
      setState(() {
        if (response.success) {
          _libraryData = response.data?['library'] ?? {};
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load library: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    setState(() => _isLoading = true);
    try {
      // Create a specific delete method or use a generic one if you have it.
      // We need to add deleteMeal to api_service.dart next.
      await ApiService.instance.deleteMeal(mealId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Meal deleted successfully"),
            backgroundColor: primaryColor,
          )
        );
      }
      _fetchLibrary(); // Refresh after delete
    } catch (e) {
      debugPrint('Failed to delete meal: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: $e"),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  // --- Theme Helpers ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA); // Very light gray from UI
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primaryColor => const Color(0xFFFE7235);
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Meals",
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 20),
          _buildCategoryTabs(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _buildMealList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final bool isActive = _selectedDate == date['fullDate'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date['fullDate'];
              });
              // Note: Backend doesn't support grouping library by date yet, 
              // but we show the active selection visually.
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 65,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : (isDark ? const Color(0xFF252525) : const Color(0xFFF1F1F1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date['day'],
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date['date'],
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.map((category) {
          final bool isSelected = _selectedCategory == category;
          // Capitalize first letter
          final String title = category.substring(0, 1).toUpperCase() + category.substring(1);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected && !isDark
                      ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isSelected ? textPrimary : textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealList() {
    final List meals = _libraryData[_selectedCategory] ?? [];
    
    if (meals.isEmpty) {
      return Center(
        child: Text(
          "No meals found for this category.",
          style: GoogleFonts.poppins(color: textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        final nutrition = meal['totalNutrition'] ?? {};
        final double calories = (nutrition['calories'] ?? 0).toDouble();
        final double protein = (nutrition['protein'] ?? 0).toDouble();
        final double fats = (nutrition['fats'] ?? 0).toDouble();
        final double carbs = (nutrition['carbs'] ?? 0).toDouble();
        
        // Try to derive an emoji, default to standard meal
        String emoji = "🍲";
        final String name = meal['name']?.toString().toLowerCase() ?? '';
        if (name.contains('egg')) emoji = "🍳";
        if (name.contains('avocado')) emoji = "🥑";
        if (name.contains('pancake')) emoji = "🥞";
        if (name.contains('pineapple')) emoji = "🍍";
        if (name.contains('salad')) emoji = "🥗";
        if (name.contains('rice')) emoji = "🍚";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0), width: 1.5),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['name'] ?? 'Unknown Meal',
                          style: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text("🔥 ", style: TextStyle(fontSize: 12)),
                            Text(
                              "${calories.round()} kcal",
                              style: GoogleFonts.poppins(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action button (Delete)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE0E0E0)),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: textSecondary, size: 20),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: cardColor,
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteMeal(meal['id'] ?? '');
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Text("Delete Meal", style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nutrition Bars Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNutrientBar("Protein", protein, const Color(0xFF4CAF50), 100),
                  _buildNutrientBar("Fats", fats, const Color(0xFFF44336), 50),
                  _buildNutrientBar("Carbs", carbs, const Color(0xFFFFC107), 150),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildNutrientBar(String label, double value, Color color, double maxVal) {
    final double percent = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        // Vertical Progress Bar
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 4,
              height: 36 * percent,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${value.round()}g",
              style: GoogleFonts.poppins(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
