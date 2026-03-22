import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'report_equipment_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  bool isLoading = true;
  List<dynamic> alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.instance.getMyEquipmentAlerts();
      if (res.success && mounted) {
        setState(() {
          alerts = res.data?['alerts'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception(res.error ?? 'Error loading alerts');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFE8845C);
      case 'low': return const Color(0xFFF59E0B);
      default: return const Color(0xFFE0E0E0);
    }
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, List<Color>> colors = {
      'open':        [const Color(0xFFEF4444), const Color(0xFFFEF2F2)],
      'in_progress': [const Color(0xFFF59E0B), const Color(0xFFFFFBEB)],
      'resolved':    [const Color(0xFF22C55E), const Color(0xFFF0FDF4)],
    };
    final Map<String, String> labels = {
      'open': 'Open',
      'in_progress': 'In Progress',
      'resolved': 'Resolved ✓',
    };
    final List<Color> c = colors[status] ?? [const Color(0xFF9E9E9E), const Color(0xFFF5F5F5)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c[1], borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status,
        style: TextStyle(color: c[0], 
          fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    final color = _getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(urgency.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
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
        title: const Text('My Complaints',
          style: TextStyle(color: Color(0xFF1A1A1A), 
            fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
        : alerts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: const Color(0xFFE8845C),
              onRefresh: _fetchAlerts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildComplaintCard(alert);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8845C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ReportEquipmentScreen())).then((_) => _fetchAlerts()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8845C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outlined, 
              size: 64, color: Color(0xFFE8845C)),
          ),
          const SizedBox(height: 24),
          const Text('No complaints yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, 
              color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text("You haven't reported any equipment issues",
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8845C),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ReportEquipmentScreen())).then((_) => _fetchAlerts()),
            child: const Text('Report an Issue',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: _getUrgencyColor(alert['urgency'] ?? 'medium'),
            width: 4,
          ),
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: equipment name + status badge
            Row(children: [
              Expanded(
                child: Text(alert['equipment'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A), fontSize: 16)),
              ),
              _buildStatusBadge(alert['status'] ?? 'open'),
            ]),
            const SizedBox(height: 8),

            // Issue text
            Text(alert['issue'] ?? 'No issue described',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),

            if (alert['description'] != null && alert['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(alert['description'],
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF5F5F5), height: 1),
            const SizedBox(height: 12),

            // Bottom row: date + urgency + location
            Row(children: [
              const Icon(Icons.calendar_today_rounded, 
                size: 12, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text(_formatDate(alert['createdAt'] ?? ''),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
              if (alert['location'] != null && alert['location'].toString().isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_rounded,
                  size: 12, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Text(alert['location'],
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
              ],
              const Spacer(),
              _buildUrgencyBadge(alert['urgency'] ?? 'medium'),
            ]),

            // Admin notes (shown when resolved or if present)
            if (alert['adminNotes'] != null && alert['adminNotes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CB342).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF7CB342).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded,
                      color: Color(0xFF7CB342), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin Response',
                            style: TextStyle(color: Color(0xFF7CB342),
                              fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(alert['adminNotes'],
                            style: const TextStyle(color: Color(0xFF1A1A1A),
                              fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Photo thumbnail if exists
            if (alert['imageBase64'] != null && alert['imageBase64'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(alert['imageBase64']),
                  height: 120, width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
