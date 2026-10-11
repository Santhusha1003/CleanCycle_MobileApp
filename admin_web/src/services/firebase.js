import { getApp, getApps, initializeApp } from 'firebase/app'
import { getAuth, getIdTokenResult } from 'firebase/auth'
import { doc, getDoc, getFirestore } from 'firebase/firestore'
import { isOfficerRole } from './roles.js'

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

// Never provision anonymous users or change roles from the client.
export async function ensureOfficer() {
  await auth.authStateReady()
  const user = auth.currentUser
  if (!user || user.isAnonymous) throw new Error('Sign in with an existing Municipal Officer account.')
  const token = await getIdTokenResult(user)
  if (isOfficerRole(token.claims.role)) return user
  const profile = await getDoc(doc(db, 'users', user.uid))
  if (!profile.exists() || !isOfficerRole(profile.data().role)) throw new Error('Municipal Officer access requires an officer role in your existing profile or a trusted custom claim. Contact the account administrator.')
  return user
}
