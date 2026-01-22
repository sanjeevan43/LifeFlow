---
inclusion: always
---

# Flutter Development Guidelines for LifeFlow

## Project Overview
LifeFlow is a Flutter productivity app with Firebase backend for task management, habit tracking, and water intake monitoring.

## Architecture
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions, FCM)
- **State Management**: StatefulWidget with StreamBuilder
- **Navigation**: Bottom Navigation with IndexedStack

## Code Standards

### Dart/Flutter Best Practices
1. **Always use const constructors** where possible for performance
2. **Use named parameters** for widget constructors
3. **Implement proper disposal** for controllers and streams
4. **Use AutomaticKeepAliveClientMixin** for expensive screens
5. **Handle async operations** with proper error handling and mounted checks

### File Organization
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (Task, Habit, Reminder)
├── screens/                  # UI screens
├── services/                 # Business logic (Firebase, Auth, Notifications)
└── widgets/                  # Reusable UI components
```

### Naming Conventions
- **Files**: snake_case (e.g., `task_screen.dart`)
- **Classes**: PascalCase (e.g., `TaskScreen`)
- **Variables**: camelCase (e.g., `taskList`)
- **Private members**: prefix with underscore (e.g., `_loadTasks`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_TIMEOUT`)

## Firebase Integration

### Firestore Collections
- `users/` - User profiles with XP and settings
- `tasks/` - User tasks with completion status
- `habits/` - User habits with streak tracking
- `reminders/` - User reminders with scheduling
- `water_intake/` - Daily water consumption records

### Security Rules
All collections require authentication:
```javascript
allow read, write: if request.auth != null;
```

### Data Operations
- **Always check user authentication** before operations
- **Use transactions** for atomic updates (e.g., XP awards)
- **Handle offline scenarios** gracefully
- **Cache critical data** to reduce reads

## Platform Compatibility

### Web Platform
- Voice background service is NOT supported
- Device permissions have limited support
- Use `kIsWeb` checks for platform-specific code
- Notifications require service worker setup

### Mobile Platform (Android/iOS)
- Full feature support including voice recognition
- Background services work properly
- Device permissions fully functional
- Local notifications work natively

### Platform Checks
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

## Error Handling

### Best Practices
1. **Always wrap Firebase calls** in try-catch blocks
2. **Check mounted state** before setState after async operations
3. **Provide user feedback** via SnackBar for errors
4. **Log errors** for debugging (use debugPrint, not print)
5. **Graceful degradation** when services fail

### Example Pattern
```dart
Future<void> _saveTask() async {
  try {
    await FirebaseService.addTask(taskData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task saved')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

## UI/UX Guidelines

### Theme
- **Primary Color**: #6C63FF (Purple/Indigo)
- **Secondary Color**: #00E5FF (Cyan/Aqua)
- **Background**: #121212 (Pure Black)
- **Surface**: #1E1E1E (Dark Gray)
- **Material Design 3** with dark theme

### Consistency
- Use theme colors from `Theme.of(context)`
- Maintain consistent spacing (8, 16, 24, 32)
- Use consistent border radius (12-16px for cards)
- Follow Material Design guidelines

### Loading States
- Show CircularProgressIndicator for async operations
- Provide meaningful loading messages
- Disable buttons during operations
- Use RefreshIndicator for pull-to-refresh

### Empty States
- Show helpful empty state messages
- Include relevant icons
- Provide clear call-to-action
- Guide users on what to do next

## Testing

### Manual Testing
- Test on both web and mobile platforms
- Verify Firebase operations work
- Check notification permissions
- Test offline scenarios
- Verify XP awards correctly

### Automated Testing
- Use the built-in Test Functions screen
- Run tests after major changes
- Verify all Firebase operations
- Check authentication flow

## Performance Optimization

### Best Practices
1. **Use const constructors** wherever possible
2. **Implement caching** for frequently accessed data
3. **Use AutomaticKeepAliveClientMixin** for expensive screens
4. **Lazy load** large lists with pagination
5. **Dispose controllers** properly to prevent memory leaks

### Firebase Optimization
- Cache user stats (5-minute TTL)
- Use StreamBuilder for real-time updates
- Batch write operations when possible
- Limit query results with `.limit()`

## Common Patterns

### Adding Data
```dart
final docRef = await FirebaseService.addTask({
  'title': title,
  'userId': FirebaseAuth.instance.currentUser!.uid,
  'createdAt': FieldValue.serverTimestamp(),
});
```

### Updating Data
```dart
await FirebaseService.updateTask(taskId, {
  'isCompleted': true,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Streaming Data
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseService.getUserTasks(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return ErrorWidget(snapshot.error);
    if (!snapshot.hasData) return LoadingWidget();
    return ListView(children: ...);
  },
)
```

### Awarding XP
```dart
await GamificationService.awardXP(GamificationService.xpPerTask);
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Task Completed! +10 XP')),
);
```

## Debugging

### Common Issues
1. **Permission Denied**: Check Firestore rules
2. **Data Not Saving**: Verify authentication
3. **Notifications Not Working**: Check permissions
4. **XP Not Awarding**: Check user profile exists

### Debug Tools
- Use Test Functions screen in Profile
- Check browser console (F12) for errors
- Use Flutter DevTools for performance
- Check Firebase Console for data

## Git Workflow

### Commit Messages
- Use clear, descriptive messages
- Format: `[type]: description`
- Types: feat, fix, refactor, docs, style, test

### Before Committing
1. Run `flutter analyze` (should have 0 errors)
2. Test on target platform
3. Verify Firebase operations work
4. Check for console errors

## Dependencies

### Core Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase
- `firebase_messaging`, `flutter_local_notifications` - Notifications
- `google_sign_in` - Google authentication
- `speech_to_text`, `flutter_background_service` - Voice features
- `permission_handler`, `url_launcher` - Device access

### Keep Updated
- Check for security updates regularly
- Test after updating dependencies
- Review breaking changes in changelogs

## Security

### Best Practices
1. **Never commit** Firebase config with sensitive keys
2. **Use environment variables** for secrets
3. **Validate user input** before saving
4. **Sanitize data** from Firestore
5. **Follow least privilege** principle in rules

### Firestore Rules
- Require authentication for all operations
- Validate data structure on write
- Prevent unauthorized access to other users' data
- Use security rules testing in Firebase Console

## Deployment

### Pre-Deployment Checklist
- [ ] All tests pass
- [ ] No console errors
- [ ] Firebase rules are production-ready
- [ ] Google Sign-In configured
- [ ] Notification certificates set up
- [ ] Privacy policy updated
- [ ] App icons and splash screens set

### Build Commands
```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Support & Maintenance

### Regular Tasks
- Monitor Firebase usage and costs
- Review and update dependencies
- Check for user-reported issues
- Update documentation
- Backup Firestore data regularly

### When Adding Features
1. Update this steering file
2. Add tests for new functionality
3. Update user documentation
4. Test on all platforms
5. Update Firebase rules if needed
