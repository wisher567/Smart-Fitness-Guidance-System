const { admin, db } = require('./src/config/firebase');

async function createAdmin() {
  const email = 'admin@fitfusion.com';
  const password = 'password123';
  const name = 'FitFusion Admin';

  try {
    let userRecord;
    try {
      // Check if user already exists
      userRecord = await admin.auth().getUserByEmail(email);
      console.log('User already exists in Authentication:', userRecord.uid);
      
      // Update password just in case
      await admin.auth().updateUser(userRecord.uid, { password });
      console.log('Password reset to password123');
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        // Create new user
        userRecord = await admin.auth().createUser({
          email,
          password,
          displayName: name,
        });
        console.log('Created new user in Authentication:', userRecord.uid);
      } else {
        throw e;
      }
    }

    // Set Firestore document
    const userDoc = {
      uid: userRecord.uid,
      email: email,
      name: name,
      role: 'admin',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await db.collection('users').doc(userRecord.uid).set(userDoc);
    console.log(`Successfully set role to 'admin' in Firestore for UID: ${userRecord.uid}`);
    console.log('---');
    console.log('Email:', email);
    console.log('Password:', password);
    console.log('---');
    process.exit(0);

  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
}

createAdmin();
