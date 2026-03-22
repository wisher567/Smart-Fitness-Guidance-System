import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({Key? key}) : super(key: key);
  @override
  State<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String selectedCategory  = 'general';
  bool isSubmitting        = false;
  bool isSubmitted         = false;
  List<Map<String, dynamic>> myMessages = [];
  bool isLoadingMessages   = false;

  // Reply state
  String? _replyingToId;                             // message id being replied to
  final _replyController = TextEditingController();
  bool _isSendingReply = false;

  final List<Map<String, dynamic>> categories = [
    { 'value': 'general',    'label': 'General',    'icon': '💬' },
    { 'value': 'billing',    'label': 'Billing',    'icon': '💳' },
    { 'value': 'technical',  'label': 'Technical',  'icon': '🔧' },
    { 'value': 'trainer',    'label': 'Trainer',    'icon': '👨💼' },
    { 'value': 'complaint',  'label': 'Complaint',  'icon': '⚠️' },
    { 'value': 'suggestion', 'label': 'Suggestion', 'icon': '💡' },
    { 'value': 'membership', 'label': 'Membership', 'icon': '🏋️' },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyMessages() async {
    setState(() => isLoadingMessages = true);
    try {
      final res = await ApiService.instance.getMyContactMessages();
      if (mounted) {
        setState(() {
          myMessages = List<Map<String,dynamic>>.from(res.data?['messages'] ?? []);
          isLoadingMessages = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_subjectController.text.trim().isEmpty) {
      _showSnackBar('Please enter a subject', isError: true);
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('Please enter your message', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ApiService.instance.sendContactAdminMessage(
        _subjectController.text.trim(),
        _messageController.text.trim(),
        selectedCategory,
      );

      setState(() {
        isSubmitting = false;
        isSubmitted  = true;
      });

      _subjectController.clear();
      _messageController.clear();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => isSubmitted = false);
          _tabController.animateTo(1);
          _fetchMyMessages();
        }
      });
    } catch (e) {
      setState(() => isSubmitting = false);
      _showSnackBar('Failed to send: ${e.toString()}', isError: true);
    }
  }

  Future<void> _sendReply(String messageId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter your reply', isError: true);
      return;
    }

    setState(() => _isSendingReply = true);

    try {
      final res = await ApiService.instance.replyToAdminMessage(messageId, text);
      if (res.success) {
        _replyController.clear();
        setState(() {
          _replyingToId = null;
          _isSendingReply = false;
        });
        _showSnackBar('Reply sent!');
        _fetchMyMessages();
      } else {
        setState(() => _isSendingReply = false);
        _showSnackBar(res.error ?? 'Failed to send reply', isError: true);
      }
    } catch (e) {
      setState(() => _isSendingReply = false);
      _showSnackBar('Failed to send reply: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF7CB342),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
        title: const Text('Contact Admin', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Color(0xFFF0F0F0), height: 1),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFE8845C),
                unselectedLabelColor: const Color(0xFF9E9E9E),
                indicatorColor: const Color(0xFFE8845C),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  const Tab(text: 'Send Message'),
                  Tab(text: 'My Messages (${myMessages.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    if (isSubmitted) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, __) => Transform.scale(
                scale: value,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(color: const Color(0xFF7CB342).withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF7CB342), size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Message Sent! ✅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text('Admin will reply within 24 hours', style: TextStyle(color: Color(0xFF9E9E9E))),
            const SizedBox(height: 8),
            const Text('Check your email for confirmation', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8845C).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8845C).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFFE8845C), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Our admin team typically replies within 24 hours. You will receive a confirmation email after sending.',
                  style: TextStyle(color: Color(0xFFD4673A), fontSize: 12, height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Category', Icons.category_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat['value'];
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8845C) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFFE8845C) : const Color(0xFFE0E0E0)),
                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFE8845C).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(cat['label']!, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1A1A1A), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Subject', Icons.title_rounded),
          const SizedBox(height: 10),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'e.g. Question about my membership',
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8845C), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Message', Icons.message_rounded),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Describe your issue or question in detail...',
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8845C), width: 2)),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8845C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              onPressed: isSubmitting ? null : _sendMessage,
              child: isSubmitting
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    const SizedBox(width: 10),
                    const Text('Sending...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return isLoadingMessages
      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8845C)))
      : myMessages.isEmpty
      ? Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 12),
            const Text('No messages yet', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Send a message to the admin team', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
          ],
        ))
      : RefreshIndicator(
          color: const Color(0xFFE8845C),
          onRefresh: _fetchMyMessages,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myMessages.length,
            itemBuilder: (_, i) => _buildMessageCard(myMessages[i]),
          ),
        );
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    final hasReply = (msg['adminReply'] ?? '').isNotEmpty;
    final replies  = List<Map<String, dynamic>>.from(msg['replies'] ?? []);
    final msgId    = msg['id'] as String? ?? '';
    final isReplyOpen = _replyingToId == msgId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasReply ? Border.all(color: const Color(0xFF7CB342).withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(children: [
            Expanded(
              child: Text(msg['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasReply ? const Color(0xFF7CB342).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(hasReply ? '✅ Replied' : '⏳ Pending', style: TextStyle(color: hasReply ? const Color(0xFF7CB342) : const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(msg['message'] ?? '', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(_formatDate(msg['createdAt']), style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),

          // ── Conversation thread (replies array) ──
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            const Text('Conversation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 8),
            ...replies.map((r) => _buildReplyBubble(r)),
          ] else if (hasReply) ...[
            // Legacy: show adminReply field when replies[] is empty
            const SizedBox(height: 12),
            _buildReplyBubble({ 'from': 'admin', 'text': msg['adminReply'], 'createdAt': msg['repliedAt'] }),
          ],

          // ── Reply button ──
          if (hasReply || replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (!isReplyOpen)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _replyingToId = msgId),
                  icon: const Icon(Icons.reply_rounded, size: 16, color: Color(0xFFE8845C)),
                  label: const Text('Reply', style: TextStyle(color: Color(0xFFE8845C), fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE8845C), width: 1),
                    ),
                  ),
                ),
              ),

            // ── Inline reply input ──
            if (isReplyOpen) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      autofocus: true,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8845C), width: 2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isSendingReply
                        ? const SizedBox(width: 36, height: 36, child: Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(color: Color(0xFFE8845C), strokeWidth: 2.5),
                          ))
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFFE8845C)),
                            onPressed: () => _sendReply(msgId),
                            splashRadius: 20,
                          ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyingToId = null;
                          _replyController.clear();
                        }),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBubble(Map<String, dynamic> reply) {
    final isAdmin = reply['from'] == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdmin
            ? const Color(0xFF7CB342).withOpacity(0.3)
            : const Color(0xFFE8845C).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
              color: isAdmin ? const Color(0xFF7CB342) : const Color(0xFFE8845C),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isAdmin ? 'Admin Reply' : 'Your Reply',
              style: TextStyle(
                color: isAdmin ? const Color(0xFF7CB342) : const Color(0xFFE8845C),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (reply['createdAt'] != null)
              Text(
                _formatDate(reply['createdAt']),
                style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10),
              ),
          ]),
          const SizedBox(height: 6),
          Text(
            reply['text'] ?? '',
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFE8845C), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Icon(icon, color: const Color(0xFFE8845C), size: 16),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
    ]);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month-1]} ${date.year} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}
