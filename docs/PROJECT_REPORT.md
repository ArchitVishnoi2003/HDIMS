# HDIMS Project Report

## Features & Working

HDIMS is a Flutter-based mobile application for managing health records and doctor-patient collaboration with privacy-first controls.

- **Doctor workflows**:
  - Add, view, edit, and delete patient profiles.
  - Search patients by name, email, and phone.
  - Send doctor-patient link requests and manage linked patients.
  - Request access to a patient’s encrypted health records and view decrypted data only after patient approval.
- **Patient workflows**:
  - Register as a patient and automatically link to doctor-entered profiles by email.
  - View personal details, current medications, allergies, checkups, appointments, and routine plans.
  - Enable Privacy Mode to encrypt all self-entered records on-device.
  - Approve or deny doctor access requests and revoke active doctor sessions.
- **Core data structures**:
  - `users/{uid}` stores user profiles and patient-generated health records.
  - `patients/{docId}` stores doctor-entered patient records.
  - `access_requests` tracks doctor requests for encrypted record access.
  - `link_requests` tracks doctor-patient linking workflows.
  - Subcollections under `users/{uid}` store medications, allergies, checkups, appointments, and routine plans.
- **Security and privacy controls**:
  - Patient data is optionally encrypted at field-level with AES-256 before storage.
  - Secure storage holds decryption keys on the device; keys are never shared with the server.
  - Doctor access is gated by explicit patient approval and session expiry.

## Problem Statement

Clinical health information is often fragmented, inaccessible, and lacking patient control. HDIMS addresses:

- fragmented records across doctors, clinics, and patients
- the need for a shared platform for doctors and patients
- the need for privacy-preserving access to sensitive health data
- the need for a transparent approval process for doctor access

## Methodology

The project is implemented as a cross-platform Flutter mobile app backed by Firebase services. Key methodology points include:

1. **Modular app architecture**
   - Flutter for a single codebase across Android and iOS.
   - Firebase Authentication for secure sign-in and user identity.
   - Cloud Firestore for structured health record storage and real-time updates.

2. **Separation of roles and data**
   - Doctor-entered data is stored in `patients`.
   - Patient-entered data is stored in `users/{uid}` and subcollections.
   - This separation preserves role-specific workflows while allowing linked views when accounts match.

3. **Privacy Mode and encryption**
   - Patients may enable Privacy Mode to encrypt sensitive records on-device.
   - Encryption uses AES-256 with per-field random IVs.
   - Decryption keys are derived from a PIN and user UID, then stored securely on the device.

4. **Access request workflow**
   - Doctors submit access requests via `access_requests`.
   - Patients see pending requests in real-time and may approve or deny them.
   - Upon approval, a time-limited decrypted snapshot is written to `access_sessions`.
   - Sessions automatically expire after 4 hours and can be revoked by the patient at any time.

5. **Data enrichment and syncing**
   - Doctor profiles are enriched with linked patient `users` data when available.
   - Updates to overlapping fields sync across `patients` and `users` collections for consistency.

6. **User experience design**
   - Doctor dashboard supports fast patient lookup and management.
   - Patient dashboard is organised into tabs for records, routines, privacy, and notifications.

## Results & Insights

- **Improved doctor-patient coordination**: The app enables doctors and patients to connect through link requests and shared records without directly exposing all patient data.
- **Privacy-first sharing**: Patients keep control of their own encrypted records and can approve or deny doctor access in real time.
- **Clear auditability**: Access requests, approvals, denials, and revocations are maintained as structured Firestore records.
- **Consistent record views**: Patients and doctors see the same up-to-date information when a patient account is linked, reducing data mismatch.
- **Session-based access**: Automatic 4-hour session expiry creates a safer sharing model than permanent access grants.

## Novelty

- **Patient-controlled encryption flow**: HDIMS lets patients enable AES-256 encryption for their data and keep the decryption key solely on their device.
- **Explicit access approval**: Doctor access to encrypted patient records is not automatic; it requires a patient-approved request and creates a temporary access session.
- **Privacy-aware doctor workflow**: Doctors can request access from within the patient detail view and are informed when Privacy Mode is active.
- **Link request mechanism**: The app supports doctor-driven linking by email with in-app patient acceptance, making doctor-patient relationships explicit and consensual.
- **Unified mobile management**: A single app serves both hospitals/doctors and patients, integrating record management, privacy controls, and routine planning in one interface.

## Key Takeaways

- HDIMS is built for privacy-first health record management with clear role separation for doctors and patients.
- The system prioritises consent by making doctor access requests explicit and time-limited.
- Encryption is optional but strong, with keys stored securely on the patient device.
- Linked account data enrichment ensures both doctors and patients share a consistent view of health records.
- The app brings together clinical records, consent workflows, and routine planning in a single mobile experience.

## Technical Stack

- **Framework**: Flutter for a single cross-platform mobile experience on Android and iOS.
- **Authentication**: Firebase Authentication for secure login and user identity management.
- **Database**: Cloud Firestore for real-time data storage, structured collections, and access control metadata.
- **Encryption**: AES-256 field-level encryption for sensitive patient data.
- **Secure Storage**: `flutter_secure_storage` for safely storing encryption keys on-device.
- **AI Integration**: Google Gemini for generating personalised patient routines and wellness guidance.

## Security Highlights

- **Patient-consent based access**: Doctors can only view encrypted patient records after explicit approval from the patient.
- **On-device encryption**: Sensitive patient data is encrypted before leaving the device when Privacy Mode is active.
- **Secure key storage**: Decryption keys are stored in platform-provided secure storage and are never transmitted to the server.
- **Time-limited sharing**: Approved doctor sessions expire automatically after 4 hours.
- **Revocation support**: Patients can revoke doctor access immediately, removing the decrypted snapshot.
- **Privacy policy compliance**: Consent is recorded on signup, and legacy accounts are required to agree before access.

## Future Enhancements

- **Role-based analytics**: Add dashboards for doctors and admins to visualise patient trends, appointment load, and treatment history.
- **Advanced consent management**: Introduce granular consent options for sharing specific record categories with different providers.
- **Offline support**: Cache patient records securely for offline viewing while preserving encryption controls.
- **Multi-user collaboration**: Support multiple doctors per patient with shared access management and audit trails.
- **Improved health insights**: Add summarised health metrics, alerts, and recommendations based on patient history.
- **Patient education**: Introduce contextual health education content and reminders alongside routine plans.
