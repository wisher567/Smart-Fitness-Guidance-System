import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'my_complaints_screen.dart';

class ReportEquipmentScreen extends StatefulWidget {
  const ReportEquipmentScreen({super.key});
  @override
  State<ReportEquipmentScreen> createState() => _ReportEquipmentScreenState();
}

class _ReportEquipmentScreenState extends State<ReportEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String selectedEquipment = '';
  String customEquipment = '';
  String issue = '';
  String description = '';
  String urgency = 'medium';
  String location = '';
  File? selectedImage;
  bool isSubmitting = false;
  bool isSubmitted = false;

  // Common gym equipment list
  final List<String> equipmentList = [
    'Treadmill',
    'Elliptical Machine',
    'Stationary Bike',
    'Rowing Machine',
    'Pull-up Bar',
    'Squat Rack',
    'Bench Press',
    'Leg Press Machine',
    'Cable Machine',
    'Dumbbell Rack',
    'Barbell',
    'Resistance Bands',
    'Weight Plates',
    'Foam Roller',
    'Boxing Bag',
    'Battle Ropes',
    'Kettlebells',
    'Shower/Changing Room',
    'Locker',
    'Air Conditioning',
    'Other (specify below)',
  ];

  final List<Map<String, dynamic>> urgencyLevels = [
    {
      'value': 'low',
      'label': 'Low',
      'desc': 'Minor issue, not urgent',
      'color': const Color(0xFFF59E0B),
      'icon': Icons.info_outline_rounded,
    },
    {
      'value': 'medium',
      'label': 'Medium',
      'desc': 'Needs attention soon',
      'color': const Color(0xFFE8845C),
      'icon': Icons.warning_amber_rounded,
    },
    {
      'value': 'high',
      'label': 'High',
      'desc': 'Safety concern, urgent!',
      'color': const Color(0xFFEF4444),
      'icon': Icons.error_outline_rounded,
    },
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera, // or gallery
      maxWidth: 800,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String?> _imageToBase64() async {
    if (selectedImage == null) return null;
    final bytes = await selectedImage!.readAsBytes();
    if (bytes.length > 500000) return null; // skip if > 500KB
    return base64Encode(bytes);
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select equipment'),
        backgroundColor: const Color(0xFFEF4444),
      ));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final imageBase64 = await _imageToBase64();
      final equipmentName = selectedEquipment == 'Other (specify below)'
          ? customEquipment
          : selectedEquipment;

      final res = await ApiService.instance.submitEquipmentAlert({
        'equipment':   equipmentName,
        'issue':       issue,
        'description': description,
        'urgency':     urgency,
        'location':    location,
        'imageBase64': imageBase64,
      });

      if (res.success) {
        setState(() {
          isSubmitting = false;
          isSubmitted = true;
        });
      } else {
        throw Exception(res.error ?? 'Unknown error');
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSubmitted) return _buildSuccessScreen();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report Equipment Issue',
          style: TextStyle(color: Color(0xFF1A1A1A), 
            fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: const Divider(color: Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8845C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8845C).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, 
                    color: Color(0xFFE8845C), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your complaint will be sent directly to our admin team. '
                      'We aim to resolve issues within 24 hours.',
                      style: TextStyle(color: Color(0xFFD4673A), 
                        fontSize: 12, height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // SECTION: Select Equipment
              _buildSectionTitle('Select Equipment', Icons.fitness_center_rounded),
              const SizedBox(height: 10),
              
              // Equipment grid chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: equipmentList.map((equipment) {
                  final isSelected = selectedEquipment == equipment;
                  return GestureDetector(
                    onTap: () => setState(() => selectedEquipment = equipment),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFFE8845C) 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                            ? const Color(0xFFE8845C) 
                            : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(
                          color: const Color(0xFFE8845C).withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 2),
                        )] : [],
                      ),
                      child: Text(
                        equipment,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                          fontSize: 12,
                          fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Custom equipment input (show when Other selected)
              if (selectedEquipment == 'Other (specify below)') ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Equipment Name',
                    hintText: 'e.g. Smith Machine',
                    prefixIcon: const Icon(Icons.edit_rounded, 
                      color: Color(0xFFE8845C), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE8845C), width: 2)),
                  ),
                  onChanged: (v) => customEquipment = v,
                  validator: (v) => v!.isEmpty 
                    ? 'Please specify equipment name' : null,
                ),
              ],

              const SizedBox(height: 20),

              // SECTION: Issue Description
              _buildSectionTitle('Describe the Issue', Icons.report_problem_rounded),
              const SizedBox(height: 10),

              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g. Belt is slipping and making noise',
                  prefixIcon: const Icon(Icons.short_text_rounded,
                    color: Color(0xFFE8845C), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8845C), width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => issue = v,
                validator: (v) => v!.isEmpty 
                  ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8845C), width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => description = v,
              ),

              const SizedBox(height: 20),

              // SECTION: Urgency Level
              _buildSectionTitle('Urgency Level', Icons.priority_high_rounded),
              const SizedBox(height: 10),

              Row(children: urgencyLevels.map((level) {
                final isSelected = urgency == level['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => urgency = level['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: level['value'] != 'high' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? (level['color'] as Color).withOpacity(0.12)
                          : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected 
                            ? level['color'] as Color
                            : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(level['icon'] as IconData,
                            color: isSelected 
                              ? level['color'] as Color
                              : const Color(0xFF9E9E9E),
                            size: 22),
                          const SizedBox(height: 4),
                          Text(level['label'] as String,
                            style: TextStyle(
                              color: isSelected 
                                ? level['color'] as Color
                                : const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            )),
                          const SizedBox(height: 2),
                          Text(level['desc'] as String,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 20),

              // SECTION: Location (optional)
              _buildSectionTitle('Location in Gym (Optional)', 
                Icons.location_on_rounded),
              const SizedBox(height: 10),

              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g. Ground Floor, near entrance',
                  prefixIcon: const Icon(Icons.place_rounded,
                    color: Color(0xFFE8845C), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8845C), width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => location = v,
              ),

              const SizedBox(height: 20),

              // SECTION: Photo (optional)
              _buildSectionTitle('Add Photo (Optional)', 
                Icons.camera_alt_rounded),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: selectedImage != null ? 200 : 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedImage != null 
                        ? const Color(0xFFE8845C) 
                        : const Color(0xFFE0E0E0),
                      width: selectedImage != null ? 2 : 1,
                      style: selectedImage != null 
                        ? BorderStyle.solid 
                        : BorderStyle.solid,
                    ),
                  ),
                  child: selectedImage != null
                    ? Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A).withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, 
                                color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded,
                            color: Color(0xFFE8845C), size: 32),
                          const SizedBox(height: 8),
                          const Text('Tap to add photo',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A), 
                              fontWeight: FontWeight.w600)),
                          const Text('Helps admin identify the issue faster',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E), fontSize: 11)),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: isSubmitting ? null : _submitComplaint,
                  child: isSubmitting
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)),
                          const SizedBox(width: 10),
                          const Text('Submitting...',
                            style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ])
                    : Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, 
                            color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text('Submit Complaint',
                            style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFFE8845C), size: 18),
      const SizedBox(width: 8),
      Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A))),
    ]);
  }

  // SUCCESS SCREEN shown after submission
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated success icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845C).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFFE8845C), size: 56),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Complaint Submitted! ✅',
                style: TextStyle(fontSize: 24, 
                  fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Your complaint has been sent to our admin team. '
                'We will look into this as soon as possible.',
                style: TextStyle(color: Color(0xFF9E9E9E), 
                  height: 1.5, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // What happens next
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What happens next?',
                      style: TextStyle(fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A), fontSize: 14)),
                    const SizedBox(height: 12),
                    _buildNextStep('1', 'Admin reviews your complaint', 
                      const Color(0xFFE8845C)),
                    const SizedBox(height: 8),
                    _buildNextStep('2', 'Equipment gets inspected', 
                      const Color(0xFFE8845C)),
                    const SizedBox(height: 8),
                    _buildNextStep('3', 'Issue resolved within 24 hours', 
                      const Color(0xFF7CB342)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pushReplacement(context, 
                    MaterialPageRoute(
                      builder: (_) => const MyComplaintsScreen())),
                  child: const Text('View My Complaints',
                    style: TextStyle(color: Colors.white, 
                      fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(String number, String text, Color color) {
    return Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(number,
            style: TextStyle(color: color, 
              fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13)),
    ]);
  }
}
