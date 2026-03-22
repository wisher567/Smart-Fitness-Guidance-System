const { db } = require('../config/firebase');

const createEquipmentAlert = async (uid, alertData) => {
  // Get user info
  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.data();

  const alert = {
    uid,
    reportedByName: user?.name || 'Unknown Member',
    reportedByEmail: user?.email || '',
    equipment: alertData.equipment,
    issue: alertData.issue,
    description: alertData.description || '',
    urgency: alertData.urgency || 'medium', // low | medium | high
    location: alertData.location || '',     // e.g. "Ground Floor"
    imageBase64: alertData.imageBase64 || null,
    status: 'open',                         // open | in_progress | resolved
    adminNotes: '',
    resolvedAt: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    date: new Date().toISOString().slice(0, 10), // YYYY-MM-DD
  };

  const saved = await db.collection('equipmentAlerts').add(alert);

  return { 
    id: saved.id, 
    ...alert,
    message: 'Your complaint has been submitted successfully!' 
  };
};

const getAllAlerts = async () => {
  const snap = await db.collection('equipmentAlerts').get();
  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
};

const getAlertById = async (id) => {
  const doc = await db.collection('equipmentAlerts').doc(id).get();
  if (!doc.exists) throw new Error('Alert not found');
  return { id: doc.id, ...doc.data() };
};

const getMyAlerts = async (uid) => {
  const snap = await db.collection('equipmentAlerts')
    .where('uid', '==', uid)
    .get();
  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
};

const updateAlertStatus = async (id, status, adminNotes) => {
  const update = {
    status,
    adminNotes: adminNotes || '',
    updatedAt: new Date().toISOString(),
  };
  if (status === 'resolved') {
    update.resolvedAt = new Date().toISOString();
  }
  await db.collection('equipmentAlerts').doc(id).update(update);
  return { success: true, id, status };
};

const deleteAlert = async (id) => {
  await db.collection('equipmentAlerts').doc(id).delete();
  return { success: true };
};

const assignTrainer = async (memberUid, trainerId) => {
  const trainerDoc = await db.collection('users').doc(trainerId).get();
  const trainer    = trainerDoc.data();
  
  await db.collection('users').doc(memberUid).update({
    assignedTrainerId: trainerId,
    trainerName: trainer.name,
    updatedAt: new Date().toISOString(),
  });
  
  return { success: true, trainerName: trainer.name };
};

module.exports = {
  createEquipmentAlert,
  getAllAlerts,
  getAlertById,
  getMyAlerts,
  updateAlertStatus,
  deleteAlert,
  assignTrainer,
};
