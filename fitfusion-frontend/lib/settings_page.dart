import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/providers/theme_provider.dart';
import 'package:fitfusion/services/auth_service.dart';
import 'package:fitfusion/welcome_screen.dart';
import 'package:fitfusion/screens/subscription/my_subscription_screen.dart';
import 'package:fitfusion/screens/subscription/payment_history_screen.dart';
import 'package:fitfusion/screens/subscription/plans_screen.dart';
import 'package:fitfusion/screens/support/contact_admin_screen.dart';
import 'package:fitfusion/screens/subscription/manage_cards_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String _selectedGoal = 'weight_loss';
  String _selectedLevel = 'beginner';
  String? _photoUrl;
  Uint8List? _selectedImageBytes;
  bool _removePhotoOnSave = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.instance.getUserProfile();
      if (mounted && response.success) {
        final u = response.data?['user'];
        setState(() {
          _nameController.text = u['name']?.toString() ?? '';
          _phoneController.text = u['phone']?.toString() ?? '';
          _ageController.text = u['age']?.toString() ?? '';
          _weightController.text = u['weight']?.toString() ?? '';
          _heightController.text = u['height']?.toString() ?? '';
          String goal = u['fitnessGoal']?.toString() ?? 'weight_loss';
          if (!['weight_loss', 'muscle_gain', 'endurance', 'general'].contains(goal)) {
             goal = 'weight_loss';
          }
          _selectedGoal = goal;

          String level = u['fitnessLevel']?.toString() ?? 'Beginner';
          if (!['Beginner', 'Intermediate', 'Somewhat Active', 'Advanced', 'Athlete'].contains(level)) {
             level = 'Beginner';
          }
          _selectedLevel = level;
          _photoUrl = u['photoUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.saveUserProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 25,
        weight: double.tryParse(_weightController.text) ?? 70.0,
        height: double.tryParse(_heightController.text) ?? 170.0,
        fitnessGoal: _selectedGoal,
        fitnessLevel: _selectedLevel,
        phone: _phoneController.text.trim(),
      );
      
      if (_removePhotoOnSave) {
        await ApiService.instance.updateAvatarUrl(''); // Empty string tells backend to remove it
      } else if (_selectedImageBytes != null) {
        await ApiService.instance.uploadAvatarBytes(_selectedImageBytes!, 'avatar.jpg');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to signal a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on Theme Mode (Light vs Dark)
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final primaryOrange = const Color(0xFFFE7235);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   _buildAvatarSection(primaryOrange, cardColor),
                   const SizedBox(height: 24),
                  // --- Theme Toggle Card ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primaryOrange, size: 28),
                            const SizedBox(width: 15),
                            Text(
                              isDark ? "Dark Mode" : "Light Mode",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                            ),
                          ],
                        ),
                        Switch(
                          value: isDark,
                          activeThumbColor: primaryOrange,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text("Profile Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),

                  // --- Profile Inputs ---
                  _buildInput("Full Name", _nameController, hintColor, cardColor, textColor),
                  _buildInput("Phone Number", _phoneController, hintColor, cardColor, textColor, isNumber: true),
                  _buildInput("Age", _ageController, hintColor, cardColor, textColor, isNumber: true),
                  Row(
                    children: [
                      Expanded(child: _buildInput("Weight (kg)", _weightController, hintColor, cardColor, textColor, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInput("Height (cm)", _heightController, hintColor, cardColor, textColor, isNumber: true)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text("Fitness Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    label: "Fitness Goal",
                    value: _selectedGoal,
                    items: const [
                      DropdownMenuItem(value: 'weight_loss', child: Text('Weight Loss')),
                      DropdownMenuItem(value: 'muscle_gain', child: Text('Muscle Gain')),
                      DropdownMenuItem(value: 'endurance', child: Text('Endurance')),
                      DropdownMenuItem(value: 'general', child: Text('General / AI Coach')),
                    ],
                    onChanged: (val) => setState(() => _selectedGoal = val.toString()),
                    cardColor: cardColor,
                    hintColor: hintColor,
                    textColor: textColor,
                  ),

                  _buildDropdown(
                    label: "Fitness Level",
                    value: _selectedLevel,
                    items: const [
                      DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'Somewhat Active', child: Text('Somewhat Active')),
                      DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                      DropdownMenuItem(value: 'Athlete', child: Text('Athlete')),
                    ],
                    onChanged: (val) => setState(() => _selectedLevel = val.toString()),
                    cardColor: cardColor,
                    hintColor: hintColor,
                    textColor: textColor,
                  ),

                  const SizedBox(height: 30),

                  // --- Subscription & Payments Section ---
                  Align(alignment: Alignment.centerLeft,
                    child: Text("Subscription & Payments",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSubscriptionTile(
                          icon: Icons.card_membership_rounded,
                          label: 'My Subscription',
                          subtitle: 'View your active plan',
                          primaryOrange: primaryOrange,
                          textColor: textColor,
                          hintColor: hintColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySubscriptionScreen())),
                        ),
                        Divider(height: 1, indent: 56, color: hintColor.withOpacity(0.2)),
                        _buildSubscriptionTile(
                          icon: Icons.upgrade_rounded,
                          label: 'Upgrade Plan',
                          subtitle: 'Browse membership plans',
                          primaryOrange: primaryOrange,
                          textColor: textColor,
                          hintColor: hintColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen())),
                        ),
                        Divider(height: 1, indent: 56, color: hintColor.withOpacity(0.2)),
                        _buildSubscriptionTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Payment History',
                          subtitle: 'View past transactions',
                          primaryOrange: primaryOrange,
                          textColor: textColor,
                          hintColor: hintColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
                        ),
                        Divider(height: 1, indent: 56, color: hintColor.withOpacity(0.2)),
                        _buildSubscriptionTile(
                          icon: Icons.credit_card_rounded,
                          label: 'Manage Cards',
                          subtitle: 'Add & remove saved cards',
                          primaryOrange: primaryOrange,
                          textColor: textColor,
                          hintColor: hintColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCardsScreen())),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- Support Section ---
                  Align(alignment: Alignment.centerLeft,
                    child: Text("Support",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ContactAdminScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8845C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.support_agent_rounded,
                            color: Color(0xFFE8845C), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact Admin',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 14)),
                            Text('Get help from our support team',
                              style: TextStyle(color: Color(0xFF9E9E9E),
                                fontSize: 12)),
                          ],
                        )),
                        const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF9E9E9E)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cardColor,
                            title: Text('Sign Out', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to sign out?', style: TextStyle(color: hintColor)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _signOut();
                                },
                                child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text("Sign Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // --- Avatar Section UI & Logic ---
  Widget _buildAvatarSection(Color primaryOrange, Color cardColor) {
    return Center(
      child: GestureDetector(
        onTap: () => _showAvatarOptions(primaryOrange, cardColor),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardColor,
                image: _getDecorationImage(),
                border: Border.all(color: primaryOrange, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: (_selectedImageBytes == null && (_photoUrl == null || _photoUrl!.isEmpty)) 
                  ? Icon(Icons.person, size: 50, color: primaryOrange) 
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getDecorationImage() {
    if (_selectedImageBytes != null) {
      return DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('http')) {
        return DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover);
      } else {
        return DecorationImage(image: AssetImage(_photoUrl!), fit: BoxFit.cover);
      }
    }
    return null;
  }

  void _showAvatarOptions(Color primaryOrange, Color cardColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Upload Photo', style: TextStyle(color: textColor)),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _selectedImageBytes = bytes;
                      _removePhotoOnSave = false;
                    });
                  }
                },
              ),
              if (_selectedImageBytes != null || (_photoUrl != null && _photoUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImageBytes = null;
                      _photoUrl = null;
                      _removePhotoOnSave = true;
                    });
                  },
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInput(String label, TextEditingController controller, Color hintColor, Color cardColor, Color textColor, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required Color cardColor,
    required Color hintColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color primaryOrange,
    required Color textColor,
    required Color hintColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
            Text(subtitle, style: TextStyle(color: hintColor, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: hintColor, size: 20),
        ]),
      ),
    );
  }
}
