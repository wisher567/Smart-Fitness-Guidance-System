const { db } = require('../config/firebase');

// GET /api/trainer/dashboard
const getDashboard = async (req, res) => {
  try {
    const trainerUid = req.user.uid;
    const today = new Date().toISOString().slice(0, 10);

    // Get assigned clients
    const clientsSnap = await db.collection('users')
      .where('assignedTrainerId', '==', trainerUid)
      .get();
    const clients = clientsSnap.docs.map(d => ({
      uid: d.id, ...d.data()
    }));

    // Get today's classes
    const classesSnap = await db.collection('classes')
      .where('trainerId', '==', trainerUid)
      .get();
    const allClasses = classesSnap.docs.map(d => ({
      id: d.id, ...d.data()
    }));
    const todayClasses = allClasses.filter(c => 
      c.dateTime?.slice(0, 10) === today
    );

    // Get recent workout plans created by trainer
    const plansSnap = await db.collection('workoutPlans')
      .where('trainerId', '==', trainerUid)
      .get();
    const plans = plansSnap.docs.map(d => ({
      id: d.id, ...d.data()
    }));

    // Get recent client activity (last 5 completed workouts)
    const workoutsSnap = await db.collection('workouts')
      .where('completed', '==', true)
      .get();
    
    const clientUids = clients.map(c => c.uid);
    const recentActivity = workoutsSnap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(w => clientUids.includes(w.uid))
      .sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt))
      .slice(0, 5);

    res.json({
      success: true,
      stats: {
        totalClients:  clients.length,
        todayClasses:  todayClasses.length,
        totalClasses:  allClasses.length,
        totalPlans:    plans.length,
        activeClients: clients.filter(c => c.status !== 'suspended').length,
      },
      todayClasses,
      recentClients:  clients.slice(0, 5),
      recentActivity,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/trainer/clients
const getMyClients = async (req, res) => {
  try {
    const snap = await db.collection('users')
      .where('assignedTrainerId', '==', req.user.uid)
      .get();
    
    const clients = snap.docs.map(d => ({ uid: d.id, ...d.data() }));
    res.json({ success: true, clients });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/trainer/clients/:uid
const getClientDetail = async (req, res) => {
  try {
    const clientDoc = await db.collection('users')
      .doc(req.params.uid).get();
    
    if (!clientDoc.exists) {
      return res.status(404).json({ error: 'Client not found' });
    }

    const client = clientDoc.data();
    
    // Verify this client belongs to this trainer
    if (client.assignedTrainerId !== req.user.uid && 
        req.trainer.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Get workout stats
    const workoutsSnap = await db.collection('workouts')
      .where('uid', '==', req.params.uid)
      .get();
    
    const workouts = workoutsSnap.docs.map(d => d.data());
    const completed = workouts.filter(w => w.completed);

    res.json({
      success: true,
      client: { uid: clientDoc.id, ...client },
      stats: {
        totalWorkouts:    workouts.length,
        completedWorkouts: completed.length,
        totalCaloriesBurned: completed.reduce(
          (s, w) => s + (w.plan?.estimatedCalories || 0), 0
        ),
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/trainer/clients/:uid/workouts
const getClientWorkouts = async (req, res) => {
  try {
    const snap = await db.collection('workouts')
      .where('uid', '==', req.params.uid)
      .get();
    
    const workouts = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    res.json({ success: true, workouts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/trainer/plans
const createPlan = async (req, res) => {
  try {
    const { clientUid, planName, exercises, notes, targetDate } = req.body;
    
    if (!clientUid || !planName || !exercises?.length) {
      return res.status(400).json({ 
        error: 'clientUid, planName and exercises are required' 
      });
    }

    const plan = {
      trainerId:  req.user.uid,
      trainerName: req.trainer.name,
      clientUid,
      planName,
      exercises,
      notes:      notes || '',
      targetDate: targetDate || null,
      status:     'assigned',
      createdAt:  new Date().toISOString(),
      updatedAt:  new Date().toISOString(),
    };

    const saved = await db.collection('workoutPlans').add(plan);

    // Also save to client's workouts collection
    await db.collection('workouts').add({
      uid:       clientUid,
      planName,
      plan: {
        planName,
        exercises,
        estimatedCalories: exercises.reduce(
          (s, e) => s + (e.estimatedCalories || 0), 0
        ),
        totalDuration: `${exercises.length * 5} minutes`,
        difficulty: 'Intermediate',
      },
      completed:  false,
      assignedBy: req.user.uid,
      createdAt:  new Date().toISOString(),
    });

    res.json({ success: true, plan: { id: saved.id, ...plan } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/trainer/chat/:uid (send message to client)
const sendMessage = async (req, res) => {
  try {
    const trainerUid  = req.user.uid;
    const clientUid   = req.params.uid;
    const { message } = req.body;

    // Create chat room ID (always sorted so same room both ways)
    const roomId = [trainerUid, clientUid].sort().join('_');

    await db.collection('trainerChats')
      .doc(roomId)
      .collection('messages')
      .add({
        senderId:   trainerUid,
        senderName: req.trainer.name,
        senderRole: 'trainer',
        message,
        timestamp:  Date.now(),
        read:       false,
      });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/trainer/chat/:uid
const getChatHistory = async (req, res) => {
  try {
    const trainerUid = req.user.uid;
    const clientUid  = req.params.uid;
    const roomId     = [trainerUid, clientUid].sort().join('_');

    const snap = await db.collection('trainerChats')
      .doc(roomId)
      .collection('messages')
      .orderBy('timestamp', 'asc')
      .get();
    
    const messages = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ success: true, messages });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getMyClasses   = async (req, res) => {
  try {
    const snap = await db.collection('classes')
      .where('trainerId', '==', req.user.uid).get();
    const classes = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(a.dateTime) - new Date(b.dateTime));
    res.json({ success: true, classes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getMyPlans = async (req, res) => {
  try {
    const snap = await db.collection('workoutPlans')
      .where('trainerId', '==', req.user.uid).get();
    const plans = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ success: true, plans });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getClientNutrition = async (req, res) => {
  try {
    const snap = await db.collection('nutrition')
      .where('uid', '==', req.params.uid).get();
    const plans = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ success: true, latestPlan: plans[0] || null });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updatePlan = async (req, res) => {
  try {
    await db.collection('workoutPlans').doc(req.params.id).update({
      ...req.body,
      updatedAt: new Date().toISOString(),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const deletePlan = async (req, res) => {
  try {
    await db.collection('workoutPlans').doc(req.params.id).delete();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const assignPlanToClient = async (req, res) => {
  try {
    await db.collection('workoutPlans').doc(req.params.id).update({
      status: 'assigned',
      assignedAt: new Date().toISOString(),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getChatClients = async (req, res) => {
  try {
    const snap = await db.collection('users')
      .where('assignedTrainerId', '==', req.user.uid).get();
    const clients = snap.docs.map(d => ({ uid: d.id, ...d.data() }));
    res.json({ success: true, clients });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, phone, specialization, bio, experience } = req.body;
    await db.collection('users').doc(req.user.uid).update({
      name, phone, specialization, bio, experience,
      updatedAt: new Date().toISOString(),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getClientNotes = async (req, res) => {
  try {
    const trainerId = req.user.uid;
    const { uid } = req.params; // client uid
    const snap = await db.collection('trainerNotes')
      .doc(trainerId)
      .collection('notes')
      .where('clientUid', '==', uid)
      .orderBy('createdAt', 'desc')
      .get();
    const notes = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ success: true, notes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const addClientNote = async (req, res) => {
  try {
    const trainerId = req.user.uid;
    const { uid } = req.params; // client uid
    const { note } = req.body;
    const newNote = {
      clientUid: uid,
      note,
      createdAt: new Date().toISOString()
    };
    const docRef = await db.collection('trainerNotes')
      .doc(trainerId)
      .collection('notes')
      .add(newNote);
    res.json({ success: true, note: { id: docRef.id, ...newNote } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getDashboard, getMyClients, getClientDetail,
  getClientWorkouts, getClientNutrition,
  getMyClasses, getMyPlans, createPlan,
  updatePlan, deletePlan, assignPlanToClient,
  getChatClients, getChatHistory, sendMessage,
  updateProfile, getClientNotes, addClientNote
};
