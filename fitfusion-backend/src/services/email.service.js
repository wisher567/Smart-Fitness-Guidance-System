const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// EMAIL 1: Welcome email when trainer added
const sendTrainerWelcomeEmail = async (trainer) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn(`[Warning] EMAIL creds not set. Skipping welcome email to ${trainer.email}`);
    return null;
  }

  const html = `<!DOCTYPE html><html><head><style>
    body{font-family:Arial,sans-serif;background:#f8f8f8;margin:0;padding:0}
    .c{max-width:600px;margin:40px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hd{background:linear-gradient(135deg,#E8845C,#D4673A);padding:40px;text-align:center}
    .hd h1{color:#fff;margin:0;font-size:28px}.hd p{color:rgba(255,255,255,.85);margin:8px 0 0}
    .bd{padding:36px}.gr{font-size:20px;font-weight:700;color:#1A1A1A;margin-bottom:16px}
    .tx{color:#555;line-height:1.7;font-size:15px}
    .ic{background:#FDF0EB;border-left:4px solid #E8845C;border-radius:8px;padding:16px;margin:24px 0}
    .ic p{margin:6px 0;color:#1A1A1A;font-size:14px}.ic strong{color:#E8845C}
    .ft{background:#f8f8f8;padding:24px;text-align:center;color:#9E9E9E;font-size:12px;border-top:1px solid #eee}
  </style></head><body><div class="c">
    <div class="hd"><div style="font-size:28px;font-weight:900;margin-bottom:12px;color:#fff;letter-spacing:2px">FF</div>
      <h1>Welcome to FitFusion!</h1><p>You have been added as a Personal Trainer</p></div>
    <div class="bd">
      <p class="gr">Hello, ${trainer.name}! 👋</p>
      <p class="tx">We are excited to welcome you to the FitFusion Gym team! Here are your details:</p>
      <div class="ic">
        <p><strong>Name:</strong> ${trainer.name}</p>
        <p><strong>Email:</strong> ${trainer.email}</p>
        <p><strong>Specialization:</strong> ${trainer.specialization || 'General Fitness'}</p>
        <p><strong>Role:</strong> Personal Trainer</p>
      </div>
      <p class="tx">You will receive email notifications whenever:</p>
      <ul style="color:#555;line-height:2;font-size:15px">
        <li>A new class is scheduled and assigned to you</li>
        <li>A member requests your training assistance</li>
        <li>Your class schedule is updated</li>
      </ul>
      <p class="tx">Welcome aboard! 💪</p>
    </div>
    <div class="ft"><p>&copy; 2026 FitFusion Gym Management System</p></div>
  </div></body></html>`;

  const info = await transporter.sendMail({
    from: process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to: trainer.email,
    subject: '🏋️ Welcome to FitFusion Gym Team!',
    html,
  });
  console.log(`Welcome email sent to ${trainer.email} (${info.messageId})`);
  return info;
};

// EMAIL 2: Class schedule email to trainer
const sendClassScheduleEmail = async (trainer, gymClass) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn(`[Warning] EMAIL creds not set. Skipping class email to ${trainer.email}`);
    return null;
  }

  const html = `<!DOCTYPE html><html><head><style>
    body{font-family:Arial,sans-serif;background:#f8f8f8;margin:0;padding:0}
    .c{max-width:600px;margin:40px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hd{background:linear-gradient(135deg,#E8845C,#D4673A);padding:40px;text-align:center}
    .hd h1{color:#fff;margin:0;font-size:26px}.hd p{color:rgba(255,255,255,.85);margin:8px 0 0}
    .bd{padding:36px}.tx{color:#555;line-height:1.7;font-size:15px}
    .cc{background:#FDF0EB;border-radius:12px;padding:20px;margin:24px 0}
    .cc h3{color:#E8845C;margin:0 0 12px;font-size:20px}
    .dr{margin:8px 0;color:#1A1A1A;font-size:14px}
    .ft{background:#f8f8f8;padding:24px;text-align:center;color:#9E9E9E;font-size:12px;border-top:1px solid #eee}
  </style></head><body><div class="c">
    <div class="hd"><div style="font-size:40px;margin-bottom:12px">📅</div>
      <h1>New Class Assigned!</h1><p>You have a new class scheduled</p></div>
    <div class="bd">
      <p style="font-size:18px;font-weight:700;color:#1A1A1A">Hello, ${trainer.name}!</p>
      <p class="tx">A new class has been assigned to you:</p>
      <div class="cc">
        <h3>${gymClass.name}</h3>
        <p class="dr">📅 ${gymClass.date || ''} at ${gymClass.time || ''}</p>
        <p class="dr">⏱️ ${gymClass.duration || 60} minutes</p>
        <p class="dr">📍 ${gymClass.location || 'Main Studio'}</p>
        <p class="dr">👥 Max capacity: ${gymClass.capacity || 20} members</p>
        ${gymClass.description ? `<p class="dr">📝 ${gymClass.description}</p>` : ''}
      </div>
      <p class="tx">Please arrive 10 minutes before class starts. Good luck! 💪</p>
    </div>
    <div class="ft"><p>&copy; 2026 FitFusion Gym Management System</p></div>
  </div></body></html>`;

  const info = await transporter.sendMail({
    from: process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to: trainer.email,
    subject: `📅 New Class Assigned: ${gymClass.name}`,
    html,
  });
  console.log(`Class email sent to ${trainer.email} (${info.messageId})`);
  return info;
};

// EMAIL 3: Member requests trainer
const sendTrainerRequestEmail = async (trainer, member, request) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn(`[Warning] EMAIL creds not set. Skipping request email to ${trainer.email}`);
    return null;
  }

  const html = `<!DOCTYPE html><html><head><style>
    body{font-family:Arial,sans-serif;background:#f8f8f8;margin:0;padding:0}
    .c{max-width:600px;margin:40px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hd{background:linear-gradient(135deg,#E8845C,#D4673A);padding:40px;text-align:center}
    .hd h1{color:#fff;margin:0;font-size:26px}
    .bd{padding:36px}.tx{color:#555;line-height:1.7;font-size:15px}
    .mc{background:#FDF0EB;border-radius:12px;padding:20px;margin:24px 0}
    .mc h3{color:#E8845C;margin:0 0 12px}
    .dt{margin:8px 0;color:#1A1A1A;font-size:14px}.dt strong{color:#E8845C}
    .nb{background:#fff8f0;border:1px solid #E8845C;border-radius:8px;padding:14px;margin:16px 0}
    .nb p{margin:0;color:#555;font-style:italic}
    .ft{background:#f8f8f8;padding:24px;text-align:center;color:#9E9E9E;font-size:12px;border-top:1px solid #eee}
  </style></head><body><div class="c">
    <div class="hd"><div style="font-size:40px;margin-bottom:12px">🙋</div>
      <h1>New Training Request!</h1></div>
    <div class="bd">
      <p style="font-size:18px;font-weight:700;color:#1A1A1A">Hello, ${trainer.name}!</p>
      <p class="tx">A FitFusion member has requested your personal training assistance.</p>
      <div class="mc">
        <h3>👤 ${member.name}</h3>
        <p class="dt"><strong>Email:</strong> ${member.email}</p>
        <p class="dt"><strong>Fitness Goal:</strong> ${(member.fitnessGoal || 'general fitness').replace(/_/g, ' ')}</p>
        <p class="dt"><strong>Fitness Level:</strong> ${member.fitnessLevel || 'beginner'}</p>
      </div>
      ${request.message ? `<p class="tx"><strong>Member's message:</strong></p>
      <div class="nb"><p>"${request.message}"</p></div>` : ''}
      <p class="tx">The admin will review and approve this request.</p>
    </div>
    <div class="ft"><p>&copy; 2026 FitFusion Gym Management System</p></div>
  </div></body></html>`;

  const info = await transporter.sendMail({
    from: process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to: trainer.email,
    subject: `🙋 New Training Request from ${member.name}`,
    html,
  });
  console.log(`Request email sent to ${trainer.email} (${info.messageId})`);
  return info;
};

// ─────────────────────────────────────────
const sendRequestApprovedToMember = async (member, trainer, session) => {
  const sessionDate = session?.sessionDate
    ? new Date(session.sessionDate).toLocaleDateString('en-LK', {
        weekday: 'long', year: 'numeric',
        month: 'long', day: 'numeric'
      })
    : 'To be confirmed';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background: #f8f8f8; 
          margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; 
          background: white; border-radius: 16px; overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { background: linear-gradient(135deg, #7CB342, #558B2F);
          padding: 40px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 26px; }
        .header p { color: rgba(255,255,255,0.85); margin: 8px 0 0; }
        .body { padding: 36px; }
        .text { color: #555; line-height: 1.7; font-size: 15px; }

        .session-card { 
          background: linear-gradient(135deg, #E8845C, #D4673A);
          border-radius: 16px; padding: 24px; margin: 24px 0;
          color: white; }
        .session-card h3 { margin: 0 0 16px; font-size: 18px; 
          opacity: 0.9; }
        .session-row { display: flex; align-items: center; 
          margin: 10px 0; }
        .session-icon { font-size: 18px; margin-right: 12px; 
          width: 24px; }
        .session-text { font-size: 15px; font-weight: bold; }
        .session-label { font-size: 11px; opacity: 0.8; 
          margin-top: 1px; }

        .contact-card { background: #F8F9FA; border-radius: 14px; 
          padding: 20px; margin: 20px 0; 
          border: 1px solid #E8845C; }
        .contact-card h3 { color: #E8845C; margin: 0 0 14px; 
          font-size: 16px; }
        .contact-row { display: flex; align-items: center; 
          margin: 8px 0; }
        .contact-icon { font-size: 16px; margin-right: 10px; 
          width: 20px; }
        .contact-text { color: #1A1A1A; font-size: 14px; }
        .contact-text a { color: #E8845C; 
          text-decoration: none; }

        .tips-box { background: #FDF0EB; border-radius: 12px; 
          padding: 16px; margin: 20px 0; }
        .tips-box h4 { color: #E8845C; margin: 0 0 10px; }
        .tips-box ul { margin: 0; padding-left: 20px; 
          color: #555; }
        .tips-box li { margin: 6px 0; font-size: 13px; }

        .footer { background: #f8f8f8; padding: 24px; 
          text-align: center; color: #9E9E9E; font-size: 12px; 
          border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">

        <div class="header">
          <div style="font-size:48px; margin-bottom:12px;">🎉</div>
          <h1>Trainer Request Approved!</h1>
          <p>You have been assigned a personal trainer</p>
        </div>

        <div class="body">
          <p style="font-size:18px; font-weight:bold; color:#1A1A1A;">
            Congratulations, ${member.name}! 🎊
          </p>
          <p class="text">
            Great news! Your request for a personal trainer has been 
            approved. You have been assigned to 
            <strong>${trainer.name}</strong> who specializes in 
            <strong>${trainer.specialization || 'General Fitness'}</strong>.
          </p>

          <!-- First Session Card -->
          <div class="session-card">
            <h3>📅 Your First Training Session</h3>
            <div class="session-row">
              <span class="session-icon">📅</span>
              <div>
                <div class="session-text">${sessionDate}</div>
                <div class="session-label">Date</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">🕐</span>
              <div>
                <div class="session-text">
                  ${session?.sessionTime || 'To be confirmed'}
                </div>
                <div class="session-label">Time</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">📍</span>
              <div>
                <div class="session-text">
                  ${session?.sessionLocation || 'Main Gym Floor'}
                </div>
                <div class="session-label">Location</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">⏱️</span>
              <div>
                <div class="session-text">
                  ${session?.sessionDuration || '60 minutes'}
                </div>
                <div class="session-label">Duration</div>
              </div>
            </div>
            ${session?.sessionNotes ? `
            <div class="session-row">
              <span class="session-icon">📝</span>
              <div>
                <div class="session-text">${session.sessionNotes}</div>
                <div class="session-label">Notes from Admin</div>
              </div>
            </div>` : ''}
          </div>

          <!-- Trainer Contact Card -->
          <div class="contact-card">
            <h3>👨💼 Your Trainer's Contact Details</h3>
            <div class="contact-row">
              <span class="contact-icon">👤</span>
              <span class="contact-text">
                <strong>${trainer.name}</strong>
              </span>
            </div>
            <div class="contact-row">
              <span class="contact-icon">🏋️</span>
              <span class="contact-text">
                ${trainer.specialization || 'General Fitness'}
              </span>
            </div>
            ${trainer.phone ? `
            <div class="contact-row">
              <span class="contact-icon">📞</span>
              <span class="contact-text">
                <a href="tel:${trainer.phone}">${trainer.phone}</a>
              </span>
            </div>` : ''}
            ${trainer.email ? `
            <div class="contact-row">
              <span class="contact-icon">✉️</span>
              <span class="contact-text">
                <a href="mailto:${trainer.email}">${trainer.email}</a>
              </span>
            </div>` : ''}
            ${trainer.bio ? `
            <div class="contact-row" style="margin-top:10px;">
              <span class="contact-icon">💬</span>
              <span class="contact-text" 
                style="color:#555; font-style:italic;">
                "${trainer.bio}"
              </span>
            </div>` : ''}
          </div>

          <!-- Tips -->
          <div class="tips-box">
            <h4>💡 Tips for Your First Session</h4>
            <ul>
              <li>Arrive 10 minutes early</li>
              <li>Wear comfortable workout clothes</li>
              <li>Bring a water bottle</li>
              <li>Let your trainer know about any injuries</li>
              <li>Open the FitFusion app to track your workout</li>
            </ul>
          </div>

          <p class="text">
            Feel free to contact your trainer before the session 
            if you have any questions. We wish you the best on 
            your fitness journey! 💪
          </p>
        </div>

        <div class="footer">
          <p>© 2026 FitFusion Gym Management System</p>
          <p>Open the FitFusion app to track your progress</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      member.email,
    subject: `✅ Trainer Assigned! First session on ${sessionDate}`,
    html,
  });
};

// ─────────────────────────────────────────
// EMAIL: Approval email to TRAINER
// Includes member contact + session time
// ─────────────────────────────────────────
const sendRequestApprovedToTrainer = async (trainer, member, session) => {
  const sessionDate = session?.sessionDate
    ? new Date(session.sessionDate).toLocaleDateString('en-LK', {
        weekday: 'long', year: 'numeric',
        month: 'long', day: 'numeric'
      })
    : 'To be confirmed';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background: #f8f8f8;
          margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto;
          background: white; border-radius: 16px; overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { background: linear-gradient(135deg, #E8845C, #D4673A);
          padding: 40px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 26px; }
        .body { padding: 36px; }
        .text { color: #555; line-height: 1.7; font-size: 15px; }

        .session-card {
          background: linear-gradient(135deg, #1E2A3B, #2D3F56);
          border-radius: 16px; padding: 24px; margin: 24px 0;
          color: white; }
        .session-card h3 { margin: 0 0 16px; font-size: 18px;
          opacity: 0.9; }
        .session-row { display: flex; align-items: flex-start;
          margin: 10px 0; }
        .session-icon { font-size: 18px; margin-right: 12px;
          width: 24px; margin-top: 2px; }
        .session-text { font-size: 15px; font-weight: bold; }
        .session-label { font-size: 11px; opacity: 0.7;
          margin-top: 2px; }

        .member-card { background: #F8F9FA; border-radius: 14px;
          padding: 20px; margin: 20px 0;
          border-left: 4px solid #E8845C; }
        .member-card h3 { color: #E8845C; margin: 0 0 14px; }
        .info-row { display: flex; margin: 8px 0; }
        .info-label { color: #9E9E9E; font-size: 13px;
          width: 140px; flex-shrink: 0; }
        .info-value { color: #1A1A1A; font-size: 13px;
          font-weight: 600; }
        .info-value a { color: #E8845C; text-decoration: none; }

        .alert-box { background: #FDF0EB; border-radius: 12px;
          padding: 16px; margin: 20px 0;
          border: 1px solid #E8845C30; }
        .footer { background: #f8f8f8; padding: 24px;
          text-align: center; color: #9E9E9E; font-size: 12px;
          border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">

        <div class="header">
          <div style="font-size:48px; margin-bottom:12px;">💪</div>
          <h1>New Client Assigned!</h1>
          <p>You have a new member to train</p>
        </div>

        <div class="body">
          <p style="font-size:18px; font-weight:bold; color:#1A1A1A;">
            Hello, ${trainer.name}!
          </p>
          <p class="text">
            A new member has been assigned to you for personal training.
            Here are their details and your first scheduled session:
          </p>

          <!-- Session Details -->
          <div class="session-card">
            <h3>📅 First Training Session</h3>
            <div class="session-row">
              <span class="session-icon">📅</span>
              <div>
                <div class="session-text">${sessionDate}</div>
                <div class="session-label">Date</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">🕐</span>
              <div>
                <div class="session-text">
                  ${session?.sessionTime || 'To be confirmed'}
                </div>
                <div class="session-label">Time</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">📍</span>
              <div>
                <div class="session-text">
                  ${session?.sessionLocation || 'Main Gym Floor'}
                </div>
                <div class="session-label">Location</div>
              </div>
            </div>
            <div class="session-row">
              <span class="session-icon">⏱️</span>
              <div>
                <div class="session-text">
                  ${session?.sessionDuration || '60 minutes'}
                </div>
                <div class="session-label">Duration</div>
              </div>
            </div>
            ${session?.sessionNotes ? `
            <div class="session-row">
              <span class="session-icon">📝</span>
              <div>
                <div class="session-text">${session.sessionNotes}</div>
                <div class="session-label">Admin Notes</div>
              </div>
            </div>` : ''}
          </div>

          <!-- Member Info -->
          <div class="member-card">
            <h3>👤 Your New Client</h3>
            <div class="info-row">
              <span class="info-label">Name</span>
              <span class="info-value">${member.name}</span>
            </div>
            ${member.phone ? `
            <div class="info-row">
              <span class="info-label">Phone</span>
              <span class="info-value">
                <a href="tel:${member.phone}">${member.phone}</a>
              </span>
            </div>` : ''}
            ${member.email ? `
            <div class="info-row">
              <span class="info-label">Email</span>
              <span class="info-value">
                <a href="mailto:${member.email}">${member.email}</a>
              </span>
            </div>` : ''}
            <div class="info-row">
              <span class="info-label">Age</span>
              <span class="info-value">${member.age || 'N/A'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">BMI</span>
              <span class="info-value">
                ${member.bmi || 'N/A'}
              </span>
            </div>
            <div class="info-row">
              <span class="info-label">Fitness Goal</span>
              <span class="info-value" style="color:#E8845C;">
                ${(member.fitnessGoal || 'general fitness')
                  .replace(/_/g, ' ')
                  .replace(/\b\w/g, l => l.toUpperCase())}
              </span>
            </div>
            <div class="info-row">
              <span class="info-label">Fitness Level</span>
              <span class="info-value">
                ${(member.fitnessLevel || 'Beginner')
                  .replace(/\b\w/g, l => l.toUpperCase())}
              </span>
            </div>
            ${member.medicalConditions?.length ? `
            <div class="info-row">
              <span class="info-label">Medical</span>
              <span class="info-value" style="color:#EF4444;">
                ⚠️ ${member.medicalConditions.join(', ')}
              </span>
            </div>` : ''}
            ${member.weight && member.height ? `
            <div class="info-row">
              <span class="info-label">Weight / Height</span>
              <span class="info-value">
                ${member.weight}kg / ${member.height}cm
              </span>
            </div>` : ''}
          </div>

          <!-- Preparation tips -->
          <div class="alert-box">
            <p style="margin:0; color:#D4673A; font-weight:bold;">
              💡 Preparation Checklist
            </p>
            <ul style="margin:10px 0 0; padding-left:20px; 
              color:#555; font-size:13px; line-height:1.8;">
              <li>Contact the member before the session to introduce yourself</li>
              <li>Review their fitness goal: 
                <strong>${(member.fitnessGoal || 'general fitness')
                  .replace(/_/g, ' ')}</strong>
              </li>
              ${member.medicalConditions?.length
                ? '<li style="color:#EF4444;">⚠️ Be aware of their medical conditions</li>'
                : ''}
              <li>Prepare a beginner assessment workout plan</li>
              <li>Arrive at ${session?.sessionLocation || 'the gym'} 
                on time</li>
            </ul>
          </div>

          <p class="text">
            Please contact the member using the details above 
            to confirm the session and introduce yourself.
            Good luck with your new client! 🏋️
          </p>
        </div>

        <div class="footer">
          <p>© 2026 FitFusion Gym Management System</p>
          <p>For any changes please contact the admin team</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      trainer.email,
    subject: `💪 New Client Assigned: ${member.name} — First session ${sessionDate}`,
    html,
  });
};

// ─────────────────────────────────────────
// EMAIL: Rejection email to MEMBER
// ─────────────────────────────────────────
const sendRequestRejectedToMember = async (member, trainer, adminNote) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background: #f8f8f8;
          margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto;
          background: white; border-radius: 16px; overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { background: linear-gradient(135deg, #64748B, #475569);
          padding: 40px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 26px; }
        .body { padding: 36px; }
        .text { color: #555; line-height: 1.7; font-size: 15px; }
        .note-box { background: #FEF2F2; border-radius: 12px;
          padding: 16px; margin: 20px 0;
          border-left: 4px solid #EF4444; }
        .action-box { background: #FDF0EB; border-radius: 12px;
          padding: 16px; margin: 20px 0; }
        .footer { background: #f8f8f8; padding: 24px;
          text-align: center; color: #9E9E9E; font-size: 12px;
          border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div style="font-size:48px; margin-bottom:12px;">📋</div>
          <h1>Trainer Request Update</h1>
        </div>
        <div class="body">
          <p style="font-size:18px; font-weight:bold; color:#1A1A1A;">
            Hello, ${member.name}
          </p>
          <p class="text">
            We have reviewed your request for trainer 
            <strong>${trainer.name}</strong>. 
            Unfortunately we are unable to approve this request 
            at this time.
          </p>
          ${adminNote ? `
          <div class="note-box">
            <p style="margin:0; color:#EF4444; font-weight:bold; 
              margin-bottom:6px;">
              📝 Note from Admin:
            </p>
            <p style="margin:0; color:#555;">${adminNote}</p>
          </div>` : ''}
          <div class="action-box">
            <p style="margin:0; color:#E8845C; font-weight:bold;
              margin-bottom:8px;">
              💡 What you can do:
            </p>
            <ul style="margin:0; padding-left:20px; color:#555;
              font-size:14px; line-height:1.8;">
              <li>Open the FitFusion app and request a different trainer</li>
              <li>Contact the gym admin for more information</li>
              <li>Try again when trainer availability opens up</li>
            </ul>
          </div>
          <p class="text">
            We apologize for any inconvenience. Our team is working 
            to ensure every member gets the support they need.
          </p>
        </div>
        <div class="footer">
          <p>© 2026 FitFusion Gym Management System</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      member.email,
    subject: `📋 Update on your trainer request`,
    html,
  });
};

const sendWelcomeEmail = async (member) => {
  const bmiCategory = 
    member.bmi < 18.5 ? 'Underweight' :
    member.bmi < 25   ? 'Normal weight' :
    member.bmi < 30   ? 'Overweight' : 'Obese';

  const goalTips = {
    weight_loss:     'Focus on cardio + calorie deficit diet',
    muscle_gain:     'Focus on strength training + high protein diet',
    endurance:       'Focus on cardio + consistent training',
    flexibility:     'Focus on stretching + yoga sessions',
    general_fitness: 'Mix of cardio, strength and flexibility',
  };

  const tip = goalTips[member.fitnessGoal] || 
    'Stay consistent and track your progress!';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; 
          background: #f8f8f8; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto;
          background: white; border-radius: 16px; 
          overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { 
          background: linear-gradient(135deg, #E8845C, #D4673A);
          padding: 50px 40px; text-align: center; }
        .logo { font-size: 56px; margin-bottom: 12px; }
        .header h1 { color: white; margin: 0; font-size: 30px;
          font-weight: bold; }
        .header p { color: rgba(255,255,255,0.85); 
          margin: 8px 0 0; font-size: 16px; }
        .body { padding: 40px; }
        .greeting { font-size: 22px; font-weight: bold; 
          color: #1A1A1A; margin-bottom: 12px; }
        .text { color: #555; line-height: 1.8; font-size: 15px;
          margin-bottom: 16px; }

        .stats-grid { display: grid; 
          grid-template-columns: 1fr 1fr; 
          gap: 12px; margin: 24px 0; }
        .stat-card { background: #FDF0EB; 
          border-radius: 12px; padding: 16px;
          text-align: center; }
        .stat-value { font-size: 24px; font-weight: bold;
          color: #E8845C; }
        .stat-label { font-size: 12px; color: #9E9E9E;
          margin-top: 4px; }

        .goal-card { 
          background: linear-gradient(135deg, #0F1923, #1E2A3B);
          border-radius: 14px; padding: 20px; margin: 24px 0; }
        .goal-card h3 { color: #E8845C; margin: 0 0 8px;
          font-size: 16px; }
        .goal-card p { color: white; margin: 0; 
          font-size: 14px; line-height: 1.6; }
        .goal-badge { display: inline-block; 
          background: #E8845C; color: white;
          padding: 4px 12px; border-radius: 20px;
          font-size: 12px; font-weight: bold;
          margin-bottom: 10px;
          text-transform: capitalize; }

        .features-section { margin: 28px 0; }
        .features-section h3 { color: #1A1A1A; font-size: 17px;
          font-weight: bold; margin-bottom: 16px; }
        .feature-item { display: flex; align-items: flex-start;
          margin-bottom: 14px; }
        .feature-icon { font-size: 22px; margin-right: 14px;
          margin-top: 2px; flex-shrink: 0; }
        .feature-text h4 { margin: 0 0 3px; color: #1A1A1A;
          font-size: 14px; font-weight: bold; }
        .feature-text p { margin: 0; color: #9E9E9E;
          font-size: 13px; }

        .points-banner { 
          background: linear-gradient(135deg, #E8845C, #D4673A);
          border-radius: 14px; padding: 20px; margin: 24px 0;
          text-align: center; color: white; }
        .points-banner h3 { margin: 0 0 6px; font-size: 20px; }
        .points-banner p { margin: 0; opacity: 0.9; 
          font-size: 14px; }

        .tips-box { background: #F8F9FA; border-radius: 12px;
          padding: 18px; margin: 20px 0;
          border-left: 4px solid #E8845C; }
        .tips-box h4 { color: #E8845C; margin: 0 0 10px;
          font-size: 15px; }
        .tips-box p { color: #555; margin: 0; font-size: 14px;
          line-height: 1.6; }

        .cta-button { display: block; text-align: center;
          background: linear-gradient(135deg, #E8845C, #D4673A);
          color: white; padding: 16px 32px;
          border-radius: 14px; text-decoration: none;
          font-weight: bold; font-size: 16px;
          margin: 28px 0; }

        .footer { background: #f8f8f8; padding: 28px;
          text-align: center; color: #9E9E9E; font-size: 12px;
          border-top: 1px solid #eee; }
        .footer a { color: #E8845C; text-decoration: none; }
      </style>
    </head>
    <body>
      <div class="container">

        <!-- Header -->
        <div class="header">
          <div class="logo" style="font-size:28px;font-weight:900;letter-spacing:2px">FF</div>
          <h1>Welcome to FitFusion!</h1>
          <p>Your AI-powered fitness journey starts now</p>
        </div>

        <!-- Body -->
        <div class="body">
          <p class="greeting">Hello, ${member.name}! 👋</p>
          <p class="text">
            We are thrilled to have you join the FitFusion family! 
            Your profile has been created successfully and you are 
            all set to begin your fitness transformation journey.
          </p>

          <!-- Profile Stats -->
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-value">${member.bmi}</div>
              <div class="stat-label">Your BMI</div>
              <div style="font-size:11px; color:#E8845C; 
                margin-top:3px;">${bmiCategory}</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">${member.weight}kg</div>
              <div class="stat-label">Current Weight</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">${member.age}</div>
              <div class="stat-label">Age</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">${member.height}cm</div>
              <div class="stat-label">Height</div>
            </div>
          </div>

          <!-- Fitness Goal -->
          <div class="goal-card">
            <div class="goal-badge">
              🎯 ${(member.fitnessGoal || 'general fitness').replace(/_/g, ' ')}
            </div>
            <h3>Your Personalized Goal Plan</h3>
            <p>${tip}</p>
          </div>

          <!-- App Features -->
          <div class="features-section">
            <h3>🚀 What you can do with FitFusion</h3>
            <div class="feature-item">
              <span class="feature-icon">🤖</span>
              <div class="feature-text">
                <h4>AI Workout Recommendations</h4>
                <p>Get personalized workout plans based on 
                  your goals and fitness level</p>
              </div>
            </div>
            <div class="feature-item">
              <span class="feature-icon">🥗</span>
              <div class="feature-text">
                <h4>Smart Nutrition Planning</h4>
                <p>AI meal plans with Sri Lankan food options 
                  matched to your calorie targets</p>
              </div>
            </div>
            <div class="feature-item">
              <span class="feature-icon">📸</span>
              <div class="feature-text">
                <h4>Food Scanner</h4>
                <p>Take a photo of any meal and get instant 
                  calorie and nutrition breakdown</p>
              </div>
            </div>
            <div class="feature-item">
              <span class="feature-icon">🎯</span>
              <div class="feature-text">
                <h4>Posture Detection</h4>
                <p>Real-time AI posture correction while 
                  you exercise using your phone camera</p>
              </div>
            </div>
            <div class="feature-item">
              <span class="feature-icon">💬</span>
              <div class="feature-text">
                <h4>FitBot AI Assistant</h4>
                <p>24/7 AI fitness coach for workout tips, 
                  diet advice and motivation</p>
              </div>
            </div>
            <div class="feature-item">
              <span class="feature-icon">🏆</span>
              <div class="feature-text">
                <h4>Points & Badges</h4>
                <p>Earn points for every workout, meal log 
                  and activity to climb the leaderboard</p>
              </div>
            </div>
          </div>

          <!-- Points banner -->
          <div class="points-banner">
            <h3>🎁 You start with 0 points!</h3>
            <p>Complete your first workout to earn 50 points<br>
              Log your first meal to earn 10 points<br>
              Chat with FitBot to earn 5 points</p>
          </div>

          <!-- Personalized tip -->
          <div class="tips-box">
            <h4>💡 Your First Step</h4>
            <p>Open the FitFusion app and tap 
              <strong>"Get AI Workout"</strong> to receive your 
              first personalized workout plan. Our AI has already 
              analyzed your profile and is ready to guide you!</p>
          </div>

          <p class="text">
            If you have any questions, our admin team is always 
            available to help. You can contact us directly 
            through the app using the 
            <strong>"Contact Admin"</strong> feature.
          </p>

          <p class="text" style="color:#E8845C; font-weight:bold;">
            Let's get started and crush those goals! 💪🔥
          </p>
        </div>

        <!-- Footer -->
        <div class="footer">
          <p>© 2026 FitFusion Gym Management System</p>
          <p>You received this because you joined FitFusion</p>
          <p style="margin-top:8px;">
            Need help? 
            <a href="mailto:${process.env.EMAIL_USER}">
              Contact our support team
            </a>
          </p>
        </div>

      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      member.email,
    subject: `🏋️ Welcome to FitFusion, ${member.name}! Your fitness journey begins`,
    html,
  });
};

// Email to admin when member contacts
const sendContactAdminEmail = async (member, ticket) => {
  const categoryIcons = {
    general:       '💬',
    billing:       '💳',
    technical:     '🔧',
    trainer:       '👨‍💼',
    complaint:     '⚠️',
    suggestion:    '💡',
    membership:    '🏋️',
  };

  const icon = categoryIcons[ticket.category] || '💬';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif;
          background: #f8f8f8; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto;
          background: white; border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { background: linear-gradient(135deg, #1E2A3B, #2D3F56);
          padding: 36px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 24px; }
        .header p { color: rgba(255,255,255,0.7);
          margin: 8px 0 0; }
        .body { padding: 36px; }
        .text { color: #555; line-height: 1.7; font-size: 15px; }
        .member-card { background: #FDF0EB;
          border-radius: 12px; padding: 18px; margin: 20px 0;
          border-left: 4px solid #E8845C; }
        .member-card h3 { color: #E8845C; margin: 0 0 12px; }
        .info-row { display: flex; margin: 6px 0; }
        .info-label { color: #9E9E9E; font-size: 13px;
          width: 100px; flex-shrink: 0; }
        .info-value { color: #1A1A1A; font-size: 13px;
          font-weight: 600; }
        .message-box { background: #F8F9FA;
          border-radius: 12px; padding: 20px; margin: 20px 0;
          border: 1px solid #E8845C30; }
        .message-box h3 { color: #1A1A1A; margin: 0 0 12px;
          font-size: 15px; }
        .message-text { color: #333; line-height: 1.7;
          font-size: 14px; white-space: pre-wrap; }
        .category-badge { display: inline-block;
          background: #E8845C; color: white;
          padding: 4px 14px; border-radius: 20px;
          font-size: 12px; font-weight: bold;
          text-transform: capitalize; margin-bottom: 16px; }
        .footer { background: #f8f8f8; padding: 24px;
          text-align: center; color: #9E9E9E; font-size: 12px;
          border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div style="font-size:40px; margin-bottom:12px;">
            ${icon}
          </div>
          <h1>New Member Message</h1>
          <p>A member has contacted the admin team</p>
        </div>
        <div class="body">
          <div class="category-badge">
            ${icon} ${ticket.category}
          </div>

          <div class="member-card">
            <h3>👤 From Member</h3>
            <div class="info-row">
              <span class="info-label">Name</span>
              <span class="info-value">${member.name}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Email</span>
              <span class="info-value">${member.email}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Goal</span>
              <span class="info-value">
                ${(member.fitnessGoal || 'N/A').replace(/_/g,' ')}
              </span>
            </div>
            <div class="info-row">
              <span class="info-label">Plan</span>
              <span class="info-value">
                ${member.membershipPlanName || 'No plan'}
              </span>
            </div>
          </div>

          <div class="message-box">
            <h3>📝 Subject: ${ticket.subject}</h3>
            <p class="message-text">${ticket.message}</p>
          </div>

          <p class="text">
            Please reply to this member within 24 hours.
            You can respond directly to their email:
            <strong>${member.email}</strong>
          </p>
          <p class="text" style="font-size:12px; color:#9E9E9E;">
            Ticket ID: ${ticket.createdAt}
          </p>
        </div>
        <div class="footer">
          <p>© 2026 FitFusion Admin Notification</p>
          <p>Reply directly to: ${member.email}</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      process.env.EMAIL_USER, // sends to admin email
    replyTo: member.email,           // reply goes to member
    subject: `${icon} [FitFusion] ${ticket.subject} — from ${member.name}`,
    html,
  });
};

// Confirmation email to member
const sendContactConfirmationEmail = async (member, ticket) => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif;
          background: #f8f8f8; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto;
          background: white; border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .header { background: linear-gradient(135deg, #E8845C, #D4673A);
          padding: 36px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 24px; }
        .body { padding: 36px; }
        .text { color: #555; line-height: 1.7; font-size: 15px; }
        .confirm-card { background: #F0FDF4;
          border-radius: 12px; padding: 20px; margin: 20px 0;
          border-left: 4px solid #7CB342; text-align: center; }
        .confirm-card h3 { color: #7CB342; margin: 0 0 8px; }
        .message-preview { background: #F8F9FA;
          border-radius: 12px; padding: 16px; margin: 20px 0;
          border: 1px solid #E0E0E0; }
        .message-preview h4 { color: #9E9E9E; font-size: 12px;
          margin: 0 0 8px; text-transform: uppercase; }
        .message-preview p { color: #333; font-size: 14px;
          margin: 0; line-height: 1.6; }
        .timeline { margin: 24px 0; }
        .timeline-item { display: flex; align-items: flex-start;
          margin-bottom: 16px; }
        .timeline-dot { width: 32px; height: 32px;
          border-radius: 50%; display: flex; align-items: center;
          justify-content: center; font-size: 14px;
          flex-shrink: 0; margin-right: 14px; margin-top: 2px; }
        .timeline-content h4 { margin: 0 0 3px; color: #1A1A1A;
          font-size: 14px; font-weight: bold; }
        .timeline-content p { margin: 0; color: #9E9E9E;
          font-size: 12px; }
        .footer { background: #f8f8f8; padding: 24px;
          text-align: center; color: #9E9E9E; font-size: 12px;
          border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div style="font-size:40px; margin-bottom:12px;">✅</div>
          <h1>Message Received!</h1>
        </div>
        <div class="body">
          <p style="font-size:18px; font-weight:bold; 
            color:#1A1A1A;">
            Hello, ${member.name}!
          </p>

          <div class="confirm-card">
            <h3>✅ Your message has been sent to our admin team</h3>
            <p style="color:#555; margin:0; font-size:14px;">
              We will get back to you within 24 hours
            </p>
          </div>

          <div class="message-preview">
            <h4>📝 Your Message</h4>
            <p><strong>Subject:</strong> ${ticket.subject}</p>
            <p style="margin-top:8px;">${ticket.message}</p>
          </div>

          <div class="timeline">
            <p style="font-weight:bold; color:#1A1A1A; 
              margin-bottom:16px;">
              What happens next:
            </p>
            <div class="timeline-item">
              <div class="timeline-dot" 
                style="background:#E8845C20;">✅</div>
              <div class="timeline-content">
                <h4>Message Received</h4>
                <p>Admin team has been notified</p>
              </div>
            </div>
            <div class="timeline-item">
              <div class="timeline-dot" 
                style="background:#F59E0B20;">👀</div>
              <div class="timeline-content">
                <h4>Under Review</h4>
                <p>Admin will read your message soon</p>
              </div>
            </div>
            <div class="timeline-item">
              <div class="timeline-dot" 
                style="background:#7CB34220;">📧</div>
              <div class="timeline-content">
                <h4>Reply Within 24 Hours</h4>
                <p>Admin will reply to ${member.email}</p>
              </div>
            </div>
          </div>

          <p class="text">
            You can also check your message history in the 
            FitFusion app under 
            <strong>Profile → My Messages</strong>.
          </p>
        </div>
        <div class="footer">
          <p>© 2026 FitFusion Gym Management System</p>
          <p>Please do not reply to this email</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from:    process.env.EMAIL_FROM || `"FitFusion" <${process.env.EMAIL_USER}>`,
    to:      member.email,
    subject: `✅ We received your message — FitFusion Support`,
    html,
  });
};

module.exports = {
  sendTrainerWelcomeEmail,
  sendClassScheduleEmail,
  sendTrainerRequestEmail,
  sendRequestApprovedToMember,
  sendRequestApprovedToTrainer,
  sendRequestRejectedToMember,
  sendWelcomeEmail,
  sendContactAdminEmail,
  sendContactConfirmationEmail,
};
