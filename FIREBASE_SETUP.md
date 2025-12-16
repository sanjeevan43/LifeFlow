# Firebase Setup Instructions

## Fix the Errors You're Seeing

### 1. Deploy Firestore Rules
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init firestore

# Deploy rules and indexes
firebase deploy --only firestore
```

### 2. Alternative: Manual Setup in Firebase Console

**Go to Firebase Console → Your Project → Firestore Database**

#### Set Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
    match /habits/{habitId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
    match /water_intake/{docId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
    match /water/{docId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
  }
}
```

#### Create Indexes:
Go to **Indexes** tab and create:

1. **Collection: tasks**
   - userId (Ascending)
   - createdAt (Descending)

2. **Collection: habits**
   - userId (Ascending) 
   - createdAt (Descending)

### 3. Test Authentication
1. Run the app
2. Create a new account first
3. Then try using the features

The errors will be fixed once you:
- ✅ Set proper Firestore rules
- ✅ Create the required indexes
- ✅ Sign in with a valid account