const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://fitfusion-backend-52ef5-default-rtdb.asia-southeast1.firebasedatabase.app/"
});

const db = admin.firestore();
const auth = admin.auth();
const rtdb = admin.database();

module.exports = { admin, db, rtdb, auth };