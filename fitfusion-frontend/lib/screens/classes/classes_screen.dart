import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({Key? key}) : super(key: key);
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Map<String, dynamic>> classes = [];
  bool isLoading = true;
  String currentUserUid = '';

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await ApiService.instance.getUpcomingClasses();
      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            classes = List<Map<String, dynamic>>.from(response.data!['classes'] ?? []);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _enrollInClass(String classId) async {
    try {
      final response = await ApiService.instance.enrollInClass(classId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.success ? '✅ Enrolled successfully!' : response.error ?? 'Failed'),
          backgroundColor: response.success ? const Color(0xFF7CB342) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      _fetchClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to enroll: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  Future<void> _cancelEnrollment(String classId) async {
    try {
      await ApiService.instance.cancelEnrollment(classId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enrollment cancelled'),
          backgroundColor: Color(0xFF9E9E9E),
          behavior: SnackBarBehavior.floating,
        ));
      }
      _fetchClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to cancel'),
          backgroundColor: Color(0xFFEF4444),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 4, height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE8845C),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          const Text('Gym Classes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ]),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
          : classes.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.calendar_today_rounded, size: 64, color: Color(0xFFE0E0E0)),
                    SizedBox(height: 12),
                    Text('No upcoming classes', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
                    Text('Check back later!', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
                  ]),
                )
              : RefreshIndicator(
                  color: const Color(0xFFE8845C),
                  onRefresh: _fetchClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: classes.length,
                    itemBuilder: (_, i) => _buildClassCard(classes[i]),
                  ),
                ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> gymClass) {
    final enrolled = List<String>.from(gymClass['enrolledMembers'] ?? []);
    final isEnrolled = enrolled.contains(currentUserUid);
    final capacity = gymClass['capacity'] ?? 20;
    final enrolledCount = enrolled.length;
    final isFull = enrolledCount >= capacity;

    String dateStr = 'TBD';
    String timeStr = '';
    if (gymClass['date'] != null) {
      dateStr = gymClass['date'];
    }
    if (gymClass['time'] != null) {
      timeStr = gymClass['time'];
    }
    if (gymClass['dateTime'] != null) {
      final dt = DateTime.tryParse(gymClass['dateTime']);
      if (dt != null) {
        dateStr = '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)}';
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        border: isEnrolled ? Border.all(color: const Color(0xFFE8845C), width: 2) : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: isEnrolled ? const Color(0xFFE8845C) : const Color(0xFFE0E0E0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(gymClass['name'] ?? 'Class',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              ),
              if (isEnrolled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8845C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Enrolled ✓',
                    style: TextStyle(color: Color(0xFFE8845C), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _buildDetail(Icons.calendar_today_rounded, dateStr),
              if (timeStr.isNotEmpty) _buildDetail(Icons.access_time_rounded, timeStr),
              _buildDetail(Icons.timer_rounded, '${gymClass['duration'] ?? 60} min'),
              _buildDetail(Icons.location_on_rounded, gymClass['location'] ?? 'Main Studio'),
              _buildDetail(Icons.person_rounded, gymClass['trainer'] ?? gymClass['trainerName'] ?? 'TBD'),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Capacity', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
              const Spacer(),
              Text('$enrolledCount / $capacity',
                style: TextStyle(
                  color: isFull ? const Color(0xFFEF4444) : const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: capacity > 0 ? enrolledCount / capacity : 0,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation(
                  isFull ? const Color(0xFFEF4444)
                    : enrolledCount / capacity > 0.8 ? const Color(0xFFF59E0B) : const Color(0xFF7CB342)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled ? const Color(0xFFF5F5F5) : isFull ? const Color(0xFFEF4444) : const Color(0xFFE8845C),
                  foregroundColor: isEnrolled ? const Color(0xFFEF4444) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isEnrolled ? const BorderSide(color: Color(0xFFEF4444)) : BorderSide.none,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isFull && !isEnrolled ? null
                  : () => isEnrolled ? _cancelEnrollment(gymClass['id']) : _enrollInClass(gymClass['id']),
                child: Text(
                  isEnrolled ? 'Cancel Enrollment' : isFull ? 'Class Full' : 'Enroll Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFFE8845C)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
    ]);
  }

  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(day - 1) % 7];
  }

  String _month(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
