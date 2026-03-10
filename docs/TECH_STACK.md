# HDIMS — Tech Stack & Architecture

## Core Technologies

| Layer | Technology | Version / Notes |
|---|---|---|
| UI Framework | Flutter | Dart SDK ≥ 3.4.4 |
| Language | Dart | null-safe |
| State Management | Flutter `setState` + `StreamSubscription` | No external state manager |
| Auth | Firebase Authentication | Email/password |
| Database | Cloud Firestore | NoSQL document store |
| Encryption | `encrypt` package (AES-256-CBC) | ^5.0.3 |
| Secure Key Storage | `flutter_secure_storage` | ^9.2.2 (Android Keystore / iOS Keychain) |
| AI | Google Gemini via `google_generative_ai` | Model fallback chain |
| SVG Assets | `flutter_svg` | Static vector illustrations |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                 Flutter UI Layer                    │
│  Pages  ←─────────────────────────────────────────┐ │
│  (Stateful Widgets, MaterialApp routing)           │ │
└─────────────────┬───────────────────────────────┬─┘ │
                  │ calls                         │ setState
                  ▼                               │
┌─────────────────────────────────────────────────────┐
│              Services Layer                         │
│  EncryptionService   AccessRequestService           │
│  (static helpers)    (static helpers)               │
└───────┬──────────────────┬──────────────────────────┘
        │ flutter_secure   │ Firestore SDK calls
        │ _storage         │
        ▼                  ▼
┌──────────────┐  ┌────────────────────────────────────┐
│ Android      │  │          Cloud Firestore            │
│ Keystore /   │  │  users/  patients/  access_requests │
│ iOS Keychain │  │  (subcollections per user)          │
└──────────────┘  └────────────────────────────────────┘
```

---

## Routing Architecture

All routing is driven by Firebase state — no manual navigation is required after login:

```
MyApp (MaterialApp)
 └─ AuthWrapper  ← StreamBuilder(FirebaseAuth.authStateChanges)
      ├─ unauthenticated  → HomeScreen  (named route /auth)
      └─ authenticated    → UserTypeWrapper
           ├─ FutureBuilder(users/{uid})
           ├─ no userType         → UserTypeSelection
           ├─ privacyConsentAt==null → ConsentScreen
           ├─ userType='hospital' → Dashboard
           └─ userType='patient'  → PatientDashboard
```

Named routes registered in `MaterialApp.routes`:

| Route | Widget |
|---|---|
| `/auth` | `HomeScreen` |
| `/dashboard` | `Dashboard` |
| `/patient-dashboard` | `PatientDashboard` |
| `/user-type-selection` | `UserTypeSelection` |
| `/ask-ai` | `AskAIPage` |

---

## Encryption Architecture

### Key Derivation
```
PIN (6 digits) + Firebase UID
        │
        ▼  50,000 × SHA-256 iterations  (run in background Dart isolate via compute())
        │
   256-bit AES key
        │
        ▼
flutter_secure_storage  →  key: "priv_enc_{uid}"
  (Android Keystore / iOS Keychain — never leaves device)
```

### Per-Field Encryption
```
plaintext string
        │
        ▼  AES-256-CBC, random 16-byte IV
        │
 base64( IV[16] + ciphertext )
        │
        ▼
Firestore value: "enc:<base64string>"
```

- The `enc:` prefix lets `decryptMap()` distinguish encrypted from plaintext fields.
- Non-string fields (timestamps, booleans, numbers) are never encrypted.

### Bulk Transform
`encryptAllRecords` / `decryptAllRecords` iterate over four Firestore subcollections (`medications`, `allergies`, `checkups`, `appointments`) and batch-transform all documents.

### What Gets Encrypted (Privacy Mode ON)

| Location | Fields |
|---|---|
| `users/{uid}` | insuranceProvider, policyNumber, coverageType, validUntil |
| `users/{uid}` | chronicConditions (each list item) |
| `users/{uid}/medications/*` | All string fields |
| `users/{uid}/allergies/*` | All string fields |
| `users/{uid}/checkups/*` | All string fields (including medicines list items) |
| `users/{uid}/appointments/*` | All string fields |

### What Stays Unencrypted
name, email, phone, address, age, gender, weight, height, bloodGroup, emergencyContact, userType, linkedPatientId, privacyModeEnabled

---

## Doctor Access Session Architecture

```
Doctor taps "Request Access"
  │
  ▼
access_requests/{id}  { patientUid, doctorUid, doctorName, status:'pending', requestedAt }
  │
  │  patient_dashboard StreamBuilder watches pending requests
  │  patient_privacy_security page also shows pending requests
  │
  ▼
Patient taps "Approve"
  │
  ▼  AccessRequestService.approveRequest()
  │    1. Read subcollections (medications, allergies, checkups, appointments)
  │    2. Decrypt each map with EncryptionService.decryptMap()
  │    3. Write plaintext snapshot to users/{uid}/access_sessions/{requestId}
  │       with expiresAt = now + 4 hours
  │    4. Update access_requests/{id}.status = 'approved'
  │
  ▼
Doctor reads session via AccessRequestService.readSession()
  │    Checks expiresAt; deletes document if expired; returns null if missing
  │
  ▼
Doctor can view decrypted records (tabbed dialog) and edit patient details
  │
  ▼
Session auto-expires after 4 hours  OR  Patient taps "Revoke"
  │    revokeAccess() deletes session doc + marks request 'revoked'
```

---

## Data Enrichment Architecture

When doctor-side pages (View / Update / Delete) fetch patients from the `patients` collection, `AccessRequestService.enrichWithUserData()` is called to merge data from the `users` collection:

```
patients/{docId}  (doctor-entered data)
        │
        ▼  enrichWithUserData()
        │    1. Query users collection by matching email
        │    2. If linked account found:
        │       - Overlay users fields (name, phone, address, age, bloodGroup, gender) onto patient map
        │       - Attach _userUid (the user's UID) and _privacyMode (bool) as metadata
        │    3. If no linked account: return patient data as-is
        │
        ▼
Enriched patient map used for display and access checks
```

This ensures doctors always see the patient's most up-to-date self-maintained information.

---

## Data Flow: Patient Write (Privacy Mode ON)

```
User fills form → taps Save
        │
        ▼
_prepare(rawMap)
  └─ EncryptionService.encryptMap(uid, rawMap)
        │  for each String field → encrypt() → "enc:<base64>"
        ▼
FirebaseFirestore .collection('users').doc(uid).collection('<subcol>').add(encryptedMap)
```

## Data Flow: Patient Read (Privacy Mode ON)

```
Firestore snapshot arrives via StreamSubscription
        │
        ▼  listener (async)
 EncryptionService.decryptMap(uid, rawMap)
  └─  for each field starting with "enc:" → decrypt() → plaintext string
        │
        ▼
setState({ _items = decryptedList })
        │
        ▼
build() renders from state list (no StreamBuilder in widget tree)
```

---

## Data Flow: Doctor Edit (Linked Patient)

```
Doctor modifies fields → taps Update Patient
        │
        ▼
1. Update patients/{docId} in Firestore
        │
        ▼
2. Query users collection by patient email
        │  If linked account found:
        ▼
3. Update users/{uid} with overlapping fields
   (name, phone, address, age, bloodGroup)
```

---

## Firestore Security Notes

The app currently relies on Firebase Auth UID matching in client-side queries (`where('doctorId', isEqualTo: currentUser.uid)`). Production deployment should add Firestore Security Rules to enforce:

- Patients may only read/write their own subcollections (`request.auth.uid == uid`)
- Doctors may only read patients where `doctorId == request.auth.uid`
- Access sessions may only be read by the `doctorUid` stored in the document
- Access requests may be created only by a doctor; approved/denied/revoked only by the patient
