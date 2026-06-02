const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const DEFAULT_ADMIN_EMAILS = ["nurikslam.beis@gmail.com"];
const SUPPORTED_AUDIENCES = new Set([
  "all_users",
  "professions_access",
  "push_ready",
]);

exports.sendPushCampaign = onCall({region: "us-central1"}, async (request) => {
  const auth = request.auth;
  if (!auth?.uid) {
    throw new HttpsError(
        "unauthenticated",
        "You must sign in before sending a notification campaign.",
    );
  }

  const userSnapshot = await db.collection("users").doc(auth.uid).get();
  const userData = userSnapshot.data() || {};
  const callerEmail = normalizeString(
      auth.token.email || userData.email,
      160,
  ).toLowerCase();
  const callerRole = normalizeString(userData.role, 40).toLowerCase();

  if (!callerEmail) {
    throw new HttpsError(
        "permission-denied",
        "This account does not have access to send notification campaigns.",
    );
  }

  const allowedAdminEmails = getAllowedAdminEmails();
  const isAdmin =
    callerRole === "admin" || allowedAdminEmails.includes(callerEmail);

  if (!isAdmin) {
    throw new HttpsError(
        "permission-denied",
        "Only administrators can send notification campaigns.",
    );
  }

  const title = normalizeString(request.data?.title, 120);
  const body = normalizeString(request.data?.body, 400);
  const audience = normalizeString(request.data?.audience, 40);
  const route = normalizeString(request.data?.route, 160);

  if (!title) {
    throw new HttpsError(
        "invalid-argument",
        "Notification title is required.",
    );
  }

  if (!body) {
    throw new HttpsError(
        "invalid-argument",
        "Notification body is required.",
    );
  }

  if (!SUPPORTED_AUDIENCES.has(audience)) {
    throw new HttpsError(
        "invalid-argument",
        "Unsupported campaign audience.",
    );
  }

  const recipients = await loadRecipients(audience);
  const campaignRef = db.collection("notification_campaigns").doc();

  await campaignRef.set({
    title,
    body,
    audience,
    route,
    status: recipients.length == 0 ? "skipped" : "processing",
    targetedCount: recipients.length,
    successCount: 0,
    failureCount: 0,
    invalidTokenCount: 0,
    sentByUid: auth.uid,
    sentByEmail: callerEmail,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (recipients.length == 0) {
    return {
      success: false,
      campaignId: campaignRef.id,
      audience,
      targetedCount: 0,
      successCount: 0,
      failureCount: 0,
      invalidTokenCount: 0,
      message: "No matching users with active push tokens were found.",
    };
  }

  let successCount = 0;
  let failureCount = 0;
  let invalidTokenCount = 0;

  try {
    const batches = chunkArray(recipients, 500);

    for (const batch of batches) {
      const response = await messaging.sendEachForMulticast({
        tokens: batch.map((item) => item.token),
        notification: {
          title,
          body,
        },
        data: {
          title,
          body,
          audience,
          route,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "learning_updates",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      const invalidRecipients = [];
      response.responses.forEach((item, index) => {
        if (item.success) {
          return;
        }

        const errorCode = item.error?.code || "";
        if (isInvalidTokenError(errorCode)) {
          invalidRecipients.push(batch[index]);
        }

        logger.warn("Push send failed", {
          campaignId: campaignRef.id,
          uid: batch[index].uid,
          errorCode,
          errorMessage: item.error?.message || "",
        });
      });

      if (invalidRecipients.length > 0) {
        invalidTokenCount += invalidRecipients.length;
        await clearInvalidTokens(invalidRecipients);
      }
    }

    await campaignRef.set({
      status: "completed",
      successCount,
      failureCount,
      invalidTokenCount,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    return {
      success: true,
      campaignId: campaignRef.id,
      audience,
      targetedCount: recipients.length,
      successCount,
      failureCount,
      invalidTokenCount,
      message: "Notification campaign sent successfully.",
    };
  } catch (error) {
    logger.error("sendPushCampaign failed", error);

    await campaignRef.set({
      status: "failed",
      failureCount: recipients.length,
      errorMessage: error instanceof Error ? error.message : String(error),
      failedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    throw new HttpsError(
        "internal",
        "Notification campaign could not be sent.",
    );
  }
});

async function loadRecipients(audience) {
  const usersSnapshot = await db.collection("users").get();
  const recipients = [];
  const seenTokens = new Set();

  usersSnapshot.docs.forEach((doc) => {
    const data = doc.data() || {};
    if (!matchesAudience(data, audience)) {
      return;
    }

    const token = normalizeString(data.pushToken, 4096);
    if (!token || seenTokens.has(token)) {
      return;
    }

    seenTokens.add(token);
    recipients.push({
      uid: doc.id,
      token,
    });
  });

  return recipients;
}

function matchesAudience(userData, audience) {
  const notificationsEnabled =
    userData.settings?.notificationsEnabled !== false;
  const permissionStatus = normalizeString(
      userData.notificationPermissionStatus,
      40,
  ).toLowerCase();
  const token = normalizeString(userData.pushToken, 4096);

  const pushReady =
    Boolean(token) &&
    notificationsEnabled &&
    permissionStatus !== "denied" &&
    permissionStatus !== "disabled";

  if (!pushReady) {
    return false;
  }

  if (audience === "professions_access") {
    return userData.hasProfessionsAccess === true;
  }

  if (audience === "push_ready") {
    return true;
  }

  return true;
}

async function clearInvalidTokens(recipients) {
  const writer = db.bulkWriter();

  recipients.forEach((recipient) => {
    writer.set(
        db.collection("users").doc(recipient.uid),
        {
          pushToken: FieldValue.delete(),
          pushTokenUpdatedAt: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
    );
  });

  await writer.close();
}

function chunkArray(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

function normalizeString(value, maxLength) {
  return String(value || "").trim().slice(0, maxLength);
}

function getAllowedAdminEmails() {
  const value = process.env.ALLOWED_ADMIN_EMAILS || "";
  const parsed = value
      .split(",")
      .map((item) => item.trim().toLowerCase())
      .filter(Boolean);

  return parsed.length > 0 ? parsed : DEFAULT_ADMIN_EMAILS;
}

function isInvalidTokenError(errorCode) {
  return [
    "messaging/invalid-registration-token",
    "messaging/registration-token-not-registered",
    "messaging/invalid-argument",
  ].includes(errorCode);
}
