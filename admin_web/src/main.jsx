import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.jsx'
import { ensureDevAuth } from './services/firebase.js'

/**
 * Bootstrap anonymous Firebase auth before mounting the React app.
 * This ensures request.auth != null is satisfied for all Firestore calls.
 *
 * TEMPORARY DEV AUTH — TODO: Replace with proper Municipal Officer sign-in
 * when Member 01's authentication system is ready.
 */
ensureDevAuth()
  .then(() => {
    createRoot(document.getElementById('root')).render(
      <StrictMode>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </StrictMode>,
    )
  })
  .catch((err) => {
    // Auth failed — still mount the app; individual pages will show error states
    console.error('[DEV AUTH] Anonymous sign-in failed:', err)
    createRoot(document.getElementById('root')).render(
      <StrictMode>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </StrictMode>,
    )
  })
