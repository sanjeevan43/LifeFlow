const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Send notification to a specific user by userId
 * Callable function from client or triggered by other functions
 */
exports.sendNotificationToUser = functions.https.onCall(async (data, context) => {
    const { userId, title, body, data: notificationData } = data;

    if (!userId || !title || !body) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    try {
        // Get user's FCM token from Firestore
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }

        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) {
            throw new functions.https.HttpsError('failed-precondition', 'User has no FCM token');
        }

        // Send the notification
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: notificationData || {},
        };

        const response = await messaging.send(message);
        console.log('Notification sent:', response);

        return { success: true, messageId: response };
    } catch (error) {
        console.error('Error sending notification:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Trigger notification when a task is due (runs every hour)
 */
exports.sendTaskReminders = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);

    try {
        // Get tasks due in the next hour that haven't been notified
        const tasksSnapshot = await db.collection('tasks')
            .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(now))
            .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(oneHourFromNow))
            .where('isCompleted', '==', false)
            .where('reminderSent', '==', false)
            .get();

        const notifications = [];

        for (const taskDoc of tasksSnapshot.docs) {
            const task = taskDoc.data();
            const userId = task.userId;

            // Get user's FCM token
            const userDoc = await db.collection('users').doc(userId).get();
            if (!userDoc.exists || !userDoc.data().fcmToken) continue;

            const fcmToken = userDoc.data().fcmToken;

            // Send notification
            const message = {
                token: fcmToken,
                notification: {
                    title: '⏰ Task Reminder',
                    body: `"${task.title}" is due soon!`,
                },
                data: {
                    taskId: taskDoc.id,
                    type: 'task_reminder',
                },
            };

            notifications.push(
                messaging.send(message).then(() => {
                    // Mark as notified
                    return taskDoc.ref.update({ reminderSent: true });
                })
            );
        }

        await Promise.all(notifications);
        console.log(`Sent ${notifications.length} task reminders`);

        return null;
    } catch (error) {
        console.error('Error sending task reminders:', error);
        return null;
    }
});

/**
 * Send streak warning notification (runs daily at 8 PM)
 */
exports.sendStreakWarnings = functions.pubsub.schedule('0 20 * * *')
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        try {
            // Get all habits
            const habitsSnapshot = await db.collection('habits').get();
            const userHabits = {};

            // Group habits by user
            habitsSnapshot.forEach(doc => {
                const habit = doc.data();
                const userId = habit.userId;
                if (!userHabits[userId]) userHabits[userId] = [];
                userHabits[userId].push({ id: doc.id, ...habit });
            });

            const notifications = [];

            for (const [userId, habits] of Object.entries(userHabits)) {
                // Check if any habit not completed today
                const incompleteHabits = habits.filter(h => {
                    if (!h.lastCompleted) return true;
                    const lastDate = h.lastCompleted.toDate();
                    return lastDate < today;
                });

                if (incompleteHabits.length === 0) continue;

                // Get user's FCM token
                const userDoc = await db.collection('users').doc(userId).get();
                if (!userDoc.exists || !userDoc.data().fcmToken) continue;

                const fcmToken = userDoc.data().fcmToken;

                const message = {
                    token: fcmToken,
                    notification: {
                        title: '🔥 Don\'t break your streak!',
                        body: `You have ${incompleteHabits.length} habit(s) to complete today!`,
                    },
                    data: {
                        type: 'streak_warning',
                    },
                };

                notifications.push(messaging.send(message));
            }

            await Promise.all(notifications);
            console.log(`Sent ${notifications.length} streak warnings`);

            return null;
        } catch (error) {
            console.error('Error sending streak warnings:', error);
            return null;
        }
    });

/**
 * Welcome notification when user first signs up
 */
exports.sendWelcomeNotification = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const userId = context.params.userId;
        const userData = snap.data();

        // Wait a bit for FCM token to be saved
        await new Promise(resolve => setTimeout(resolve, 5000));

        // Re-fetch to get FCM token
        const userDoc = await db.collection('users').doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
            console.log('No FCM token for new user:', userId);
            return null;
        }

        try {
            const message = {
                token: fcmToken,
                notification: {
                    title: '🎉 Welcome to LifeFlow!',
                    body: 'Start your productivity journey today. Add your first task!',
                },
                data: {
                    type: 'welcome',
                },
            };

            await messaging.send(message);
            console.log('Welcome notification sent to:', userId);

            return null;
        } catch (error) {
            console.error('Error sending welcome notification:', error);
            return null;
        }
    });
