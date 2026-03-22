const { admin, db } = require('../config/firebase');
const adminService = require('../services/admin.service');
const {
  sendTrainerWelcomeEmail,
  sendClassScheduleEmail,
  sendTrainerRequestEmail,
  sendRequestApprovedToMember,
  sendRequestApprovedToTrainer,
  sendRequestRejectedToMember,
} = require('../services/email.service');

const getRevenueStats = async (req, res) => {
  try {
    const snap = await db.collection('payments').get();
    const payments = snap.docs.map(d => d.data());

    // Group by month
    const monthly = {};
    payments.filter(p => p.status === 'completed').forEach(p => {
      const month = p.createdAt?.slice(0, 7); // YYYY-MM
      if (!month) return;
      if (!monthly[month]) monthly[month] = { month, revenue: 0, count: 0 };
      monthly[month].revenue += p.amount || 0;
      monthly[month].count++;
    });

    const result = Object.values(monthly)
      .sort((a, b) => a.month.localeCompare(b.month))
      .slice(-12);

    res.json({ success: true, monthly: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getMemberStats = async (req, res) => {
  try {
    const snap = await db.collection('users')
      .where('role', '==', 'member').get();
    const members = snap.docs.map(d => d.data());

    const monthly = {};
    members.forEach(m => {
      const month = m.updatedAt?.slice(0, 7) || m.createdAt?.slice(0, 7);
      if (!month) return;
      if (!monthly[month]) monthly[month] = { month, count: 0 };
      monthly[month].count++;
    });

    const result = Object.values(monthly)
      .sort((a, b) => a.month.localeCompare(b.month))
      .slice(-12);

    let total = 0;
    result.forEach(r => { total += r.count; r.total = total; });

    res.json({ success: true, monthly: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const addTrainer = async (req, res) => {
  let userRecord = null;
  try {
    const { name, email, phone, specialization, experience, bio } = req.body;
    
    userRecord = await admin.auth().createUser({
      email,
      password: 'Password123!',
      displayName: name,
    });

    const newTrainer = {
      uid: userRecord.uid,
      name,
      email,
      phone,
      specialization: specialization || '',
      experience: experience || '',
      bio,
      role: 'trainer',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    await db.collection('users').doc(userRecord.uid).set(newTrainer);

    // Send welcome email (async - don't block response)
    sendTrainerWelcomeEmail(newTrainer).catch(err =>
      console.error('Welcome email failed:', err.message)
    );
    
    res.json({ success: true, trainer: newTrainer });
  } catch (err) {
    if (userRecord && err.code !== 'auth/email-already-exists') {
      try {
        await admin.auth().deleteUser(userRecord.uid);
      } catch (rollbackErr) {
        console.error('Failed to rollback auth user creation:', rollbackErr);
      }
    }
    res.status(500).json({ error: err.message });
  }
};

const getTrainers = async (req, res) => {
  try {
    const snap = await db.collection('users').where('role', '==', 'trainer').get();
    const trainers = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, trainers });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getAllPlans = async (req, res) => {
  try {
    const snap = await db.collection('plans').get();
    const plans = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, plans });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const createPlan = async (req, res) => {
  try {
    const newPlan = { ...req.body, createdAt: new Date().toISOString() };
    const docRef = await db.collection('plans').add(newPlan);
    res.json({ success: true, plan: { id: docRef.id, ...newPlan } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updatePlan = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('plans').doc(id).update({
      ...req.body,
      updatedAt: new Date().toISOString()
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const deletePlan = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('plans').doc(id).delete();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getDashboardStats = async (req, res) => {
  try {
    const memSnap = await db.collection('users').where('role', '==', 'member').get();
    const paymentsSnap = await db.collection('payments').where('status', '==', 'completed').get();
    const alertsSnap = await db.collection('equipmentAlerts').where('status', '==', 'open').get();
    
    let rev = 0;
    const currentMonth = new Date().toISOString().slice(0, 7);
    paymentsSnap.docs.forEach(d => {
       const cd = d.data().createdAt;
       if (cd && cd.startsWith(currentMonth)) rev += (d.data().amount || 0);
    });

    res.json({
      success: true,
      stats: {
        totalMembers: memSnap.size,
        activeSubscriptions: Math.floor(memSnap.size * 0.8), // Placeholder logic
        totalRevenue: rev,
        openEquipmentAlerts: alertsSnap.size
      }
    });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const getAllMembers = async (req, res) => {
  try {
    const [membersSnap, subsSnap] = await Promise.all([
      db.collection('users').where('role', '==', 'member').get(),
      db.collection('subscriptions').get(),
    ]);

    // Build a map of uid -> subscription data
    const subsMap = {};
    subsSnap.docs.forEach(doc => {
      const data = doc.data();
      subsMap[doc.id] = data;  // subscriptions doc id = uid
    });

    const members = membersSnap.docs.map(doc => {
      const member = { uid: doc.id, ...doc.data() };
      const sub = subsMap[doc.id];
      if (sub && sub.status === 'active') {
        member.membershipPlanName = sub.planName || null;
        member.membershipStatus = sub.status;
        member.membershipEndDate = sub.endDate || null;
      } else {
        member.membershipPlanName = null;
        member.membershipStatus = sub ? sub.status : null;
      }
      return member;
    });

    members.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    res.json({ success: true, members });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const getMemberById = async (req, res) => {
  try {
    const { uid } = req.params;
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'User not found' });
    res.json({ success: true, member: { uid: doc.id, ...doc.data() } });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const getAllPayments = async (req, res) => {
  try {
    const snap = await db.collection('payments').get();
    const payments = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    payments.sort((a,b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    res.json({ success: true, payments });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const getAllClasses = async (req, res) => {
  try {
    const snap = await db.collection('classes').get();
    const classes = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, classes });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const createClass = async (req, res) => {
  try {
    const newClass = {
      ...req.body,
      enrolledMembers: [],
      createdAt: new Date().toISOString(),
    };
    // Build dateTime from date + time for backward compatibility
    if (req.body.date && req.body.time) {
      newClass.dateTime = `${req.body.date}T${req.body.time}:00`;
    }
    const docRef = await db.collection('classes').add(newClass);

    // Send email to assigned trainer
    if (req.body.trainerId && req.body.trainerId !== 'Unassigned') {
      const trainerDoc = await db.collection('users').doc(req.body.trainerId).get();
      if (trainerDoc.exists) {
        sendClassScheduleEmail(trainerDoc.data(), newClass).catch(err =>
          console.error('Class email failed:', err.message)
        );
      }
    }

    res.json({ success: true, class: { id: docRef.id, ...newClass } });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const updateClass = async (req, res) => {
  try {
    await db.collection('classes').doc(req.params.id).update({
      ...req.body, updatedAt: new Date().toISOString()
    });
    res.json({ success: true });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const deleteClass = async (req, res) => {
  try {
    await db.collection('classes').doc(req.params.id).delete();
    res.json({ success: true });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const createAlert = async (req, res) => {
  try {
    const { equipment, issue, description, urgency, location, imageBase64 } = req.body;
    
    if (!equipment || !issue) {
      return res.status(400).json({ 
        error: 'Equipment name and issue description are required' 
      });
    }

    if (!['low', 'medium', 'high'].includes(urgency)) {
      return res.status(400).json({ 
        error: 'Urgency must be low, medium, or high' 
      });
    }

    const result = await adminService.createEquipmentAlert(req.user.uid, {
      equipment, issue, description, urgency, location, imageBase64
    });

    res.json({ success: true, alert: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getAllAlerts = async (req, res) => {
  try {
    const { status, urgency } = req.query;
    let alerts = await adminService.getAllAlerts();
    
    if (status) alerts = alerts.filter(a => a.status === status);
    if (urgency) alerts = alerts.filter(a => a.urgency === urgency);

    const stats = {
      total:       alerts.length,
      open:        alerts.filter(a => a.status === 'open').length,
      in_progress: alerts.filter(a => a.status === 'in_progress').length,
      resolved:    alerts.filter(a => a.status === 'resolved').length,
      high:        alerts.filter(a => a.urgency === 'high').length,
    };

    res.json({ success: true, alerts, stats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getMyAlerts = async (req, res) => {
  try {
    const alerts = await adminService.getMyAlerts(req.user.uid);
    res.json({ success: true, alerts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getAlertById = async (req, res) => {
  try {
    const alert = await adminService.getAlertById(req.params.id);
    res.json({ success: true, alert });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updateAlert = async (req, res) => {
  try {
    const { status, adminNotes } = req.body;
    
    if (!['open', 'in_progress', 'resolved'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const result = await adminService.updateAlertStatus(
      req.params.id, status, adminNotes
    );
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const deleteAlert = async (req, res) => {
  try {
    await adminService.deleteAlert(req.params.id);
    res.json({ success: true, message: 'Alert deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updateTrainer = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('users').doc(id).update({
      ...req.body, updatedAt: new Date().toISOString()
    });
    res.json({ success: true });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const deleteTrainer = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('users').doc(id).delete();
    res.json({ success: true });
  } catch(e) { res.status(500).json({error: e.message}); }
};

const assignTrainer = async (req, res) => {
  try {
    const { uid } = req.params; // member uid
    const { assignedTrainerId } = req.body;
    
    if (!assignedTrainerId) {
      return res.status(400).json({ error: 'Trainer ID is required' });
    }

    const result = await adminService.assignTrainer(uid, assignedTrainerId);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── TRAINER REQUESTS ──────────────────────────────

// POST /api/admin/trainer-requests (member creates)
const createTrainerRequest = async (req, res) => {
  try {
    const { trainerId, message, preferredDate, preferredTime } = req.body;
    const uid = req.user.uid;

    const memberDoc = await db.collection('users').doc(uid).get();
    const member = memberDoc.data();

    const trainerDoc = await db.collection('users').doc(trainerId).get();
    if (!trainerDoc.exists) return res.status(404).json({ error: 'Trainer not found' });
    const trainer = trainerDoc.data();

    // Check pending
    const existing = await db.collection('trainerRequests')
      .where('memberUid', '==', uid).where('status', '==', 'pending').get();
    if (!existing.empty) return res.status(400).json({ error: 'You already have a pending request' });

    const request = {
      memberUid: uid, memberName: member.name, memberEmail: member.email || '',
      trainerId, trainerName: trainer.name, trainerEmail: trainer.email || '',
      message: message || '', status: 'pending', adminNote: '',
      preferredDate: preferredDate || null,
      preferredTime: preferredTime || null,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
    };
    const saved = await db.collection('trainerRequests').add(request);

    sendTrainerRequestEmail(trainer, member, request).catch(err =>
      console.error('Request email failed:', err.message));

    res.json({ success: true, requestId: saved.id, message: 'Request sent! Admin will review it soon.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// GET /api/admin/trainer-requests (admin)
const getAllRequests = async (req, res) => {
  try {
    const snap = await db.collection('trainerRequests').get();
    const requests = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const stats = {
      total: requests.length,
      pending: requests.filter(r => r.status === 'pending').length,
      approved: requests.filter(r => r.status === 'approved').length,
      rejected: requests.filter(r => r.status === 'rejected').length,
    };
    res.json({ success: true, requests, stats });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// GET /api/admin/trainer-requests/my (member)
const getMyRequests = async (req, res) => {
  try {
    const snap = await db.collection('trainerRequests')
      .where('memberUid', '==', req.user.uid).get();
    const requests = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ success: true, requests });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

const updateRequest = async (req, res) => {
  try {
    const { 
      status, 
      adminNote,
      sessionDate,
      sessionTime,
      sessionLocation,
      sessionNotes,
      sessionDuration,
    } = req.body;

    const requestId  = req.params.id;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const requestDoc = await db.collection('trainerRequests')
      .doc(requestId).get();
    if (!requestDoc.exists) {
      return res.status(404).json({ error: 'Request not found' });
    }

    const request = requestDoc.data();

    // Build session info object
    const sessionInfo = status === 'approved' ? {
      sessionDate:     sessionDate || '',
      sessionTime:     sessionTime || '',
      sessionLocation: sessionLocation || 'Main Gym Floor',
      sessionNotes:    sessionNotes || '',
      sessionDuration: sessionDuration || '60 minutes',
    } : null;

    // Update request in Firestore
    await db.collection('trainerRequests').doc(requestId).update({
      status,
      adminNote:   adminNote || '',
      sessionInfo: sessionInfo,
      updatedAt:   new Date().toISOString(),
    });

    // Get member and trainer full details
    const memberDoc  = await db.collection('users')
      .doc(request.memberUid).get();
    const trainerDoc = await db.collection('users')
      .doc(request.trainerId).get();

    const member  = { uid: request.memberUid,  ...memberDoc.data() };
    const trainer = { uid: request.trainerId, ...trainerDoc.data() };

    if (status === 'approved') {
      // Assign trainer to member in Firestore
      await db.collection('users').doc(request.memberUid).update({
        assignedTrainerId: request.trainerId,
        trainerName:       trainer.name,
        trainerPhone:      trainer.phone || '',
        trainerEmail:      trainer.email || '',
        firstSessionInfo:  sessionInfo,
        updatedAt:         new Date().toISOString(),
      });

      // Send approval email to MEMBER
      // (includes trainer contact + session details)
      sendRequestApprovedToMember(
        member, trainer, sessionInfo
      ).catch(err =>
        console.error('Member approval email failed:', err.message)
      );

      // Send approval email to TRAINER
      // (includes member contact + session details)
      sendRequestApprovedToTrainer(
        trainer, member, sessionInfo
      ).catch(err =>
        console.error('Trainer approval email failed:', err.message)
      );

    } else {
      // Send rejection email to member
      sendRequestRejectedToMember(
        member, trainer, adminNote
      ).catch(err =>
        console.error('Rejection email failed:', err.message)
      );
    }

    res.json({
      success: true,
      message: `Request ${status} successfully. Emails sent to both parties.`
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── CLASS ENROLLMENT (Member) ─────────────────────

// GET /api/admin/classes/all (members see upcoming)
const getAllClassesForMembers = async (req, res) => {
  try {
    const snap = await db.collection('classes').get();
    const now = new Date();
    const classes = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      .filter(c => {
        if (c.dateTime) return new Date(c.dateTime) >= now;
        if (c.date) return new Date(c.date) >= new Date(now.toISOString().slice(0, 10));
        return true;
      })
      .sort((a, b) => new Date(a.dateTime || a.date || 0) - new Date(b.dateTime || b.date || 0));
    res.json({ success: true, classes });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// POST /api/admin/classes/:id/enroll
const enrollInClass = async (req, res) => {
  try {
    const uid = req.user.uid;
    const classRef = db.collection('classes').doc(req.params.id);
    const classDoc = await classRef.get();
    if (!classDoc.exists) return res.status(404).json({ error: 'Class not found' });

    const gymClass = classDoc.data();
    const enrolled = gymClass.enrolledMembers || [];
    if (enrolled.includes(uid)) return res.status(400).json({ error: 'Already enrolled' });
    if (enrolled.length >= (gymClass.capacity || 20)) return res.status(400).json({ error: 'Class is full' });

    await classRef.update({ enrolledMembers: [...enrolled, uid] });
    res.json({ success: true, message: 'Enrolled successfully!' });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// DELETE /api/admin/classes/:id/enroll
const cancelEnrollment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const classRef = db.collection('classes').doc(req.params.id);
    const classDoc = await classRef.get();
    if (!classDoc.exists) return res.status(404).json({ error: 'Class not found' });

    const enrolled = classDoc.data().enrolledMembers || [];
    await classRef.update({ enrolledMembers: enrolled.filter(id => id !== uid) });
    res.json({ success: true, message: 'Enrollment cancelled' });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

const getAllMessages = async (req, res) => {
  try {
    const snap = await db.collection('contactMessages').get();
    const messages = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const stats = {
      total:    messages.length,
      open:     messages.filter(m => m.status === 'open').length,
      replied:  messages.filter(m => m.status === 'replied').length,
    };

    res.json({ success: true, messages, stats });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const replyToMessage = async (req, res) => {
  try {
    const { adminReply } = req.body;
    const msgRef = db.collection('contactMessages').doc(req.params.id);
    const msgDoc = await msgRef.get();

    if (!msgDoc.exists) {
      return res.status(404).json({ error: 'Message not found' });
    }

    const msg = msgDoc.data();

    await msgRef.update({
      adminReply,
      status:    'replied',
      repliedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      replies: [...(msg.replies || []), { from: 'admin', text: adminReply, createdAt: new Date().toISOString() }],
    });

    // Send reply email to member
    const { transporter } = require('../services/email.service');
    const nodemailer = require('nodemailer');
    const transporterObj = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const replyHtml = `
      <div style="font-family:Arial; max-width:600px; margin:auto;">
        <div style="background:linear-gradient(135deg,#E8845C,#D4673A);
          padding:30px; text-align:center; border-radius:16px 16px 0 0;">
          <h2 style="color:white; margin:0;">Admin Reply</h2>
        </div>
        <div style="background:white; padding:30px; 
          border-radius:0 0 16px 16px;
          box-shadow:0 4px 20px rgba(0,0,0,0.08);">
          <p>Hello <strong>${msg.memberName}</strong>,</p>
          <p>The admin team has replied to your message:</p>
          <div style="background:#F8F9FA; border-left:4px solid #E8845C;
            padding:16px; border-radius:8px; margin:16px 0;">
            <p style="margin:0; font-weight:bold; color:#9E9E9E; 
              font-size:12px;">YOUR MESSAGE:</p>
            <p style="margin:8px 0 0;">${msg.message}</p>
          </div>
          <div style="background:#F0FDF4; border-left:4px solid #7CB342;
            padding:16px; border-radius:8px; margin:16px 0;">
            <p style="margin:0; font-weight:bold; color:#7CB342;
              font-size:12px;">ADMIN REPLY:</p>
            <p style="margin:8px 0 0;">${adminReply}</p>
          </div>
          <p style="color:#555;">
            Check the FitFusion app for more updates.
          </p>
        </div>
      </div>
    `;

    await transporterObj.sendMail({
      from:    process.env.EMAIL_FROM || '"FitFusion" <${process.env.EMAIL_USER}>',
      to:      msg.memberEmail,
      subject: `📧 Admin replied to your message — FitFusion`,
      html:    replyHtml,
    });

    res.json({ success: true, message: 'Reply sent successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getRevenueStats, getMemberStats,
  addTrainer, getTrainers, updateTrainer, deleteTrainer,
  updatePlan, deletePlan,
  getDashboardStats,
  getAllMembers, getMemberById, getAllPayments, getAllPlans, createPlan,
  getAllClasses, createClass, updateClass, deleteClass,
  createAlert, getAllAlerts, getMyAlerts, getAlertById, updateAlert, deleteAlert,
  assignTrainer,
  createTrainerRequest, getAllRequests, getMyRequests, updateRequest,
  getAllClassesForMembers, enrollInClass, cancelEnrollment,
  getAllMessages, replyToMessage,
};
