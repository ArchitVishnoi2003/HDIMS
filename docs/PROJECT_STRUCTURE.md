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
│   │   └── access_request_service.dart  # Doctor→Patient access request + session + enrichment
│   │
│   └── pages/
│       ├── auth/                          # Authentication & onboarding
│       │   ├── signup_page.dart           # Login / Sign-up screen (HomeScreen) + privacy consent modal
│       │   ├── login_form.dart            # Legacy login components (partially unused)
│       │   ├── auth.dart                  # Auth utilities
│       │   ├── user_type_selection.dart   # Screen shown when userType is missing
│       │   ├── consent_screen.dart        # Full-screen privacy consent for legacy accounts
│       │   └── save_email.dart            # Email save utility
│       │
│       ├── doctor/                        # Doctor / hospital side
│       │   ├── dashboard.dart             # Doctor home: 2×2 grid (Add/Update/Delete/View) + drawer
│       │   ├── ad_patient.dart            # Add patient form → patients/{docId}
│       │   ├── view_patient.dart          # List + search patients; enriched data; access requests; view decrypted records
│       │   ├── update_patient.dart        # Thin wrapper → SelectPatientToUpdate
│       │   ├── select_patient_to_update.dart  # Patient picker; access-gated editing
│       │   ├── edit_patient_details.dart  # Full patient edit form; syncs to users collection
│       │   └── delete_patient.dart        # Patient list with delete confirmation; enriched data
│       │
│       └── patient/                       # Patient side
│           ├── patient_dashboard.dart     # Bottom nav (6 tabs) + drawer + access-request banner + shield icon
│           ├── patient_home.dart          # Overview / welcome page (tab 0)
│           ├── patient_personal_details.dart  # Name, contact, address linked from patients doc (tab 1)
│           ├── patient_medicines_allergy.dart # Medications + allergies CRUD; encrypted writes (tab 2)
│           ├── patient_checkups_history.dart  # Checkup history CRUD; encrypted writes (tab 3)
│           ├── patient_appointments.dart  # Appointments CRUD; encrypted writes (tab 4)
│           ├── patient_routine.dart       # Daily routine management (tab 5)
│           ├── patient_profile.dart       # Profile edit only (name, phone, address, age, blood group)
│           ├── patient_privacy_security.dart  # Privacy Mode toggle + access requests + session management
│           └── ask_diet_plan.dart         # AI health/diet chat powered by Gemini
│
├── docs/                            # Project documentation (this folder)
│   ├── PROJECT_OVERVIEW.md
│   ├── PROJECT_STRUCTURE.md
│   ├── FEATURES.md
│   ├── TECH_STACK.md
│   ├── HOW_TO_USE.md
│   └── DB_STRUCTURE.md
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
| `AccessRequestService` | Create/approve/deny/revoke access requests; write/read timed access sessions; data enrichment from `users` collection |

### `AccessRequestService` Key Methods

| Method | Description |
|---|---|
| `requestAccess()` | Doctor creates a pending access request |
| `approveRequest()` | Patient approves; decrypts records and writes session snapshot |
| `denyRequest()` | Patient denies the request |
| `revokeAccess()` | Patient revokes an active session; deletes snapshot and marks request revoked |
| `hasAccess()` | Checks if doctor has a non-expired approved session |
| `getApprovedRequestId()` | Returns the first valid approved request ID for a doctor-patient pair |
| `readSession()` | Reads decrypted session data; auto-deletes if expired |
| `enrichWithUserData()` | Merges `users` collection data over `patients` collection data for linked accounts; attaches `_userUid` and `_privacyMode` metadata |

### Firestore Collections

```
users/{uid}
  name, email, userType, phone, address, age, bloodGroup, gender,
  weight, height, emergencyContact, createdAt, updatedAt
  linkedPatientId           ← patient account ↔ patients doc link
  privacyModeEnabled        ← bool
  privacyConsentAt          ← Timestamp
  privacyConsentVersion     ← '1.0'
  insuranceProvider, policyNumber, coverageType, validUntil  ← encrypted if privacy on
  chronicConditions         ← List<String>, each item encrypted if privacy on

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
  patientUid, doctorUid, doctorEmail, doctorName
  status ('pending' | 'approved' | 'denied' | 'revoked')
  requestedAt, expiresAt
```

### Access Request Status Lifecycle

```
pending → approved (patient approves → session created, 4hr TTL)
pending → denied   (patient denies)
approved → revoked (patient manually revokes → session deleted)
approved → expired (4hr TTL passes → session auto-deleted on next read)
```
