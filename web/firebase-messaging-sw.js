importScripts('https://www.gstatic.com/firebasejs/10.4.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.4.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyB0z_tT1sY9M2oyXWJVDSQpLvfqvoPhwTw",
  authDomain: "ruckup-c4cf1.firebaseapp.com",
  projectId: "ruckup-c4cf1",
  storageBucket: "ruckup-c4cf1.appspot.com",
  messagingSenderId: "1034961980508",
  appId: "1:1034961980508:web:cdb2f3bc13b7ad43602a99"
});

const messaging = firebase.messaging();
