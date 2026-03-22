import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fitfusion/meal_library_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/providers/calorie_provider.dart';

enum ScanState { idle, imageSelected, analyzing, resultReady, saving, saved }

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> with TickerProviderStateMixin {
  // --- Dynamic Theme Colors ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;
  Color get cardColor => isDark ? const Color(0xFF1A1A1A) : Colors.white;
  static const Color _brandOrange = Color(0xFFFE7235);
  Color get primaryColor => _brandOrange;
  Color get secondaryColor => isDark ? const Color(0xFFFF6D00) : const Color(0xFFFF5722);
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? const Color(0xFF9E9E9E) : Colors.black54;

  // --- Core State ---
  bool _isManual = false; // Default to AI Scanner now
  ScanState _scanState = ScanState.idle;
  String _selectedMealType = "Dinner";
  
  // --- Manual Form State ---
  double _proteinValue = 15;
  double _carbsValue = 20;
  double _fatValue = 12;
  double _caloriesValue = 250;
  bool _isSavingManual = false;
  final TextEditingController _manualNameController = TextEditingController();

  // --- AI Scanner State ---
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Map<String, dynamic>? _scanResult;
  String? _scannedMealId;
  String _scanError = '';

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut)
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _manualNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _scanState = ScanState.imageSelected;
          _scanResult = null;
          _scannedMealId = null;
          _scanError = '';
        });
      }
    } catch (e) {
      setState(() => _scanError = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _scanState = ScanState.analyzing;
      _scanError = '';
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final response = await ApiService.instance.scanMeal(bytes, _selectedImage!.name, _selectedMealType.toLowerCase());
      
      setState(() {
        if (response.success) {
          _scanResult = response.data?['scanAnalysis'];
          _scannedMealId = response.data?['mealId'] ?? response.data?['id'];
          _scanState = ScanState.resultReady;

          // Trigger progress bar animation securely
          int cals = _scanResult!['totalNutrition']?['calories'] ?? 0;
          double percent = cals / 2000.0;
          if (percent > 1.0) percent = 1.0;

          _progressAnimation = Tween<double>(begin: 0, end: percent).animate(
            CurvedAnimation(parent: _progressController, curve: Curves.easeOut)
          );
          _progressController.forward(from: 0);
        } else {
          _scanState = ScanState.imageSelected;
          _scanError = response.error ?? 'Unknown error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _scanState = ScanState.imageSelected;
        _scanError = 'Failed to analyze image: $e';
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_scanResult == null) return;
    setState(() {
      _scanState = ScanState.saving;
    });

    try {
      // Fake save delay for premium feel, then update CalorieProvider
      await Future.delayed(const Duration(milliseconds: 800));

      if (_scannedMealId != null) {
        await ApiService.instance.logMeal(_scannedMealId!, _selectedMealType.toLowerCase());
      }

      // Update calorie dashboard optimistically
      if (mounted) {
        final n = _scanResult!['totalNutrition'] ?? {};
        final cals = (n['calories'] as num?)?.toInt() ?? 0;
        if (cals > 0) {
          context.read<CalorieProvider>().onMealLogged({
            'calories': cals,
            'protein': n['protein'] ?? 0,
            'carbs': n['carbs'] ?? 0,
            'fats': n['fats'] ?? 0,
            'fiber': n['fiber'] ?? 0,
          });
        }
      }

      setState(() {
        _scanState = ScanState.saved;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardColor,
            duration: const Duration(seconds: 3),
            content: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: primaryColor, width: 4))
              ),
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                "Meal saved! +5 points earned 🎉",
                style: GoogleFonts.poppins(color: textPrimary),
              ),
            ),
          )
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MealLibraryPage()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanState = ScanState.resultReady;
          _scanError = 'Failed to save: $e';
        });
      }
    }
  }

  Future<void> _saveManualMeal() async {
    final name = _manualNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a meal name")));
      return;
    }

    setState(() => _isSavingManual = true);

    try {
      final response = await ApiService.instance.saveCustomMeal(
        name: name,
        category: _selectedMealType,
        calories: _caloriesValue.round(),
        protein: _proteinValue.round(),
        carbs: _carbsValue.round(),
        fats: _fatValue.round(),
      );

      if (mounted) {
        setState(() => _isSavingManual = false);
        if (response.success) {
          final mealId = response.data?['mealId'] ?? response.data?['id'];
          if (mealId != null) {
            await ApiService.instance.logMeal(mealId, _selectedMealType.toLowerCase());
          }
          // Update calorie dashboard optimistically
          context.read<CalorieProvider>().onMealLogged({
             'calories': _caloriesValue.round(),
             'protein': _proteinValue.round(),
             'carbs': _carbsValue.round(),
             'fats': _fatValue.round(),
             'fiber': 0,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: cardColor,
              duration: const Duration(seconds: 3),
              content: Container(
                decoration: BoxDecoration(border: Border(left: BorderSide(color: primaryColor, width: 4))),
                padding: const EdgeInsets.only(left: 12),
                child: Text("Custom Meal saved! 🎉", style: GoogleFonts.poppins(color: textPrimary)),
              ),
            )
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MealLibraryPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? "Failed to save")));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingManual = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            
            // Tab Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isManual = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !_isManual ? primaryColor.withAlpha(38) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "AI Scanner",
                            style: GoogleFonts.poppins(
                              color: !_isManual ? primaryColor : textSecondary,
                              fontSize: 15,
                              fontWeight: !_isManual ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isManual = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isManual ? (isDark ? const Color(0xFF333333) : Colors.grey.shade300) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Manual Entry",
                            style: GoogleFonts.poppins(
                              color: _isManual ? Colors.white : textSecondary,
                              fontSize: 15,
                              fontWeight: _isManual ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isManual) 
              _buildManualForm()
            else 
              _buildAiScanner(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // AI SCANNER UI METHODS
  // ---------------------------------------------------------

  Widget _buildAiScanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealTypeSelector(),
          const SizedBox(height: 24),
          
          _buildImageArea(),
          const SizedBox(height: 24),

          if (_scanError.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_scanError, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13)),
            ),

          if (_scanState == ScanState.analyzing)
            _buildAnalyzingState()
          else if (_scanState == ScanState.resultReady || _scanState == ScanState.saving || _scanState == ScanState.saved)
            _buildAnalysisCard(),

          if (_scanState == ScanState.idle)
            _buildEmptyTips(),

          if (_scanState == ScanState.resultReady || _scanState == ScanState.saving || _scanState == ScanState.saved)
            _buildSaveButton()
          else if (_scanState == ScanState.imageSelected)
            _buildAnalyzeButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
            ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
            : [_brandOrange, const Color(0xFFFF8C5A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                "Scan Your Meal",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "AI-powered nutrition analysis",
            style: GoogleFonts.poppins(color: Colors.white.withAlpha(204), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final types = [
      {'label': 'Breakfast', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber},
      {'label': 'Lunch', 'icon': Icons.wb_cloudy_rounded, 'color': Colors.blue},
      {'label': 'Dinner', 'icon': Icons.nights_stay_rounded, 'color': Colors.purple},
      {'label': 'Snack', 'icon': Icons.apple_rounded, 'color': secondaryColor},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedMealType == type['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedMealType = type['label'] as String),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withAlpha(38) : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF333333) : Colors.grey.shade300),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(type['icon'] as IconData, size: 18, color: isSelected ? type['color'] as Color : textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      type['label'] as String,
                      style: GoogleFonts.poppins(
                        color: isSelected ? primaryColor : textSecondary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_selectedImage == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? const Color(0xFF333333) : Colors.grey.shade300), width: 2), // Standard border as fallback for dashed
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 48, color: primaryColor)
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(begin: 1.0, end: 1.05, duration: const Duration(seconds: 1), curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.05, end: 1.0, duration: const Duration(seconds: 1), curve: Curves.easeInOut),
            const SizedBox(height: 12),
            Text("Tap to take photo", style: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            Text("or choose from gallery", style: GoogleFonts.poppins(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOutlinedButton("Camera", Icons.camera_alt_rounded, () => _pickImage(ImageSource.camera)),
                const SizedBox(width: 12),
                _buildOutlinedButton("Gallery", Icons.photo_library_rounded, () => _pickImage(ImageSource.gallery)),
              ],
            )
          ],
        ),
      );
    }

    // Image Selected State
    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: kIsWeb
                ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
          ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(204)],
              ),
            ),
          ),
        ),
        // Active Badge
        Positioned(
          bottom: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor),
            ),
            child: Text(_selectedMealType, style: GoogleFonts.poppins(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        // Retake Button
        Positioned(
          top: 12, right: 12,
          child: InkWell(
            onTap: () => setState(() {
              _selectedImage = null;
              _scanState = ScanState.idle;
            }),
            child: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(128),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildOutlinedButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withAlpha(128)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTips() {
    final tips = [
      {"icon": "🍛", "title": "Sri Lankan Food", "desc": "We recognize rice, curry & hoppers"},
      {"icon": "📸", "title": "Best Results", "desc": "Good lighting = accurate analysis"},
      {"icon": "⚡", "title": "Instant", "desc": "Results in under 3 seconds"}
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tips.map((t) => Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(t['title']!, style: GoogleFonts.poppins(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(t['desc']!, style: GoogleFonts.poppins(color: textSecondary, fontSize: 12), maxLines: 2),
            ],
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAnalyzingState() {
    return Shimmer.fromColors(
      baseColor: cardColor,
      highlightColor: (isDark ? const Color(0xFF252525) : Colors.grey.shade100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Analyzing your meal", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                AnimatedTextKit(
                  animatedTexts: [TyperAnimatedText('...', textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 16), speed: const Duration(milliseconds: 300))],
                  repeatForever: true,
                )
              ],
            ),
            const SizedBox(height: 8),
            Text("Powered by Groq AI", style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    if (_scanResult == null) return const SizedBox.shrink();

    final nutrition = _scanResult!['totalNutrition'] ?? {};
    // Safely parse score — AI may return 0-10 or 0-100 scale
    final rawScore = (_scanResult!['healthScore'] ?? 5);
    final double scoreNum = (rawScore is num) ? rawScore.toDouble() : double.tryParse(rawScore.toString()) ?? 5.0;
    // Normalize: if AI returned on 0-100 scale, convert to 0-10
    final double scoreOf10 = scoreNum > 10 ? scoreNum / 10.0 : scoreNum;
    final double safePercent = (scoreOf10 / 10.0).clamp(0.0, 1.0);
    final int displayScore = scoreOf10.round().clamp(0, 10);
    final String mealName = _scanResult!['mealName'] ?? "Scanned Meal";
    final String tip = _scanResult!['suggestions'] ?? "Enjoy your meal!";
    final List tags = _scanResult!['tags'] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 400, // Ensuring it stretches
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor.withAlpha(38),
                        radius: 20,
                        child: Icon(Icons.check_circle_rounded, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mealName, style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: primaryColor.withAlpha(51), borderRadius: BorderRadius.circular(4)),
                              child: Text("High Confidence", style: GoogleFonts.poppins(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 20.0,
                        lineWidth: 4.0,
                        percent: safePercent,
                        center: Text("$displayScore", style: GoogleFonts.poppins(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        progressColor: primaryColor,
                        backgroundColor: (isDark ? const Color(0xFF333333) : Colors.grey.shade300),
                      )
                    ],
                  ),
                  
                  Container(height: 1, color: (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200), margin: const EdgeInsets.symmetric(vertical: 16)),

                  // Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      _buildNutrientTile("Calories", "${nutrition['calories']}", "kcal", Icons.local_fire_department_rounded, secondaryColor),
                      _buildNutrientTile("Protein", "${nutrition['protein']}", "g", Icons.fitness_center_rounded, const Color(0xFF2196F3)),
                      _buildNutrientTile("Carbs", "${nutrition['carbs']}", "g", Icons.grain_rounded, const Color(0xFFFFC107)),
                      _buildNutrientTile("Fats", "${nutrition['fats']}", "g", Icons.opacity_rounded, const Color(0xFF9C27B0)),
                    ]
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Daily Calories", style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
                      Text("${nutrition['calories']} / 2000 kcal", style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: (isDark ? const Color(0xFF252525) : Colors.grey.shade100),
                        valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      );
                    }
                  ),

                  const SizedBox(height: 20),
                  
                  // AI Tip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF252525) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(left: BorderSide(color: Color(0xFFFFC107), width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 8),
                            Text("AI Insight", style: GoogleFonts.poppins(color: const Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(tip, style: GoogleFonts.poppins(color: textPrimary, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  if (tags.isNotEmpty) SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags.map((tag) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF252525) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (isDark ? const Color(0xFF333333) : Colors.grey.shade300)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: primaryColor, size: 8),
                            const SizedBox(width: 6),
                            Text(tag.toString(), style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNutrientTile(String label, String value, String unit, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF252525) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: GoogleFonts.poppins(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 2),
                    Text(unit, style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
                  ],
                ),
                Text(label, style: GoogleFonts.poppins(color: textSecondary, fontSize: 12)),
              ],
            ),
          )
        ],
      )
    ).animate().scaleXY(begin: 0.9, end: 1.0, duration: const Duration(milliseconds: 300)).fadeIn();
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _analyzeImage,
        child: Text("Analyze Image", style: GoogleFonts.poppins(color: bgColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isSaving = _scanState == ScanState.saving;
    final isSaved = _scanState == ScanState.saved;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFF00BFA5)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: (isSaving || isSaved) ? null : _saveMeal,
        child: isSaving
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isSaved ? "Saved to Library!" : "Save Meal to Library", 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .shimmer(duration: const Duration(seconds: 2), color: Colors.white.withAlpha(51));
  }

  // ---------------------------------------------------------
  // MANUAL FORM UI (Legacy - styled dark)
  // ---------------------------------------------------------

  Widget _buildManualForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Meal Name", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _manualNameController,
              style: GoogleFonts.poppins(color: textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.restaurant, color: isDark ? Colors.white54 : Colors.black54),
                hintText: "Enter your meal name...",
                hintStyle: GoogleFonts.poppins(color: textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMealTypeSelector(), // Add category selection here too
          const SizedBox(height: 24),
          _buildSliderSection("Total Calories", _caloriesValue, (val) => setState(() => _caloriesValue = val), max: 2000, suffix: "kcal"),
          const SizedBox(height: 16),
          _buildSliderSection("Total Protein", _proteinValue, (val) => setState(() => _proteinValue = val)),
          const SizedBox(height: 16),
          _buildSliderSection("Total Carbs", _carbsValue, (val) => setState(() => _carbsValue = val)),
          const SizedBox(height: 16),
          _buildSliderSection("Total Fat", _fatValue, (val) => setState(() => _fatValue = val)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isSavingManual ? null : _saveManualMeal,
              child: _isSavingManual 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("Save Custom Meal", style: GoogleFonts.poppins(color: bgColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(String title, double value, ValueChanged<double> onChanged, {double max = 100, String suffix = "g"}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            Text("${value.round()}$suffix", style: GoogleFonts.poppins(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: primaryColor,
            inactiveTrackColor: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
            thumbColor: primaryColor,
          ),
          child: Slider(value: value, min: 0, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
