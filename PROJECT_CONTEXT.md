# HDIMS — Project Context Document

## 1. What Is This App?

**HDIMS** (Health Data Information Management System) is a Flutter mobile application that solves the problem of fragmented, paper-based, and siloed medical records. It provides a **unified digital platform** where:

- **Patients** can view and manage their complete health profile in one place.
- **Doctors / Hospital staff** can create, access, update, and delete patient records as needed during consultations.

The core problem it addresses: when a patient visits a new doctor, the doctor is often unaware of the patient's existing conditions, allergies, current medications, or family history — leading to misdiagnosis or dangerous prescriptions. HDIMS eliminates this risk by making all relevant health data instantly accessible.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ≥3.4.4) |
| State Management | `setState` (no external state manager) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore |
| AI | Google Generative AI (`google_generative_ai` package) — Gemini models |
| UI | Material Design 3, custom gradient theme |
| SVG | `flutter_svg` |
| Platform | Android (primary); iOS theoretically supported |

**Primary color:** `0xFF6C5CE7` (purple-indigo) with `0xFF74B9FF` (light blue) gradient.
**Background color:** `0xFFF8F9FA` (off-white).

---

## 3. Project Structure

```
lib/
├── main.dart                          # App entry, routing, auth wrappers
├── firebase_options.dart              # Firebase configuration (auto-generated)
├── const/
│   ├── secrets.dart                   # Gemini API key (hardcoded — see security note)
│   └── hehe.dart                      # Unused placeholder
├── data/
│   ├── gemini_service.dart            # Gemini AI singleton service
│   └── huhu.dart                      # Empty placeholder
└── pages/
    ├── signup_page.dart               # HomeScreen: combined Login + Signup UI
    ├── user_type_selection.dart       # Account type picker (for existing users w/o type)
    ├── login_form.dart                # Legacy unused login components
    ├── auth.dart                      # Unused
    ├── save_email.dart                # Unused
    │
    ├── dashboard.dart                 # DOCTOR: main dashboard (grid menu)
    ├── ad_patient.dart                # DOCTOR: Add new patient
    ├── view_patient.dart              # DOCTOR: View/search all patients
    ├── update_patient.dart            # DOCTOR: Update patient (thin wrapper)
    ├── select_patient_to_update.dart  # DOCTOR: Select which patient to update
    ├── edit_patient_details.dart      # DOCTOR: Edit form for a selected patient
    ├── delete_patient.dart            # DOCTOR: Delete a patient
    │
    ├── patient_dashboard.dart         # PATIENT: main shell (bottom nav + drawer)
    ├── patient_home.dart              # PATIENT: Home overview (HARDCODED DATA)
    ├── patient_personal_details.dart  # PATIENT: Personal info display (HARDCODED DATA)
    ├── patient_medicines_allergy.dart # PATIENT: Medicines & allergies (HARDCODED DATA)
    ├── patient_checkups_history.dart  # PATIENT: Medical history (HARDCODED DATA)
    ├── patient_appointments.dart      # PATIENT: Appointments (HARDCODED DATA)
    ├── patient_routine.dart           # PATIENT: Daily routine/diet/exercise (HARDCODED DATA)
    ├── patient_profile.dart           # PATIENT: Editable profile (live Firestore)
    └── ask_diet_plan.dart             # AI chat page (live Gemini API)
```

---

## 4. Authentication & User Flow

### Sign Up
1. User opens app → `AuthWrapper` detects no logged-in user → shows `HomeScreen`.
2. User fills name, email, password, selects **Patient** or **Hospital** account type.
3. Firebase Auth creates user → Firestore `users/{uid}` document created with `{name, email, userType, createdAt}`.
4. Navigates to appropriate dashboard.

### Sign In
1. User enters email, password, selects login type (Patient / Hospital).
2. Firebase Auth signs in → `UserTypeWrapper` reads `users/{uid}.userType`.
3. Routes to `Dashboard` (hospital) or `PatientDashboard` (patient).

### Auth State Persistence
`AuthWrapper` listens to `FirebaseAuth.instance.authStateChanges()` — app auto-resumes session on relaunch.

### Edge Case: Missing userType
If a user exists in Auth but has no `userType` field (e.g., old account), `UserTypeSelection` page is shown to let them pick.

---

## 5. Firestore Data Model

### `users` collection
```
users/{uid} {
  name: String
  email: String
  userType: 'hospital' | 'patient'
  createdAt: Timestamp
  // For patients (editable from PatientProfile):
  phone?: String
  address?: String
  age?: int
  bloodGroup?: String
  updatedAt?: Timestamp
}
```

### `patients` collection
Created by doctors. Each document represents a patient record owned by a doctor.
```
patients/{docId} {
  name: String
  email: String
  phone: String
  age: String
  gender: String
  address: String
  pin: String               // Pin code
  blood: String             // Blood group
  'medical history': String
  vaccination: String
  'current medication': String
  'family history': String
  allergies: String
  doctorId: String          // UID of the doctor who created this record
  createdAt: Timestamp
  updatedAt?: Timestamp
}
```

**Note:** There is currently **no cross-link** between the `patients` collection and the `users` collection for patient accounts. The same person may exist as a `users` document (their auth account) AND as a `patients` document (created by their doctor), but these are not linked by any field.

---

## 6. Doctor/Hospital Side — Feature Details

### Dashboard (`dashboard.dart`)
- Fetches doctor's name from `users/{uid}` on load.
- Displays 2×2 grid of action cards: Add Patient, Update Patient, Delete Patient, View Patients.
- Side drawer with same navigation + Sign Out.

### Add Patient (`ad_patient.dart`)
- Form fields: name, email, phone, age, gender, address, pin, blood group, medical history, vaccination, current medications, family history, allergies.
- Validates name + email (required + format).
- Saves to `patients` collection with `doctorId = currentUser.uid`.

### View Patients (`view_patient.dart`)
- Fetches all `patients` where `doctorId == currentUser.uid`.
- Sorted alphabetically by name (client-side).
- Real-time search by name, email, or phone.
- Tap a patient → modal dialog showing all fields.

### Update Patient (`update_patient.dart` → `select_patient_to_update.dart` → `edit_patient_details.dart`)
- Two-step: select patient from searchable list, then edit all fields.
- `EditPatientDetails` pre-populates form, updates Firestore on save.

### Delete Patient (`delete_patient.dart`)
- Searchable list of own patients.
- Tap → confirmation dialog → permanent Firestore delete.

---

## 7. Patient Side — Feature Details

### PatientDashboard (`patient_dashboard.dart`)
Shell widget with:
- **AppBar** with menu button (opens drawer) and logout option (3-dot menu).
- **Bottom Navigation Bar** with 6 tabs.
- **Side Drawer** with full navigation + Profile Settings, Help & Support, Ask AI, About, Sign Out.

| Tab | Page | Status |
|---|---|---|
| 0 — Home | `PatientHome` | Hardcoded dummy data |
| 1 — Details | `PatientPersonalDetails` | Hardcoded dummy data |
| 2 — Medicines | `PatientMedicinesAllergy` | Hardcoded dummy data |
| 3 — History | `PatientCheckupsHistory` | Hardcoded dummy data |
| 4 — Appointments | `PatientAppointments` | Hardcoded dummy data |
| 5 — Routine | `PatientRoutine` | Hardcoded dummy data |

### PatientHome (`patient_home.dart`)
Displays:
- Welcome banner with patient name (hardcoded "John Doe").
- Quick stat cards: weight, height, blood group, age.
- Allergy alert section.
- Quick access grid (Medical History, Appointments, Medicines, Daily Routine, Ask AI).
- Upcoming appointments preview.

### PatientPersonalDetails (`patient_personal_details.dart`)
Displays: basic info, allergies (tagged with severity), chronic conditions, emergency contact, insurance information.
**Note at bottom:** "Your personal details are updated by the hospital staff."

### PatientMedicinesAllergy (`patient_medicines_allergy.dart`)
Displays:
- **Forbidden Medicines** list with severity tags and safe alternatives.
- **Current Medications** list with dosage and frequency.
- **Allergy Information** section.

### PatientCheckupsHistory (`patient_checkups_history.dart`)
Displays past checkup records each with:
- Date, disease/condition, doctor, hospital.
- Vital signs: BP, blood sugar, temperature, weight.
- Prescription image placeholder ("Coming Soon").
- Medicines prescribed.

### PatientAppointments (`patient_appointments.dart`)
Displays upcoming and completed appointments with:
- Doctor, hospital, department, date, time, type, notes.
- Reschedule / Cancel buttons (both are stubs — "coming soon").
- "Book New Appointment" button (stub).

### PatientRoutine (`patient_routine.dart`)
Three-tab view:
- **Daily** — time-based schedule of activities and medicines.
- **Exercise** — recommended exercises with duration, frequency, benefits.
- **Diet** — meal plan with times and dietary restrictions.

### PatientProfile (`patient_profile.dart`)
Live Firestore page. Reads/writes to `users/{uid}`:
- Shows: name (initial avatar), email (read-only), phone, address, age, blood group.
- Edit mode toggle (pencil icon in app bar).
- Saves to Firestore on "Save Changes".

---

## 8. AI Feature — Ask AI (`ask_diet_plan.dart` + `gemini_service.dart`)

### GeminiService
- Singleton pattern.
- Uses `google_generative_ai` package.
- Default model: `gemini-2.5-flash`.
- Falls back through a list of models if the primary one fails.
- API key sourced from `Secrets.geminiApiKey` (hardcoded in `secrets.dart`) or `--dart-define=GEMINI_API_KEY`.
- System prompt: "You are a helpful healthcare assistant. Provide safe, general nutrition guidance. Avoid diagnosing."

### AskAIPage
- Chat-style UI with user/AI message bubbles.
- Suggestion chips on empty state: vegetarian meal plan, low-sodium breakfast, protein snacks, diabetic-friendly dinner.
- Sends prompt to `GeminiService.askDietPlan()`.
- Shows typing indicator while waiting.

---

## 9. Known Issues & Gaps

### Critical
1. **Patient pages use hardcoded data** — all 6 patient bottom-nav pages (`PatientHome` through `PatientRoutine`) display dummy data ("John Doe") instead of real Firestore data. These need to be wired up.
2. **No patient-doctor cross-link** — a patient's own auth account (`users` collection) is not linked to the records created by their doctor (`patients` collection). Patients cannot view what their doctor entered about them.

### Security
3. **Hardcoded Gemini API key** in `lib/const/secrets.dart` — this is committed to the repo and visible in the APK. Should be moved to environment config or a server-side proxy.

### Incomplete Features
4. **Google Sign-In** — button exists on login screen but is not implemented.
5. **Appointments** — booking, rescheduling, and cancellation are all stubbed with "coming soon" messages.
6. **Prescription images** — checkup history shows "Coming Soon" placeholder; no image upload implemented.

### Code Quality
7. **`login_form.dart`** contains a large amount of legacy/unused code: `LoginScreen`, `Background`, `WelcomeScreen`, `Responsive`, `LoginAndSignupBtn`, etc. These reference components that don't exist. The actual login UI is in `signup_page.dart`.
8. **`lib/pages/auth.dart`** and **`lib/pages/save_email.dart`** exist but are not used anywhere in routing.
9. **`lib/data/huhu.dart`** and **`lib/const/hehe.dart`** are empty placeholder files.

---

## 10. App Routes Summary

```dart
'/':                   AuthWrapper → auto-detects session
'/auth':               HomeScreen (login/signup)
'/user-type-selection': UserTypeSelection
'/dashboard':          Dashboard (hospital/doctor)
'/patient-dashboard':  PatientDashboard (patient)
'/ask-ai':             AskAIPage (AI chat)
```

---

## 11. What Needs To Be Built / Fixed (Roadmap)

1. **Connect patient pages to Firestore** — read actual patient data from `users/{uid}` (and potentially `patients/{docId}` if linked to their doctor's record).
2. **Link patients to their doctor records** — when a patient signs up with the same email a doctor used in `ad_patient`, the records should be unified.
3. **Implement appointments CRUD** — real booking, rescheduling, cancellation with Firestore.
4. **Prescription image upload** — Firebase Storage integration.
5. **Remove dead code** — clean up `login_form.dart`, `auth.dart`, `save_email.dart`, placeholder files.
6. **Secure the API key** — move Gemini key out of source code.
7. **Implement Google Sign-In** — if needed.
8. **Fix `PatientHome`** — use real user data instead of "John Doe".
