import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RequestTrainerScreen extends StatefulWidget {
  const RequestTrainerScreen({Key? key}) : super(key: key);
  @override
  State<RequestTrainerScreen> createState() => _RequestTrainerScreenState();
}

class _RequestTrainerScreenState extends State<RequestTrainerScreen> {
  List<Map<String, dynamic>> trainers = [];
  Map<String, dynamic>? selectedTrainer;
  Map<String, dynamic>? myRequest;
  final _messageController = TextEditingController();
  DateTime? preferredDate;
  TimeOfDay? preferredTime;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final trainersResp = await ApiService.instance.getTrainers();
      final requestsResp = await ApiService.instance.getMyTrainerRequests();

      if (mounted) {
        setState(() {
          trainers = List<Map<String, dynamic>>.from(trainersResp.data?['trainers'] ?? []);
          final requests = List<Map<String, dynamic>>.from(requestsResp.data?['requests'] ?? []);
          myRequest = requests.isNotEmpty ? requests.first : null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (selectedTrainer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a trainer'),
        backgroundColor: Color(0xFFEF4444),
      ));
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final trainerId = selectedTrainer!['uid'] ?? selectedTrainer!['id'] ?? '';
      
      String? formattedTime;
      if (preferredTime != null) {
        final local = MaterialLocalizations.of(context);
        formattedTime = local.formatTimeOfDay(preferredTime!);
      }

      final response = await ApiService.instance.createTrainerRequest(
        trainerId, 
        _messageController.text.trim(),
        preferredDate: preferredDate?.toIso8601String().split('T')[0],
        preferredTime: formattedTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.success
            ? '✅ Request sent! Admin will review it soon.'
            : response.error ?? 'Failed to send request'),
          backgroundColor: response.success ? const Color(0xFF7CB342) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      if (response.success) await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Request a Trainer',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFF0F0F0), height: 1)),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
        : RefreshIndicator(
            color: const Color(0xFFE8845C),
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Existing request status
                if (myRequest != null) ...[
                  _buildRequestStatus(myRequest!),
                  const SizedBox(height: 20),
                ],

                // Show form only if no pending request
                if (myRequest == null || myRequest!['status'] != 'pending') ...[
                  // Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8845C).withOpacity(0.3)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFE8845C), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select a trainer below and submit your request. '
                          'The admin will review and assign them to you. '
                          'Both you and the trainer will be notified by email.',
                          style: TextStyle(color: const Color(0xFFD4673A), fontSize: 12, height: 1.4)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Choose trainer section
                  _buildSectionHeader('Choose a Trainer'),
                  const SizedBox(height: 12),

                  trainers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('No trainers available', style: TextStyle(color: Color(0xFF9E9E9E)))),
                      )
                    : Column(mainAxisSize: MainAxisSize.min,
                        children: trainers.map((t) => _buildTrainerCard(t)).toList()),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Your Message (Optional)'),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _messageController, maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell the trainer about your goals, schedule preferences, etc...',
                      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8845C), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Preferred First Session (Optional)'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFFE8845C)),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) setState(() => preferredDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E0E0))),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFFE8845C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              preferredDate == null ? 'Select Date' : '${preferredDate!.year}-${preferredDate!.month.toString().padLeft(2,'0')}-${preferredDate!.day.toString().padLeft(2,'0')}',
                              style: TextStyle(color: preferredDate == null ? const Color(0xFF9E9E9E) : const Color(0xFF1A1A1A), fontSize: 13, fontWeight: preferredDate == null ? FontWeight.normal : FontWeight.w600),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFFE8845C)),
                              ),
                              child: child!,
                            ),
                          );
                          if (time != null) setState(() => preferredTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E0E0))),
                          child: Row(children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFFE8845C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              preferredTime == null ? 'Select Time' : preferredTime!.format(context),
                              style: TextStyle(color: preferredTime == null ? const Color(0xFF9E9E9E) : const Color(0xFF1A1A1A), fontSize: 13, fontWeight: preferredTime == null ? FontWeight.normal : FontWeight.w600),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8845C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                      onPressed: isSubmitting ? null : _submitRequest,
                      child: isSubmitting
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ]),
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Row(children: [
      Container(width: 4, height: 20,
        decoration: BoxDecoration(color: const Color(0xFFE8845C), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
    ]);
  }

  Widget _buildRequestStatus(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final colors = {
      'pending': [const Color(0xFFFFFBEB), const Color(0xFFF59E0B)],
      'approved': [const Color(0xFFF0FDF4), const Color(0xFF7CB342)],
      'rejected': [const Color(0xFFFEF2F2), const Color(0xFFEF4444)],
    };
    final icons = {'pending': '⏳', 'approved': '✅', 'rejected': '❌'};
    final labels = {'pending': 'Request Pending', 'approved': 'Request Approved!', 'rejected': 'Request Rejected'};
    final descs = {
      'pending': 'Your request to train with ${request['trainerName']} is being reviewed by the admin.',
      'approved': '🎉 You have been assigned to ${request['trainerName']}! Check your email for details.',
      'rejected': 'Your request was not approved. You can submit a new request below.',
    };

    final c = colors[status] ?? [const Color(0xFFF5F5F5), const Color(0xFF9E9E9E)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c[0], borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c[1].withOpacity(0.4))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icons[status] ?? '❓', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(labels[status] ?? status, style: TextStyle(fontWeight: FontWeight.bold, color: c[1], fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        Text(descs[status] ?? '', style: const TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.5)),
        
        Builder(builder: (context) {
          final session = request['sessionInfo'] ?? request;
          if (status == 'approved' && session['sessionDate'] != null) {
            return Column(children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7CB342).withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📅 First Session Details', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), fontSize: 14)),
                  const SizedBox(height: 10),
                  _buildSessionRow(Icons.calendar_today_rounded, 'Date', session['sessionDate'] ?? ''),
                  _buildSessionRow(Icons.access_time_rounded, 'Time', session['sessionTime'] ?? 'TBD'),
                  _buildSessionRow(Icons.location_on_rounded, 'Location', session['sessionLocation'] ?? 'Gym'),
                  _buildSessionRow(Icons.timer_rounded, 'Duration', session['sessionDuration'] ?? '60 min'),
                  if (session['sessionNotes']?.toString().isNotEmpty ?? false)
                    _buildSessionRow(Icons.note_rounded, 'Note', session['sessionNotes']),
                ]),
              ),
            ]);
          }
          return const SizedBox.shrink();
        }),

        if (request['adminNote']?.toString().isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status == 'rejected' ? const Color(0xFFFEF2F2) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: status == 'rejected' ? const Color(0xFFEF4444).withOpacity(0.2) : Colors.transparent),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.message_rounded, size: 14, color: status == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFF9E9E9E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Admin note: "${request['adminNote']}"',
                  style: TextStyle(color: status == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFF777777), fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Text('Requested trainer: ${request['trainerName']}',
          style: TextStyle(color: c[1], fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSessionRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: const Color(0xFF7CB342)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildTrainerCard(Map<String, dynamic> trainer) {
    final isSelected = selectedTrainer?['uid'] == trainer['uid'] ||
                       selectedTrainer?['id'] == trainer['id'];

    return GestureDetector(
      onTap: () => setState(() => selectedTrainer = trainer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8845C).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFE8845C) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE8845C), Color(0xFFD4673A)]),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(_getInitials(trainer['name'] ?? ''),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trainer['name'] ?? 'Trainer',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), fontSize: 15)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.fitness_center_rounded, size: 12, color: Color(0xFFE8845C)),
              const SizedBox(width: 4),
              Text(trainer['specialization'] ?? 'General Fitness',
                style: const TextStyle(color: Color(0xFFE8845C), fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            if (trainer['bio'] != null && trainer['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(trainer['bio'].toString(),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ])),
          if (isSelected)
            Container(width: 24, height: 24,
              decoration: const BoxDecoration(color: Color(0xFFE8845C), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14))
          else
            Container(width: 24, height: 24,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0)), shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
