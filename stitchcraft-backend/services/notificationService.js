import admin from 'firebase-admin';
import Notification from '../models/Notification.js';
import User from '../models/User.js';

let firebaseInitialized = false;

/**
 * Lazily initialize Firebase Admin SDK if credentials exist
 */
const initFirebase = () => {
  if (firebaseInitialized) return true;
  const apps = admin?.apps || admin?.default?.apps || [];
  if (apps.length > 0) {
    firebaseInitialized = true;
    return true;
  }

  const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountRaw && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return false;
  }

  try {
    let credential;
    if (serviceAccountRaw) {
      if (serviceAccountRaw.trim().startsWith('{')) {
        credential = admin.credential.cert(JSON.parse(serviceAccountRaw));
      } else {
        credential = admin.credential.cert(serviceAccountRaw);
      }
    } else {
      credential = admin.credential.applicationDefault();
    }

    admin.initializeApp({ credential });
    firebaseInitialized = true;
    console.log('[NotificationService] Firebase Admin SDK successfully initialized.');
    return true;
  } catch (error) {
    console.warn('[NotificationService] Failed to initialize Firebase Admin SDK:', error.message);
    return false;
  }
};

/**
 * Register or update an FCM device token for a user
 */
export const registerUserDeviceToken = async (userId, token) => {
  if (!userId || !token) return false;
  try {
    const user = await User.findById(userId);
    if (!user) return false;

    const currentTokens = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
    if (!currentTokens.includes(token)) {
      user.fcmTokens = [...currentTokens, token];
      await user.save();
    }
    return true;
  } catch (error) {
    console.error('[NotificationService] Failed to register device token:', error.message);
    return false;
  }
};

/**
 * Dispatch an in-app and push notification
 *
 * @param {Object} params
 * @param {string} params.shopId - Shop ID for multi-tenant isolation
 * @param {string} [params.customerId] - Associated customer ID
 * @param {string} [params.orderId] - Associated order ID
 * @param {string} [params.title] - Notification title (e.g. 'Order Delivered')
 * @param {string} params.message - Notification body text
 * @param {string} [params.type] - Category (e.g. 'order_status', 'payment', 'inventory')
 * @param {Object} [params.data] - Additional metadata for FCM data payload
 */
export const dispatchNotification = async ({
  shopId,
  customerId,
  orderId,
  title,
  message,
  type = 'general',
  data = {},
}) => {
  if (!shopId || !message) {
    console.warn('[NotificationService] Missing shopId or message for notification');
    return null;
  }

  // 1. Create in-app notification record in DB
  let dbNotification = null;
  try {
    dbNotification = await Notification.create({
      shopId,
      customerId: customerId || null,
      orderId: orderId || null,
      title: title || 'StitchCraft Update',
      message,
      type,
      read: false,
    });
  } catch (err) {
    console.error('[NotificationService] Failed to persist in-app notification:', err.message);
  }

  // 2. Dispatch FCM Push Notifications if Firebase is available
  let pushSentCount = 0;
  try {
    const isReady = initFirebase();
    if (isReady) {
      // Find staff and owners belonging to the shop who have FCM tokens
      const shopUsers = await User.find({ shopId });
      const tokenUserMap = new Map();

      for (const u of shopUsers) {
        const tokens = Array.isArray(u.fcmTokens)
          ? u.fcmTokens
          : (u.fcmToken ? [u.fcmToken] : []);

        for (const tok of tokens) {
          if (typeof tok === 'string' && tok.length > 10) {
            tokenUserMap.set(tok, u);
          }
        }
      }

      const allTokens = Array.from(tokenUserMap.keys());
      if (allTokens.length > 0) {
        const payload = {
          tokens: allTokens,
          notification: {
            title: title || 'StitchCraft',
            body: message,
          },
          data: {
            notificationId: dbNotification ? String(dbNotification._id) : '',
            orderId: orderId ? String(orderId) : '',
            shopId: String(shopId),
            type: String(type),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            ...Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v ?? '')])
            ),
          },
        };

        const response = await admin.messaging().sendEachForMulticast(payload);
        pushSentCount = response.successCount;

        // Clean up invalid or expired tokens
        const staleTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const code = resp.error.code;
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered'
            ) {
              staleTokens.push(allTokens[idx]);
            }
          }
        });

        if (staleTokens.length > 0) {
          for (const u of shopUsers) {
            if (Array.isArray(u.fcmTokens)) {
              const cleaned = u.fcmTokens.filter((t) => !staleTokens.includes(t));
              if (cleaned.length !== u.fcmTokens.length) {
                u.fcmTokens = cleaned;
                await u.save().catch(() => {});
              }
            }
          }
        }
      }
    }
  } catch (pushErr) {
    console.warn('[NotificationService] Push notification dispatch failed:', pushErr.message);
  }

  return {
    notification: dbNotification,
    pushSentCount,
  };
};

export default {
  dispatchNotification,
  registerUserDeviceToken,
};
