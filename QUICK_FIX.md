# Quick Fix for Firebase Errors

## Go to Firebase Console NOW:

1. **Open**: https://console.firebase.google.com
2. **Select your project**: my-app-11ae0
3. **Go to**: Firestore Database

## Step 1: Fix Security Rules
- Click **Rules** tab
- Replace all content with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

- Click **Publish**

## Step 2: Create Indexes
- Click **Indexes** tab
- Click **Add Index**
- Create these 2 indexes:

**Index 1:**
- Collection: `tasks`
- Field 1: `userId` (Ascending)
- Field 2: `createdAt` (Descending)

**Index 2:**
- Collection: `habits` 
- Field 1: `userId` (Ascending)
- Field 2: `createdAt` (Descending)

## Done!
Your app will work immediately after this.