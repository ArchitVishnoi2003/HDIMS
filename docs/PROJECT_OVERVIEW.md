# HDIMS — Project Overview & Use Case

## What is HDIMS?

**HDIMS** (Health Data Information Management & Security System) is a cross-platform mobile application built with Flutter that provides a unified, secure platform for managing patient health records. It bridges the gap between healthcare providers (doctors/hospitals) and their patients by centralising medical data in a single, access-controlled system.

---

## The Problem It Solves

Managing health records in most clinical settings involves:

- Paper files that get lost, damaged, or misfiled
- Patient data siloed across different hospitals and clinics
- Patients who have no easy way to view or contribute to their own records
- No audit trail when records are accessed or modified
- No patient consent mechanism before sensitive data is shared

HDIMS addresses all of the above with a digital-first, privacy-by-design approach.

---

## Who Is It For?

| User Type | Role |
|---|---|
| **Hospital / Doctor** | Adds and manages patient profiles; views medical history; requests access to encrypted records; views decrypted health data after patient approval |
| **Patient** | Views records added by their doctor; self-records medications, allergies, checkups, appointments, and daily routines; controls encryption of their data; approves or revokes doctor access to encrypted records |

---

## Core Use Cases

### For Doctors
1. Register a hospital account and log in.
2. Add new patients with full demographic and medical profiles.
3. View, update, or remove patient records at any time. Patient data is enriched from the `users` collection when a linked patient account exists, ensuring the doctor always sees the most up-to-date information.
4. When a patient has enabled Privacy Mode, request access to their self-entered encrypted records and wait for patient approval.
5. Once approved, view the patient's decrypted medications, allergies, checkups, and appointments in a tabbed dialog. Edit patient records with changes syncing to both `patients` and `users` collections.
6. Access sessions expire automatically after 4 hours — re-request if needed.

### For Patients
1. Register a patient account (linked to their email).
2. The app automatically links the patient account to any existing doctor-entered profile.
3. Browse personal details, medications, allergies, checkup history, appointments, and daily routine — all in one place.
4. Optionally enable **Privacy Mode** to AES-256-encrypt all self-entered health data before it leaves the device.
5. Manage privacy and doctor access from a dedicated **Privacy & Security** page (accessible via the shield icon or drawer).
6. Receive real-time notifications when a doctor requests access to encrypted records; approve or deny with one tap.
7. Revoke any active doctor session at any time — access is terminated immediately.
8. Use the built-in **AI Health Assistant** (powered by Google Gemini) for diet planning and health Q&A.

---

## Key Value Propositions

| Feature | Benefit |
|---|---|
| Unified health record store | Single source of truth for both doctor and patient |
| Patient-controlled encryption | Patients hold the only key; data is private even from the developer |
| Doctor access request flow | Informed consent before any encrypted record is revealed |
| Patient access revocation | Patients can terminate doctor access at any time |
| Data enrichment | Doctors see patient's own self-maintained data, not just doctor-entered records |
| Access-gated editing | Doctors cannot modify records of privacy-enabled patients without approval |
| Privacy consent at signup | GDPR/HIPAA-aligned consent recorded in Firestore with timestamp |
| AI health assistant | Personalised diet and wellness guidance without leaving the app |
| Cross-platform | Android and iOS from a single codebase |
