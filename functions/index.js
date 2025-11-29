const admin = require('firebase-admin');
const { onCall } = require('firebase-functions/v2/https');
admin.initializeApp();

// Callable function to delete a Firebase Auth user by UID
exports.deleteUser = onCall(async (req, res) => {
  const { uid } = req.data;

  if (!uid) {
    return { success: false, message: 'UID is required' };
  }

  try {
    await admin.auth().deleteUser(uid);
    return { success: true, message: `User ${uid} deleted successfully` };
  } catch (error) {
    return { success: false, message: `Error deleting user: ${error.message}` };
  }
});
