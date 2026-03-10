# HDIMSS — Features

## Doctor / Hospital Features

### Patient Management
- **Add Patient** — Full registration form: name, email, phone, age, gender, blood group, address, pin code, medical history, vaccinations, current medications, family history, allergies. Saved to `patients` collection with the doctor's UID as `doctorId`.
- **View Patients** — Searchable, alphabetically sorted list of the doctor's patients. Search across name, email, and phone simultaneously. Tap any patient to see a full details dialog. Data is enriched from the patient's `users` collection when a linked account exists, so the doctor sees the patient's own self-maintained data alongside doctor-entered records.
- **Edit Patient** — Update any field of a patient's record; changes reflected in Firestore immediately. When the patient has a linked `users` account, overlapping fields (name, phone, address, age, blood group) are synced to the `users` collection as well. **Access-gated**: if the patient has Privacy Mode enabled, the doctor must have an approved access session before editing.
- **Delete Patient** — Select a patient and permanently remove their record after confirmation. Patient list is enriched with `users` collection data for accurate display.

### Privacy Mode Awareness (Doctor Side)
- When a patient has Privacy Mode enabled, the patient detail dialog shows a **"Privacy Mode Active"** banner.
- A **"Request Access"** button lets the doctor submit an access request to the patient.
- Doctor receives a snack-bar confirmation that the request was sent and is waiting for patient approval.

### Viewing Decrypted Records (After Approval)
- Once a patient approves the access request, the patient detail dialog shows a **"View Records"** button (green).
- Tapping it opens a **tabbed dialog** with four tabs: Medications, Allergies, Checkups, and Appointments — all showing the decrypted data from the patient's access session snapshot.
- Sessions expire automatically after 4 hours.

---

## Patient Features

### Home Dashboard
- Welcome card with the patient's name.
- Quick overview of linked records and health stats.
- Bottom navigation bar with six tabs; hamburger drawer with full menu.

### Personal Details
- Displays the demographic information entered by the doctor (`patients` collection).
- Automatically linked to the patient account by matching email address.

### Medicines & Allergies (Tab 2)
- **Allergies** — Add/edit/delete allergies with allergen name, description, and severity (Low / Medium / High). Severity shown with colour-coded chips.
- **Medications** — Add/edit/delete current medications with name, dosage, frequency, purpose, and start date.
- All writes/reads transparently encrypted when Privacy Mode is active.
- Text overflow protection on all fields displaying potentially encrypted data.

### Checkup History (Tab 3)
- Log medical checkups with date, disease/diagnosis, treatment, attending doctor, hospital, blood pressure, blood sugar, temperature, weight, and current medicines.
- Sorted newest-first.
- All data encrypted at rest when Privacy Mode is active.
- Text overflow protection on all fields displaying potentially encrypted data.

### Appointments (Tab 4)
- Book, edit, and delete appointments with doctor name, hospital, department, date, time, appointment type, notes, and status (Upcoming / Completed / Cancelled).
- Stats row showing upcoming vs. past appointment counts.
- Sections split by status.
- Text overflow protection on all fields displaying potentially encrypted data.

### Daily Routine (Tab 5)
- Manage daily health routines and habits.

### Profile Settings
- Edit display name, phone, address, age, and blood group.
- Profile-only page — privacy and access management are in a dedicated page.

### Privacy & Security (Dedicated Page)
Accessible via the **shield icon** in the AppBar or the **"Privacy & Security"** item in the drawer.

- **Privacy Mode toggle** — enable AES-256 on-device encryption of all self-entered records:
  - Set a 6-digit PIN (must enter twice to confirm).
  - On enable: derives encryption key from PIN + UID, stores key in Android Keystore / iOS Keychain, encrypts all existing records in Firestore subcollections.
  - On disable: decrypts all records back to plaintext, removes key from secure storage.
  - Status badge shows "encrypted" or explains how to enable.

- **Pending Access Requests** — real-time card showing all pending doctor requests with **Approve** and **Deny** buttons.
  - **Approve** — decrypts all subcollection records on-device and writes a plaintext snapshot to `users/{uid}/access_sessions/{requestId}` that automatically expires in 4 hours.
  - **Deny** — marks the request as denied immediately.

- **Active Doctor Sessions** — card showing all currently approved access sessions with:
  - Doctor name and remaining time before expiry.
  - **Revoke** button to immediately terminate access (deletes the session document and marks the request as revoked).

### Doctor Access Request Banner
- A **real-time banner** also appears at the top of the dashboard whenever a doctor has a pending access request, for quick approve/deny without navigating to the Privacy & Security page.

### AI Health Assistant
- Chat interface powered by Google Gemini.
- Provides diet plans and general health advice.
- Supports multiple Gemini model fallbacks for reliability.

---

## Security & Privacy Features

### Privacy Consent at Signup
- New accounts must read and scroll through the full Privacy Policy (8 sections) before tapping "Confirm & Continue".
- Checkbox is locked until the user scrolls to the bottom of the document.
- Consent timestamp (`privacyConsentAt`) and version (`privacyConsentVersion: '1.0'`) are saved to Firestore on account creation.

### Legacy Account Consent Gate
- Existing accounts that pre-date the consent feature are shown a full-screen `ConsentScreen` on their next login.
- The screen cannot be dismissed — only "I Agree" advances to the dashboard.
- Consent fields are written to Firestore; the user is not shown the screen again.

### AES-256 Field-Level Encryption (Privacy Mode)
- Algorithm: AES-256-CBC with a random 16-byte IV per field.
- Stored format: `enc:<base64(IV + ciphertext)>` — visually distinguishable from plaintext.
- Key derivation: 50,000 SHA-256 iterations of `(PIN + UID)` run in a background Dart isolate.
- Key stored exclusively in `flutter_secure_storage` (Android Keystore / iOS Keychain); never sent to any server.

### Time-Limited Doctor Access Sessions
- Approved sessions contain plaintext snapshots stored at `users/{uid}/access_sessions/{requestId}`.
- Sessions carry an `expiresAt` timestamp set to 4 hours after approval.
- On read, `AccessRequestService.readSession()` deletes expired sessions and returns `null`.

### Patient-Controlled Access Revocation
- Patients can revoke any active doctor session at any time from the Privacy & Security page.
- Revocation immediately deletes the session snapshot and marks the access request as `'revoked'`.
