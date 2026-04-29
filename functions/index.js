const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document("messages/{messageId}")
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();

      const threadId = message.threadId;
      const senderId = message.senderId;
      const senderName = message.senderName || "User";
      const text = message.message;

      /// 🔥 GET THREAD
      const threadDoc = await admin
        .firestore()
        .collection("threads")
        .doc(threadId)
        .get();

      if (!threadDoc.exists) return;

      const threadData = threadDoc.data();
      const participants = threadData.participants || [];

      /// 🔥 FIND RECEIVER
      const receiverId = participants.find(
        (id) => id !== senderId
      );

      if (!receiverId) return;

      /// 🔥 GET USER TOKEN
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      const token = userDoc.data()?.fcmToken;

      if (!token) return;

      /// 🔥 SEND PUSH
      const payload = {
        notification: {
          title: senderName,
          body: text,
        },
        data: {
          type: "message",
          threadId: threadId,
          senderId: senderId,
        },
      };

      await admin.messaging().sendToDevice(token, payload);

      console.log("Notification sent successfully");

    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });