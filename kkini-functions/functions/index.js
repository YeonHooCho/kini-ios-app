const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = onDocumentCreated(
    "families/{familyId}/chatMessages/{messageId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return null;

      const message = snap.data();
      const familyId = event.params.familyId;
      const senderName = message.senderName || "가족";
      const text = message.text || "메시지가 도착했습니다.";

      // 해당 가족방 내 구성원 중 보낸 사람을 제외한 상대방 FCM 토큰 수집
      const usersSnapshot = await admin
          .firestore()
          .collection("families")
          .doc(familyId)
          .collection("users")
          .get();

      const tokens = [];
      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        if (doc.id !== senderName && data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) return null;

      // 잠금 화면을 즉시 깨우는 High Priority APNs 페이로드
      const payload = {
        notification: {
          title: senderName,
          body: text,
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      return admin.messaging().sendEachForMulticast(payload);
    },
);
