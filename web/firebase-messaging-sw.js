importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDnm5sEFvwXlLOG3000UwYWFSlTvOd3UuA",
  appId: "1:431075872084:web:05e24f0de4a7b7961fccc1",
  messagingSenderId: "431075872084",
  projectId: "my-app-11ae0",
  authDomain: "my-app-11ae0.firebaseapp.com",
  storageBucket: "my-app-11ae0.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
