// src/services/chatbot.service.js
const Groq = require('groq-sdk');
const { db } = require('../config/firebase');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const FITBOT_SYSTEM_PROMPT = `
You are FitBot, an advanced AI personal fitness coach inside the FitFusion app.
You have deep knowledge of the user's complete fitness journey including their
workouts, nutrition, progress, and goals.

Your personality:
- Encouraging, supportive and motivating
- Data-driven — reference the user's actual history when giving advice
- Like a real personal trainer who remembers everything
- Celebrate achievements and milestones
- Give specific actionable advice, not generic tips

Your responsibilities:
- Analyze the user's recent workout and nutrition history
- Track progress over time and point out improvements
- Suggest adjustments based on performance trends
- Provide personalized Sri Lankan food recommendations
- Give detailed workout guidance with sets, reps, rest times
- Motivate users who are struggling or inactive
- Warn if user is overtraining or under-eating
- Celebrate badges and point milestones

Response rules:
- Give DETAILED responses (8-12 sentences minimum)
- Always reference specific data from user history when available
- Use the user's actual name
- Include specific numbers (calories, reps, sets, weights)
- Break responses into clear sections when needed
- Never give medical diagnoses
- Always suggest consulting a doctor for injuries
- If no history exists yet, motivate them to start and explain what tracking will unlock
`;

// ─────────────────────────────────────────
// BUILD FULL USER CONTEXT
// ─────────────────────────────────────────
const buildUserContext = async (uid) => {
  // Run all queries in parallel for speed
  const [
    userDoc,
    workoutsSnap,
    nutritionSnap,
    foodScansSnap,
    chatSnap
  ] = await Promise.all([
    db.collection('users').doc(uid).get(),

    // Last 7 workouts
    db.collection('workouts')
      .where('uid', '==', uid)
      .get(),

    // Last 5 nutrition plans
    db.collection('nutrition')
      .where('uid', '==', uid)
      .get(),

    // Last 5 food scans
    db.collection('foodScans')
      .where('uid', '==', uid)
      .get(),

    // Last 20 chat messages
    db.collection('chatHistory')
      .doc(uid)
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(20)
      .get()
  ]);

  const user = userDoc.exists ? userDoc.data() : {};

  // Process workouts
  const workouts = workoutsSnap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 7);

  const completedWorkouts = workouts.filter(w => w.completed);
  const pendingWorkouts = workouts.filter(w => !w.completed);

  // Calculate workout streak
  const streak = calculateStreak(completedWorkouts);

  // Process nutrition
  const nutritionPlans = nutritionSnap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 3);

  // Process food scans
  const foodScans = foodScansSnap.docs
    .map(d => d.data())
    .sort((a, b) => new Date(b.scannedAt) - new Date(a.scannedAt))
    .slice(0, 5);

  // Process chat history
  const chatHistory = chatSnap.docs
    .reverse()
    .map(d => d.data());

  // Build detailed context string
  const contextString = `
=== USER PROFILE ===
Name: ${user.name || 'User'}
Age: ${user.age || 'unknown'}
Weight: ${user.weight || 'unknown'}kg
Height: ${user.height || 'unknown'}cm
BMI: ${user.bmi || 'unknown'} (${getBMICategory(user.bmi)})
Fitness Goal: ${user.fitnessGoal || 'not set'}
Fitness Level: ${user.fitnessLevel || 'not set'}
Medical Conditions: ${(user.medicalConditions || []).join(', ') || 'none'}
Total Points: ${user.points || 0}
Badges Earned: ${(user.badges || []).join(', ') || 'none yet'}
Member Since: ${user.updatedAt ? new Date(user.updatedAt).toLocaleDateString() : 'unknown'}

=== WORKOUT HISTORY (Last 7) ===
Total Workouts Done: ${completedWorkouts.length}
Current Streak: ${streak} days
${completedWorkouts.length > 0 ? `
Recent completed workouts:
${completedWorkouts.slice(0, 5).map((w, i) => `
${i + 1}. ${w.planName} 
   - Date: ${new Date(w.completedAt || w.createdAt).toLocaleDateString()}
   - Duration: ${w.plan?.totalDuration || 'unknown'}
   - Calories burned: ${w.plan?.estimatedCalories || 'unknown'}
   - Rating: ${w.rating ? `${w.rating}/5` : 'not rated'}
   - Difficulty: ${w.plan?.difficulty || 'unknown'}
`).join('')}` : 'No workouts completed yet'}
${pendingWorkouts.length > 0 ? `Pending workout: ${pendingWorkouts[0]?.planName}` : ''}

=== NUTRITION & DIET ===
${nutritionPlans.length > 0 ? `
Latest meal plan: ${nutritionPlans[0]?.planName}
Daily calorie target: ${nutritionPlans[0]?.plan?.dailyCalories || 'not set'} kcal
Macros target: Protein ${nutritionPlans[0]?.macros?.protein || 0}g, 
               Carbs ${nutritionPlans[0]?.macros?.carbs || 0}g, 
               Fats ${nutritionPlans[0]?.macros?.fats || 0}g
Meals logged today: ${(nutritionPlans[0]?.mealsLogged || []).length}
Total calories logged: ${(nutritionPlans[0]?.mealsLogged || []).reduce((sum, m) => sum + (m.actualCalories || 0), 0)} kcal
` : 'No nutrition plan created yet'}

=== FOOD SCANS (Recent) ===
${foodScans.length > 0 ? foodScans.map(s => `
- ${s.mealName || 'Food'}: ${s.totalNutrition?.calories || 0} kcal 
  (Health score: ${s.healthScore || 'N/A'}/10)
  Date: ${new Date(s.scannedAt).toLocaleDateString()}
`).join('') : 'No food scans yet'}

=== PROGRESS ANALYSIS ===
${generateProgressAnalysis(completedWorkouts, user)}
  `.trim();

  return { user, contextString, chatHistory };
};

// ─────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────
const calculateStreak = (completedWorkouts) => {
  if (completedWorkouts.length === 0) return 0;

  const dates = completedWorkouts
    .map(w => new Date(w.completedAt || w.createdAt).toDateString())
    .filter((d, i, arr) => arr.indexOf(d) === i) // unique dates
    .sort((a, b) => new Date(b) - new Date(a));

  let streak = 0;
  const today = new Date().toDateString();
  const yesterday = new Date(Date.now() - 86400000).toDateString();

  if (dates[0] !== today && dates[0] !== yesterday) return 0;

  for (let i = 0; i < dates.length; i++) {
    const expected = new Date(Date.now() - i * 86400000).toDateString();
    if (dates[i] === expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
};

const getBMICategory = (bmi) => {
  if (!bmi) return 'unknown';
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal weight';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
};

const generateProgressAnalysis = (completedWorkouts, user) => {
  if (completedWorkouts.length === 0) {
    return 'No workout history yet — user is just getting started!';
  }

  const totalCaloriesBurned = completedWorkouts
    .reduce((sum, w) => sum + (w.plan?.estimatedCalories || 0), 0);

  const avgRating = completedWorkouts
    .filter(w => w.rating)
    .reduce((sum, w, _, arr) => sum + w.rating / arr.length, 0);

  const recentWorkoutNames = completedWorkouts
    .slice(0, 3)
    .map(w => w.planName)
    .join(', ');

  return `
Total calories burned from all workouts: ${totalCaloriesBurned} kcal
Average workout rating: ${avgRating ? avgRating.toFixed(1) + '/5' : 'not rated yet'}
Most recent workouts: ${recentWorkoutNames}
Total completed workouts: ${completedWorkouts.length}
Points accumulated: ${user.points || 0}
  `.trim();
};

// ─────────────────────────────────────────
// MAIN CHAT FUNCTION
// ─────────────────────────────────────────
const chat = async (uid, userMessage) => {
  // 1. Build full user context
  const { user, contextString, chatHistory } = await buildUserContext(uid);

  // 2. Build messages for Groq with full history
  const messages = [
    {
      role: 'system',
      content: FITBOT_SYSTEM_PROMPT
    },
    {
      role: 'system',
      content: `Here is the complete user data and history you must use to personalize your response:\n\n${contextString}`
    },
    // Include previous conversation
    ...chatHistory.map(msg => ({
      role: msg.sender === 'user' ? 'user' : 'assistant',
      content: msg.message
    })),
    // Current message
    {
      role: 'user',
      content: userMessage
    }
  ];

  // 3. Call Groq with higher token limit for detailed responses
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages,
    max_tokens: 1024,      // longer responses
    temperature: 0.8,      // slightly creative
    top_p: 0.9
  });

  const botReply = response.choices[0].message.content;

  // 4. Save messages to Firestore
  const messagesRef = db
    .collection('chatHistory')
    .doc(uid)
    .collection('messages');

  const now = Date.now();

  await Promise.all([
    messagesRef.add({
      sender: 'user',
      message: userMessage,
      timestamp: now
    }),
    messagesRef.add({
      sender: 'bot',
      message: botReply,
      timestamp: now + 1
    })
  ]);

  // 5. Award points
  await db.collection('users').doc(uid).set(
    { points: (user.points || 0) + 5 },
    { merge: true }
  );

  // 6. Generate smart suggestions based on user context
  const suggestions = generateSmartSuggestions(botReply, user);

  return {
    reply: botReply,
    pointsEarned: 5,
    totalPoints: (user.points || 0) + 5,
    suggestions
  };
};

// ─────────────────────────────────────────
// SMART SUGGESTIONS
// ─────────────────────────────────────────
const generateSmartSuggestions = (botReply, user) => {
  const lower = botReply.toLowerCase();
  const suggestions = new Set();

  // Context-aware suggestions
  if (lower.includes('workout') || lower.includes('exercise'))
    suggestions.add('Generate my workout for today');
  if (lower.includes('diet') || lower.includes('nutrition') || lower.includes('eat'))
    suggestions.add('Create my meal plan');
  if (lower.includes('protein'))
    suggestions.add('Best protein foods in Sri Lanka?');
  if (lower.includes('calorie') || lower.includes('calories'))
    suggestions.add('Scan my food for calories');
  if (lower.includes('progress') || lower.includes('improve'))
    suggestions.add('Show my progress summary');
  if (lower.includes('rest') || lower.includes('recovery'))
    suggestions.add('What should I do on rest days?');
  if (lower.includes('streak') || lower.includes('consistent'))
    suggestions.add('How do I maintain my streak?');

  // Goal-based suggestions
  if (user.fitnessGoal === 'weight_loss')
    suggestions.add('What are the best fat burning exercises?');
  if (user.fitnessGoal === 'muscle_gain')
    suggestions.add('How much protein do I need daily?');

  // Default suggestions if none matched
  if (suggestions.size === 0) {
    suggestions.add('Generate my workout for today');
    suggestions.add('What should I eat today?');
    suggestions.add('How is my progress?');
  }

  return Array.from(suggestions).slice(0, 3);
};

// ─────────────────────────────────────────
// GET CHAT HISTORY
// ─────────────────────────────────────────
const getChatHistory = async (uid) => {
  const snap = await db
    .collection('chatHistory')
    .doc(uid)
    .collection('messages')
    .orderBy('timestamp', 'asc')
    .get();
  return snap.docs.map(d => d.data());
};

// ─────────────────────────────────────────
// CLEAR CHAT HISTORY
// ─────────────────────────────────────────
const clearChatHistory = async (uid) => {
  const messagesRef = db
    .collection('chatHistory')
    .doc(uid)
    .collection('messages');

  const snap = await messagesRef.get();
  const batch = db.batch();
  snap.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  return { success: true, message: 'Chat history cleared' };
};

module.exports = { chat, getChatHistory, clearChatHistory };