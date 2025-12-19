# Firebase Functions Setup for LifeFlow

## Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`

## Deploy Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Functions Included

| Function | Trigger | Description |
|----------|---------|-------------|
| `sendNotificationToUser` | HTTPS Callable | Send notification to specific user |
| `sendTaskReminders` | Every 1 hour | Notify users about tasks due soon |
| `sendStreakWarnings` | Daily at 8 PM IST | Warn users about incomplete habits |
| `sendWelcomeNotification` | User signup | Welcome message to new users |

## Firestore Structure Used

```
users/{userId}
  - fcmToken: string (auto-saved on login)
  - fcmTokenUpdatedAt: timestamp
  - notificationsEnabled: boolean

tasks/{taskId}
  - userId: string
  - title: string
  - dueDate: timestamp
  - isCompleted: boolean
  - reminderSent: boolean (set by function)
```

## Testing Locally

```bash
firebase emulators:start --only functions
```
