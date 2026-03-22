import 'package:flutter/material.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'workout_library_page.dart';
import 'nutrition_start_page.dart';
import 'ai_coach_page.dart';
import 'activity_status_page.dart';
import 'settings_page.dart';
import 'package:fitfusion/leaderboard_page.dart';
import 'package:fitfusion/screens/hydration/hydration_screen.dart';
import 'package:fitfusion/screens/calories/calorie_dashboard_screen.dart';
import 'package:fitfusion/add_meal_page.dart';
import 'package:fitfusion/screens/posture/posture_detection_screen.dart';
import 'package:fitfusion/screens/equipment/report_equipment_screen.dart';
import 'package:fitfusion/screens/classes/classes_screen.dart';
import 'package:fitfusion/screens/trainer/request_trainer_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'User';
  int _points = 0;
  bool _isLoading = true;
  String? _photoUrl;
  
  // Search State
  List<dynamic> _allMeals = [];
  List<dynamic> _filteredMeals = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchLibrary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLibrary() async {
    try {
      final response = await ApiService.instance.getMealLibrary();
      if (mounted && response.success) {
        final library = response.data?['library'] as Map<String, dynamic>? ?? {};
        setState(() {
          _allMeals = [];
          library.forEach((category, meals) {
            if (meals is List) {
              _allMeals.addAll(meals);
            }
          });
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch library for search: $e");
    }
  }

  void _filterMeals(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMeals = []);
      return;
    }
    
    final q = query.toLowerCase();
    setState(() {
      _filteredMeals = _allMeals.where((meal) {
        final name = (meal['name'] ?? '').toString().toLowerCase();
        final category = (meal['category'] ?? '').toString().toLowerCase();
        final tags = (meal['tags'] as List<dynamic>? ?? []);
        final tagMatch = tags.any((tag) => tag.toString().toLowerCase().contains(q));
        
        return name.contains(q) || category.contains(q) || tagMatch;
      }).toList();
      
      // Sort: favorites first, then by timesEaten
      _filteredMeals.sort((a, b) {
        final favA = a['isFavorite'] == true;
        final favB = b['isFavorite'] == true;
        if (favA && !favB) return -1;
        if (!favA && favB) return 1;
        final timesEatenA = (a['timesEaten'] ?? 0) as int;
        final timesEatenB = (b['timesEaten'] ?? 0) as int;
        return timesEatenB.compareTo(timesEatenA);
      });
    });
  }

  Future<void> _logMeal(dynamic meal) async {
    final mealId = meal['id']?.toString() ?? '';
    final category = meal['category']?.toString() ?? 'snack';
    
    if (mealId.isEmpty) return;
    
    final response = await ApiService.instance.logMeal(mealId, category);
    
    if (response.success && mounted) {
      _searchController.clear();
      setState(() {
        _isSearching = false;
        _filteredMeals = [];
      });
      FocusScope.of(context).unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('${meal['name'] ?? 'Meal'} added to today\'s log!'),
          ]),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? "Failed to log meal")),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast': return const Color(0xFFFFC107);
      case 'lunch':     return const Color(0xFF4CAF50);
      case 'dinner':    return const Color(0xFF2196F3);
      case 'snack':     return const Color(0xFFE07B54);
      default:          return const Color(0xFF9C27B0);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast': return Icons.wb_sunny_rounded;
      case 'lunch':     return Icons.wb_cloudy_rounded;
      case 'dinner':    return Icons.nights_stay_rounded;
      case 'snack':     return Icons.apple_rounded;
      default:          return Icons.restaurant_rounded;
    }
  }

  TextSpan _highlightMatch(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14));
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) {
      return TextSpan(text: text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14));
    }
    return TextSpan(children: [
      TextSpan(text: text.substring(0, index), style: const TextStyle(color: Colors.black87, fontSize: 14)),
      TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: const Color(0xFFE07B54), 
          fontWeight: FontWeight.bold, 
          fontSize: 14,
          backgroundColor: const Color(0xFFE07B54).withAlpha(25)
        )
      ),
      TextSpan(text: text.substring(index + query.length), style: const TextStyle(color: Colors.black87, fontSize: 14)),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.instance.getUserProfile();
      if (mounted && response.success) {
        setState(() {
          _userName = response.data?['user']['name'] ?? 'User';
          _points = response.data?['user']['points'] ?? 0;
          _photoUrl = response.data?['user']['photoUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFE7235))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildDashboardCard(),
              const SizedBox(height: 25),
              _buildSearchBar(),
              if (_isSearching) _buildSearchResults() else ...[
                const SizedBox(height: 30),
                _sectionTitle("Browse Category"),
                const SizedBox(height: 16),
                _buildCategories(),
                const SizedBox(height: 30),
                _sectionTitle("Workout"),
                _imageCard(
                  "assets/images/workout_bg.png",
                  "Upper Strength 2",
                  "8 Series Workout",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WorkoutLibraryPage()),
                    );
                    if (mounted) _loadProfile();
                  },
                ),
                const SizedBox(height: 20),
                _sectionTitle("Diet & Nutrition"),
                _dietCard(context),
                const SizedBox(height: 20),
                _sectionTitle("Activities"),
                _activityCard(context),
                const SizedBox(height: 20),
                _sectionTitle("AI Coach"),
                _imageCard(
                  "assets/images/aicoach_bg.png",
                  "1,879+ AI Conversation",
                  "Personalized fitness guidance",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiCoachPage()),
                    );
                    if (mounted) _loadProfile();
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getAvatarImage() {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('http')) {
        return NetworkImage(_photoUrl!);
      } else {
        return AssetImage(_photoUrl!);
      }
    }
    return const AssetImage("assets/images/profile_new.png");
  }

  // ================= Widgets =================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                  if (result == true && mounted) {
                    _loadProfile();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFE7235).withAlpha(77),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    backgroundImage: _getAvatarImage(),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              if (result == true && mounted) {
                _loadProfile();
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildDashboardCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFE7235), Color(0xFFFF966B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFE7235).withAlpha(77),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Progress",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$_points",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "pts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Active",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // White overlay pattern
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
          ],
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: _searchController,
          onTap: () {
            setState(() => _isSearching = true);
          },
          onChanged: (query) => _filterMeals(query),
          decoration: InputDecoration(
            hintText: 'Search your saved meals...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: _isSearching 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _filteredMeals = [];
                    });
                    FocusScope.of(context).unfocus();
                  },
                )
              : const Icon(Icons.tune_rounded, color: Color(0xFFE07B54)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text.trim();
    
    if (query.isNotEmpty && _filteredMeals.isEmpty) {
      return Column(children: [
        _buildBackButton(),
        const SizedBox(height: 20),
        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('No meals found for "$query"', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Try scanning a new meal or add it manually', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMealPage()));
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 16),
            label: const Text('Scan Meal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE07B54),
              side: const BorderSide(color: Color(0xFFE07B54)),
            ),
          ),
        ])
      ]);
    }

    final mealsToShow = query.isEmpty 
        ? (_allMeals.toList()..sort((a,b) => ((b['timesEaten'] ?? 0) as int).compareTo((a['timesEaten'] ?? 0) as int))).take(5).toList()
        : _filteredMeals;

    if (query.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text('Recently Eaten', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...mealsToShow.map((meal) => _buildMealResultItem(meal)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...mealsToShow.map((meal) => _buildMealResultItem(meal)),
      ],
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 16),
      child: TextButton.icon(
        onPressed: () {
          _searchController.clear();
          setState(() {
            _isSearching = false;
            _filteredMeals = [];
          });
          FocusScope.of(context).unfocus();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey, size: 20),
        label: const Text('Back', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMealResultItem(dynamic meal) {
    final category = meal['category']?.toString() ?? 'snack';
    final name = meal['name']?.toString() ?? 'Meal';
    final nutrition = meal['totalNutrition'] ?? {};
    final isFav = meal['isFavorite'] == true;
    final query = _searchController.text.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          // Left: category icon in colored circle
          CircleAvatar(
            radius: 22,
            backgroundColor: _getCategoryColor(category).withAlpha(38),
            child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 20),
          ),
          const SizedBox(width: 12),
          
          // Middle: meal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: _highlightMatch(name, query)),
                const SizedBox(height: 6),
                Row(children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFF6D00).withAlpha(25), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6D00), size: 12),
                        const SizedBox(width: 4),
                        Text('${nutrition['calories'] ?? 0} kcal', style: const TextStyle(color: Color(0xFFFF6D00), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2196F3).withAlpha(25), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: Color(0xFF2196F3), size: 12),
                        const SizedBox(width: 4),
                        Text('${nutrition['protein'] ?? 0}g protein', style: const TextStyle(color: Color(0xFF2196F3), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          
          // Right: favorite icon + log button
          Column(
            children: [
              if (isFav) const Icon(Icons.bookmark_rounded, color: Color(0xFFE07B54), size: 16),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _logMeal(meal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE07B54), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFE7235),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              "See All",
              style: TextStyle(
                color: Color(0xFFFE7235),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final cats = [
      {'label': 'Hydration', 'icon': Icons.water_drop, 'page': const HydrationScreen()},
      {'label': 'Leaderboard', 'icon': Icons.workspace_premium, 'page': const LeaderboardPage()},
      {'label': 'Calorie', 'icon': Icons.local_fire_department, 'page': const CalorieDashboardScreen()},
      {'label': 'Classes', 'icon': Icons.calendar_today_rounded, 'page': const ClassesScreen()},
      {'label': 'Get Trainer', 'icon': Icons.person_search_rounded, 'page': const RequestTrainerScreen()},
      {'label': 'Posture', 'icon': Icons.accessibility_new_rounded, 'page': const PostureDetectionScreen()},
      {'label': 'Workouts', 'icon': Icons.fitness_center, 'page': const WorkoutLibraryPage()},
      {'label': 'Report Issue', 'icon': Icons.report_problem_rounded, 'page': const ReportEquipmentScreen()},
      {'label': 'Nutrition', 'icon': Icons.restaurant, 'page': const NutritionStartPage()},
      {'label': 'Food Scan', 'icon': Icons.camera_alt, 'page': const AddMealPage()},
    ];

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: cats.asMap().entries.map((entry) {
            final cat = entry.value;
            final isFirst = entry.key == 0;
            return Padding(
              padding: EdgeInsets.only(right: entry.key < cats.length - 1 ? 12 : 0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => cat['page'] as Widget)),
                child: _categoryButton(
                  cat['label'] as String,
                  isFirst ? const Color(0xFFFE7235) : Colors.white,
                  isFirst,
                  icon: cat['icon'] as IconData,
                  iconColor: isFirst ? Colors.white : const Color(0xFFFE7235),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _categoryButton(
    String text,
    Color color,
    bool active, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withAlpha(102),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard(
    String image,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(217),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Play button overlay
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withAlpha(51),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.97, 0.97), end: const Offset(1.0, 1.0));
  }

  Widget _dietCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NutritionStartPage()),
        );
        if (mounted) _loadProfile();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                bottom: -20,
                width: 220,
                child: Image.asset(
                  "assets/images/diet_bg.png",
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay on right side
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha(77),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _nutritionPill("25g", "Protein"),
                        const SizedBox(width: 10),
                        _nutritionPill("16g", "Fats"),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      "Salad & Egg",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Color(0xFFFE7235),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "548 kcal",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.timer_outlined, size: 16, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        const Text(
                          "20 min",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon at bottom right
              const Positioned(
                bottom: 20,
                right: 20,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFE7235),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionPill(String amount, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityStatusPage()),
        );
        if (mounted) _loadProfile();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                left: 30,
                top: 30,
                child: Transform.rotate(
                  angle: -0.5,
                  child: _pillBadge("1h", const Color(0xffFF7029), textColor: Colors.white),
                ),
              ),
              Positioned(
                right: 40,
                top: 40,
                child: Transform.rotate(
                  angle: 0.2,
                  child: _pillBadge("15h", const Color(0xff2962FF), textColor: Colors.white),
                ),
              ),
              Positioned(
                left: 40,
                bottom: 30,
                child: Transform.rotate(
                  angle: 0.3,
                  child: _pillBadge("7h", const Color(0xffFF3B30), textColor: Colors.white),
                ),
              ),
              Positioned(
                right: 35,
                bottom: 40,
                child: Transform.rotate(
                  angle: -0.4,
                  child: const Text(
                    "87h",
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xff1A1A1A),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        "68h",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This week",
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _pillBadge(String label, Color color, {required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
