/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBhO_AF-YmZuDBB5d_kEShLX2puR3PL0uA',
  authDomain: 'puremood.firebaseapp.com',
  projectId: 'puremood',
  storageBucket: 'puremood.firebasestorage.app',
  messagingSenderId: '445401180913',
  appId: '1:445401180913:web:97170d1b26370d92b29750'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload && payload.notification && payload.notification.title) || 'PureMood';
  const options = {
    body: (payload && payload.notification && payload.notification.body) || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(title, options);
});
