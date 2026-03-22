// src/services/leaderboard.service.js
const { db } = require('../config/firebase');

const getLeaderboard = async (uid) => {
  // Get all members sorted by points
  const snap = await db
    .collection('users')
    .where('role', '==', 'member')
    .get();

  // Sort by points manually (no index needed)
  const allUsers = snap.docs
    .map(d => d.data())
    .sort((a, b) => (b.points || 0) - (a.points || 0))
    .slice(0, 10); // top 10 only

  // Build leaderboard with ranks
  const leaderboard = allUsers.map((user, index) => ({
    rank: index + 1,
    name: user.name,
    points: user.points || 0,
    badges: user.badges || [],
    badgeCount: (user.badges || []).length,
    isCurrentUser: user.uid === uid,
    medal: getMedal(index + 1)
  }));

  // Find current user's rank (might be outside top 10)
  const allSorted = snap.docs
    .map(d => d.data())
    .sort((a, b) => (b.points || 0) - (a.points || 0));

  const myRank = allSorted.findIndex(u => u.uid === uid) + 1;
  const myData = allSorted.find(u => u.uid === uid);

  return {
    leaderboard,
    myStats: {
      rank: myRank,
      points: myData?.points || 0,
      badges: myData?.badges || [],
      totalUsers: allSorted.length,
      percentile: Math.round(((allSorted.length - myRank) / allSorted.length) * 100)
    }
  };
};

const getMedal = (rank) => {
  if (rank === 1) return '🥇';
  if (rank === 2) return '🥈';
  if (rank === 3) return '🥉';
  return '🏅';
};

module.exports = { getLeaderboard };