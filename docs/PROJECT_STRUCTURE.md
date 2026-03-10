# HDIMSS — Project Structure

```
hdimss/
├── android/                         # Android-specific build config
│   └── app/
│       ├── build.gradle.kts         # App-level Gradle (minSdk, dependencies)
│       ├── google-services.json     # Firebase config (Android)
│       └── src/main/
│           └── kotlin/.../          # MainActivity (future FLAG_SECURE hook)
│
├── ios/                             # iOS-specific build config
│
├── lib/                             # All Dart source code
│   ├── main.dart                    # Entry point; AuthWrapper & UserTypeWrapper routing
│   ├── firebase_options.dart        # Auto-generated Firebase initialization options
│   │
│   ├── const/
│   │   └── secrets.dart             # Gemini API key (should be moved to Cloud Function)
│   │
│   ├── data/
│   │   ├── huhu.dart                # Placeholder (unused)
│   │   └── gemini_service.dart      # Gemini AI singleton with model fallback
│   │
│   ├── services/
│   │   ├── encryption_service.dart  # AES-256-CBC field encryption + PBKDF2 key derivation
│   │   └── access_request_service.dart  # Doctor→Patient access request + session management
│   │
│   └── pages/
│       ├── signup_page.dart         # Login / Sign-up screen (HomeScreen) + privacy consent modal
│       ├── login_form.dart          # Legacy login components (partially unused)
│       ├── user_type_selection.dart # Screen shown when userType is missing
│       ├── consent_screen.dart      # Full-screen privacy consent for legacy accounts
│       │
│       ├── ── DOCTOR SIDE ──
│       ├── dashboard.dart           # Doctor home: 2×2 grid (Add/Update/Delete/View) + drawer
│       ├── ad_patient.dart          # Add patient form → patients/{docId}
│       ├── view_patient.dart        # List + search patients; tap to view details; access requests
│       ├── update_patient.dart      # Thin wrapper → SelectPatientToUpdate
│       ├── select_patient_to_update.dart  # Patient picker for editing
│       ├── edit_patient_details.dart      # Full patient edit form
│       └── delete_patient.dart      # Patient list with delete confirmation
│       │
│       ├── ── PATIENT SIDE ──
│       ├── patient_dashboard.dart   # Bottom nav (6 tabs) + drawer + access-request banner
│       ├── patient_home.dart        # Overview / welcome page (tab 0)
│       ├── patient_personal_details.dart  # Name, contact, address linked from patients doc (tab 1)
│       ├── patient_medicines_allergy.dart # Medications + allergies CRUD; encrypted writes (tab 2)
│       ├── patient_checkups_history.dart  # Checkup history CRUD; encrypted writes (tab 3)
│       ├── patient_appointments.dart      # Appointments CRUD; encrypted writes (tab 4)
│       ├── patient_routine.dart     # Daily routine management (tab 5)
│       ├── patient_profile.dart     # Profile edit + Privacy Mode toggle + PIN setup
│       └── ask_diet_plan.dart       # AI health/diet chat powered by Gemini
│
├── docs/                            # Project documentation (this folder)
│   ├── PROJECT_OVERVIEW.md
│   ├── PROJECT_STRUCTURE.md
│   ├── FEATURES.md
│   ├── TECH_STACK.md
│   └── HOW_TO_USE.md
│
├── firebase.json                    # Firebase CLI config
├── pubspec.yaml                     # Flutter dependencies and asset declarations
└── README.md                        # Top-level project README
```

---

## Key Architectural Boundaries

### `lib/main.dart` — Routing Brain

```
Firebase.initializeApp()
  └─ AuthWrapper (StreamBuilder on FirebaseAuth.authStateChanges)
       ├─ not logged in  → HomeScreen  (/auth)
       └─ logged in      → UserTypeWrapper (FutureBuilder on users/{uid})
            ├─ no userType        → UserTypeSelection
            ├─ no privacyConsent  → ConsentScreen
            ├─ userType=hospital  → Dashboard
            └─ userType=patient   → PatientDashboard
```

### `lib/services/` — Business Logic Layer

| Service | Responsibility |
|---|---|
| `EncryptionService` | Key derivation, secure storage, AES-256 encrypt/decrypt, bulk record transforms |
| `AccessRequestService` | Create/approve/deny access requests; write/read timed access sessions |

### Firestore Collections

```
users/{uid}
  name, email, userType, createdAt
  linkedPatientId           ← patient account ↔ patients doc link
  privacyModeEnabled        ← bool
  privacyConsentAt          ← Timestamp
  privacyConsentVersion     ← '1.0'

  /medications/{id}         ← patient self-entered; optionally encrypted
  /allergies/{id}
  /checkups/{id}
  /appointments/{id}
  /access_sessions/{reqId}  ← 4-hour decrypted snapshot for doctor

patients/{docId}
  name, email, phone, age, gender, address, pin, blood
  'medical history', vaccination, 'current medication', 'family history', allergies
  doctorId, createdAt, updatedAt

access_requests/{reqId}
  patientUid, doctorUid, doctorName, status, requestedAt, expiresAt
```
