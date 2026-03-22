import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.instance.getLeaderboard();
      
      setState(() {
        if (response.success) {
          _users = response.data?['leaderboard'] ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  // --- Theme Helpers ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primaryColor => const Color(0xFFFE7235); // Fitfusion Orange
  Color get highlightColor => primaryColor.withAlpha(isDark ? 51 : 25);
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Leaderboard",
          style: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _users.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildPodium(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No leaderboard data available.",
        style: GoogleFonts.poppins(color: textSecondary, fontSize: 16),
      ),
    );
  }

  // -------------------------------------------------------------
  // PODIUM SECTION (Ranks 2, 1, 3)
  // -------------------------------------------------------------
  Widget _buildPodium() {
    if (_users.isEmpty) return const SizedBox.shrink();

    // Ensure we have up to 3 users for the podium
    final first = _users.isNotEmpty ? _users[0] : null;
    final second = _users.length > 1 ? _users[1] : null;
    final third = _users.length > 2 ? _users[2] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _buildPodiumAvatar(second, 2, 80, const Color(0xFFC0C0C0)), // Silver
          if (second != null) const SizedBox(width: 15),
          
          if (first != null) Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildPodiumAvatar(first, 1, 110, primaryColor, isFirst: true), // Gold/Orange
          ),
          
          if (third != null) const SizedBox(width: 15),
          if (third != null) _buildPodiumAvatar(third, 3, 80, const Color(0xFFCD7F32)), // Bronze
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildPodiumAvatar(dynamic user, int rank, double size, Color ringColor, {bool isFirst = false}) {
    final String name = user['name'] ?? 'User';
    final int points = user['points'] ?? 0;
    
    // We try to use their photoUrl, otherwise fallback to an asset or initial
    final String? photoUrl = user['photoUrl'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) 
          Icon(Icons.workspace_premium, color: primaryColor, size: 36)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 1000.ms),
            
        if (isFirst) const SizedBox(height: 8),

        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3),
                image: DecorationImage(
                  image: _getAvatarImage(photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ringColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: bgColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name.split(' ').first, // Just first name to keep it clean on podium
          style: GoogleFonts.poppins(color: textPrimary, fontSize: isFirst ? 16 : 14, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, color: primaryColor, size: 14),
            const SizedBox(width: 4),
            Text(
              "$points pts",
              style: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // LIST SECTION (Ranks 4+)
  // -------------------------------------------------------------
  Widget _buildList() {
    // Only show items from rank 4 (index 3) onwards in the list
    if (_users.length <= 3) return const SizedBox.shrink();

    final listUsers = _users.sublist(3);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        itemCount: listUsers.length,
        itemBuilder: (context, index) {
          final user = listUsers[index];
          final rank = index + 4; // Because we skipped the first 3
          final bool isCurrentUser = user['uid'] == _currentUserId;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? highlightColor : (isDark ? const Color(0xFF2A2A2D) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isCurrentUser 
                  ? Border.all(color: primaryColor.withAlpha(isDark ? 128 : 76)) 
                  : (isDark ? null : Border.all(color: const Color(0xFFE0E0E0))),
              boxShadow: isDark ? [] : [
                if (!isCurrentUser)
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      rank.toString(),
                      style: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _getAvatarImage(user['photoUrl']),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ],
              ),
              title: Text(
                isCurrentUser ? "You" : (user['name'] ?? 'User'),
                style: GoogleFonts.poppins(
                  color: textPrimary, 
                  fontSize: 15, 
                  fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500
                ),
              ),
              trailing: Text(
                "${user['points'] ?? 0} pts",
                style: GoogleFonts.poppins(
                  color: isCurrentUser ? primaryColor : textSecondary, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  // Helper to fallback safely if network image is missing or broken
  ImageProvider _getAvatarImage(String? url) {
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/images/profile_new.png');
  }
}
