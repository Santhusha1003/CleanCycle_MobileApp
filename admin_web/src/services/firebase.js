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
 * TEMPORARY DEVELOPMENT AUTHENTICATION:
 * Anonymous sign-in is used so that `request.auth != null` is satisfied for
 * the temporary development Firestore rules. Once Member 01 completes Firebase
 * Authentication and role management, replace signInAnonymously() with the
 * proper Municipal Officer sign-in flow.
 * TODO: Replace anonymous auth with role-based auth when Member 01's auth
 * system is ready.
 */

import { getApp, getApps, initializeApp } from 'firebase/app'
import { getAuth, signInAnonymously } from 'firebase/auth'
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
const app  = getApps().some((app) => app.name === '[DEFAULT]')
  ? getApp()
  : initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db   = getFirestore(app)

// TEMPORARY DEVELOPMENT AUTHENTICATION
// Sign in anonymously so that request.auth != null is satisfied.
// This mirrors the approach used in the Flutter SplashScreen.
// Must later be replaced by Member 01's proper authentication and role-based
// access system. Share one pending sign-in across bootstrap, listeners and CRUD.
let authPromise = null

export function ensureDevAuth() {
  if (!authPromise) {
    authPromise = (async () => {
      // Restore any persisted session before deciding to create an anonymous user.
      await auth.authStateReady()
      if (auth.currentUser) return auth.currentUser
      const credential = await signInAnonymously(auth)
      return credential.user
    })().finally(() => {
      // Allow retry after failure, or a new sign-in if the session is later lost.
      authPromise = null
    })
  }
  return authPromise
}
