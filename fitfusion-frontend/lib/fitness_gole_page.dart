import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/services/auth_service.dart';
import 'assessment_avatar_page.dart';
import 'home_page.dart';

class FitnessGolePage extends StatefulWidget {
  final int age;
  final double weight;
  final String fitnessLevel;
  final String gender;
  const FitnessGolePage({
    super.key,
    required this.age,
    required this.weight,
    required this.fitnessLevel,
    required this.gender,
  });

  @override
  State<FitnessGolePage> createState() => _FitnessGolePageState();
}

class _FitnessGolePageState extends State<FitnessGolePage> {
  int selectedIndex = 1; // Default selected: AI Coach
  bool _isLoading = false;

  final List<Map<String, dynamic>> options = [
    {"title": "I wanna lose weight", "icon": Icons.monitor_weight_outlined, "value": "weight_loss"},
    {"title": "I wanna try AI Coach", "icon": Icons.smart_toy_outlined, "value": "general"},
    {"title": "I wanna get bulks", "icon": Icons.fitness_center, "value": "muscle_gain"},
    {"title": "I wanna gain endurance", "icon": Icons.show_chart, "value": "endurance"},
    {"title": "Just trying out the app! 👍", "icon": Icons.phone_iphone, "value": "general"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              /// Top Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "5 of 6",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// Title
              const Text(
                "Assessment",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              const Text(
                "What’s your fitness\ngoal/target?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              /// Options
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              options[index]["icon"],
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                options[index]["title"],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// Continue Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfileAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileAndContinue() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userName = auth.currentUser?.displayName ?? 
                       auth.currentUser?.email?.split('@')[0] ?? 'User';

      await ApiService.instance.saveUserProfile(
        name: userName,
        age: widget.age,
        weight: widget.weight,
        height: 170.0, // Hardcoded or default for now
        fitnessGoal: options[selectedIndex]['value'],
        fitnessLevel: widget.fitnessLevel,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AssessmentAvatarPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        // If saving fails, still navigate but show a warning
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved locally. Will sync later.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
