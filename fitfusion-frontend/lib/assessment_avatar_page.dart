import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitfusion/services/api_service.dart';
import 'home_page.dart';

class AssessmentAvatarPage extends StatefulWidget {
  const AssessmentAvatarPage({super.key});

  @override
  State<AssessmentAvatarPage> createState() => _AssessmentAvatarPageState();
}

class _AssessmentAvatarPageState extends State<AssessmentAvatarPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.5,
    initialPage: 1,
  );
  int _currentPage = 1;

  final List<String> _avatars = [
    "assets/images/avatar_beanie.png",
    "assets/images/avatar_bunny.png",
    "assets/images/avatar_cat.png",
  ];

  Uint8List? _selectedImageBytes;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _saveAvatarAndContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_selectedImageBytes != null) {
        // Upload the custom image bytes
        await ApiService.instance.uploadAvatarBytes(_selectedImageBytes!, 'avatar.jpg');
      } else {
        // Send the asset path of the currently selected carousel avatar
        await ApiService.instance.updateAvatarUrl(_avatars[_currentPage]);
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Failed to save avatar: $e");
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving avatar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Assessment",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Carousal of Avatars
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _avatars.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  bool isCenter = index == _currentPage;
                  double scale = isCenter ? 1.0 : 0.8;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    transform: Matrix4.diagonal3Values(scale, scale, 1.0)..setTranslationRaw(0.0, isCenter ? 0.0 : 18.0, 0.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: isCenter
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(_avatars[index], fit: BoxFit.cover),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Text section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    "Select your Avatar",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We have 23 custom premade avatars, or\nyou can upload profile locally",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: _pickImage,
              child: _selectedImageBytes != null 
                // Display the selected image natively on all platforms
                ? Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: MemoryImage(_selectedImageBytes!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                  )
                // Display the dashed upload box
                : CustomPaint(
                    painter: DashedCirclePainter(),
                    child: Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.file_upload_outlined,
                        size: 32,
                        color: Colors.black87,
                      ),
                    ),
                  ),
            ),

            const SizedBox(height: 24),

            // Upload Text
            Text(
              "or Upload from Local File",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Max 5mb, Format: jpg,png",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFA0A0A0),
              ),
            ),

            const Spacer(),

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveAvatarAndContinue,
                  child: _isSaving 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continue",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    var rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    double dashWidth = 10, dashSpace = 12;
    double circumference = 2 * pi * (size.width / 2);
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    double sweepAngle = (dashWidth / circumference) * 2 * pi;
    double spaceAngle = (dashSpace / circumference) * 2 * pi;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        rect,
        i * (sweepAngle + spaceAngle),
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
