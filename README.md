# HDIMS

**Health Data Information Management & Security System**

A cross-platform Flutter application that provides doctors and patients with a unified, privacy-first platform for managing medical records. Patients can optionally encrypt all self-entered health data on-device using AES-256, with a doctor access-request flow that requires explicit patient approval before any encrypted data is revealed.

---

## Quick Start

```bash
git clone <repo-url>
cd hdimss
flutter pub get
flutterfire configure   # regenerate firebase_options.dart for your Firebase project
flutter run
```

See [docs/HOW_TO_USE.md](docs/HOW_TO_USE.md) for full setup instructions including Firebase configuration and Gemini API key setup.

---

## Features at a Glance

### Doctor Side
- Add, view, update, and delete patient profiles
- Full patient search (name / email / phone)
- Patient data enriched from `users` collection for linked accounts
- Request access to encrypted patient records; patient approves or denies in real-time
- View decrypted records in a tabbed dialog after patient approval
- Edit patient records (access-gated when patient has Privacy Mode on); changes sync to both `patients` and `users` collections

### Patient Side
- Six-tab dashboard: Home, Personal Details, Medicines & Allergies, Checkup History, Appointments, Daily Routine
- All self-entered records are fully editable with add/edit/delete
- **Privacy Mode** — opt-in AES-256 on-device encryption; only the patient holds the key
- Dedicated **Privacy & Security** page (shield icon / drawer) for managing encryption and doctor access
- Real-time access-request banner with Approve / Deny buttons
- Revoke any active doctor session at any time
- AI Health Assistant powered by Google Gemini

### Security & Privacy
- Privacy Policy consent required at signup (scroll-to-read + checkbox)
- Legacy accounts shown full-screen consent gate before dashboard access
- Consent timestamp written to Firestore on agreement
- AES-256-CBC field-level encryption with PBKDF2 key derivation
- Keys stored in Android Keystore / iOS Keychain via `flutter_secure_storage`
- Doctor access sessions expire after 4 hours; patients can revoke anytime

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Dart ≥ 3.4.4) |
| Auth & Database | Firebase Auth + Cloud Firestore |
| Encryption | `encrypt` ^5.0.3 (AES-256-CBC) |
| Secure Storage | `flutter_secure_storage` ^9.2.2 |
| AI | Google Gemini (`google_generative_ai`) |

---

## Documentation

| Document | Description |
|---|---|
| [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md) | What HDIMS is and the problems it solves |
| [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) | File tree, Firestore schema, routing diagram |
| [docs/FEATURES.md](docs/FEATURES.md) | All features with detailed descriptions |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Architecture diagrams, encryption flow, data flow |
| [docs/HOW_TO_USE.md](docs/HOW_TO_USE.md) | Step-by-step setup and usage guide |
| [docs/DB_STRUCTURE.md](docs/DB_STRUCTURE.md) | Complete Firestore database schema |

---

## Project Structure (abbreviated)

```
lib/
├── main.dart                   # Auth routing (AuthWrapper → UserTypeWrapper)
├── services/
│   ├── encryption_service.dart # AES-256 field encryption + PBKDF2
│   └── access_request_service.dart  # Doctor access request flow + data enrichment
└── pages/
    ├── auth/                   # Login, signup, consent, user type selection
    ├── doctor/                 # Doctor dashboard, add/view/edit/delete patient
    └── patient/                # Patient dashboard, tabs, profile, privacy, AI chat
```

---

## License

Private / proprietary. All rights reserved.
