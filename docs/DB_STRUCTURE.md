# HDIMSS — Firestore Database Structure

## Collections Overview

```
├── users/{uid}                          # All app users (patients & doctors)
│   ├── medications/{docId}              # Patient-entered medications
│   ├── allergies/{docId}                # Patient-entered allergies
│   ├── checkups/{docId}                 # Patient-entered checkup history
│   ├── appointments/{docId}             # Patient-entered appointments
│   └── access_sessions/{requestId}      # Decrypted data snapshots for approved doctors
├── patients/{docId}                     # Doctor-entered patient records
└── access_requests/{docId}              # Doctor→Patient access requests
```

---

## `users/{uid}` — User Accounts

All authenticated users (both patients and doctors).

| Field | Type | Description |
|---|---|---|
| `name` | string | Display name |
| `email` | string | Email address |
| `userType` | string | `'hospital'` or `'patient'` |
| `phone` | string | Phone number |
| `address` | string | Address |
| `age` | int | Age |
| `bloodGroup` | string | Blood group |
| `gender` | string | Gender |
| `weight` | string | Weight |
| `height` | string | Height |
| `emergencyContact` | string | Emergency contact |
| `linkedPatientId` | string? | Auto-linked `patients/{docId}` by email match |
| `privacyModeEnabled` | bool | Whether encryption is active |
| `insuranceProvider` | string | Insurance provider (encrypted if privacy on) |
| `policyNumber` | string | Policy number (encrypted if privacy on) |
| `coverageType` | string | Coverage type (encrypted if privacy on) |
| `validUntil` | string | Insurance validity (encrypted if privacy on) |
| `chronicConditions` | List\<string\> | Chronic conditions (each item encrypted if privacy on) |
| `privacyConsentAt` | timestamp | When privacy policy was accepted |
| `privacyConsentVersion` | string | Privacy policy version accepted (e.g. `'1.0'`) |
| `createdAt` | timestamp | Account creation |
| `updatedAt` | timestamp | Last update |

### `users/{uid}/medications/{docId}`

| Field | Type | Encrypted? |
|---|---|---|
| `name` | string | Yes |
| `dosage` | string | Yes |
| `frequency` | string | Yes |
| `purpose` | string | Yes |
| `startDate` | string | Yes |
| `createdAt` | timestamp | No |

### `users/{uid}/allergies/{docId}`

| Field | Type | Encrypted? |
|---|---|---|
| `allergen` | string | Yes |
| `severity` | string | Yes |
| `description` | string | Yes |
| `createdAt` | timestamp | No |

### `users/{uid}/checkups/{docId}`

| Field | Type | Encrypted? |
|---|---|---|
| `disease` | string | Yes |
| `date` | string | Yes |
| `doctor` | string | Yes |
| `hospital` | string | Yes |
| `treatment` | string | Yes |
| `bp` | string | Yes |
| `sugar` | string | Yes |
| `temp` | string | Yes |
| `weight` | string | Yes |
| `medicines` | List\<string\> | Each item encrypted |
| `createdAt` | timestamp | No |

### `users/{uid}/appointments/{docId}`

| Field | Type | Encrypted? |
|---|---|---|
| `doctor` | string | Yes |
| `hospital` | string | Yes |
| `date` | string | Yes |
| `time` | string | Yes |
| `department` | string | Yes |
| `type` | string | Yes |
| `notes` | string | Yes |
| `status` | string | Yes |
| `createdAt` | timestamp | No |

### `users/{uid}/access_sessions/{requestId}`

Created when a patient approves a doctor's access request. Contains a **decrypted snapshot** of all subcollection records. Auto-expires after 4 hours.

| Field | Type | Description |
|---|---|---|
| `doctorUid` | string | The doctor who has access |
| `medications` | List\<Map\> | Decrypted medication records |
| `allergies` | List\<Map\> | Decrypted allergy records |
| `checkups` | List\<Map\> | Decrypted checkup records |
| `appointments` | List\<Map\> | Decrypted appointment records |
| `expiresAt` | timestamp | Session expiry (4 hours from approval) |

---

## `patients/{docId}` — Doctor-Entered Records

Created by doctors when adding patients. Linked to patient's `users/{uid}` by email.

| Field | Type | Description |
|---|---|---|
| `name` | string | Patient name |
| `email` | string | Patient email (used for linking) |
| `phone` | string | Phone number |
| `age` | string | Age |
| `gender` | string | Gender |
| `address` | string | Address |
| `pin` | string | Pin code |
| `blood` | string | Blood group |
| `medical history` | string | Medical history notes |
| `vaccination` | string | Vaccination records |
| `current medication` | string | Current medications |
| `family history` | string | Family medical history |
| `allergies` | string | Allergies |
| `doctorId` | string | UID of the doctor who created this record |
| `createdAt` | timestamp | Record creation |
| `updatedAt` | timestamp | Last update |

---

## `access_requests/{docId}` — Access Control

Tracks doctor requests to view a patient's encrypted health records.

| Field | Type | Description |
|---|---|---|
| `patientUid` | string | Patient's `users/{uid}` |
| `doctorUid` | string | Doctor's `users/{uid}` |
| `doctorEmail` | string | Doctor's email |
| `doctorName` | string | Doctor's display name |
| `status` | string | `'pending'` \| `'approved'` \| `'denied'` \| `'revoked'` |
| `requestedAt` | timestamp | When the request was made |
| `expiresAt` | timestamp? | When access expires (set on approval, 4 hours) |

### Status Lifecycle

```
pending → approved (patient approves → session created, 4hr TTL)
pending → denied   (patient denies)
approved → revoked (patient manually revokes → session deleted)
approved → expired (4hr TTL passes → session auto-deleted on next read)
```

---

## Encryption Details

- **Algorithm**: AES-256-CBC
- **Key derivation**: PIN + UID → 50,000 rounds SHA-256 (in background isolate)
- **Storage**: Key stored in device secure enclave (Android Keystore / iOS Keychain) via `flutter_secure_storage`
- **Format**: Encrypted values stored as `enc:<base64(iv + ciphertext)>`
- **Prefix check**: All encrypt/decrypt operations check for `enc:` prefix to avoid double-encryption

### What gets encrypted (when Privacy Mode is on)

| Location | Fields |
|---|---|
| `users/{uid}` | insuranceProvider, policyNumber, coverageType, validUntil |
| `users/{uid}` | chronicConditions (each list item) |
| `users/{uid}/medications/*` | All string fields |
| `users/{uid}/allergies/*` | All string fields |
| `users/{uid}/checkups/*` | All string fields (including medicines list items) |
| `users/{uid}/appointments/*` | All string fields |

### What stays unencrypted

name, email, phone, address, age, gender, weight, height, bloodGroup, emergencyContact, userType, linkedPatientId, privacyModeEnabled

---

## Data Enrichment (Doctor Side)

When doctors view/update/delete patients, `AccessRequestService.enrichWithUserData()` merges data from the `users` collection over `patients` collection data:

1. For each patient in the `patients` collection, query `users` by matching email
2. If a linked user account exists, overlay fields: name, phone, address, age, bloodGroup, gender
3. Attach metadata: `_userUid` (the user's Firebase UID) and `_privacyMode` (bool)
4. If no linked account, return `patients` data as-is

This ensures doctors see the patient's own self-maintained information rather than potentially stale doctor-entered data.
