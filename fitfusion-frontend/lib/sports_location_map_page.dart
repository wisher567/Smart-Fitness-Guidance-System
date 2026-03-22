import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fitfusion/providers/location_provider.dart';
import 'jogging_completed_page.dart';

class SportsLocationMapPage extends StatefulWidget {
  const SportsLocationMapPage({super.key});

  @override
  State<SportsLocationMapPage> createState() => _SportsLocationMapPageState();
}

class _SportsLocationMapPageState extends State<SportsLocationMapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Map<String, dynamic>? _selectedClass;
  
  static const CameraPosition _defaultPos = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default to SF
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    locProvider.fetchClasses();
    if (!kIsWeb) {
      // Only do geolocation on native platforms
      WidgetsBinding.instance.addPostFrameCallback((_) {
        locProvider.determinePosition().then((_) {
          if (locProvider.currentPosition != null) {
            _moveToPosition(locProvider.currentPosition!);
          }
        });
      });
    }
  }

  Future<void> _moveToPosition(Position pos) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 15.0,
      ),
    ));
  }

  void _onMarkerTapped(Map<String, dynamic> gymClass) {
    setState(() => _selectedClass = gymClass);
    final gym = gymClass['gym'] ?? {};
    final lat = double.tryParse(gym['latitude']?.toString() ?? '0');
    final lng = double.tryParse(gym['longitude']?.toString() ?? '0');
    if (lat != null && lng != null && lat != 0) {
      _controller.future.then((c) {
        c.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
      });
    }
  }

  Set<Marker> _buildMarkers(List<dynamic> classes) {
    Set<Marker> markers = {};
    for (var cls in classes) {
      final gym = cls['gym'];
      if (gym == null) continue;
      final lat = double.tryParse(gym['latitude']?.toString() ?? '');
      final lng = double.tryParse(gym['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        markers.add(Marker(
          markerId: MarkerId(cls['_id']?.toString() ?? DateTime.now().toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: cls['name'] ?? 'Class', snippet: gym['name'] ?? 'Gym'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _onMarkerTapped(cls),
        ));
      }
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(Position? userPos, Map<String, dynamic>? selectedCls) {
    if (userPos == null || selectedCls == null) return {};
    final gym = selectedCls['gym'];
    if (gym == null) return {};
    final lat = double.tryParse(gym['latitude']?.toString() ?? '');
    final lng = double.tryParse(gym['longitude']?.toString() ?? '');
    if (lat != null && lng != null) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [LatLng(userPos.latitude, userPos.longitude), LatLng(lat, lng)],
          color: const Color(0xFFFE7235),
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        )
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = Provider.of<LocationProvider>(context);

    if (_selectedClass == null && locProvider.classes.isNotEmpty) {
      _selectedClass = locProvider.classes.first;
    }

    // google_maps_flutter only works on Android & iOS
    final bool isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobileNative) {
      // Show fallback on web, Windows, macOS, Linux
      return _buildWebFallback(context, locProvider);
    }

    return _buildNativeMap(context, locProvider);
  }

  // ── Web fallback UI ─────────────────────────────────────────────────────────
  Widget _buildWebFallback(BuildContext context, LocationProvider locProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Nearby Fitness Classes",
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Map not available banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE7235), Color(0xFFFF966B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, color: Colors.white, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Map View",
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Interactive map is available on the mobile app. Browse classes below.",
                            style: GoogleFonts.inter(color: Colors.white.withAlpha(220), fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gym class list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Available Classes",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: locProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFE7235)))
                  : locProvider.classes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                "No classes available nearby",
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: locProvider.classes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cls = locProvider.classes[index];
                            final gym = cls['gym'] ?? {};
                            return _GymClassCard(
                              cls: cls,
                              gym: gym,
                              isSelected: _selectedClass == cls,
                              onTap: () => setState(() => _selectedClass = cls),
                              onCheckIn: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JoggingCompletedPage(
                                      classId: cls['_id']?.toString(),
                                      title: cls['name'] ?? 'Workout Completed',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Native Map UI ────────────────────────────────────────────────────────────
  Widget _buildNativeMap(BuildContext context, LocationProvider locProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _defaultPos,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: _buildMarkers(locProvider.classes),
              polylines: _buildPolylines(locProvider.currentPosition, _selectedClass),
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 12,
            child: GestureDetector(
              onTap: () {
                if (locProvider.currentPosition != null) {
                  _moveToPosition(locProvider.currentPosition!);
                } else {
                  locProvider.determinePosition();
                }
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: locProvider.isLoading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFE7235)))
                    : const Icon(Icons.my_location, color: Color(0xFFFE7235), size: 22),
              ),
            ),
          ),

          if (_selectedClass != null)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.2,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                final gym = _selectedClass!['gym'] ?? {};
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 5,
                            decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.fitness_center, size: 40, color: Color(0xFFFE7235)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedClass!['name'] ?? 'Class', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(gym['name'] ?? 'Gym', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.fitness_center, size: 14, color: Color(0xFFFE7235)),
                                      const SizedBox(width: 4),
                                      Text(_selectedClass!['difficulty'] ?? 'Beginner',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFFE7235))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text("Description", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 8),
                        Text(
                          _selectedClass!['description'] ?? 'Join our expert-led class designed to push your limits and maximize your fitness journey.',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFE7235),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => JoggingCompletedPage(
                                  classId: _selectedClass!['_id']?.toString(),
                                  title: _selectedClass!['name'] ?? 'Workout Completed',
                                ),
                              ));
                            },
                            child: Text("Check-in", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Gym Class Card (web fallback) ────────────────────────────────────────────
class _GymClassCard extends StatelessWidget {
  final Map<String, dynamic> cls;
  final Map<String, dynamic> gym;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;

  const _GymClassCard({
    required this.cls,
    required this.gym,
    required this.isSelected,
    required this.onTap,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFE7235) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFFFE7235), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls['name'] ?? 'Class',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gym['name'] ?? 'Gym',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (cls['difficulty'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cls['difficulty'],
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFFE7235)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onCheckIn,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFE7235),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text("Check-in", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
