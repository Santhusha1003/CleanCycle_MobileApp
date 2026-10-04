/**
 * Firebase initialization for CleanCycle Admin Web.
 *
 * Uses the same Firebase project as the Flutter mobile app:
 *   Project ID: cleancyclemobileapp
 *
 * These are standard Firebase Web client configuration values — they are
 * safe to include in client-side code. They are NOT admin/service-account
 * credentials.
 *
 * TEMPORARY DEV AUTH:
 * Anonymous sign-in is used so that `request.auth != null` is satisfied for
 * the temporary development Firestore rules. Once Member 01 completes Firebase
 * Authentication and role management, replace signInAnonymously() with the
 * proper Municipal Officer sign-in flow.
 * TODO: Replace anonymous auth with role-based auth when Member 01's auth
 * system is ready.
 */

import { initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously, onAuthStateChanged } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// Firebase Web config — same project as Flutter mobile app
const firebaseConfig = {
  apiKey:            'AIzaSyCeHjbJD76vgczCZcw0yQWZYsOBYKcrAmI',
  authDomain:        'cleancyclemobileapp.firebaseapp.com',
  projectId:         'cleancyclemobileapp',
  storageBucket:     'cleancyclemobileapp.firebasestorage.app',
  messagingSenderId: '734679342852',
  appId:             '1:734679342852:web:894520d8cab8b98a713a51',
  measurementId:     'G-WTLHVWXG3J',
}

// Initialize Firebase (idempotent — safe to call multiple times)
const app  = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db   = getFirestore(app)

// ── TEMPORARY DEV AUTH ───────────────────────────────────────────────────────
// Sign in anonymously so that request.auth != null is satisfied.
// This mirrors the approach used in the Flutter SplashScreen.
// TODO: Replace with proper role-based sign-in when Member 01's auth is ready.
let _authReady = false

export function ensureDevAuth() {
  return new Promise((resolve, reject) => {
    if (_authReady && auth.currentUser) {
      resolve(auth.currentUser)
      return
    }
    onAuthStateChanged(auth, (user) => {
      if (user) {
        _authReady = true
        resolve(user)
      }
    })
    // Trigger anonymous sign-in if not already signed in
    if (!auth.currentUser) {
      signInAnonymously(auth).catch(reject)
    }
  })
}
